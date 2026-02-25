#!/bin/bash
set -e

# Build all steampipe-postgres-fdw plugins
#
# ORIGINAL_MODULE is the upstream Go module path declared in go.mod.
# Most are github.com/turbot/..., but some were forked from other authors.
#
# VERSION overrides allow per-plugin tags (e.g., jira uses v2.0.0 because
# its go.mod declares a /v2 module path).

DEFAULT_VERSION="v1.0.0"

declare -A ORIGINAL_MODULES=(
  [btp]="github.com/ajmaradiaga/steampipe-plugin-btp"
  [confluence]="github.com/ellisvalentiner/steampipe-plugin-confluence"
  [cpi]="github.com/vadimklimov/steampipe-plugin-cpi"
  [googlesheets]="github.com/turbot/steampipe-plugin-googlesheets"
  [hubspot]="github.com/turbot/steampipe-plugin-hubspot"
  [jira]="github.com/turbot/steampipe-plugin-jira"
  [servicenow]="github.com/turbot/steampipe-plugin-servicenow"
  [shopify]="github.com/turbot/steampipe-plugin-shopify"
  [stripe]="github.com/turbot/steampipe-plugin-stripe"
  [zoom]="github.com/turbot/steampipe-plugin-zoom"
)

declare -A VERSIONS=(
  [jira]="v2.0.0"
)

PLUGINS=(
  btp
  # confluence  # SKIP: uses steampipe-plugin-sdk/v4, go mod tidy fails on deprecated otel packages
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
  echo ""
  echo "========================================"
  echo "Building plugin: ${plugin} @ ${version}"
  echo "  ORIGINAL_MODULE: ${ORIGINAL_MODULES[$plugin]}"
  echo "========================================"
  YES=1 ORIGINAL_MODULE="${ORIGINAL_MODULES[$plugin]}" ./build.sh "$plugin" "$version"
done

echo ""
echo "========================================"
echo "All plugins built!"
echo "========================================"

echo ""
echo "To create GitHub releases for all plugins, run:"
echo "  ./release-all.sh"
