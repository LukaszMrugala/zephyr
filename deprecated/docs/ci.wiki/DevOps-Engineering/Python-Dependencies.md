# Zephyr DevOps Python Dependency Method
**Purpose**
This doc describes how Python dependencies are managed on DevOps infrastructure.

**Target Audience**
DevOps Engineers

**Doc Change Process**
* Minor changes & documentation improvements may be submitted by anyone. 
* Major policy or configuration changes should be RFC'd @ FMOS_DevOps first.
## Overview

Zephyr DevOps maintains separate Python dependency sets for each Zephyr build-environment. For example:

v1.14-branch - west 0.6.3, cmake 13.3, located at /usr/local_v1.14-branch

v2.5-branch - west <tbd>, cmake <tbd>, located at /usr/local_v2.5-branch

master - west <latest>, cmake <latest>, located at /usr/local_master


## Quick-start: Python dep install/update on DevOps VMs

**0.** For production, schedule down-time for the VMs that you wish to update. For staging, simply clear update plans with other DevOps engineers via email or Teams chat.

**1.** Confirm target environment is free of any existing Python packages installed under /usr/local.

**2.** Run ansible playbook [nativeBuild02-pythonDeps.yaml](https://gitlab.devtools.intel.com/zephyrproject-rtos/devops/infrastructure/ansible-playbooks/-/blob/current/nativeBuild02-pythonDeps.yaml) with *'--limit=target.machine.intel.com'* to restrict actions to a single host.

## Troubleshooting

### West fails on "import west.main"

This most often occurs on the Jenkins instances where users are likely to run 'sudo pip3 install <package>' which results in packages being installed under /usr/local & thus conflicting with packages ** **Make sure no depDon't use system-wide environment variables (those specified in the "Manage Jenkins" configuration). Env should always been handled in the pipeline code or job runners.