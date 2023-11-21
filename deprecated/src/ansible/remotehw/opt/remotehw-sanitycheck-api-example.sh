#!/bin/bash
#####
# zephyr remotehw -> sanitycheck API example/tester
#   executes abitrary zephyr testcases on named remoteHW systems
#   must be executed from zephyrtest- systems with /opt/remotehw resources
#####

#####
# selects target remotehw system, it must be connected to this zephytest VM
REMOTEHW_SYSTEM=ehlsku11

#####
# sets build location
export WRKSPC=./zephyrproject-remotehw

#####
# extra options to pass to sanitycheck, for example, -vv to enable debug
SANITYCHECK_OPTS=-v

#####
# pointer to built-in sanitycheck-remoteHW api
#  src: https://gitlab.devtools.intel.com/zephyrproject-rtos/devops/infrastructure/ansible-playbooks
export WEST_FLASH_CMD="/opt/remotehw/remotehw-x86-efi.sh"

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
                echo "Could not create work-directory (./zephyrproject-remotehw). Aborting."
                exit
        fi
        cd $WRKSPC
        west update

        # get python deps
        pip3 install --user -r zephyr/scripts/requirements.txt

        cd ..
fi
cd $WRKSPC

#####
# setup env for build
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-0.11.4
source zephyr/zephyr-env.sh

######
# sanitycheck_remotehw - remotehw sanitycheck device testing wrapper function
#   sanitycheck_remotehw <remotehw system name> <zephyr project directory or sample path>
#   hooks remoteHW api for automatic tty device lookup
#
function sanitycheck_remotehw {
	./zephyr/scripts/sanitycheck -A zephyr-intel/boards/ -p ehl_crb \
		--device-testing --device-serial="$(remotehw-$1-get-tty)" \
		-T "$2" --west-flash="$WEST_FLASH_CMD,$1" $SANITYCHECK_OPTS
	return
}

# remotehw API tests
###############################################################################
# ping-pong test-cases to check for state retention
sanitycheck_remotehw $REMOTEHW_SYSTEM zephyr/samples/hello_world
sanitycheck_remotehw $REMOTEHW_SYSTEM zephyr/samples/synchronization
sanitycheck_remotehw $REMOTEHW_SYSTEM zephyr/samples/hello_world
sanitycheck_remotehw $REMOTEHW_SYSTEM zephyr/samples/synchronization

# FAIL hello-world device test by using sed to change Hello->Hi
sed -i 's/Hello/Hi/g' ./zephyr/samples/hello_world/src/main.c
sanitycheck_remotehw $REMOTEHW_SYSTEM zephyr/samples/hello_world

# FIX hello-world device test & run again
sed -i 's/Hi/Hello/g' ./zephyr/samples/hello_world/src/main.c
sanitycheck_remotehw $REMOTEHW_SYSTEM zephyr/samples/hello_world

