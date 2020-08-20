#!/bin/bash

# Distributed sanitycheck runner script for zephyrproject @ Intel CI
#   Targets any -intel branch & intended to run under any properly configured
#   Zephyr build environment, container or native.

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
#		$WORKSPACE/ci/modules/sanitycheck_runner.sh <total # nodes> <this node #> <sanitycheck -p options>
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
echo "ooooooooooooooooooooooooooooooooooooooooo"
echo "  Zephyr Sanitycheck Runner starting..."
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

#set PYTHONPATH using our helper script
export PYTHONPATH=$($WORKSPACE/ci/modules/set-python-path.sh $ZEPHYR_BRANCH_BASE)

export PATH="/usr/local_$ZEPHYR_BRANCH_BASE/bin:$PATH"

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

# Sanitycheck configuration & command-line generation
export TESTCASES="testcases"
export SC_CMD_BASE="scripts/sanitycheck -x=USE_CCACHE=0 -N --inline-logs"
export SC_CMD_SAVE_TESTS="$SC_CMD_BASE -B $2/$1 $3 --save-tests $TESTCASES"

#handle branch differences in sanitycheck junit output
if [ "$ZEPHYR_BRANCH_BASE" == "v1.14-branch-intel" ]; then
    export SC_CMD1="$SC_CMD_BASE -B $2/$1 -v --detailed-report $ZEPHYR_BASE/sanity-out/node$2-junit1.xml --load-tests $TESTCASES"
    export SC_CMD2="$SC_CMD_BASE -f -v --detailed-report $ZEPHYR_BASE/sanity-out/node$2-junit2.xml"
    export SC_CMD3="$SC_CMD_BASE -f -v --detailed-report $ZEPHYR_BASE/sanity-out/node$2-junit3.xml"
else if [ "$ZEPHYR_BRANCH_BASE" == "master" ]; then
        export SC_CMD1="$SC_CMD_BASE --integration -v --load-tests $TESTCASES"
        export SC_CMD2="$SC_CMD_BASE --integration -v -f"
        export SC_CMD3="$SC_CMD_BASE --integration -v -f"
    fi
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
$SC_CMD1 || sleep 10; $SC_CMD2 ||  sleep 10; $SC_CMD3
SC_RESULT=$?

#echo "Running junit-condenser..."
#cd junit
#python $WORKSPACE/ci/modules/sanitycheck-junit-condenser.py
#cd -

echo Done. SC_RESULT=$SC_RESULT.

exit $SC_RESULT
