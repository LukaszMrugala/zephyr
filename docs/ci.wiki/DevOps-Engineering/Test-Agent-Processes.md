# DevOps process for provisioning a new NUC for test-agent use

1.	Install RAM (2x 32GB)
1.  Connect keyboard, mouse & monitor to NUC, then power-on
    * Initial power-on may take up to 1 minute while memory is detected & calibrated
    * Confirm detected memory capacity is "63G" in BIOS setup screen
1.	Update BIOS to latest
    * Download BExxxx.bio file (for NUC8i5BEK: https://downloadcenter.intel.com/download/29282/BIOS-Update-BECFL357-86A-?product=126147)
    * Copy .bio file to USB disk & insert in NUC USB port
    * Hit F7 from BIOS screen, browse to fs0: and select BExxxx.bio file for update
    * Update will take 2-3 minutes. The system will reboot when complete.
1.	Configure NUC BIOS settings as follows:
    * Hit F9 to load BIOS defaults & confirm
    * Click "Advanced" button & configure sub-sections as follows:
        * Boot->Boot Configuration
            * Check "Unlimited Boot to Network Attempts"
            * Uncheck "USB", "Thunderbolt" and "Optical" under Boot Devices
        * Boot->Secure Boot
            * Uncheck "Secure Boot"
        * Power
            * Change "After Power Failure" to "Power On"
        * "Cooling"
            * Change "Fan-Control Mode" to "Cool"
    * Hit F10 to save settings & exit
1.	Install into HW Test & confirm NUC powers-on when plugged-in (without a button press)
1.	Provision NUC MAC-address in TestHead pxeboot config to allow it to fetch a OS & boot 
    * Link: TBD

# Process for removing a test-agent NUC from the test-network

To minimize the chance for a CI or QA automation outage, please use the following process to add/remove test-agents to/from the zephyr QA/CI test:

## Removing a test-agent:

1. If possible, notify FMOS_DevOps BEFORE removing a test-agent from test-network. DevOps can remove the NUC from CI inventory so that jobs are not being sent to the NUC while it's off the network.
1. Power-off test-agent system. Test-agents are stateless & do not need to be shutdown- ok to disconnect power with the power-switch or unplug.
1. Disconnect the network cable. Use care with the NUC network jacks- they can be damaged by forceful removal of the RJ-45 connector.

## Adding a test-agent/NUC:

1. If the test-agent is new, please STOP & complete the setup process first [Test Agent Setup Process.md]
1. If the test-agent is existing but has changed number or type of connected DUT (boards), STOP. Please contact DevOps to reprovision the test-agent. Have MAC address, power-switch number + types of boards connected to expedite service.
**Please submit a MR to https://gitlab.devtools.intel.com/zephyrproject-rtos/ci/-/blob/latest/hwtest/dut.map**
1. [Re]connect DUT/boards to test-agent if they were removed.
1. Plug-in NUC to network. Be sure to use a CAT-5E or CAT-6 (preferred) network cable in good-condition
1. Plug-in NUC power-supply into provisioned power-switch number
1. NUC should power-on & boot without pressing the power-button
