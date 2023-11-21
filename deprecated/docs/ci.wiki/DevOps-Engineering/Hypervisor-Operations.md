# Zepyhr DevOps Hypervisor Operations

## A. Summary

DevOps operates a single VMware ESXI 6.7 hypervisor on jfsotc17 that is tasked with CI & test automation for Intel's internal Zephyr project efforts.

## B. Accessing Hypervisor 

The hypervisor is not directly connected to the Intel intranet. To access you must be connected to our secured TestNet or use SSH tunneling to expose the https services on your local machine:

From remote:
~~~~
ssh -L 4430:192.168.0.254:443 zephyr-ci.jf.intel.com
https://127.0.0.1:4430
~~~~
From TestNet (direct connection in lab):
~~~~
https://192.168.0.254:443
~~~~

The hypervisor is also accessible via SSH from TestNet for CLI operations

### ACL 

root account should not be used

User accounts for DevOps engineers are created manually.

## C. VM Control ( power on/off, reset )

1. Notify users of reboot/downtime. If this is a production VM, clear operation with FMOS_DevOps
2. Access ESXi UI per instructions in **B** above
3. Select the VM instance you'd like to control
4. Click the "Actions" gear & select operation. If the option you require is grayed-out, contact FMOS_DevOps for permissions.

