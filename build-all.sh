#!/bin/bash
set -e

# Build all steampipe-postgres-fdw plugins
# Each plugin fork is tagged v1.0.0

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

for plugin in "${PLUGINS[@]}"; do
  echo ""
  echo "========================================"
  echo "Building plugin: ${plugin} @ ${VERSION}"
  echo "========================================"
  YES=1 ./build.sh "$plugin" "$VERSION"
done

echo ""
echo "========================================"
echo "All plugins built!"
echo "========================================"

echo ""
echo "To create GitHub releases for all plugins, run:"
echo "  ./release-all.sh"
