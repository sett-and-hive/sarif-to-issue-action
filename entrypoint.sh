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

# Resolve the SARIF file path.
# If an absolute path is provided (e.g., via ${{ github.workspace }}) it will
# not resolve correctly inside this Docker container where the workspace is
# mounted at /github/workspace. Convert absolute paths to be relative to
# GITHUB_WORKSPACE when the file cannot be found at the absolute path.
if [[ "$SARIF_FILE" = /* ]] && [ ! -f "$SARIF_FILE" ]; then
  WORKSPACE="${GITHUB_WORKSPACE:-/github/workspace}"
  # Strip leading path components one at a time and check each candidate.
  # This handles paths like ${{ github.workspace }}/relative/path that expand
  # to a host runner path not accessible inside the Docker container.
  REMAINDER="${SARIF_FILE#/}"
  RESOLVED=false
  while [[ "$REMAINDER" == */* ]]; do
    REMAINDER="${REMAINDER#*/}"
    CANDIDATE="${WORKSPACE}/${REMAINDER}"
    if [ -f "$CANDIDATE" ]; then
      echo "Note: Resolved SARIF file path to: $CANDIDATE"
      SARIF_FILE="$CANDIDATE"
      RESOLVED=true
      break
    fi
  done
  if [ "$RESOLVED" = false ]; then
    echo "Error: Could not resolve SARIF file path '$1' inside the container."
    echo "Hint: Use a relative path instead of \${{ github.workspace }} for the sarif-file input."
    exit 1
  fi
fi

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
echo "output=$?" >>"$GITHUB_OUTPUT"
