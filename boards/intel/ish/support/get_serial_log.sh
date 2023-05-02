#!/usr/bin/bash

usage () {
  cat <<HELP_USAGE
Establish console logging connection to a Simics emulator.
Usage:
$0 <simics_ip> <logging_port> <max_seconds_to_wait> <user_name>
HELP_USAGE
}

if [ $# -ne 4 ]; then
  usage;
  echo "ERROR($0): incorrect $# arguments are given"
  exit 1
fi

address=$1
port=$2
max_wait=$3
user=$4

# To avoid target host's fingerprint check on the very first SSH connection.
ssh_options="-o StrictHostKeyChecking=no"

# This delay prevents to stick at the previous test's console leftover.
wait_kill_done=1

# Force netcat to check for the console port open.
wait_port_open=1

# Start from eliminating Simics process left running from the previous test.
# We expect to have at most one Simics process running on the server.
# Double check here and at run_simics.sh as either script might run first.
# See also at run_simics.sh where it waits a bit to avoid being killed from here.

echo "INFO($0): Check if previous emulation is still running..."
ssh ${ssh_options} -T ${user}@${address} \
  'taskkill /F /T /FI "IMAGENAME eq simics-common*"' 2>&1 && \
  sleep ${wait_kill_done} && \
  until nc -w ${wait_port_open} -vz ${address} ${port} 2>&1 ; do sleep ${wait_port_open}; done && \
  nc -w ${max_wait} -vd ${address} ${port} 2>&1 | \
  sed -ue 's/\x1b\([^\[]\|\[[\?;0-9]\+[a-zA-Z]\)//g'
#
# At the Simics side we expect telnet to run in 'raw' mode without negotiating
# telnet options.
# Also filter out ASCII escape sequences (at least ESC Fe, ESC SCI) which might
# spoil the console log.
#
