#!/bin/bash

# Statless, distributed sanitycheck runner script for zephyrproject @ Intel CI
#   Targets any -intel branch & intended to run under DevOps stateless CI
#   execution environment consisting of ubuntu-zephyr-devops + pxeboot RAMdisk VMsa

#
#  todo: comment refresh...
#

# Functions:
#  * Takes batch split options as params, allowing load to be spread across multiple nodes
#  * Allows specification of sanitycheck platform using -p option
#  * Runs default test-cases, retrying two times on failures
#  * Uses ninja build option
#  * Disables CCACHE as it's known to cause build state errors in automation
#  * Generates junit xml output for reporting & visualization
#  * Enables coverage-reporting (*WIP)

# Requirements:
# =============
# This script is designed to be run within a Jenkins pipeline but can be executed stand-alone 
# with the following pre-reqs:
#
#	1. wget - required for fetching latest pythonpath set script 
#	2. the following deps/env vars are required:
#		i.   ci.git at $WORKSPACE/ci
#		i.   zephyr src tree at $WORKSPACE/zephyr
#		ii.  env vars:
#			WORKSPACE = set to directory containing ci/ & zephyr/
#			ZEPHYR_BRANCH_BASE = set to DevOps build-env type: 
#				('master', 'v1.14-branch-intel', ...)
#
# Usage:
# ======
#		cd <path to zephyr-tree> #aka ZEPHYR_BASE
#		$WORKSPACE/ci/stateless/runner.sh <total # nodes> <this node #> <sanitycheck -p options>
#			Example:
#				./sanitycheck_runner.sh 4 1 -pqemu_x86
# Output:
# =======
#		Sanitycheck output files are written to $ZEPHYR_BASE/run{1,2,3...}
#		Junit xml output is written to $ZEPHYR_BASE/junit
# Returns:
# ========
#		0 if all sanitycheck default cases succeed after 3 tries
#		any other result indicates at least one failure exists in the final retry
#
#####################################################################################

# VMs are allocated 72GB RAM with 64GB reserved.
# Secure 48GB of build space, leaving a guaranteed 16GB real RAM
mount -o remount,noatime,size=48G /dev/shm

# aggressively scrub /dev/shm for old work-directories...
find /dev/shm -name twister-out* -type d -print0 | xargs -0 rm -rf
find /dev/shm -name sanity-out* -type d -print0 | xargs -0 rm -rf

#disable ccache, it's known to cause build issues with zephyr in an automation
export CCACHE_DISABLE=1
export USE_CCACHE=0

#if running in container, source these configs
if [ -f "/container_env" ]; then
	source /container_env	#container specific overrides, if any
fi

if [ -f "/proxy.sh" ]; then
	source /proxy.sh 	#location of imported proxy config in container env
fi

# echo critical env values
###############################################################################
echo ZEPHYR_SDK_INSTALL_DIR=$ZEPHYR_SDK_INSTALL_DIR
echo ZEPHYR_TOOLCHAIN_VARIANT=$ZEPHYR_TOOLCHAIN_VARIANT
echo ZEPHYR_BRANCH_BASE=$ZEPHYR_BRANCH_BASE
echo PYTHONPATH=$PYTHONPATH
echo PATH=$PATH
echo cmake="path:$(which cmake), version: $(cmake --version)"
echo BATCH_TOTAL=$1
echo BATCH_NUMBER=$2
echo PLATFORM_OPTS=$3
echo http_proxy=$http_proxy
echo https_proxy=$https_proxy
echo no_proxy=$no_proxy
echo DOCKER_RUN=$DOCKER_RUN

# Sanitycheck configuration & command-line generation
export TESTCASES="testcases"

# handle switch from sanitycheck -> twister, gracefully
if [ -f "scripts/twister" ]; then
    export SC_CMD_BASE="$DOCKER_RUN scripts/twister -x=USE_CCACHE=0 -N --inline-logs"
else
    export SC_CMD_BASE="$DOCKER_RUN scripts/sanitycheck -x=USE_CCACHE=0 -N --inline-logs"
fi

export SC_CMD_SAVE_TESTS="$SC_CMD_BASE -B $2/$1 $3 --save-tests $TESTCASES"

#handle branch differences in twister / sanitycheck params + junit output
if [ "$ZEPHYR_BRANCH_BASE" == "v1.14-branch-intel" ]; then
    export SC_CMD1="$SC_CMD_BASE -B $2/$1 -v --detailed-report $ZEPHYR_BASE/sanity-out/node$2-junit1.xml --load-tests $TESTCASES"
    export SC_CMD2="$SC_CMD_BASE -f -v --detailed-report $ZEPHYR_BASE/sanity-out/node$2-junit2.xml"
    export SC_CMD3="$SC_CMD_BASE -f -v --detailed-report $ZEPHYR_BASE/sanity-out/node$2-junit3.xml"
elif [ "$ZEPHYR_BRANCH_BASE" == "master" ]; then
    export SC_CMD1="$SC_CMD_BASE --integration -v --load-tests $TESTCASES --retry-failed 5 --retry-interval 60"
fi

echo "Sanitycheck command-lines:"
echo "save: $SC_CMD_SAVE_TESTS"
echo "run1: $SC_CMD1"
echo "run2: $SC_CMD2"
echo "run3: $SC_CMD3"

# extract default testcases
$SC_CMD_SAVE_TESTS
# if testcase failure allowFail file for this branch exists, apply it to testcase file
if [ -f "$WORKSPACE/ci/allowlist/sanitycheck-$ZEPHYR_BRANCH_BASE.allowFail" ]; then
	#get SC_ALLOWED_TO_FAIL array for this branch
	source "$WORKSPACE/ci/allowlist/sanitycheck-$ZEPHYR_BRANCH_BASE.allowFail"
	#iterate through list of fail-able testcases, erasing line from $TESTCASES if found
	for tc in "${SC_ALLOWED_TO_FAIL[@]}"; do
		#use sed to whack any lines that have exact matches
		echo "Skipping testcase: $tc"
		sed -i "\#$tc#d" $TESTCASES
	done
fi

echo "Starting sanitycheck run w/ retries"
if [ "$ZEPHYR_BRANCH_BASE" == "v1.14-branch-intel" ]; then
	$SC_CMD1 || sleep 10; $SC_CMD2 ||  sleep 10; $SC_CMD3
	SC_RESULT=$?
elif [ "$ZEPHYR_BRANCH_BASE" == "master" ]; then
	$SC_CMD1
	SC_RESULT=$?
fi

echo Done. SC_RESULT=$SC_RESULT.

#schedule reboot in 30 sec... todo, make build-time option for retaining build results (aka, not rebooting)
# doesn't seem to be working...
#nohup sleep 30 && systemctl start reboot.target&

exit $SC_RESULT

