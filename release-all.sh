#!/bin/bash
set -e

# Create GitHub releases and upload artifacts for all plugins
# Run this after build-all.sh completes successfully

DEFAULT_VERSION="v1.0.0"
FORK_ORG="xujiahua"

declare -A VERSIONS=(
  [github]="v1.7.0"
  [jira]="v2.0.0"
  [salesforce]="v1.4.0"
)

PLUGINS=(
  btp
  confluence
  cpi
  github
  googlesheets
  hubspot
  jira
  salesforce
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
  echo "Releasing ${version} for ${REPO}"
  echo "  Artifacts: ${ARTIFACTS[*]}"
  echo "========================================"

  if gh release view "${version}" --repo "${REPO}" &>/dev/null; then
    echo "Release ${version} already exists, uploading artifacts..."
    gh release upload "${version}" "${ARTIFACTS[@]}" \
      --repo "${REPO}" \
      --clobber
    echo "✓ ${REPO} artifacts uploaded"
  else
    gh release create "${version}" "${ARTIFACTS[@]}" \
      --repo "${REPO}" \
      --title "${version}" \
      --notes "Steampipe PostgreSQL FDW for ${plugin}"
    echo "✓ ${REPO} release created"
  fi
  echo ""
done

echo "========================================"
echo "All releases created!"
echo "========================================"
