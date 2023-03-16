#!/usr/bin/bash

usage () {
  cat <<HELP_USAGE
Execute Zephyr image on the TGL board 'flashing' and power cycling it.

The DUT power cycle is controlled by the PDU through ssh.

Overall cycle time is a sum of the DUT shutdown time expected
and the PDU's outlet power cycle delay which is set to 5 sec.

Usage:
$0 <build_dir> <dut_ip> <dut_firmware_dir> <dut_image_name> <dut_user> \
<pdu_ip> <pdu_outlet> <wait_shutdown> <pdu_user>

HELP_USAGE
}

if [ $# -ne 9 ]; then
  usage;
  echo "ERROR($0): only $# arguments are given"
  exit 1
fi

src_name=$1/zephyr/ish_fw.bin

# DUT connection details; ssh public key should be on the DUT
dut_ip=$2
dest_path=$3
dest_name=$4
dut_user=$5

# PDU connection details; ssh public key should be on the PDU
pdu_ip=$6
pdu_outlet=$7
wait_shutdown=$8
pdu_user=$9

# Wait a bit for the board to really stop as PDU returns from the power cycle command too quickly.
pdu_delay=2
wait_port_open=1
flash_retry=3

# To avoid target host's fingerprint denied on SSH connection from docker containers.
ssh_options="-o StrictHostKeyChecking=no"

if [ -n ${dest_name} ]
then
    date +"%Y-%m-%d %H:%M:%S,%3N - $0 - DEBUG - ${dut_ip} DUT start flashing ${src_name}"
    # DUT mount root partition read/write.
    ssh ${ssh_options} -T ${dut_user}@${dut_ip} "mount -o remount,rw /"

    while [ ${flash_retry} -gt 0 ]
    do
        date +"%Y-%m-%d %H:%M:%S,%3N - $0 - DEBUG - ${dut_ip} DUT image write and verify."
        scp ${ssh_options} ${src_name} ${dut_user}@${dut_ip}:${dest_path}/${dest_name} && \
          ssh ${ssh_options} -T ${dut_user}@${dut_ip} "sync" && \
          scp ${ssh_options} ${dut_user}@${dut_ip}:${dest_path}/${dest_name} $1/zephyr

        if [[ $(md5sum ${src_name} $1/zephyr/${dest_name} | awk '{print $1}' | uniq | wc -l) == 1 ]]
        then
            date +"%Y-%m-%d %H:%M:%S,%3N - $0 - DEBUG - ${dut_ip} DUT image seems updated."
            break
        else
            date +"%Y-%m-%d %H:%M:%S,%3N - $0 - ERROR - ${dut_ip} DUT image update failed."
            flash_retry=`expr ${flash_retry} - 1`
        fi
    done
else
    date +"%Y-%m-%d %H:%M:%S,%3N - $0 - DEBUG - ${dut_ip} DUT power cycle without 'flashing'."
fi

if netcat -w ${wait_port_open} -vz ${dut_ip} 22
then
    date +"%Y-%m-%d %H:%M:%S,%3N - $0 - DEBUG - ${dut_ip} DUT starting shutdown."
    # needs to umount "/" directory, otherwise, the image will not be updated ?
    ssh ${ssh_options} -T ${dut_user}@${dut_ip} "umount / ; sleep 1; poweroff; exit" && \
      sleep ${wait_shutdown} && \
      date +"%Y-%m-%d %H:%M:%S,%3N - $0 - DEBUG - ${dut_ip} DUT expected shutdown."
else
    date +"%Y-%m-%d %H:%M:%S,%3N - $0 - DEBUG - ${dut_ip} DUT looks already down, no SSH."
fi

date +"%Y-%m-%d %H:%M:%S,%3N - $0 - DEBUG - ${pdu_ip} PDU/${pdu_outlet} power OFF."
ssh ${ssh_options} -T ${pdu_user}@${pdu_ip} <<EOL
        power outlets ${pdu_outlet} cycle /y
        exit
EOL

date +"%Y-%m-%d %H:%M:%S,%3N - $0 - DEBUG - ${pdu_ip} PDU/${pdu_outlet} power ON, wait for SSH."
sleep ${pdu_delay}

until nc -w ${wait_port_open} -vz ${dut_ip} 22 2>&1 ; do sleep ${wait_port_open}; done && \
  date +"%Y-%m-%d %H:%M:%S,%3N - $0 - DEBUG - ${dut_ip} DUT looks up."
#
date +"%Y-%m-%d %H:%M:%S,%3N - $0 - DEBUG - END."
#
