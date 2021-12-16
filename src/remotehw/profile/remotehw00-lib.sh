# remoteHW library
#   global settings & methods for Zephyr DevOps Remote Hardware service
remotehw_ver="rc3"
_ssh="ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
_scp="scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
_console="picocom --flow none --baud"

.remotehw-ssh-cmd() {
	$_ssh "$1" "$2"
}
export -f .remotehw-ssh-cmd


# remotehw-reset - reset target & remotehw state/processes
#  params: _pwrsw, _name, _ttydev

.remotehw-reset () {
	pkill -9 -U $LOGNAME -f "$_console $3"
	# todo: tta/usb-gpio reset call
}
export -f .remotehw-reset

# remotehw-usb-iso <flavor>
#

.remotehw-usb-iso () {
	printf "\n.remotehw-usb-iso ($remotehw_ver)\n"

	if [ ! -f "/opt/toolchains/iso/$2" ]; then
		echo " ! Could not locate $2 in /opt/toolchains/iso. Abort."
			return
	fi

        echo " * resetting usbtta state"
        # umount any existing loops, disconnect loop0 & remote USB mass storage driver
        $_ssh $1 umount /mnt/loop 2>&-
        $_ssh $1 /sbin/losetup -d /dev/loop0 2>&-
        $_ssh $1 /sbin/modprobe -r g_mass_storage
        sleep 3

	echo " * mounting NFS iso store"
        $_ssh $1 mount -t nfs -o ro,nolock 192.168.0.20:/mnt/zfs-prod/nfs-toolchains /mnt/loop

	echo " * attaching $2 iso as emulated USB flash disk"
	$_ssh $1 "/sbin/modprobe g_mass_storage file=/mnt/loop/iso/$2 ro=y iManufacturer=zephyrdevops iProduct=$1 iSerialNumber=0000"

	echo "Done. Target ready for power-on."
}
export -f .remotehw-usb-iso

# remotehw-rsvrst - resets reservations using previously auth'd NOPASSWD sudo for rm -f /tmp/remotehw-
.remotehw-rsvrst() {
	printf "\n.remotehw-rsvrst ($remotehw_ver)\n\n"
	if [ "$LOGNAME" != "root" ]; then
		echo "***************************************************************"
		echo "     This command resets the reservation for $1 by executing:"
		echo "             \"sudo rm -f /tmp/remotehw-$1.owner\""
		echo "\"sudo pkill -9 -f $_console $(.remotehw-$1-get-baud) $(remotehw-$1-get-tty)\""
		echo "   Press R to continue & enter your password for sudo if prompted."
		echo " --------------------------------------------------------------"
		echo "             Hit any other key or Ctrl-C to abort."
		echo "***************************************************************"
		read -r KEY
		if [ "$KEY" != "R" ]; then
			printf "\n\n ! Got $KEY, not R, aborting.\n\n"
			return
		fi
		printf "\n\n * proceeding...\n\n"
	fi

        if [ -f "/tmp/remotehw-$1.owner" ]; then
                sysowner=$(cat "/tmp/remotehw-$1.owner")
		echo " * $1 is currently reserved by $sysowner, forcibly removing reservation & killing terminal sessions..."

		sudo rm -f "/tmp/remotehw-$1.owner"
		sudo pkill -9 -f "$_console $(.remotehw-$1-get-baud) $(remotehw-$1-get-tty)"
        else
                echo " ! $1 not reserved. Abort."
        fi
	echo " * Done."
}
export -f .remotehw-rsvrst

# remotehw-reservation check - gates all commands on presence & contents of reservation files in $_rsvdir
.remotehw-rsvchk() {
        if [ -f "/tmp/remotehw-$1.owner" ]; then
                sysowner=$(cat "/tmp/remotehw-$1.owner")
                if [ "$sysowner" = "$LOGNAME" ]; then
			eval "$2 $3 $4 $5 $6"
                else
			printf "\n.remotehw-rsvchk ($remotehw_ver)\n"
                        echo " ! $1 is reserved to $sysowner, not $LOGNAME. Abort."
                fi
        else
		printf "\n.remotehw-rsvchk ($remotehw_ver)\n"
                echo " ! Reserve $1 first, try: remotehw-$1-reserve. Abort."
        fi
}
export -f .remotehw-rsvchk

