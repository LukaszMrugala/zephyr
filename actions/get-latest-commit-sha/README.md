# FMOS Get latest commit SHA for last successful/failed/cancelled run for GitHub Actions

[GitHub Action](https://github.com/features/actions)
curling github api with provided information

Only supports **Linux** container.

## Usage

#### Each of the steps return SHA into GITHUB_OUTPUT so it can be used elsewhere.
- successful run: successful-commit-sha
- failed run: failed-commit-sha
- cancelled run: cancelled-commit-sha

```yaml
  # SHA of successful run
  - name: get latest commit sha for successful run
    id: latest-successful-run-sha
    uses: intel-innersource/os.rtos.zephyr.devops.ci/actions/get-latest-commit-sha@main
    with:
      repository: repository-in-owner/repo-format
      event: push
      branch: main
      workflow: workflow-name.yaml
      user: username-used-for-auth
      token: your-token-used-for-auth
      success: true
      pages-to-parse: 20
  
  ## Usage in workflow
  - name: Checkout upstream branch with ${{ steps.latest-successful-run-sha.outputs.commit-sha }} SHA (main)
    uses: actions/checkout@v3.1.0
    with:
      ref: ${{ steps.latest-successful-run-sha.outputs.commit-sha }}
      fetch-depth: 0

  # SHA of failed run
  - name: get latest commit sha for failed run
    id: latest-failed-run-sha
    uses: intel-innersource/os.rtos.zephyr.devops.ci/actions/get-latest-commit-sha@main
    with:
      repository: repository-in-owner/repo-format
      event: push
      branch: main
      workflow: workflow-name.yaml
      user: username-used-for-auth
      token: your-token-used-for-auth
      failed: true
      pages-to-parse: 20

  ## Usage in workflow
  - name: Checkout upstream branch with ${{ steps.latest-failed-run-sha.outputs.commit-sha }} SHA (main)
    uses: actions/checkout@v3.1.0
    with:
      ref: ${{ steps.latest-failed-run-sha.outputs.commit-sha }}
      fetch-depth: 0

  # SHA of cancelled run
  - name: get latest commit sha for cancelled run
    id: latest-cancelled-run-sha
    uses: intel-innersource/os.rtos.zephyr.devops.ci/actions/get-latest-commit-sha@main
    with:
      repository: repository-in-owner/repo-format
      event: push
      branch: main
      workflow: workflow-name.yaml
      user: username-used-for-auth
      token: your-token-used-for-auth
      cancelled: true
      pages-to-parse: 20

  ## Usage in workflow
  - name: Checkout upstream branch with ${{ steps.latest-cancelled-run-sha.outputs.commit-sha }} SHA (main)
    uses: actions/checkout@v3.1.0
    with:
      ref: ${{ steps.latest-cancelled-run-sha.outputs.commit-sha }}
      fetch-depth: 0
```

## Input variables

See the [action.yml](./action.yml) file for more detail information.

* repository: repository-in-owner/repo-format which is a fetch target (**required**)
* user: username used for auth to github api (**required**)
* token: token used for auth to github api (**required**)
* workflow: name of the workflow that executes the run (**required**)
* event: event from which sha will be fetched push/schedule/pull_request (default **push**)
* branch: branch from which workflow will be used to fetch sha (default **main**)
* success: only successful runs will be fetched (default **false**)
* failed: only failed runs will be fetched (default **false**)
* cancelled: only cancelled runs will be fetched (default **false**)
* pages-to-parse: number of pages to parse looking for sha (default **20**)

## Output variables

See [github outputs docs](https://docs.github.com/en/actions/using-jobs/defining-outputs-for-jobs) for more information about outputs usage.

* successful-commit-sha: commit SHA of successful run
* failed-commit-sha: commit SHA of failed run
* cancelled-commit-sha: commit SHA of cancelled run
