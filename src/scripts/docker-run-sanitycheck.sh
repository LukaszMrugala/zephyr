#!/bin/bash

# Simple wrapper for running CI sanitycheck pipeline locally- using $DOCKER_RUN wrapper, cvondra
#
# Instructions:
#  1. Configure env vars below, specifically SRC_REPO, SRC_BRANCH & ZEPHYR_SDK_INSTALL_DIR
#  2. Run /workdir/<this script> to start the run

# options
###############################################################################
SRC_REPO=https://gitlab.devtools.intel.com/zephyrproject-rtos/zephyr.git
SRC_BRANCH=master
#export these, used downstream
export ZEPHYR_BRANCH_BASE="master"
export ZEPHYR_SDK_INSTALL_DIR="/opt/toolchains/zephyr-sdk-0.11.3"
export ZEPHYR_TOOLCHAIN_VARIANT="zephyr"
export ZEPHYR_BASE="/workdir/zephyr"

# setup workdir, which is passed to container as bind-mount

rm -rf workdir
mkdir -p workdir
chmod 777 workdir

# docker wrapper + env
export DOCKER_IMG="amr-registry.caas.intel.com/zephyrproject/sdk-docker-intel:staging"

export DOCKER_ENV="	-e ZEPHYR_BRANCH_BASE=$ZEPHYR_BRANCH_BASE \
					-e ZEPHYR_BASE=$ZEPHYR_BASE \
					-e ZEPHYR_SDK_INSTALL_DIR=$ZEPHYR_SDK_INSTALL_DIR \
					-e ZEPHYR_TOOLCHAIN_VARIANT=$ZEPHYR_TOOLCHAIN_VARIANT"

export DOCKER_RUN="	docker run -it --user=$UID --privileged=true \
					--mount type=bind,src=$PWD/workdir,dst=/workdir \
					--mount type=bind,src=/etc/passwd,dst=/etc/passwd \
					$DOCKER_ENV $DOCKER_IMG"

echo $DOCKER_RUN

# pull modules from ci.git
wget -q https://gitlab.devtools.intel.com/zephyrproject-rtos/ci/-/raw/master/modules/sanitycheck-runner.sh -O workdir/sanitycheck-runner.sh
wget -q https://gitlab.devtools.intel.com/zephyrproject-rtos/ci/-/raw/master/modules/west-init-update.sh -O workdir/west-init-update.sh
chmod +x workdir/*.sh

# clone source
git clone -b $SRC_BRANCH $SRC_REPO workdir/zephyr

# run west-init/update
$DOCKER_RUN /bin/sh -c "cd $ZEPHYR_BASE/.. && ./west-init-update.sh"

# run sanitycheck-runner w/ single-node options inside container
$DOCKER_RUN /bin/sh -c "cd $ZEPHYR_BASE && ../sanitycheck-runner.sh 1 1"
