#!/usr/bin/bash

usage () {
  cat <<HELP_USAGE
Execute Simics simulation with the Zephyr image.
Usage:
$0 <build_dir> <remote_ip> <simics_dir> <remote_image> <remote_script> \
   <source_script> <simics_params> <user_name>
HELP_USAGE
}

if [ $# -ne 8 ]; then
  usage;
  echo "ERROR($0): only $# arguments are given"
  exit 1
fi

local_image=$1/zephyr/ish_fw.bin
remote_ip=$2
simics_dir=$3
remote_image=${simics_dir}\\$4
simics_script=$5
remote_script=${simics_dir}\\${simics_script}
local_script=$6
simics_params=$7
user=$8

# To avoid target host's fingerprint check on the very first SSH connection.
ssh_options="-o StrictHostKeyChecking=no"

# Command to run Simics emulation with the given project.
simics_run="cd ${simics_dir} && simics.bat -batch-mode -no-win ${simics_script} ${simics_params}"

# This delay prevents to start while the previous Simics remains
# and to avoid the new Simics being killed from set_serial_log.sh.
wait_kill_done=3

# Start from eliminating Simics process left running from the previous test.
# We expect to have at most one Simics process running on the server.
# Double check here and at set_serial_log.sh as either script might run first.
echo "INFO($0): Ensure previous emulation is not running..."
ssh ${ssh_options} -T ${user}@${remote_ip} \
  'taskkill /F /T /FI "IMAGENAME eq simics-common*"' 2>&1

sleep ${wait_kill_done}

echo "INFO($0): Copy image from ${local_image} to ${remote_ip}:${remote_image}"
scp ${ssh_options} ${local_image} ${user}@${remote_ip}:${remote_image} 2>&1 && \
  scp ${ssh_options} ${local_script} ${user}@${remote_ip}:${remote_script} 2>&1 && \
    echo "INFO($0): Run Simics ${remote_ip}:${remote_image}" && \
    ssh ${ssh_options} -T ${user}@${remote_ip} "${simics_run}" 2>&1
#
echo "INFO($0): Ensure the simulation is not left running..."
ssh ${ssh_options} -T ${user}@${remote_ip} \
  'taskkill /F /T /FI "IMAGENAME eq simics-common*"' 2>&1
#
