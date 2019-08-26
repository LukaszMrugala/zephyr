# Zephyr CI Documentation Hub

This file is the offical documentation for Intel's internal CI on Zephyr Project 

Goals for this file:
1. Singular resource for all CI processes
1. Training & Mindshare for DevOps
1. Landing page for CI customers & co-travellers who want to research & resolve issues on their own
  
## Overview

### Why a container? 
* Need to be nimble WRT to SDK & build-env changes, learning from past mistakes
* Align with community & CI industry, resist urge to "roll-own" Intel solution
* Sanitycheck requires significant CPU resources, containers help w/ load-leveling & parallelism while maintaining dissectability
* Implemented properly, a docker is an "automatic disaster recovery plan"
* Credential management improved- containers are provisioned @ start with a simple key enrollment & can be revoked.
* Single-point managagment of all updates, no scaling penalty
* Simplified networking & service management

### Architecture

**Container, in general**
Jenkins is used for the CI master. When the docker is built the following tasks are run:
1. Ubuntu base installation & core updates
1. Zephyr SDK & dependency download, update & install
1. Jenkins CI install, update & plug-in install/update
1. Jenkins configuration including proxy, users & default job repo
1. Credential & known_hosts setup
1. User-friendly gitlab auth setup via the web UI

Note: We have two flavors of docker that are currently used

**zephyrci.docker**
This is the official zephyr docker w/ Jenkins added & configured for "turn-key" deployment as a Zephyr CI master.

**zephyr sdk**
The official Zephyr Project SDK docker, built & run as required. Methodolgy is TBD- split between dockerswarm & Jenkins slaves.

Only the zephyrci.docker is required to deploy a CI instance- the SDK docker is only required for offloading jobs to slaves.

**State**
* The container is designed to be stateless with all internal storage being disposable.
* Logs are maintained as long as the container exists. Is filesystem object so will (likely) survive reboots, power-outages, etc.
* Credentials are being considered for inclusion in a volume, to elimate the user-intervention required w/ gitlab.

**Reporting & Visualization**
* Design intent is for ALL output to exit the container as git status or action, as defined in Jenkins jobs
* Jenkins UI is exposed & jobs can easily be monitored
* Many reporting & visualization plugins are available for Jenkins

### Components

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
1. Provision gitlab api key & name it "gitlab"
1. Enable default CI job

todo: expand on all that...

## Authentication & Credentials

### Overview
The Jenkins instance within the container needs to be able to authenticate with our git service, gitlab.
Checkouts currently run over ssh with API status over https REST.

**Current auth setup process:**
1. Container imports host-key for devtools.intel.com at start-up
1. Container runs ssh-keygen for jenkins user at start & echos pub-key to console, for use in Gitlab SSH key web UI
1. Gitlab API key is entered manually into Jenkins web UI at start
1. Container SSH creds are used for all target repos connections w/o project/repo-specific changes.

todo: move these to common page & include in all top-level docs
## Terminology

CI - Continuous Integration
docker - a container image, a recipie. Can also refer to the docker service, see containerd. 
container - an instance of a docker image

## Links & Other Information:
* CI Docker repo: https://gitlab.devtools.intel.com/cvondra/zephyr-ci.docker.git

