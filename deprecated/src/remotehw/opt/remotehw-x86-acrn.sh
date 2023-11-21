#!/bin/bash

# remotehw-x86-acrn - zephyr sanitycheck interface for remoteHW infrastructure
#

HELP="/opt/remotehw-x86-acrn.sh <zephyr build path> <remotehw-system>"

printf "\nremotehw-x86-acrn ($REMOTEHW_VER) [$1,$2]\n"

if [ -z "$1" ]; then
	echo "Missing parameters. Abort."
	echo "$HELP"
	exit 1
fi

if [ ! -d "$1" ]; then
	echo "remotehw-x86-acrn: $1 is not a directory or is inaccessible. Abort."
	echo "$HELP"
	exit 1
fi

# attempt to find a zephyr.efi under the provided search path... HACK/todo/help!
# Since ACRN v2.6 we are using zephyr.elf instead of zephyr.bin as zephyr image.
ZBIN=$(find "$1" -name zephyr.elf)

if [ ! -f "$ZBIN" ]; then
	echo "remotehw-x86-acrn: Unable to locate zephyr.bin under provided search path ($1). Abort."
	echo "$HELP"
	exit 1
fi
echo "remotehw-x86-acrn: found zephyr.elf ($ZBIN)"

# source remotehw definitions on this system
. /etc/profile.d/remotehw*

echo "remotehw-x86-acrn: starting ACRN boot via emulated USB provided by remotehw"
echo "-------------------------------------------------------------------------"
# reset, power-off & transfer binary to USB disk emulator
"remotehw-$2-reset"
"remotehw-$2-power-off"
"remotehw-$2-usb-acrn" "$ZBIN"
"remotehw-$2-power-on"
echo "-------------------------------------------------------------------------"
printf "remotehw-x86-acrn: completed remotehw ACRN boot. System is powered-on.\n\n"
exit 0
