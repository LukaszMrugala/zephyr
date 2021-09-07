# Zephyr DevOps Remote Hardware Documentation

## Intro
This documentation covers DevOps' automated hardware-sharing system in JF1, typically referred to as "Remote Hardware" or "RemoteHW" for short. 
RemoteHW was created enable global access to our limited pre-production x86 targets, while also providing a standard, DevOps-maintained interface for interacting with Zephyr test-devices- both for developers at the command-line & upstream automation.

The service allows any Intel employee to:
* Access Zephyr DevOps-managed "zephyrtest" VMs with USB I/O for device-testing operations.   
* Reserve x86 Zephyr test targets for exclusive use
* Execute "remotehw-" to control power, emulate USB devices & connect to target UART

RemoteHW is built around [BeagleBoneBlack](https://beagleboard.org/black) (BBB) open-source maker-boards that provide USB device emulation via g_mass_storage + other low-latency I/O to the device-under-test (DUT).

## Architecture

RemoteHW ingredients:
1. Ubuntu 18.04 virtual-machines, each with dedicated USB cards & dedicated to remoteHW functions. Periodic snapshot reset.
1. Network power-switches (aka, "PDLs")
1. BeagleBoneBlack - one per target, configured as "USB TTA" per DevOps procedure.
1. RemoteHW "code", exposed to as shell env functions sourced from /etc/profile.d/remotehw* at login
1. A rack of x86 Zephyr targets in JF1-2 OISA lab

## Status & Known-Issues

RemoteHW is currently beta - all required commands are supported & we're now focusing on features to simplify sustaining this service. 

## Usage

RemoteHW commands are issued from the Linux command-line, either direct by a user or through Jenkins automation.Systems connected to remoteHW are controlled via shell commands 

Here's a list of commands that are currently supported as well as features we expect to add in the near future.

### RemoteHW Commands

| **released commands** | description |
|-----------------------|-------------|
| remotehw-<target_name>- **reserve** | reserve target     |
| remotehw-<target_name>- **release** | release target reservation, also closes picocom sessions started **get-console**  |
| remotehw-<target_name>- **rsvrst**  | reset reservation & close picocom sessions, even if owned by another user   |
| remotehw-<target_name>- **power-on**   | enables AC-power to target system |
| remotehw-<target_name>- **power-off**   | disabled AC-power to target system |
| remotehw-<target_name>- **usb-efi** <zephyr.efi>  | creates an EFI boot-disk with zephyr.EFI & attaches to target system |
| remotehw-<target_name>- **usb-grub** <zephyr.elf> | creates a grub boot-disk with zephyr.elf as multiboot target & attaches to target system |
| remotehw-<target_name>- **usb-sbl** <sbl_os> | creates SlimBootLoader payload disk & injects sbl_os into /boot directory & attaches to target system |
| remotehw-<target_name>- **usb-acrn** (zephyr.bin) (grub.cfg) | creates acrn boot disk from [acrn-binaries.zip](https://gitlab.devtools.intel.com/zephyrproject-rtos/devops/infrastructure/ansible-playbooks/-/blob/latest/remotehw/opt/acrn-binaries.zip). Overrides zephyr.bin & grub.cfg if optional arguments are supplied. |
| remotehw-<target_name>- **usb-get-p1** | disconnects emulated USB disk from target & opens ssh connection to the USB TTA. Files can be manipulated under /mnt/loop. Disk is reconnected to target when the user exits the USB TTA ssh session. |
| remotehw-<target_name>- **get-console**      | opens terminal session to configured tty for target system |
| remotehw-<target_name>- **get-tty**  | return sting for configured tty device, eg /dev/ttyUSB6 | Z11 |

| **development features**       | description | ETA |
|--------------------------------|-------------|-----|
| remotehw-<target_name>- **status**  | get target status | Z11 |

### RemoteHW Features In-Development

* GPIO to target: available but lack published methods, documentation
* PXE boot: possible but not planned yet
* Snapshot & rollback are not yet automated - only triggering rollback when requested.

### Known Issues & Bugs

1. **Commands that take a file as an argument will fail silently if the file specified by the argument does not exist or is not accessible.**

## Getting Help
**Source Code**

RemoteHW is implemented by env functions sourced from /etc/profile.d/remotehw* when you login to DevOps infrastructure. These scripts are managed by ansible, our configuration-management tool, however users are free to copy the scripts from /etc/profile.d into their local env & modify the functionality as needed. 

* [remotehw env functions](https://gitlab.devtools.intel.com/zephyrproject-rtos/devops/infrastructure/ansible-playbooks/-/tree/master/remotehw)
* [ansible playbook to deploy remotehw env](https://gitlab.devtools.intel.com/zephyrproject-rtos/devops/infrastructure/ansible-playbooks/-/blob/master/ubuntu18_PRD02-remotehw.yaml)

**Email**

[Email FMOS DevOps PDL](mailto:fmos.devops@intel.com?subject=DevOps%20RemoteHW%20Question) if you have any questions, issues or feature requests.

## Quick start

#### 1. Get access to our remotehw infrastructure.

Access to DevOps infrastructure is controlled by a [YAML file](https://gitlab.devtools.intel.com/zephyrproject-rtos/devops/infrastructure/ansible-playbooks/-/blob/current/acl-remotehw.yaml) in git. If you see your idsid in the list, you should have access.

**Options for requesting access:**
1. If you have a gitlab account, edit (or submit a cmd-line merge) [remotehw-acl.yaml](https://gitlab.devtools.intel.com/zephyrproject-rtos/devops/infrastructure/ansible-playbooks/-/blob/current/acl-remotehw.yaml), adding your domain/idsid listed in the appropriate groups.

This will automatically create a merge-request that DevOps will review & approve or deny.
Approved ACL changes are applied by this [ansible playbook](https://gitlab.devtools.intel.com/zephyrproject-rtos/devops/infrastructure/ansible-playbooks/-/blob/current/ubuntu18_PRD01-acl.yaml), which is run from a jenkins job triggered on changes.

1. [Email FMOS DevOps PDL](mailto:fmos.devops@intel.com?subject=DevOps%20ACL%20Request) with a list of machines or functions and we'll process a acl-remotehw.yaml merge for you.

#### 2. Select remoteHW VM & connect

Select remoteHW VM based on the device you'd like to access:

|**zephyrtest-blue.jf.intel.com**| |
|-----------------------------|----|
| ehlsku7  | EHL CRB, SKU7 |
| ehlsku11  | EHL CRB, SKU11 |
| tglchr01 | (**disabled until WW04**) TGL-U 4+2 Chrome (power on/off + console only) |
| minnow01 | Minnowboard |


| **zephyrtest-orange.jf.intel.com** (staging) ||
|----------------------------|-----|
| upx01    | (**disabled until WW04, devicetree issues**) Up Extreme |
| (avail) ||
| (avail) ||
| (avail) ||

```
$ ssh zephyrtest-<color>.jf.intel.com
```
#### 3. Reserve system 
Example, EHL SKU7:
```
# reserve system
user@zephyrtest-blue$ remotehw-ehlsku7-reserve

.remotehw-reserve (70afd76)
 * ehlsku7 is available. Setting owner to user.
Done. System reserved.
```

#### 4. Boot arbitrary zephyr.efi via emulated USB flash-disk
Example, EHL SKU7:
```
# power-off system first
user@zephyrtest-blue$ remotehw-ehlsku7-power-off

.remotehw-power-off (70afd76)
 * sending power-off command to pwrswitch-blue.testnet/outlet?3
Done. Target powered-off.

# create & attach usb flash-disk using zephyr.efi
user@zephyrtest-blue$ remotehw-ehlsku7-usb zephyr.efi

.remotehw-usb-efi (70afd76)
 * resetting usbtta state
 * creating new boot disk filesystem
 * deploying zephyr.efi to usbtta
 * attaching completed disk image to target
Done. USB disk attached and target ready for power-on.

# power-on system
user@zephyrtest-blue$ remotehw-ehlsku7-power-on

.remotehw-power-on (70afd76)
 * sending power-on command to pwrswitch-blue.testnet/outlet?3
Done. Target powered-on.

# get console to system
user@zephyrtest-blue$ remotehw-ehlsku7-get-console

...

# ctrl-x + ctrl-a to exit
```

#### 4. Power-off system & release reservation 
Example, EHL SKU7:
```
# power-off system
user@zephyrtest-blue$ remotehw-ehlsku7-power-off

.remotehw-power-off (70afd76)
 * sending power-off command to pwrswitch-blue.testnet/outlet?3
Done. Target powered-off.

# release reservation & kill any console sessions
user@zephyrtest-blue$ remotehw-ehlsku7-reserve

.remotehw-release (70afd76)
 * ehlsku7 owner is currently user, releasing reservation & killing console sessions.
```
## USB Test-Target Adapters (USB TTA)

For USB device emulation + other low-latency I/O to the device-under-test (DUT),
Zephyr DevOps has deployed an array of [BeagleBoneBlack](https://beagleboard.org/black) (BBB) open-source maker-boards
flashed with a [custom](https://github.com/cvondratek/usb-boot-adapter.bcbprj) [yocto](https://git.yoctoproject.org/cgit/cgit.cgi/meta-ti/) build that enables linux g_mass_storage and squashfs root in RAM.

The USB TTAs run 4.15+ LTS kernel and have a lightweight dropbear+busybox console environment that can run automation scripts, etc.
 
### Interacting with USB TTAs

 To demonstate USB TTA debug & automation capabilities, here's an annotated 
 list of commands one might use to manually modify the emulated USB flash-disk
 contents.
```
# initialize the USB disk with the acrn-binaries.zip payload
remotehw-<sys>-usb-acrn
# connect to usb-tta for your system, note dot prefix on this command
.remotehw-<sys>-get-tta
# fyi: you are now logged into a yocto image running on a BeagleBoneBlack. Fun!
# unload the g_mass_storage USB driver, this will also disconnect the USB flash disk from the test system
modprobe -r g_mass_storage
# the disk image is stored at /tmp/zephyr.disk as a 64MB linear block that emulates a flash-device,
#   we need to index into the flash device to locate the a file-system partition using losetup & mount it:
losetup -P /dev/loop0 /tmp/zephyr.disk
mount /dev/loop0p1 /mnt/loop
# Disk is now mounted to the USB TTA & you can access the files on the boot disk at /mnt/loop
# USB TTAs run a stripped-down yocto build with bash, vi, etc.
# When finished making changes, umount the disk, disconnect the loop device & restart the usb driver
umount /mnt/loop
losetup -d /dev/loop0
modprobe g_mass_storage file=/tmp/zephyr.disk ro=y iManufacturer=zephyrdevops iProduct=FlashKey iSerialNumber=1234"
# the emulated disk is now connected to the target system
```