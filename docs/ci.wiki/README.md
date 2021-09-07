# Zephyr DevOps Documentation Wiki
**Purpose:** Official documentation wiki for Zephyr DevOps services & internal processes. 

**Target Audience:** Intel Zephyr developers & users of Zephyr DevOps services. 

**Document Owner:** Zephyr DevOps 

**Change Process:** 
* Minor edits & improvements ok without approval.
* RFC to FMOS_DevOps for all other changes.

## DevOps Service Links

### CI

We use Jenkins for CI/CD automation. Our main instance is accessible to anyone inside of Intel, here: **https://zephyr-ci.ostc.intel.com**. We also operate a staging instance at **https://zephyr-ci.jf.intel.com:8080**.

### Remote Hardware (RemoteHW)

DevOps operates a remote hardware sharing-system in the JF1-2 lab (US/Oregon).
Zephyr targets are placed on shelves in our test-rack with network power control, network-access & I/O pass-through.
Other capabilities such as power-measurement or wireless network can be enabled as well. 

For additional information & source code, please see **[Remote Hardware](Remote Hardware.md)**.

### SDK docker

We maintain an internal fork of the Zephyr project SDK docker configured for use within the Intel intranet.
See: 

**https://gitlab.devtools.intel.com/zephyrproject-rtos/devops/infrastructure/sdk-docker-intel/-/tree/intel**

### Infrastructure & Systems

### TestNet (.testnet)

DevOps maintains a private test network for all HW test automation & operations. Most VMs in our cluster have access to this network via a secondary network interface with address 192.168.0.0/24. See **[DevOps Virtual Infrastructure](DevOps Virtual Infrastructure.md)** for more info.

#### SSP Ops VMs (*.ostc.intel.com)

DevOps production CI services are currently hosted on VMs provided by SSP-Ops but we expect to leave their support umbrella around WW08 2021. This section will be removed in the near future. 

#### DevOps VMs 

The following VMs are deployed to the Vmware ESXi hypervisor in JF1-2 lab.

**zephyr-ci.jf.intel.com** - new Jenkins CI main, under construction

**zephyr-zabbix.jf.intel.com** - Zabbix systems-monitoring instance

**zephyrtest-orange.jf.intel.com** - remoteHW host, DevOps use

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

#### zephyrproject-rtos@gitlab.devtools

DevOps adminstrates the IT-provided gitlab project for all Intel-internal Zephyr development:

https://gitlab.devtools.intel.com/zephyrproject-rtos

#### git cache (gitlab container)

**todo:** new gitlab-container url

#### zephyr devops teamforge

Teamforge repo with CI keys & credentials (DevOps only)

https://tf-amr-1.devtools.intel.com/sf/projects/zdevops/

### Hardware Test (HWTest & TestNet)
**todo:** condense docs & link here  

### SWLC/SDL
**todo:** link to local docs


