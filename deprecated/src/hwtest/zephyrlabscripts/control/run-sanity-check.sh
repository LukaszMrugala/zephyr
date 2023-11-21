#!/bin/bash
# Running Sanitycheck on Elkhart Lake boxes connected to Kernel Lab Infra
# Preconditions
#  0. you have up-to-date Intel  Zephyr tree
#  1. If EHL is flashed, the USB media need to be configured to come first in EFI shell 
#	This can be done in BIOS or by issuing EFI shell command "bcfg boot  mv X 0"  where X
#	Is a boot ID of USB hard flash drive you get by running "bcfg dump" WHILE drive is attached
#  2. Flash drive need to have /efi/boot/ directory
#  3. You have passwordless ssh access to black configured for your username
#  4. All Zephyr envvars are set
#
#  Known problems:
#   Sometime, cleware usb switches are getting stuck. The symptom of it is clewarecontrol process
#   hanging (so keep monitoring ps).  To get past this problem, ussue /opt/lab/reset-cleware and, 
#   if the process is still hanging, kill -9 it

function help {
	echo USAGE $0 DEVICE TEST_PATH [INTEL_BOARDS_LOCATION]
	echo "where DEVICE is ehl03|ehl04|ehl05|ehl06"
}

if test -z $ZEPHYR_BASE
then
  echo ERROR: ZEPHYR_BASE not set
  echo Please configure Zephyr environment before continuing
  exit 1
fi

DEVICE=$1
case $DEVICE in
	ehl03|ehl04|ehl05|ehl06 )
	;;
	*)
	help
	exit 1
	;;
esac

BLACK_CONTROL="ssh black.fi.intel.com control-lab-machine "
if test -n $2""
then
	TEST_TO_RUN="-T "$2
	TEST_TO_RUN_DESC=$2
else
	TEST_TO_RUN_DESC="complete test set"
fi

SOCAT_TTY=/tmp/$DEVICE-tty

#location of the ehl_crb definition
INTEL_BOARDS=$3
if test -z $INTEL_BOARDS""
then
	echo Warning: Location for INTEL boards is not provided. Assuming default
	INTEL_BOARDS=$ZEPHYR_BASE/../zephyr-intel/boards
fi
echo Looking for Intel board definitions in $INTEL_BOARDS

echo Testing kernel lab connectivity...
ssh -o "PasswordAuthentication=no" -o "StrictHostKeyChecking=no"  black.fi.intel.com control-lab-machine status  ehl03 >/dev/null 
if test $? -ne 0
then
	echo ERROR:Passwordless access to kerne lab failed. Cannot proceed. 
	exit -1
else
	echo ... successful
fi


echo RUNNING SANITYCHECK ON $TEST_TO_RUN_DESC USING DEVICE $DEVICE
#1. Booking machine
echo 1. Reserving $DEVICE from lab. Note, doing it in the background as ssh session could hang
#to be sure all is clean
$BLACK_CONTROL release $DEVICE
# actually reserving
$BLACK_CONTROL reserve $DEVICE &
#in case it is stuck, storing PID
PIDS_TO_KILL=$!

#2. Re-setting cleware to be sure (Note, brute force, all other users will suffer!
#echo 2. Resetting cleware 
#now disabled -- need to selectively enable it per cutter. 
# TODO, figure out what USB is what and do  /opt/lab/command-ehlXX-resetusb
# /opt/lab/reset-cleware

echo 3. Preparing serial console on $SOCAT_TTY
# Getting  unused port # locallyt and on black
# clever oner-liner from https://unix.stackexchange.com/questions/55913/whats-the-easiest-way-to-find-an-unused-local-port/423052#423052
LOCAL_PORT=`comm -23 <(seq 50000 51000 | sort) <(ss -Htan | awk '{print $4 }' | cut -d':' -f2 | sort -u) | shuf | head -n 1`
REMOTE_COMMAND="socat /srv/tftp/$DEVICE/reserved/pty tcp:ehlflashnuc2.fi.intel.com:$LOCAL_PORT"

TUNNEL_PROCESS=/tmp/$LOCAL_PORT-$DEVICE-tunnel.sh 
SOCAT_PROCESS=/tmp/$LOCAL_PORT-$DEVICE-socat.sh

#creating temporary scripts. That's done for the ease of management/debugging
#echo "#!/bin/sh" > $TUNNEL_PROCESS
cat > $TUNNEL_PROCESS << EOF
#!/bin/sh
#To let stuff settle at our side
sleep 3
ssh black.fi.intel.com $REMOTE_COMMAND
echo  REMOTE SOCAT ENDED
EOF

cat > $SOCAT_PROCESS << EOF
#!/bin/sh
socat -d -d -d pty,link=$SOCAT_TTY tcp-listen:$LOCAL_PORT,reuseaddr,forever
echo LOCAL SOCAT ENDED
EOF

chmod +x $SOCAT_PROCESS
chmod +x $TUNNEL_PROCESS

#removing the $SOCAT_TTY as it is in the 
sudo rm -f $SOCAT_TTY
#Need set -m so that process group id is right
set -m
$SOCAT_PROCESS &
LOCAL_SOCAT_PID=$!
$TUNNEL_PROCESS &
REMOTE_TUNNEL_PID=$!
set +m

#Second part, local socat
# echo Remote script PID = $REMOTE_TUNNEL_PID, Local script PID= $LOCAL_SOCAT_PID. 

echo 4. Sit tight. Running sanitycheck on $TEST_TO_RUN_DESC with device $DEVICE
sanitycheck -p ehl_crb --device-testing --device-serial $SOCAT_TTY \
		$TEST_TO_RUN \
		--west-flash=/opt/lab/command-$DEVICE-westflash \
		-A $INTEL_BOARDS \
		-vv

echo Done running sanitycheck. Cleaning up

#echo releasing $DEVICE from lab
$BLACK_CONTROL release $DEVICE

echo killing spawned processes
kill -9 -$LOCAL_SOCAT_PID
kill -9 -$REMOTE_TUNNEL_PID

if test -n $PIDS_TO_KILL"" 
then
	kill $PIDS_TO_KILL
fi

#echo deleting temp scripts
rm  $TUNNEL_PROCESS $SOCAT_PROCESS

#echo cleaning all remaining processes related to $DEVICE on black
ssh black.fi.intel.com "ps ax | grep $DEVICE | cut -d' ' -f1 |xargs kill"

echo all done
