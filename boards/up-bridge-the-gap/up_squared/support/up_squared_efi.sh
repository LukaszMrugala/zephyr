#!/bin/bash

usage () {
  cat <<HELP_USAGE
Execute Zephyr image on the Up_Squared 'flashing' and power cycling it.

The DUT power cycle is controlled by the PDU through ssh.

Usage:
$0 <build_dir> <pxe_ip> <pxe_dir> <pxe_image_name> <pxe_user> \
<pdu_ip> <pdu_outlet> <pdu_user>

HELP_USAGE
}

#Zephyr build dir
build_dir=$1/zephyr/

# PXE connection details; ssh public key should be on the PXE
pxe_ip=$2
pxe_dir=$3
pxe_image_name=$4
pxe_user=$5
transfer_retry=3
# PDU connection details; ssh public key should be on the PDU
pdu_ip=$6
pdu_outlet=$7
pdu_user=$8

# copy image
echo "DEBUG	- Transfer $(pxe_image_name) to PXE: ${pxe_ip}."
while [ ${transfer_retry} -gt 0 ]
do
    scp -o StrictHostKeyChecking=no ${build_dir}zephyr.efi \
	${pxe_user}@${pxe_ip}:${pxe_dir}${pxe_image_name}
	if [[ $? -eq 0 ]]
	then
		echo "DEBUG	- Transfer Done."
		break
	else
		echo "DEBUG	- Transfer Fail. Retry"
		transfer_retry=`expr ${transfer_retry} - 1`
	fi
done

#PDU usage
echo "DEBUG	- ${pdu_ip} PDU/${pdu_outlet} power cycle."
ssh -o StrictHostKeyChecking=no -T ${pdu_user}@${pdu_ip} <<EOL
        power outlets ${pdu_outlet} cycle /y
        exit
EOL