# remotehw-reserve - reserve a system for exclusive use
.remotehw-reserve() {
	printf "\n.remotehw-reserve ($remotehw_ver)\n"
	echo "https://gitlab.devtools.intel.com/zephyrproject-rtos/devops/documentation/-/tree/latest/RemoteHW"

        if [ -f "/tmp/remotehw-$1.owner" ]; then
                sysowner=$(cat "/tmp/remotehw-$1.owner")
                echo " ! $1 is already reserved by $sysowner"
        else
		echo " * $1 is available. Setting owner to $LOGNAME."
		echo "$LOGNAME" > "/tmp/remotehw-$1.owner" && chmod a+r "/tmp/remotehw-$1.owner"
		echo "Done. System reserved."
	fi
}
export -f .remotehw-reserve

.remotehw-release() {
	printf "\n.remotehw-release ($remotehw_ver)\n"

	if [ -f "/tmp/remotehw-$1.owner" ]; then
		sysowner=$(cat "/tmp/remotehw-$1.owner")
		if [ "$sysowner" = "$LOGNAME" ]; then
			echo " * $1 owner is currently $LOGNAME, releasing reservation & killing console sessions."
			pkill -9 -U $LOGNAME -f "$_console $2"
			rm -f "/tmp/remotehw-$1.owner"
		else
			echo " ! $1 is owned by $sysowner, not $LOGNAME. Abort."
			return
		fi
	else
		echo " ! $1 is not currently reserved. Abort."
		return
	fi
}
export -f .remotehw-release

# remotehw-power-XX <pwrsw_spec>
#   control power state of outlet matching <pwrsw_spec>
.remotehw-power-on() {
	printf "\n.remotehw-power-on ($remotehw_ver)\n"

	if [ -z "$1" ]; then
		echo " ! Missing pwrsw_spec parameter. Abort."
		return
	fi

	echo " * sending power-on command to $1"
	curl --noproxy "*" -s -u admin:1234 http://admin:1234@$1=ON > /dev/null
	echo "Done. Target powered-on."
}
export -f .remotehw-power-on

.remotehw-power-off() {
        printf "\n.remotehw-power-off ($remotehw_ver)\n"

	if [ -z "$1" ]; then
		echo " ! Missing pwrsw_spec parameter. Abort."
		return
	fi

	echo " * sending power-off command to $1"
	curl --noproxy "*" -s -u admin:1234 http://admin:1234@$1=OFF > /dev/null
	echo "Done. Target powered-off."
}
export -f .remotehw-power-off

.remotehw-get-console() {
        printf "\n.remotehw-get-console ($remotehw_ver)\n"

	if [ -z "$1" ]; then
		echo " ! Missing serial device parameter. Abort."
		return
	fi
	echo " * running $_console $1 $2"
	eval "$_console $1 $2"
}
export -f .remotehw-get-console

# remotehw-usb-common <usbtta_spec>
#   common setup function for usb flash disk emulation
.remotehw-usb-common() {
	if [ -z "$1" ]; then
		echo " ! Missing usbtta_spec parameter. Abort."
		return
	fi

	echo " * resetting usbtta state"
	# umount any existing loops, disconnect loop0 & remote USB mass storage driver
	$_ssh $1 umount /mnt/loop 2>&-
	$_ssh $1 /sbin/losetup -d /dev/loop0 2>&-
	$_ssh $1 /sbin/modprobe -r g_mass_storage
	sleep 3

	echo " * creating new boot disk filesystem"
	# create new filesystem in ram, loop mount it & inject grub + our efi
	$_ssh $1 "wget -q -O /dev/shm/64MB-FAT16.img.gz http://192.168.0.200/64MB-FAT16.img.gz"
	$_ssh $1 "wget -q -O /dev/shm/zephyr-grub-boot-disk.tgz http://192.168.0.200/zephyr-grub-boot-disk.tgz"
	$_ssh $1 "gunzip -c /dev/shm/64MB-FAT16.img.gz > /tmp/zephyr.disk"
	$_ssh $1 "/sbin/losetup -o 1048576 /dev/loop0 /tmp/zephyr.disk && mount /dev/loop0 /mnt/loop"
	$_ssh $1 "cd /mnt/loop && tar -xzf /dev/shm/zephyr-grub-boot-disk.tgz && sync"
}
export -f .remotehw-usb-common

