#!/bin/bash
#
# Zephyr HWTest TTY Map Interface
#   Used to look-up zephyr test-device tty from ci.git/tty.map
#   Zephyr build environment, container or native.
#
# Functions:
#  * Takes zephyr project platform name as param & checks tty.map for entries on this host
#  * Returns tty path if match found, '1' if no match if found
#
# Requires:
# ========
# $WORKSPACE/ci/hwtest/dut.map must exist
#
# Example:
# ======
#  $./get-tty.sh reel_board
#  /dev/serial/by-path/pci-0000:00:14.0-usb-0:2:1.1
#
#  $./get-tty.sh invalid-board
#  not found on this agent
#
#####################################################################################

if [ -f "$WORKSPACE/ci/hwtest/dut.map" ]; then
	source "$WORKSPACE/ci/hwtest/dut.map"
	for dut in "${HWTEST_TTYS[@]}"; do
		LISTPLAT=$(echo $dut | awk -F , '{ print $2; }')
		LISTMAC=$(echo $dut | awk -F , '{ print $1; }')
		MYMAC=$(ip address show eth0 | grep link/ether | awk '{ print $2; }')
		if [[ "$1" == "$LISTPLAT" ]] && [[ "$LISTMAC" == "$MYMAC" ]]; then
			echo $dut | awk -F , '{ print $3; }'
			exit 0
		fi
	done
	exit 1
else
   echo "dut.map not found. Cannot continue."
   exit 1
fi

