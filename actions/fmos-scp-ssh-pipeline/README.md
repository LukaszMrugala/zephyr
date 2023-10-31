# FMOS SCP-SSH pipeline for GitHub Actions

[GitHub Action](https://github.com/features/actions)
for copying files and executing commands via SSH

Only support **Linux** container.

## Usage

```yaml
name: fmos scp ssh pipeline
on:
  workflow_dispatch:
jobs:
  build:
    name: Build
    runs-on: guest-hv1-fmos-3
    container: 
      image: amr-registry.caas.intel.com/zephyrproject/ci-sdk:v0.26.4.5
      options: "-v /srv/runner/workspace:/runner/workspace"
    steps:
    - uses: actions/checkout@v3
    - name: copy files via ssh
      uses: intel-innersource/os.rtos.zephyr.devops.ci/actions/fmos-scp-ssh-pipeline@main
      with:
        hostname: your-host-name
        ssh-user: user-name-for-connect-to-host
        ssh-key: ${{ secrets.SSH-KEY }}
        scp-src: "$HOME/actions/test/twister.json, $HOME/actions/test/twister.log"
        scp-dst: your_server_target_folder_path
        ssh-pre: commands_executing_via_ssh_before_scp
        ssh-post: commands_executing_via_ssh_after_scp
        ssh-pre-rollback: commands_executing_via_ssh_if_scp_or_ssh_post_commands_fail
        scp-rollback: true
```

## Input variables

See the [action.yml](./action.yml) file for more detail information.

* hostname: ssh remote host (**required**)
* ssh-user: user name for connect to host (**required**)
* ssh-key: content of ssh private key (**required**)
* ssh-opts: ssh connection options. 
  By default is -o "UserKnownHostsFile=/dev/null" -o "LogLevel ERROR" -o "StrictHostKeyChecking no"
* connect-timeout: timeout for ssh to remote host, by default is `5s`
* scp-src: scp file list (**required**)
* scp-dst: target path on the server, must be a directory (**required**)
* ssh-pre: execute pre-commands before scp
* ssh-post: execute post-commands after scp
* ssh-pre-rollback: executue if scp or ssh-post steps fail it rollback 
  commands called in a pre-command
* scp-rollback: true for rollback scp command. It's false by default.
