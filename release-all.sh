#!/bin/bash
set -e

# Create GitHub releases and upload artifacts for all plugins
# Run this after build-all.sh completes successfully

PLUGINS=(
  btp
  confluence
  cpi
  googlesheets
  hubspot
  jira
  servicenow
  shopify
  stripe
  zoom
)

VERSION="v1.0.0"
FORK_ORG="xujiahua"

for plugin in "${PLUGINS[@]}"; do
  REPO="${FORK_ORG}/steampipe-plugin-${plugin}"
  ARTIFACTS=(dist/steampipe_postgres_${plugin}.pg*.tar.gz)

  if [ ${#ARTIFACTS[@]} -eq 0 ] || [ ! -e "${ARTIFACTS[0]}" ]; then
    echo "SKIP ${plugin}: no artifacts found in dist/"
    continue
  fi

  echo "========================================"
  echo "Creating release ${VERSION} for ${REPO}"
  echo "  Artifacts: ${ARTIFACTS[*]}"
  echo "========================================"

  gh release create "${VERSION}" "${ARTIFACTS[@]}" \
    --repo "${REPO}" \
    --title "${VERSION}" \
    --notes "Steampipe PostgreSQL FDW for ${plugin}"

  echo "✓ ${REPO} release created"
  echo ""
done

echo "========================================"
echo "All releases created!"
echo "========================================"
