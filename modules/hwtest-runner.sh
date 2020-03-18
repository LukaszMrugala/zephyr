#!/bin/bash
# HW test sanitycheck runner script for zephyrproject @ Intel CI
#   Targets any -intel branch & intended to run under any properly configured
#   Zephyr build environment, container or native.

# Functions:
#  * Allows specification of sanitycheck platform using -p option
#  * Runs default test-cases
#  * Uses ninja build option
#  * Disables CCACHE as it's known to cause build state errors in automation
#  * Generates junit xml output for reporting & visualization

# Assumptions:
#		Build environment is properly configured w/ python requirements for branch
# Usage:
#		cd <path to zephyr-tree> #aka ZEPHYR_BASE
#		./hwtest_runner.sh <sanitycheck -p options>
#			Example:
#				./sanitycheck_runner.sh -pnative_posix
# Output:
#		Sanitycheck output files are written to $ZEPHYR_BASE/run1
#		Junit xml output is written to $ZEPHYR_BASE/junit
# Returns:
#		0 if all sanitycheck default cases succeed
#       any other result indicates at least one failure exists
#####################################################################################
echo "ooooooooooooooooooooooooooooooooooooooooo"
echo "  Zephyr HW Test Runner starting..."
echo "ooooooooooooooooooooooooooooooooooooooooo"
echo "Running in ZEPHYR_BASE=$ZEPHYR_BASE on $(hostname -f)"

#disable ccache, it's known to cause build issues with zephyr in an automation
export CCACHE_DISABLE=1
export USE_CCACHE=0

#if running in container, source these configs
if [ -f "/container_env" ]; then
	source /proxy.sh 		#location of imported proxy config in container env
	source /container_env	#container specific overrides, if any
fi

#configure variable python path
export PYTHONPATH="$(find /usr/local_$ZEPHYR_BRANCH_BASE/lib -name python3.* -print0)/site-packages:$(find /usr/local_$ZEPHYR_BRANCH_BASE/lib64 -name python3.* -print0)/site-packages"
export PATH=/usr/local_$ZEPHYR_BRANCH_BASE/bin:$PATH

# clean-up from previous runs
echo "Cleaning output directories..."
rm -rf $ZEPHYR_BASE/run1
rm -rf $ZEPHYR_BASE/junit

mkdir -p junit

# echo critical env values
###############################################################################
echo ZEPHYR_SDK_INSTALL_DIR=$ZEPHYR_SDK_INSTALL_DIR
echo ZEPHYR_TOOLCHAIN_VARIANT=$ZEPHYR_TOOLCHAIN_VARIANT
echo ZEPHYR_BRANCH_BASE=$ZEPHYR_BRANCH_BASE
echo PYTHONPATH=$PYTHONPATH
echo PATH=$PATH
echo cmake="path:$(which cmake), version: $(cmake --version)"
echo PLATFORM_OPTS=$1
echo http_proxy=$http_proxy
echo https_proxy=$https_proxy
echo no_proxy=$no_proxy

# Sanitycheck configuration & command-line generation
# All default options EXCEPT -N for ninja build
export SC_CMD_BASE="scripts/sanitycheck -x=USE_CCACHE=0 -N"
export SC_CMD1="$SC_CMD_BASE -p $1 -O $ZEPHYR_BASE/run1 --device-testing --device-serial /dev/ttyACM0 --detailed-report $ZEPHYR_BASE/junit/junit-$1.xml"

echo "Sanitycheck command-line:"
echo "    $SC_CMD1"

echo "Starting sanitycheck hwtest"
$SC_CMD1 
SC_RESULT=$?

echo Done. SC_RESULT=$SC_RESULT.

exit $SC_RESULT
