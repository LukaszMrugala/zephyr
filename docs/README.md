# Zephyr CI Documentation Hub

**Goals for this file**
1. Index into other DevOps & CI Documentation
1. Training & Mindshare for DevOps
1. Landing page for CI customers & co-travellers who want to research & resolve issues on their own

## Zephyr CI Functions 

1. Monitor selected branches for merge/pull requests (aka MR/PR) and automatically trigger sanitycheck jobs
1. Integrate CI infrastructure with gitlab CI/CD functions to automate PR process, as much as is reasonable
1. Provide flexible & scalable infrastructure for running of other functions, eg: rebasing, MISRA-C, coververity & fault-injection

## Zephyr CI Instances
### Production:	https://zerobot2.ostc.intel.com
### Staging: 	https://zerobot-stg.ostc.intel.com
login for both is zephyr:zephyr. Proper ACL is in-process.

## CI pipeline status @ Gitlab
### Production: https://gitlab.devtools.intel.com/zephyrproject-rtos/zephyr/pipelines
### Staging:	https://gitlab.devtools.intel.com/cvondra/zephyr-test/pipelines

## Current CI Jobs
### https://zerobot2.ostc.intel.com/job/zephyr-ci_master_sdk-0.10.3/
Implements CI on our main internal branch, v1.14-branch-intel.
Monitors for pull/merge requests and automatically triggers sanitycheck runs.

### https://zerobot2.ostc.intel.com/job/zephyr-ci/
Sanitycheck on v1.14-branch-intel, sdk 0.10.1

### Pipelines are triggered automatically on commits.

## Architecture

todo: svg block diag

### Why a container? 
* Need to be nimble WRT to SDK & build-env changes, learning from past mistakes
* Align with community & CI industry, resist urge to "roll-own" Intel solution
* Sanitycheck requires significant CPU resources, containers help w/ load-leveling & parallelism while maintaining dissectability
* Implemented properly, a docker is an "automatic disaster recovery plan"
* Credential management improved- containers are provisioned @ start with a simple key enrollment & can be revoked.
* Single-point managagment of all updates, no scaling penalty
* Simplified networking & service management

### What happens when the container is built/started?
Jenkins is used for the CI master. When the docker is built the following tasks are run:
1. Ubuntu base installation & core updates
1. Zephyr SDK & dependency download, update & install
1. Jenkins CI install, update & plug-in install/update
1. Jenkins configuration including proxy, users & default job repo
1. Credential & known_hosts setup
1. User-friendly gitlab auth setup via the web UI

### More Reading & Resources
https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/implementing-embedded-continuous-integration-with-jenkins-and-docker-part-1

### Container Details

We have two flavors of docker that are currently used

#### zephyrci.docker
This is the official zephyr docker w/ Jenkins added & configured for "turn-key" deployment as a Zephyr CI master.

#### zephyr sdk
The official Zephyr Project SDK docker, built & run as required. Methodolgy is TBD- split between dockerswarm & Jenkins slaves.

Only the zephyrci.docker is required to deploy a CI instance- the SDK docker is only required for offloading jobs to slaves.

#### Container is stateless (mostly)

* The container is designed to be stateless with all internal storage being disposable.
* Logs are maintained as long as the container exists. Is filesystem object so will (likely) survive reboots, power-outages, etc.
* Credentials are being considered for inclusion in a volume, to elimate the user-intervention required w/ gitlab.

### Reporting & Visualization

* Design intent is for ALL output to exit the container as git status or action, as defined in Jenkins jobs
* Jenkins UI is exposed & jobs can easily be monitored
* Many reporting & visualization plugins are available for Jenkins

### Infrastructure Components

A deployed Zephyr CI solution consists of several core components:

1. Zephyr CI Docker 
1. Zephyr CI configuration repo (this)
1. Infrastructure
1. Authentication

todo: click down to each?
todo: brief on each


## Instructions for Deploying Zephyr CI

1. Procure the docker image
1. Setup config repo
1. Start container
1. Update all plugins
1. Provision SSH keys
1. Provision gitlab api key & name it "gitlab", see: https://github.com/jenkinsci/gitlab-plugin/wiki/Setup-Example
1. Enable default CI job

todo: expand on all that...

## Authentication & Credentials

### Overview
The Jenkins instance within the container needs to be able to authenticate with our git service, gitlab.
Checkouts currently run over ssh with API status over https REST.

#### Current auth setup process:
1. Container imports host-key for devtools.intel.com at start-up
1. Container runs ssh-keygen for jenkins user at start & echos pub-key to console, for use in Gitlab SSH key web UI
1. Gitlab API key is entered manually into Jenkins web UI at start
1. Container SSH creds are used for all target repos connections w/o project/repo-specific changes.

todo: move these to common page & include in all top-level docs
## Terminology

#### CI
Continuous Integration
#### docker
a container image, a recipie. Can also refer to the docker service, see containerd. 
#### container
an instance of a docker image, running or not

## Links & Other Information:
### Zephyr Project SDK Docker: https://github.com/zephyrproject-rtos/docker-image
### ZephyrProject CaaS (Docker) Registry (internal): https://amr.caas.intel.com/zephyrproject
### Gitlab-Jenkins Integration: https://docs.gitlab.com/ee/integration/jenkins.html 
### Gitlab Merge Request Pipeline: https://docs.gitlab.com/ee/ci/merge_request_pipelines/

## Bin List of Todo/Features etc

caching / rev proxy - setup nginx to buffer sdks & other large blobs?

## Pastebin for commands & other cool-tricks, intended for DevOps & CI mindshare
Will organize these... someday.

### Inject a Jenkins job xml, via java CLI
java -jar $JENKINS_CLI -s http://127.0.0.1:8080/ -auth admin:$ADMINPASSWD create-job<job.xml


### Delete a pipeline from Gitlab's CI/CD page
curl --header "PRIVATE-TOKEN: your-api-token" --request "DELETE" "https://gitlab.devtools.intel.com/api/v4/projects/xxxxx/pipelines/nnnnn"
This is currently the only reliable method to remove CI/CD pipelines from Gitlab

