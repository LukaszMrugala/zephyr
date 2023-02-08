#!/bin/bash

# Simple wrapper for running CI sanitycheck pipeline locally, WITHIN container, cvondra
#
# Instructions:
#  1. Configure env vars below, specifically SRC_REPO, SRC_BRANCH & ZEPHYR_SDK_INSTALL_DIR
#  2. Use 'enter-container.sh' (this repo) to get a bash prompt in new sdk-docker-intel container
#  3. Run /workdir/<this script> to start the run

# options
###############################################################################
SRC_REPO=https://gitlab.devtools.intel.com/zephyrproject-rtos/zephyr.git
SRC_BRANCH=master
#export these, used downstream
export ZEPHYR_BRANCH_BASE=master
export ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-0.11.3
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr

# fix gap between native & docker python paths - here we're just symlinking /usr/local_BRANCH_BASE to /usr/local
ln -s /usr/local /usr/local_master
ln -s /usr/local /usr/local_v1.14-branch-intel

# clean-up
rm -rf .west zephyr

# pull modules from ci.git
wget -q https://gitlab.devtools.intel.com/zephyrproject-rtos/ci/-/raw/master/modules/sanitycheck-runner.sh -O sanitycheck-runner.sh
wget -q https://gitlab.devtools.intel.com/zephyrproject-rtos/ci/-/raw/master/modules/west-init-update.sh -O west-init-update.sh

# clone source
git clone -b $SRC_BRANCH $SRC_REPO zephyr

# run west-init/update module
bash ./west-init-update.sh

cd zephyr

export ZEPHYR_BASE=$PWD

# run sanitycheck-runner w/ single-node options
bash ../sanitycheck-runner.sh 1 1 
