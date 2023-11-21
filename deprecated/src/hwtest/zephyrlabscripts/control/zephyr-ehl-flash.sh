#!/bin/bash
# The script is meant to be used in context of west flash
# Just like  ~/up_squared.sh in the example below
# sanitycheck -p up_squared --device-testing --device-serial /dev/ttyUSB0  -T samples/hello_world --west-flash="~/up_squared.sh"

# Precondition for the script (and whole west/sanitycheck thing)
#  1. If EHL is flashed, the USB media need to be configured to come first in EFI shell (bcfg mv 6 1)
#  2. Flash drive need to have /efi/boot/ directory
#  3. You have passwordless ssh access to black configured for your username
#  4. You issued 'control-lab-machine reserve $machine'  on black before
#  5. TO BE ADDED
#echo ARGUMENTS $@
set -e

MACHINE=ehl04

# power off via network switch
echo "Powering off..."
ssh black.fi.intel.com control-lab-machine power $MACHINE off  

test_image=$1/zephyr/zephyr.efi
#`find $2 -name "zephyr.efi"`

# copy image
echo Mounting...
/opt/lab/command-$MACHINE-mountusb
#need to be done once sudo mkdir -p /media/$MACHINE/efi/boot/ 
echo Copying...
sudo cp $test_image /media/$MACHINE/efi/boot/bootx64.efi

echo Unmounting...
/opt/lab/command-$MACHINE-detachusb

# power on
echo Powering on...
ssh black.fi.intel.com control-lab-machine power $MACHINE on

