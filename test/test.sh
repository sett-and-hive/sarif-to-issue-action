#!/bin/bash
#
# Flip the mode value to control the --dryRun flag
CONTAINER=issue-test
docker build . -t "$CONTAINER"
export DRY_RUN="true"
export LIVE_RUN="false"
MODE=$DRY_RUN
OUTPUTS_FILE=./test/test-outputs.txt
FIXTURE_FILE=./test/fixtures/codeql.sarif
OWNER=tomwillis608
REPO=sarif-to-issue-action
BRANCH=fake-test-branch
TITLE="Test security issue from build"
LABELS="build"
docker run --rm -v "$(pwd)/test":/app/test "$CONTAINER" "$FIXTURE_FILE" fake-password "$OWNER/$REPO" "$BRANCH" "$TITLE" "$LABELS" "$MODE" 2>&1 | tee $OUTPUTS_FILE
if [ "$MODE" = "$DRY_RUN" ]; then
  TEST_STRING="## Results"
else
  TEST_STRING="HttpError: Bad credentials"
fi
if grep -Fxq "$TEST_STRING" "$OUTPUTS_FILE"; then
  echo
  echo "✅ Test result: passes"

else
  echo
  echo "❌ Test result: fails"
  exit 1
fi
