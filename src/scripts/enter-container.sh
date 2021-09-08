#!/bin/bash

# zephyr CI/SDK docker container quick-start, cvondra
#  This script automates the work of pulling the latest container & setting-up a local env for
#  interactive use of the container from the command-line.
#
# Notes, caveats, warnings:
#  1. Container currently runs as UID 1500 which may or may not map to a valid user.
#  2. PWD/workdir is mounted as a container volume & UID 1500 must have RW access

export CONTAINER_URL=amr-registry.caas.intel.com/zephyrproject/sdk-docker-intel:main

#setup workdir
sudo rm -rf workdir
mkdir -p workdir
chmod 777 workdir

#copy our runner scripts to workdir for use from the container
cp container-sanitycheck-run.sh workdir/

#pull container
docker pull $CONTAINER_URL
docker run -v$PWD/workdir:/workdir:z -it $CONTAINER_URL
