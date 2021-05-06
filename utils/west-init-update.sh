#!/bin/bash

# standard west init + update method
# run from zephyr-tree CWD with pre-reqs/env vars:
#	ci.git & zephyr.git - at /ci & /zephyr, respectively
#	WORKSPACE - set to directory containing /zephyr & /ci
#	ZEPHYR_BRANCH_BASE - 'master', 'v1.14-branch' or other supported value from branch-detect.groovy
#
# Params:
# 	$1 - if set, will override west init directory (defaults to zephyr)
#

#disable ccache, it's known to cause build issues with zephyr in an automation
export CCACHE_DISABLE=1
export USE_CCACHE=0


# echo critical env values
###############################################################################
echo "PATH=$PATH"
echo "ZEPHYR_BRANCH_BASE=$ZEPHYR_BRANCH_BASE"
echo "\$1=$1"

#search for base lib path...
if [ -d "/usr/local_$ZEPHYR_BRANCH_BASE/lib" ]; then
	PYTHONPATH+="$(find /usr/local_$ZEPHYR_BRANCH_BASE/lib -type d -regex .*python3.*/site-packages)"
fi
#append lib64 path if it exists too
if [ -d "/usr/local_$ZEPHYR_BRANCH_BASE/lib64" ]; then
	PYTHONPATH+=":$(find /usr/local_$ZEPHYR_BRANCH_BASE/lib64 -type d -regex .*python3.*/site-packages)"
fi

export PYTHONPATH=$PYTHONPATH

#if running in container, source these configs
if [ -f "/proxy.sh" ]; then
	source /proxy.sh 		#location of imported proxy config in container env
fi

if [ -f "/container_env" ]; then
	source /container_env	#container specific overrides, if any
fi

###############################################################################
# run west init + update

echo "PYTHONPATH=$PYTHONPATH"

if [ -z "$1" ]; then
	rm -rf .west && /usr/local_$ZEPHYR_BRANCH_BASE/bin/west init -l zephyr && /usr/local_$ZEPHYR_BRANCH_BASE/bin/west update
else
	rm -rf .west && /usr/local_$ZEPHYR_BRANCH_BASE/bin/west init -l "$1" && /usr/local_$ZEPHYR_BRANCH_BASE/bin/west update
fi
