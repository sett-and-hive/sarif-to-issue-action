#!/bin/bash

# entrypoint.sh API
# $1 - sarif-file
# $2 - token
# $3 - repository
# $4 - branch
# $5 - title
# $6 - labels
# $7 - dry-run
# $8 - odc-sarif

set -o pipefail
set -exu
set -C

fix_odc_sarif() {
  ord_sarif="$SARIF_FILE"
  mod_sarif="$SARIF_FILE.mod"
  rm -f "$SARIF_FILE.mod"
  jq '.runs[].tool.driver.rules[] |= . + {"defaultConfiguration": { "level": "error"}}' "$ord_sarif" >"$mod_sarif"
  SARIF_FILE="$mod_sarif"
}

SARIF_FILE=$1
TOKEN=$2
REPOSITORY=$3
BRANCH=$4
TITLE=$5
LABELS=$6
DRY_RUN=$7
ODC_SARIF=$8

OWNER=$(echo "$REPOSITORY" | awk -F[/] '{print $1}')
REPO=$(echo "$REPOSITORY" | awk -F[/] '{print $2}')

if [ "$ODC_SARIF" == "true" ]; then
  fix_odc_sarif
fi

echo "Convert SARIF file $1"
# sarif-to-issue API
# --token
# --title
# --owner
# --repo
# --sarifContentOwner
# --sarifContentRepo
# --sarifContentBranch
# --dryRun
# --labels
# sarif-file-path
npx @security-alert/sarif-to-issue --dryRun "$DRY_RUN" --token "$TOKEN" --owner "$OWNER" --sarifContentOwner "$OWNER" --repo "$REPO" --sarifContentRepo "$REPO" --sarifContentBranch "$BRANCH" --title "$TITLE" --labels "$LABELS" "$SARIF_FILE"
echo "::set-output name=output::$?"
