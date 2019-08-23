# Zephyr CI Config

## Introduction

This repo contains configuration & documentation for Intel's internal CI on Zephyr Project 

## Status:
* work-in-progress

## Links & Other Information:
* CI Docker repo: https://gitlab.devtools.intel.com/cvondra/zephyr-ci.docker.git

## Instructions for Deploying Zephyr CI

1. Procure the docker image
1. Setup config repo
1. Start container
1. Update all plugins
1. Provision SSH keys
1. Provision gitlab api key & name it "gitlab"
1. Enable default CI job

## Authentication & Credentials
* Container imports host-key for devtools.intel.com at start-up
* Container runs ssh-keygen for jenkins user at start & echos pub-key to console, for use in Gitlab SSH key web UI
* Gitlab API key is entered manually into Jenkins web UI at start
* Container SSH creds are used for all target repos connections w/o project/repo-specific changes.
