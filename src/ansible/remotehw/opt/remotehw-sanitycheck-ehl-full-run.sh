#!/bin/bash
#####
# zephyr remotehw -> sanitycheck API example/tester
#   executes abitrary zephyr testcases on named remoteHW systems
#   must be executed from zephyrtest- systems with /opt/remotehw resources
#####

#####
# selects target remotehw system, it must be connected to his zephytest VM
REMOTEHW_SYSTEM=ehlsku7

#####
# sets build location
WRKSPC=./zephyrproject-remotehw

#####
# uncomment to pass extra options to sanitycheck
# SANITYCHECK_OPTS=-vv

#####
# pointer to built-in sanitycheck-remoteHW api
#  src: https://gitlab.devtools.intel.com/zephyrproject-rtos/devops/infrastructure/ansible-playbooks
WEST_FLASH_CMD="/opt/remotehw/remotehw-x86-efi.sh"

#####
# if $WORKSPACE doesn't exist, create it & pull zephyr + python deps
if [ ! -d "$WRKSPC" ]; then
	echo "Creating a new zephyr remotehw workspace at $WRKSPC"

        # install west & update PATH
        pip3 install --user west
        source ~/.profile # update PATH for new west install

        # init zephyr repo from our internal tree
        west init -m ssh://git@gitlab.devtools.intel.com:29418/zephyrproject-rtos/zephyr-intel.git $WRKSPC
        if [ ! -d "$WRKSPC" ]; then
                echo "Could not create workspace at $WRKSPC. Aborting."
                exit
        fi
        cd $WRKSPC
        west update

        # get python deps
        pip3 install --user -r zephyr/scripts/requirements.txt

        cd -
fi
cd $WRKSPC

#####
# setup env for build
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-0.11.4
source zephyr/zephyr-env.sh

######
# run all sanitycheck cases for ehl_crb & execute on REMOTEHW_SYSTEM (ehlsku7, ehlsku11, etc)
#
./zephyr/scripts/sanitycheck -A zephyr-intel/boards/ -p ehl_crb \
	--device-testing --device-serial="$(remotehw-$REMOTEHW_SYSTEM-get-tty)" \
	--west-flash="$WEST_FLASH_CMD,$REMOTEHW_SYSTEM" $SANITYCHECK_OPTS
