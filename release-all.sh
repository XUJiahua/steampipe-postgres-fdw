#!/bin/bash
set -e

# Create GitHub releases and upload artifacts for all plugins
# Run this after build-all.sh completes successfully

DEFAULT_VERSION="v1.0.0"
FORK_ORG="xujiahua"

declare -A VERSIONS=(
  [jira]="v2.0.0"
)

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

for plugin in "${PLUGINS[@]}"; do
  version="${VERSIONS[$plugin]:-$DEFAULT_VERSION}"
  REPO="${FORK_ORG}/steampipe-plugin-${plugin}"
  ARTIFACTS=(dist/steampipe_postgres_${plugin}.pg*.tar.gz)

  if [ ${#ARTIFACTS[@]} -eq 0 ] || [ ! -e "${ARTIFACTS[0]}" ]; then
    echo "SKIP ${plugin}: no artifacts found in dist/"
    continue
  fi

  echo "========================================"
  echo "Creating release ${version} for ${REPO}"
  echo "  Artifacts: ${ARTIFACTS[*]}"
  echo "========================================"

  gh release create "${version}" "${ARTIFACTS[@]}" \
    --repo "${REPO}" \
    --title "${version}" \
    --notes "Steampipe PostgreSQL FDW for ${plugin}"

  echo "✓ ${REPO} release created"
  echo ""
done

echo "========================================"
echo "All releases created!"
echo "========================================"
