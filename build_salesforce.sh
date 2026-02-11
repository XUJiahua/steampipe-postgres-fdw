#!/bin/bash
set -e

PLUGIN=salesforce
PLUGIN_VERSION=v1.3.0
ORIGINAL_MODULE=github.com/turbot/steampipe-plugin-salesforce
FORK_MODULE=github.com/xujiahua/steampipe-plugin-salesforce
PLATFORM=$(uname)

# Determine platform suffix for tar.gz naming
ARCH=$(uname -m)
case "${PLATFORM}_${ARCH}" in
  Linux_x86_64)   PLATFORM_SUFFIX="linux_amd64" ;;
  Linux_aarch64)  PLATFORM_SUFFIX="linux_arm64" ;;
  Darwin_x86_64)  PLATFORM_SUFFIX="darwin_amd64" ;;
  Darwin_arm64)   PLATFORM_SUFFIX="darwin_arm64" ;;
  *) echo "ERROR: unsupported platform ${PLATFORM}_${ARCH}"; exit 1 ;;
esac

# PG versions to build for: use arguments or default to all
if [ $# -gt 0 ]; then
  PG_VERSIONS=("$@")
else
  PG_VERSIONS=(14 15 16 17)
fi

for PG_VER in "${PG_VERSIONS[@]}"; do
  PG_CONFIG="/usr/lib/postgresql/${PG_VER}/bin/pg_config"

  if [ ! -x "$PG_CONFIG" ]; then
    echo "ERROR: pg_config not found for PG ${PG_VER} at ${PG_CONFIG}"
    echo "Install with: sudo apt install postgresql-server-dev-${PG_VER}"
    exit 1
  fi

  echo "========================================"
  echo "Building for PostgreSQL ${PG_VER}"
  echo "  pg_config: ${PG_CONFIG}"
  echo "========================================"

  # Step 1: Generate prebuild.go for this PG version
  rm -f prebuild.go
  make prebuild.go PG_CONFIG="$PG_CONFIG"

  # Step 2: Clean and create work directory
  rm -rf work && mkdir -p work

  # Step 3: Copy source tree (including generated prebuild.go)
  rsync -a --exclude='.git' --exclude='build-*' --exclude='dist/' . work/ >/dev/null 2>&1

  cd work

  # Step 4: Run code generator with original module path (for correct Go imports)
  go run generate/generator.go templates . "$PLUGIN" "$PLUGIN_VERSION" "$ORIGINAL_MODULE"

  # Step 5: Add replace directive to redirect original module to fork
  go mod edit -replace "${ORIGINAL_MODULE}=${FORK_MODULE}@${PLUGIN_VERSION}"

  # Step 6: Tidy dependencies
  go mod tidy

  # Step 7: Build
  make -C ./fdw clean PG_CONFIG="$PG_CONFIG"
  make -C ./fdw go PG_CONFIG="$PG_CONFIG"
  make -C ./fdw PG_CONFIG="$PG_CONFIG"
  make -C ./fdw standalone plugin="$PLUGIN" PG_CONFIG="$PG_CONFIG"

  cd ..

  # Step 8: Copy build artifacts to version-specific directory
  OUTPUT_DIR="build-${PLATFORM}-pg${PG_VER}"
  rm -rf "$OUTPUT_DIR"
  mkdir -p "$OUTPUT_DIR"
  cp -a "work/build-${PLATFORM}/"* "$OUTPUT_DIR/"

  # Step 9: Package as tar.gz matching upstream naming convention
  # Format: steampipe_postgres_<plugin>.pg<ver>.<platform>.tar.gz
  TARBALL_NAME="steampipe_postgres_${PLUGIN}.pg${PG_VER}.${PLATFORM_SUFFIX}.tar.gz"
  TARBALL_DIR="steampipe_postgres_${PLUGIN}.pg${PG_VER}.${PLATFORM_SUFFIX}"
  mkdir -p "dist/${TARBALL_DIR}"
  cp "$OUTPUT_DIR/steampipe_postgres_${PLUGIN}.so" "dist/${TARBALL_DIR}/"
  cp "$OUTPUT_DIR/steampipe_postgres_${PLUGIN}.control" "dist/${TARBALL_DIR}/"
  cp "$OUTPUT_DIR/steampipe_postgres_${PLUGIN}--1.0.sql" "dist/${TARBALL_DIR}/"
  cp "$OUTPUT_DIR/install.sh" "dist/${TARBALL_DIR}/"
  cp "$OUTPUT_DIR/README.md" "dist/${TARBALL_DIR}/"
  tar -czf "dist/${TARBALL_NAME}" -C dist "${TARBALL_DIR}"
  rm -rf "dist/${TARBALL_DIR}"

  # Clean up
  rm -f prebuild.go

  echo "PG ${PG_VER} build complete! Artifacts in ${OUTPUT_DIR}/"
  echo "  Package: dist/${TARBALL_NAME}"
  echo ""
done

echo "========================================"
echo "All builds complete!"
echo ""
echo "Packages:"
ls -lh dist/*.tar.gz
echo ""
echo "To upload to GitHub release:"
echo "  gh release upload ${PLUGIN_VERSION} dist/*.tar.gz --repo ${FORK_MODULE#github.com/} --clobber"
echo "  or"
echo "  gh release create ${PLUGIN_VERSION} dist/*.tar.gz --repo ${FORK_MODULE#github.com/} --title \"${PLUGIN_VERSION}\" --notes \"Steampipe PostgreSQL FDW for Salesforce\""
