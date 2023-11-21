#!/bin/bash

# remotehw-x86-efi - zephyr sanitycheck interface for remoteHW infrastructure
#

HELP="/opt/remotehw-x86-efi.sh <zephyr build path> <remotehw-system>"

printf "\nremotehw-x86-efi ($REMOTEHW_VER) [$1,$2]\n"

if [ -z "$1" ]; then
	echo "Missing parameters. Abort."
	echo "$HELP"
	exit 1
fi

if [ ! -d "$1" ]; then
	echo "remotehw-x86-efi: $1 is not a directory or is inaccessible. Abort."
	echo "$HELP"
	exit 1
fi

# attempt to find a zephyr.efi under the provided search path... HACK/todo/help!
ZEFI=$(find "$1" -name zephyr.efi)

if [ ! -f "$ZEFI" ]; then
	echo "remotehw-x86-efi: Unable to locate zephyr.efi under provided search path ($1). Abort."
	echo "$HELP"
	exit 1
fi
echo "remotehw-x86-efi: found zephyr.efi ($ZEFI)"

# source remotehw definitions on this system
. /etc/profile.d/remotehw*

echo "remotehw-x86-efi: starting EFI boot via emulated USB provided by remotehw"
echo "-------------------------------------------------------------------------"
# reserve, power-off & transfer binary to USB disk emulator
"remotehw-$2-reserve"
"remotehw-$2-power-off"
"remotehw-$2-usb-efi" "$ZEFI"
# power-on system
"remotehw-$2-power-on"
echo "-------------------------------------------------------------------------"
printf "remotehw-x86-efi: completed remotehw EFI boot. Exit.\n\n"
exit 0
