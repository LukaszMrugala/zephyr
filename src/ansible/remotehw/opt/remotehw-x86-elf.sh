#!/bin/bash

# remotehw-x86-elf - zephyr sanitycheck interface for remoteHW infrastrcture
#
#
#  usage: /opt/remotehw-x86-elf.sh <remotehw-system> <zephyr.elf>

echo "remotehw-x86-elf: Called with param1=$1 and param2=$2"

if [ -z "$1" ]; then
	echo "Missing parameters. Abort."
	echo "  Usage: remotehw-x86-elf <remotehw-system> <zephyr.elf>."
	exit 1;
fi

if [ ! -f "$2" ]; then
	echo "remotehw-x86-elf: Input file not found or inaccessible. Abort."
	echo "  Usage: remotehw-x86-elf <remotehw-system> <zephyr.elf>."
	exit 1;
fi

# source remotehw definitions on this system
. /etc/profile.d/remotehw*

# reserve, power-off & transfer binary to USB disk emulator
"remotehw-$1-reserve"
"remotehw-$1-power-off"
"remotehw-$1-usb-grub" "$2"

# power-on system
"remotehw-$1-power-on"

echo "remotehw-x86-elf: RemoteHW target $1 powered-on with $2 as USB grub multiboot payload."
echo "remotehw-x86-elf: Exit."