# remotehw-usb-grub <usbtta_spec> <zephyr.elf>
#   prepare a virtual USB flash disk with <zephyr.elf> as grub payload
#   and attach it to <usbtta_spec>.
.remotehw-usb-grub() {
        printf "\n.remotehw-usb-grub ($remotehw_ver)\n"

        if [ -z "$2" ]; then
                echo " ! Missing boot file parameter. Abort."
                return
        fi

        if [ -z "$1" ]; then
                echo " ! Missing usbtta_spec parameter. Abort."
                return
        fi

	.remotehw-usb-common $1

	echo " * deploying $2 to usbtta along with our grub.cfg from /opt/remotehw" 
	$_scp "$2" $1:/mnt/loop/zephyr.elf 2>&-
	$_scp /opt/remotehw/grub.cfg "$1:/mnt/loop/EFI/BOOT/grub.cfg"

	echo " * attaching completed disk image to target"
	# umount disk image, disconnect loop0 & start g_mass_storage driver with our boot disk image
	$_ssh $1 "umount /mnt/loop && /sbin/losetup -d /dev/loop0 && /sbin/modprobe g_mass_storage file=/tmp/zephyr.disk ro=y iManufacturer=zephyrdevops iProduct=FlashKey iSerialNumber=1234"
	echo "Done. USB disk attached and target ready for power-on."
}
export -f .remotehw-usb-grub

# remotehw-usb-efi <usbtta_spec> <zephyr.efi>
#   prepare a virtual USB flash disk with <zephyr.efi> as EFI bootfile
#   and attach it to <usbtta_spec>.
.remotehw-usb-efi() {
        printf "\n.remotehw-usb-efi ($remotehw_ver)\n"

        if [ -z "$2" ]; then
                echo " ! Missing boot file parameter. Abort."
                return
        fi

        if [ -z "$1" ]; then
                echo " ! Missing usbtta_spec parameter. Abort."
                return
        fi

	.remotehw-usb-common $1

	echo " * deploying $2 to usbtta" 
	$_scp "$2" "$1:/mnt/loop/EFI/BOOT/bootx64.efi"

	echo " * attaching completed disk image to target"
	# umount disk image, disconnect loop0 & start g_mass_storage driver with our boot disk image
	$_ssh "$1" "umount /mnt/loop && /sbin/losetup -d /dev/loop0 && /sbin/modprobe g_mass_storage file=/tmp/zephyr.disk ro=y iManufacturer=zephyrdevops iProduct=FlashKey iSerialNumber=1234"
	echo "Done. USB disk attached and target ready for power-on."
}
export -f .remotehw-usb-efi

#####
## usb-acrn
##
## should probably be renamed to usb-grub-custom

.remotehw-usb-acrn() {
        printf "\n.remotehw-usb-acrn ($remotehw_ver)\n"

        if [ -z "$1" ]; then
                echo " ! Missing usbtta_spec parameter. Abort."
                return
        fi

	.remotehw-usb-common $1

	echo " * unzipping acrn-binaries.zip to EFI/BOOT..."
	$_scp /opt/remotehw/acrn-binaries.zip "$1:/tmp/acrn-binaries.zip"
	$_ssh "$1" "mkdir -p /tmp/acrn && unzip -d /tmp/acrn /tmp/acrn-binaries.zip && mv /tmp/acrn/acrn-binaries/* /mnt/loop/EFI/BOOT && rm -rf /tmp/acrn*"

	if [ -f "$2" ]; then
		echo " * deploying user-provided zephyr.bin and zephyr.elf ($2) to EFI/BOOT"
		$_scp "$2" "$1:/mnt/loop/EFI/BOOT/zephyr.bin"
		$_scp "$2" "$1:/mnt/loop/EFI/BOOT/zephyr.elf"
	fi

	if [ -f "$3" ]; then
		echo " * deploying user-provided grub.cfg ($3) to EFI/BOOT" 
		$_scp "$3" "$1:/mnt/loop/EFI/BOOT/grub.cfg"
	fi

	if [ -f "$4" ]; then
		echo " * deploying user-provided file ($4) to EFI/BOOT" 
		$_scp "$4" "$1:/mnt/loop/EFI/BOOT"
	fi

	echo " * attaching completed disk image to target"
	# umount disk image, disconnect loop0 & start g_mass_storage driver with our boot disk image
	$_ssh "$1" "umount /mnt/loop && /sbin/losetup -d /dev/loop0 && /sbin/modprobe g_mass_storage file=/tmp/zephyr.disk ro=y iManufacturer=zephyrdevops iProduct=FlashKey iSerialNumber=1234"
	echo "Done. USB disk attached and target ready for power-on."
}
export -f .remotehw-usb-acrn

