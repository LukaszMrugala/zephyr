#!/bin/bash

# remotehw-ehl-example.sh
#   Run twister on zephyr-intel with device-testing via remoteHW API
#   -> clones from innersource/os.rtos.zephyr.zephyr-intel via SSH

# select target remotehw system
REMOTEHW_SYSTEM=ehlsku7

# sets build location
WRKSPC=./zephyrproject-remotehw

# use our remoteHW API for flash command
WEST_FLASH_CMD="/opt/remotehw/remotehw-x86-efi.sh"

# set SDK
export ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-0.13.2
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr

# Step 1: Create os.rtos.zephyr.zephyr-intel workspace if it doesn't exist
if [ ! -d "$WRKSPC" ]; then
	echo "Creating a new zephyr remotehw workspace at $WRKSPC"

        # install west & update PATH
        pip3 install --user west
        source ~/.profile # update PATH for new west install

        # init zephyr repo from our internal tree
        west init -m git@github.com:intel-innersource/os.rtos.zephyr.zephyr-intel.git $WRKSPC
        if [ ! -d "$WRKSPC" ]; then
                echo "Could not create workspace at $WRKSPC. Aborting."
                exit
        fi
        cd $WRKSPC

	# swap innersource http urls to ssh in west.yml
	sed -i 's#https://github.com/intel-innersource#git@github.com:intel-innersource#g' zephyr-intel/west.yml

        west update

        # get python deps
        pip3 install --user -r zephyr/scripts/requirements.txt

        cd -
fi
cd $WRKSPC

# Step 2: Run Twister using remoteHW API

source zephyr/zephyr-env.sh

./zephyr/scripts/twister -v -A zephyr-intel/boards/ -p ehl_crb \
	--device-testing --device-serial="$(remotehw-$REMOTEHW_SYSTEM-get-tty)" \
	--west-flash="$WEST_FLASH_CMD,$REMOTEHW_SYSTEM" $TWISTER_OPTS
