#!/bin/bash
# Standard sanitycheck runner script for zephyrproject @ Intel, cvondra
#  Takes repo & branch as env parameter & runs sanitycheck with
#  default test-cases, retrying two times on failures.
#
# Instructions:
#  0. Setup dev env from https://docs.zephyrproject.org/latest/getting_started/index.html 
#  1. Configure env vars below, specifically SRC_REPO, SRC_BRANCH
#  2. Find/install the zephyr SDK on your machine & set ZEPHYR_SDK_INSTALL_DIR accordingly
#  3. Run with ./sanitycheck-runner.sh

# Common options: repo, branch & SDK location
###############################################################################
export SRC_REPO=https://gitlab.devtools.intel.com/zephyrproject-rtos/zephyr.git
#export SRC_REPO=ssh://git@gitlab.devtools.intel.com:29418/zephyrproject-rtos/zephyr.git
export SRC_BRANCH=v1.14-branch
export ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-0.10.3
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr

# Uncommon options
################################################################################
# Option to override sanitycheck output directory
#   Defaults to PWD/sanity_out (disk). 
#   Use /dev/shm/sanity_out for speedy builds w/ 64GB+ RAM 
export SC_OUT_ROOT=$PWD/sanity_out
#export SC_OUT_ROOT=/dev/shm/sanity_out

#Disable ccache, it's known to cause build issues with zephyr in an automation
export CCACHE_DISABLE=1 
export USE_CCACHE=0

# Sanitycheck configuration & command-line generation
# All default options EXCEPT -N for ninja build
export SC_CMD_BASE="scripts/sanitycheck -x=USE_CCACHE=0 -N"
export SC_CMD1="$SC_CMD_BASE -O $SC_OUT_ROOT/run1"
export SC_CMD2="$SC_CMD_BASE -f -O $SC_OUT_ROOT/run2"
export SC_CMD3="$SC_CMD_BASE -f -O $SC_OUT_ROOT/run3"

###############################################################################
# Start
###############################################################################
echo "Zephyr sanitycheck run starting."
echo "Script config:"
echo "  repo: $SRC_REPO"
echo "  branch: $SRC_BRANCH"
echo "  sanitycheck output: $SC_OUT_ROOT"
echo "  SDK: $ZEPHYR_SDK_INSTALL_DIR"
echo "***************************************************************************"
echo "    WARNING: $PWD/zephyproject and $SC_OUT_ROOT/* will be deleted!"
echo "***************************************************************************"
echo "Hit Ctrl-C if any of this doesn't look right."
echo "Continuing in 10 seconds..."
sleep 10

#Whack artifacts from previous runs
rm -rf zephyrproject
rm -rf $SC_OUT_ROOT

# Create dir structure
mkdir -p zephyrproject && cd zephyrproject
#clone repo & checkout target branch
git clone -b $SRC_BRANCH $SRC_REPO zephyr

echo "Updating python requirements from tree"
pip3 install --user -r zephyr/scripts/requirements.txt

echo "Updating west"
pip3 install --user -U west

echo "west init"
west init -l zephyr
west update

cd zephyr
source zephyr-env.sh

echo "Starting sanitycheck run w/ retries"
$SC_CMD1 || sleep 10; $SC_CMD2 ||  sleep 10; $SC_RUN3

echo Done. See $SC_OUT_ROOT for sanitycheck output
