#!/bin/bash

set -o pipefail
set -exu
set -C

# entrypoint.sh API
# $1 - sarif-file
# $2 - token
# $3 - repository
# $4 - branch
# $5 - title
# $6 - labels
# $7 - dry-run
SARIF_FILE=$1
TOKEN=$2
REPOSITORY=$3
BRANCH=$4
TITLE=$5
LABELS=$6
DRY_RUN=$7

OWNER=$(echo "$REPOSITORY" | awk -F[/] '{print $1}')
REPO=$(echo "$REPOSITORY" | awk -F[/] '{print $2}')

echo "Convert SARIF file $1"
# sarif-to-issue API
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