.remotehw-usb-sbl() {
        printf "\n.remotehw-usb-sbl ($remotehw_ver)\n"

        if [ -z "$2" ]; then
                echo " * Missing boot file parameter. Abort."
                return
        fi

        if [ -z "$1" ]; then
                echo " * Missing usbtta_spec parameter. Abort."
                return
        fi

        if [ -z "$1" ]; then
                echo " * Missing usbtta_spec parameter. Abort."
                return
        fi

        echo " * resetting usbtta state"
        # umount any existing loops, disconnect loop0 & remote USB mass storage driver
        $_ssh $1 umount /mnt/loop 2>&-
        $_ssh $1 /sbin/losetup -d /dev/loop0 2>&-
        $_ssh $1 /sbin/modprobe -r g_mass_storage
        sleep 3

        echo " * xfr sbl.disk.gz & unzip"
	$_scp /opt/remotehw/sbl.disk.gz "$1:/tmp/sbl.disk.gz"
        $_ssh $1 "gunzip -c /tmp/sbl.disk.gz > /tmp/zephyr.disk"
        $_ssh $1 "/sbin/losetup -P /dev/loop0 /tmp/zephyr.disk && mount /dev/loop0p2 /mnt/loop && mkdir /mnt/loop/boot"

	echo " * deploying $2 to usbtta"
	$_scp "$2" "$1:/mnt/loop/boot/sbl_os"

	echo " * attaching completed disk image to target"
	# umount disk image, disconnect loop0 & start g_mass_storage driver with our boot disk image
	$_ssh $1 "umount /mnt/loop && /sbin/losetup -d /dev/loop0 && /sbin/modprobe g_mass_storage file=/tmp/zephyr.disk ro=y iManufacturer=zephyrdevops iProduct=FlashKey iSerialNumber=1234"
	echo "Done. USB disk attached and target ready for power-on."
}
export -f .remotehw-usb-sbl

# remotehw-get-tta <tta_spec>
#   open ssh connection to <tta_spec>.
.remotehw-get-tta() {
        if [ -z "$1" ]; then
                echo " * Missing tta_spec (user@host) parameter. Abort."
                return
        fi

        echo "opening $1"
        $_ssh "$1" "$2"
}
export -f .remotehw-get-tta

#####
## usb-get-p1 - mounts emulated disk partition #1 on USB TTA & opens ssh connection for user to edit files
##                 automatically re-attaches disk to target when ssh connection is closed
## 	        is filesystem agnostic, provided the USB TTA supports the filesystem (ext3,vfat...)
.remotehw-usb-get-p1() {
        printf "\n.remotehw-usb-get-part1 ($remotehw_ver)\n"

        if [ -z "$1" ]; then
                echo " ! Missing usbtta_spec parameter. Abort."
                return
        fi

        if [ -z "$2" ]; then
                echo " ! Missing remotehw system name. Abort."
                return
        fi

	echo " * checking for existing disk image on usb-tta"

	if .remotehw-ssh-cmd $1 "eval [ -f '/tmp/zephyr.disk' ]"; then 
		echo " * found /tmp/zephyr.disk"
	else
		echo " ! /tmp/zephyr.disk not found, initialize with usb-efi first."
		return
	fi

	echo " * Disconnecting disk from target & mounting at $1:/mnt/loop"
	.remotehw-ssh-cmd $1 "umount /mnt/loop 2>&-; /sbin/losetup -d /dev/loop0 2>&-; /sbin/modprobe -r g_mass_storage 2>&-;"
	.remotehw-ssh-cmd $1 "/sbin/losetup -P /dev/loop0 /tmp/zephyr.disk && mount /dev/loop0p1 /mnt/loop"
	echo " * disk mount complete."
	printf "\n\n  ########################################################################\n"
	echo "     You will now be connected to the usb-tta via ssh."
	echo "     The emulated flash-disk filesystem is located at /mnt/loop"
	echo "     Use vi to edit files locally."
	echo "     scp is supported for transfering files over the network, example:"
	echo "      $ scp zephyr.file $1:/mnt/loop/EFI/BOOT/zephyr.file"
	echo "     "
	echo "     When finished making changes, type 'exit' to disconnect. Changes will be "
	echo "     automatically applied & disk reconnected to target."
	printf "  ########################################################################\n\n"
	sleep 3
	echo " * opening ssh connection to usbtta $1..."
	.remotehw-$2-get-tta

	echo " * applying changes to /tmp/zephyr.disk@$1..."
	.remotehw-ssh-cmd $1 "umount /mnt/loop && /sbin/losetup -d /dev/loop0 && /sbin/modprobe g_mass_storage file=/tmp/zephyr.disk ro=y iManufacturer=zephyrdevops iProduct=FlashKey iSerialNumber=1234"
	echo " * Done. Changes applied & disk connected to target."


}
export -f .remotehw-usb-get-p1
