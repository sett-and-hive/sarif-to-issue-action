# sarif-to-issue-action

A GitHub action for @security-alert/sarif-to-issue

This GitHub action converts a SARIF file with security vulnerability findings
into an issue with the `@security-alert/sarif-to-issue` NPM package.

To run `sarif-to-issue-action` you must determine these values.

These are the inputs to Docker image.

## Inputs

### `sarif-file`

Path to SARIF file to add to the issue.
Required.

### `token`

Your GitHub Access Token.
For example, `${{ secrets.GITHUB_TOKEN }}`.
Required.

### `repository`

GitHub repository where this action will run, in owner/repo format.
For example, `${{ github.repository }}`.
Required.

### `branch`

Branch the PR is on.
For example, `${{ github.head_ref }}`.
Required.

### `title`

Title for the issue.
Default: `SARIF vulnerabilities report`.

### `labels`

Labels for the issue.
Default: `security`.

### `dry-run`

If true, do not post the results to a PR. If false, do post the results to the PR.
Default: false

## Example usage

Add this action to your own GitHub action yaml file, replacing the value in
`sarif-file` with the path to the file you want to convert
and add to your image, likely the output of a
security scanning tool.

```yaml
- name: Post SARIF findings in an issue
  if: github.event_name == 'pull_request'
  uses: tomwillis608/sarif-to-issue-action@v1
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    repository: ${{ github.repository }}
    branch: ${{ github.head_ref }}
    sarif-file: scan/results/xss.sarif
    title: My security issue
    labels: security
    dry-run: false
```

If you want to test locally with `nektos/act`, you will need to add
values that work locally with `act`.  Make sure you use an action VM that contains
the Docker client, like `ubuntu-latest=catthehacker`.

```console
act -P ubuntu-latest=catthehacker/ubuntu:act-20.04 -j test pull_request
```

With a section in your `test` job similar to this:

```yaml
- name: Post SARIF findings in the image
  if: github.event_name == 'pull_request'
  uses: tomwillis608/sarif-to-issue-action@main
  with:
    token: fake-secret
    repository: ${{ github.repository }}
    branch: your-branch
    sarif-file: ./test/fixtures/codeql.sarif
    title: My security issue
    labels: security-test
    dry-run: true
```

## Testing

There is a simple test that builds and runs the Dockerfile and does a dry run of
`@security-alert/sarif-to-issue` with a test fixture file with known vulnerabilities.

```console
test/test.sh
```

## CI

There are two files that perform different tests on the repository.
[issue-test.yaml workflow](./.github/workflow/issue-test.yaml) uses the
`tomwillis608/sarif-to-issue-action` action as one would in their own action workflow.

[ci-test.yaml workflow](./.github/workflow/ci-test.yaml) runs the same test
script used to develop the action in this repository, ``test/test.sh`.

## Notes

### Support for OWASP dependency-check

To make an OWASP dependency-check SARIF file work for the converter,
you need to add an expected `defaultConfiguration` element to each `rules` object.

```console
jq '.runs[].tool.driver.rules[] |= . +
  {"defaultConfiguration": { "level": "error"}}' test/fixtures/odc.sarif >odc-mod.sarif
```
