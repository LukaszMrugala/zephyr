# Zephyr DevOps Documentation Wiki
**Purpose:** Official documentation wiki for Zephyr DevOps services & internal processes. 

**Target Audience:** Intel Zephyr developers & users of Zephyr DevOps services. 

**Document Owner:** Zephyr DevOps 

**Change Process:** 
* Minor edits & improvements ok without approval.
* RFC to FMOS_DevOps for all other changes.

## DevOps Service Links

### CI: Innersource Github Actions + Jenkins 

We have embedded Github Actions workflows in all production innersource repos, for example: [zephyr](https://github.com/intel-innersource/os.rtos.zephyr.zephyr/actions) & [zephyr-intel](https://github.com/intel-innersource/os.rtos.zephyr.zephyr-intel/actions). DevOps maintains a minimal Jenkins instance running on [zephyr-ci.jf.intel.com](https://zephyr-ci.jf.intel.com/) for supporting automation tasks + testing. 

### Remote Hardware (RemoteHW)

DevOps operates a remote hardware sharing-system in the JF1-2 lab (US/Oregon).
Zephyr targets are placed on shelves in our test-rack with network power control, network-access & I/O pass-through.
Other capabilities such as power-measurement or wireless network can be enabled as well. 

For additional information & source code, please see **[Remote Hardware](Remote Hardware.md)**.

### SDK docker

We maintain an internal fork of the Zephyr project SDK docker configured for use within the Intel intranet.
See: 

https://github.com/intel-innersource/os.rtos.zephyr.devops.infrastructure.sdk-docker-intel/README-INTEL.md

### Infrastructure & Systems

### TestNet (.testnet)

DevOps maintains a private test network for all HW test automation & operations. Most VMs in our cluster have access to this network via a secondary network interface with address 192.168.0.0/24. See **[DevOps Virtual Infrastructure](DevOps Virtual Infrastructure.md)** for more info.

#### DevOps VMs 

The following VMs are deployed to the Vmware ESXi hypervisor in JF1-2 lab.

**zephyr-ci.jf.intel.com** - new Jenkins CI main, under construction

**zephyr-zabbix.jf.intel.com** - Zabbix systems-monitoring instance

**zephyr-devops.jf.intel.com** - DevOps staging

**zephyrtest-blue.jf.intel.com** - remoteHW host, EHL + TGRVP

**fresno.jf.intel.com** - DevOps use

Backend Service VMs (accessible only from within TestNet)

**nas.zephyr-testnet** - freeNAS VM serving 2TB of SSD RAID

**gw.zephyr-testnet** - pfsense gateway for TestNet

**zbuild{01..06}.testnet** - CI build agents

#### Physical Systems 

**zephyr-ci-th01.jf.intel.com** - 1U server, implements "TestHead" function in JF

**zephyr-ci-th02.jf.intel.com** - 1U server, implements "TestHead" function in SH (once installed)


### git services

#### innersource/os.rtos.zephyr.*

Main internal Zephyr/1RTOS repos

#### zephyrproject-rtos@gitlab.devtools ( pending EOL )

DevOps adminstrates the IT-provided gitlab project for all Intel-internal Zephyr development:

https://gitlab.devtools.intel.com/zephyrproject-rtos

#### zephyr devops teamforge ( pending EOL )

Teamforge repo with CI keys & credentials (DevOps only)

https://tf-amr-1.devtools.intel.com/sf/projects/zdevops/

2021: Replaced by hidden.tar.secret in ci.git
