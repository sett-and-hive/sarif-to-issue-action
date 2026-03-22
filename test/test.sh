#!/bin/bash
#
# Flip the mode value to control the --dryRun flag

create_docker_image() {
  TEST_IMAGE=issue-test-image
  docker build . -t "$TEST_IMAGE" -q
}

run_docker() {
  image="$1"
  sarif_file="$2"
  odc_sarif="$3"
  docker run --rm -v "$(pwd)/test":/app/test "$image" "$sarif_file" fake-password "$OWNER/$REPO" "$BRANCH" "$TITLE" "$LABELS" "$MODE" "$odc_sarif" 2>&1 | tee "$OUTPUTS_FILE"
  echo "$OUTPUTS_FILE"
}

# Run docker with the test fixtures mounted under GITHUB_WORKSPACE so that
# an absolute "host" path (simulating ${{ github.workspace }}/...) is resolved
# correctly by entrypoint.sh's path-resolution logic.
run_docker_absolute_path() {
  image="$1"
  sarif_file="$2"
  odc_sarif="$3"
  docker run --rm \
    -v "$(pwd)/test":/github/workspace/test \
    -e GITHUB_WORKSPACE=/github/workspace \
    "$image" "$sarif_file" fake-password "$OWNER/$REPO" "$BRANCH" "$TITLE" "$LABELS" "$MODE" "$odc_sarif" 2>&1 | tee "$OUTPUTS_FILE"
  echo "$OUTPUTS_FILE"
}

test_string() {
  mode=$1
  if [ "$mode" = "$DRY_RUN" ]; then
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
  sarif_file="$1"
  odc_sarif="$2"
  run_docker "$IMAGE" "$sarif_file" "$odc_sarif"
  TEST_STRING=$(test_string "$MODE")
  test_result "$TEST_STRING"
}

# Like run_test but uses the absolute-path docker runner and additionally
# verifies that the resolution note message (with the expected resolved path)
# appears in the output.
run_test_absolute_path() {
  sarif_file="$1"
  odc_sarif="$2"
  expected_resolved_path="$3"
  run_docker_absolute_path "$IMAGE" "$sarif_file" "$odc_sarif"
  TEST_STRING=$(test_string "$MODE")
  test_result "$TEST_STRING"
  if grep -q "Note: Resolved SARIF file path to: $expected_resolved_path" "$OUTPUTS_FILE"; then
    echo
    echo "✅ Path resolution note found in output"
  else
    echo
    echo "❌ Path resolution note not found in output (expected: $expected_resolved_path)"
    exit 1
  fi
}

###
# Script starts here
###
export DRY_RUN="true"
export LIVE_RUN="false"
MODE=$DRY_RUN
OUTPUTS_FILE=./test/test-outputs.txt
OWNER=sett-and-hive
REPO=sarif-to-issue-action
BRANCH=fake-test-branch
TITLE="Test security issue from build"
LABELS="build"

rm -f $OUTPUTS_FILE
IMAGE=$(create_docker_image)
echo "$IMAGE"

CODEQL_FIXTURE="./test/fixtures/codeql.sarif"
ODC_FIXTURE="./test/fixtures/odc.sarif"

run_test "$CODEQL_FIXTURE" "false"
run_test "$ODC_FIXTURE" "true"

# Test that an absolute path (simulating ${{ github.workspace }}/...) is
# resolved correctly inside the Docker container.
# The fake prefix "/home/runner/work/owner/repo" won't exist in the container;
# the entrypoint should strip it and find the file under GITHUB_WORKSPACE.
CODEQL_ABSOLUTE="/home/runner/work/owner/repo/test/fixtures/codeql.sarif"
ODC_ABSOLUTE="/home/runner/work/owner/repo/test/fixtures/odc.sarif"

run_test_absolute_path "$CODEQL_ABSOLUTE" "false" "/github/workspace/test/fixtures/codeql.sarif"
run_test_absolute_path "$ODC_ABSOLUTE" "true" "/github/workspace/test/fixtures/odc.sarif"
