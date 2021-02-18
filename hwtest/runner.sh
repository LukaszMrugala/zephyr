#!/bin/bash
# HW test interface for zephyrproject @ Intel CI
#   Intended to be called from a Test-Agent NUC from within a west update'd zephyr tree
#   If the target platform exists on the Test-Agent, twister/sanitycheck device-testing 
#   runs & result code is returned. 
#   If the target platform does not exist on the Test-Agent, ENOFAIL is returned
# Assumptions:
#		Build environment is properly configured w/ python requirements for branch
# Usage:
#		cd <path to zephyr-tree> #aka ZEPHYR_BASE
#		./hwtest_runner.sh <zephyr_platform_name> <availNodes> <nodeNumber>
#			Example:
#				./hwtest_runner.sh frdm_k64f 2 1
# Output:
#		Junit xml output is written to $ZEPHYR_BASE/{sanity-out,twister-out}
# Returns:
#		0 if all sanitycheck default cases succeed
#       any other result indicates at least one failure exists
#####################################################################################

#disable ccache, it's known to cause build issues with zephyr in an automation
export CCACHE_DISABLE=1
export USE_CCACHE=0

#configure variable python path
# -- not currently supported by testOS -- #
#export PYTHONPATH="$(find /usr/local_$ZEPHYR_BRANCH_BASE/lib -name python3.* -print0)/site-packages:$(find /usr/local_$ZEPHYR_BRANCH_BASE/lib64 -name python3.* -print0)/site-packages"
#export PATH=/usr/local_$ZEPHYR_BRANCH_BASE/bin:$PATH

export ZEPHYR_BASE=$WORKSPACE/zephyrproject/zephyr
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-0.12.2

echo "hwtest-runner.sh: $ZEPHYR_BASE@$(hostname -f),sdk=$ZEPHYR_SDK_INSTALL_DIR,env=$ZEPHYR_BRANCH_BASE"

export SC_CMD_BASE="scripts/sanitycheck -x=USE_CCACHE=0 -N"
export SC_CMD1="$SC_CMD_BASE -p $1 -B $3/$2 --device-testing --device-serial /dev/$4"


echo "Starting sanitycheck hwtest"
DEVTTY=$("../../ci/hwtest/get-tty.sh $1")
if( "$DEVTTY" == 1); then
	echo "ERROR: could not map tty $1 on this platform -- check ci.git/hwtest/tty.map"
	echo "ABORTING"
	exit 1
fi

CMD="scripts/twister -x=USE_CCACHE=0 -v --device-testing --device-serial $DEVTTY -p $1"
$CMD
RESULT=$?
echo "Done. RESULT=$RESULT."
exit $RESULT
