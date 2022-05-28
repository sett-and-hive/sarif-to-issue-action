#!/bin/bash
#
# Flip the mode value to control the --dryRun flag

create_docker_image() {
  TEST_IMAGE=issue-test-image
  docker build . -t "$TEST_IMAGE" -q
}

run_docker() {
  docker run --rm -v "$(pwd)/test":/app/test "$1" "$2" fake-password "$OWNER/$REPO" "$BRANCH" "$TITLE" "$LABELS" "$MODE" 2>&1 | tee "$OUTPUTS_FILE"
  echo "$OUTPUTS_FILE"
}

test_string() {
  if [ "$1" = "$DRY_RUN" ]; then
    echo "## Results"
  else
    echo "HttpError: Bad credentials"
  fi
}

test_result() {
  if grep -Fxq "$TEST_STRING" "$OUTPUTS_FILE"; then
    echo
    echo "✅ Test result: passes"
  else
    echo
    echo "❌ Test result: fails"
    exit 1
  fi
}

run_test() {
  run_docker "$IMAGE" "$1"
  TEST_STRING=$(test_string "$MODE")
  test_result "$TEST_STRING"
}

###
# Script starts here
###
export DRY_RUN="true"
export LIVE_RUN="false"
MODE=$DRY_RUN
OUTPUTS_FILE=./test/test-outputs.txt
OWNER=tomwillis608
REPO=sarif-to-issue-action
BRANCH=fake-test-branch
TITLE="Test security issue from build"
LABELS="build"

rm -f $OUTPUTS_FILE
IMAGE=$(create_docker_image)
echo "$IMAGE"

# shellcheck disable=SC2043
# remove this disable when we loop over multiple files
for testfile in "./test/fixtures/codeql.sarif"; do
  echo "$testfile"
  run_test "$testfile"
done
#FIXTURE_FILE=./test/fixtures/codeql.sarif
# FIXTURE_FILE=./test/fixtures/odc.sarif
