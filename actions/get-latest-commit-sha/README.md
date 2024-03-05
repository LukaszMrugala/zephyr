# FMOS Get latest commit SHA for last successful/failed/cancelled run for GitHub Actions

[GitHub Action](https://github.com/features/actions)
curling github api with provided information

Only supports **Linux** container.

## Usage

#### Each of the steps return variable into GITHUB_ENV so it can be used elsewhere.
- successful run: env.LATEST_SCUCCESSFUL_RUN_SHA
- failed run: env.LATEST_FAILED_RUN_SHA
- cancelled run: LATEST_CANCELLED_RUN_SHA

```yaml
  - name: get latest commit sha for successful run
    uses: intel-innersource/os.rtos.zephyr.devops.ci/actions/get-latest-commit-sha@main
    with:
      repository: repository-in-owner/repo-format
      event: push
      branch: main
      workflow: workflow-name.yaml
      user: username-used-for-auth
      token: your-token-used-for-auth
      success: true
  - name: get latest commit sha for failed run
    uses: intel-innersource/os.rtos.zephyr.devops.ci/actions/get-latest-commit-sha@main
    with:
      repository: repository-in-owner/repo-format
      event: push
      branch: main
      workflow: workflow-name.yaml
      user: username-used-for-auth
      token: your-token-used-for-auth
      failed: true
  - name: get latest commit sha for cancelled run
    uses: intel-innersource/os.rtos.zephyr.devops.ci/actions/get-latest-commit-sha@main
    with:
      repository: repository-in-owner/repo-format
      event: push
      branch: main
      workflow: workflow-name.yaml
      user: username-used-for-auth
      token: your-token-used-for-auth
      cancelled: true
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
