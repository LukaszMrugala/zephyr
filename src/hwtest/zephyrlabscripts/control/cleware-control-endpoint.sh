#!/bin/bash

IFS='-/'
read -ra arr <<<"$0" 

# bail out if there are less than 3 elements parsed
#${arr[@]:s:n}

if [ ${#arr[@]} -lt 3 ] 
then
	echo  ERROR: Cannot derive what to do from the script name. 
	echo  Did you launch something else than commmand-dev-action ? 
fi

echo if you receive error messages while using Cleware devices or
echo if this script is getting stuck, please run /opt/lab/reset-cleware 

let idx1=${#arr[@]}-3
let idx2=idx1+1
let idx3=idx2+1

cmd=${arr[idx1]}
dev=${arr[idx2]}
act=${arr[idx3]}

#if IFS is not reset then all strings containing  -/ will be broken down
IFS=$'\n'

case $cmd in
	command)
	;;
	*)
	echo Invalid script name
	echo 'Script name: command-<device name>-<action>' 
	echo where device is one of ehl03, ehl04, ehl05, ehl06
        echo action is one of: status, mountusb, detachusb, flash
	exit
	;;
esac

MOUNT_POINT=/media/$dev
#to pass to function below with no hassle
INPUT1=$1

case $dev in
	ehl03)
	serial=1504635
	port=0
	#y2sn=214IYW1P
	y2sn=214MBU1C
#	note, get specific usb device name by running
#	find -L /dev/disk/by-id -samefile /dev/sdc1
	usbdev=/dev/disk/by-id/usb-Kingston_DataTraveler_3.0_E0D55E6CBD1CB3C1095800B9-0:0-part1
	;;
	ehl04)
	serial=1504636
	port=1
	y2sn=214MBTVK
	usbdev=/dev/disk/by-id/usb-Kingston_DataTraveler_3.0_D067E515959EF420361319CA-0:0-part1
	;;
	ehl05)
	serial=1504638
	port=3
	y2sn=20BV4WRI
	usbdev=/dev/disk/by-id/usb-Kingston_DataTraveler_3.0_E0D55E6CBD1CB3C1095800C3-0:0-part1
	#note: This one (actual USB media) has some problem and somehow is not mapped to /dev/disk-by/id
	;;
	ehl06)
	serial=1504637
	cleware_usbid=001/10
	port=2
	y2sn=214IYL7W
	usbdev=/dev/disk/by-id/usb-Kingston_DataTraveler_3.0_C81F660A788DF420364817B5-0:0-part1
	;;
	*)
	echo invalid device name
	exit
	;;
esac

#Executes commands with shell, and if command is timed out
#runs cleanup routine for max of $3 attempts
function timeout_with_cleanup ()
{
  COMMAND="$1"
  WAIT=$2
  MAXTRIES=$3
  CLEANUP="$4"
  attempt=0
  while [ $attempt -le $MAXTRIES ]
  do
    #echo attempt $attempt, running $COMMAND, sleep $WAIT
    #running command with timeout
    timeout $WAIT bash -c "$COMMAND"
    #if timed out
    TM_RET=$?
    if [ $TM_RET -eq 124 ]
    then
      echo timeout executing $COMMAND
      $CLEANUP
      attempt=$(( $attempt + 1 ))
    else
#      echo Normal exit, code $TM_RET
      break
    fi
  done

  if [ $attempt -eq $MAXTRIES ]
  then
    echo Execution of $COMMAND failed: too many attempts
  fi
}

#Wrapper for cleware command
function run_clewarecontrol {
  COMMAND="sudo clewarecontrol $@"
  timeout_with_cleanup "$COMMAND" 30 3 /opt/lab/reset-cleware
}

#An actual action function
function perform_action {
	action=$1

  case $action in
	on)
	echo powering on $dev
        echo Attemtping SSH to black. Ensure you have ssh configured and device reserved
	ssh black.fi.intel.com control-lab-machine power $dev on
	;;

	off)
	echo powering off $dev
        echo Attemtping SSH to black. Ensure you have ssh configured and device reserved
        ssh black.fi.intel.com control-lab-machine power $dev off
	;;

	mountusb)
	sudo mkdir -p $MOUNT_POINT
	sudo umount -q $MOUNT_POINT
	echo mounting USB storage $usbdev for $dev to $MOUNT_POINT
	run_clewarecontrol -c 1 -d $serial -as 1 1
	sleep 5
	echo if mounting fails, please revert to old way mounting /dev/sdX1
	sudo mount $usbdev $MOUNT_POINT
	#if [ $? -ne 0 ]
	#then
	#	echo mouting using /dev/disk-by-id failed.  trying alternative...
	#	HD=\$( dmesg | grep 'sd[a-z]: ' | tail -1 | sed 's/.*: //')
	#	sudo mount /dev/\$HD1 $MOUNT_POINT
	#fi
	;;

	detachusb)
	echo unmounting the USB storage from $MOUNT_POINT and
	echo re-attaching it to $dev machine
	#better would be to umount $usbdev buit somehow this does not work
	sync $MOUNT_POINT
	sleep 2
	sudo umount $MOUNT_POINT
        run_clewarecontrol -c 1 -d  $serial -as 0 1
	;;

	flash)
	IMAGE=$INPUT1
	echo flashing $dev with "$IMAGE"
	if test -f "$IMAGE"; then
		sudo /opt/lab/y2programmer/Y2ProgCli  batch --sn $y2sn --cs 1 -f "$IMAGE" and exit
	else
        	echo USAGE: $0  IFWIW_IMAGE_FILE
	fi
	;;

	status)
	echo $dev USB attached to PC '(1-attached)':
	run_clewarecontrol  -c 1 -d  $serial -rs 1
	echo $dev USB attached to board '(1-attached)':
	run_clewarecontrol -c 1 -d  $serial -rs 0

	echo checking mountpoint
	mount | grep /media/$dev
	echo trying ssh to black for power status
	ssh black.fi.intel.com control-lab-machine status $dev
	;;


	westflash)
        TEST_IMAGE=$INPUT1/zephyr/zephyr.efi
	echo West Flash command handler, putting test image $TEST_IMAGE to $dev
	# A complex process taking $image and putting it as /efi/boot/bootx64  + powering device 
	# power off via network switch
	perform_action off
	perform_action mountusb
	echo Copying...
	sudo cp $TEST_IMAGE /media/$dev/efi/boot/bootx64.efi
	perform_action detachusb
	perform_action on
	;;

       *)
        echo Do not know what to do with $dev
	;;
  esac
}

perform_action $act
