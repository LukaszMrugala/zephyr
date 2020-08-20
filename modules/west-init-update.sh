#!/bin/bash

# standard west init + update method
# run from zephyr-tree CWD with pre-reqs/env vars:
#	ci.git & zephyr.git - at /ci & /zephyr, respectively
#	WORKSPACE - set to directory containing /zephyr & /ci
#	ZEPHYR_BRANCH_BASE - 'master', 'v1.14-branch-intel' or other supported value from branch-detect.groovy
#
#disable ccache, it's known to cause build issues with zephyr in an automation
export CCACHE_DISABLE=1
export USE_CCACHE=0

#if running in container, source these configs
if [ -f "/container_env" ]; then
	source /proxy.sh 		#location of imported proxy config in container env
	source /container_env	#container specific overrides, if any
fi

#configure variable python path, both lib & lib64
export PYTHONPATH=$($WORKSPACE/ci/modules/set-python-path.sh $ZEPHYR_BRANCH_BASE)
export PATH=/usr/local_$ZEPHYR_BRANCH_BASE/bin:$PATH

# echo critical env values
###############################################################################
echo "PYTHONPATH=$PYTHONPATH"
echo "PATH=$PATH"
echo "WEST=$(which west)"
echo "CMAKE=path:$(which cmake), version: $(cmake --version)"

rm -rf .west && west init -l zephyr && west update

