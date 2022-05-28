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

### `odc-sarif`

If true, the SARIF input is formatted in the
[OWASP Dependency Check](https://owasp.org/www-project-dependency-check/)
dialect and the input file will be modified so that the action can
correctly parse the SARIF. If false, as for CodeQL SARIF, do nothing extra.
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

If you want to test locally with [`nektos/act`](https://github.com/nektos/act),
you will need to add choose a VM runner with `docker` so the tests work locally with
`act`.  Make sure you use an [action VM runner](https://github.com/nektos/act#runners)
that contains the Docker client, like `ubuntu-latest=catthehacker`.

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

You will need to give you job write permissions for issues for this action to succeed.

### Sample action file

```yaml
# A workflow that posts SARIF results to an issue

name: Your security scan workflow

on:
  pull_request:
    branches: [main]
  schedule:
    - cron: "0 3 * * *"
  workflow_dispatch:

permissions:
  issues: write

jobs:
  issue:
    runs-on: ubuntu-latest
    name: Run the scan that generates a SARIF file

    steps:

      - name: Checkout
        uses: actions/checkout@v3

      # Your actual scanning step here
      - name: Your security scanner that generates SARIF output
        uses: your-favorite/security-scanner@main
        with:
            format: SARIF
            report-path: ./report/scan-findings.sarif

      - name: Post SARIF findings in the issue
        uses: tomwillis608/sarif-to-issue-action@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          repository: ${{ github.repository }}
          branch: ${{ github.head_ref }}
          sarif-file: ./report/scan-findings.sarif
          title: "Security scanning results"
          labels: security
          odc-sarif: false
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

## Contributing

Pull requests and stars are always welcome.

For bugs and feature requests, [please create an issue](https://github.com/tomwillis608/sarif-to-issue-action/issues).

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :star:
