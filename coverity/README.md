###### This Directory explains the process of Running Static Scan Analysis using Coverity on Zephyr. 

# Coverity Process

## Coverity Installation

Coverity Toolkit can be download from here : https://scan.coverity.com/download

## Coverity Build
Run Sanity check for all the tests on all the architectures using the script "run-cov.sh" from inside the zephyr tree to kick off the Coverity Build. The emitted files will be compressed in a tar file to be used for Coverity Analysis.

### Things to Remember:
a)	Update the Zephyr SDK to the Most Recent Version. Check if a newer SDK version is released at https://www.zephyrproject.org/developers/#downloads and then follow the instructions to setup the development environment setup for Zephyr here: Getting started guide at https://www.zephyrproject.org/developers/#downloads

b)	Check if your environment variables are set for ZEPHYR_SDK_INSTALL_DIR, ZEPHYR_TOOLCHAIN_VARIANT and the path of bin directory in the installed Coverity toolkit is to your system path. Also ZEPHYR_BASE should be set in your environment using “source zepyr-env.sh” from inside the zephyr tree.

c)	Do ```west update``` and ```west upgrade``` and have the most updated Zephyr code (Git pull) from https://github.com/zephyrproject-rtos/zephyr before kicking off the build process. 

d)	The build process takes about 1-2 days to complete.

e)	Try to use the clean Zephyr code each time for build process.

## Coverity Analysis
Upload the Coverity build to https://scan.coverity.com. The build will be analyzed on Coverity Server in about 1 hour and all the Coverity issues found during the analysis phase can be found in Coverity Connect Portal in the “Outstanding issues”.  View Defects tab on https://scan.coverity.com/projects/zephyr?tab=overview will redirect to Coverity Connect Portal. 

## GitHub Issues

GitHub issues should be opened for all the corresponding Coverity issues in https://github.com/zephyrproject-rtos/zephyr using the “coverity-automation.py” script. Fetch the Outstanding issues from Coverity Connect Portal (https://scan9.coverity.com/) as a CSV file to use it for opening GitHub Issues.

### Parameters required in the environment to run Coverity-Automation Script

•	export REPORT_PATH="Path to CSV file which contains all the outstanding Coverity Issues”

•	export COV_USER="Coverity Username"

•	export GITHUB_TOKEN="Token of public GitHub account"
 
            
Running the Script “coverity-automation.py” will not open the redundant Coverity issues. It will only create any new Coverity issues found and the script doesn’t reopen any closed issues.

## Triaging

A Developer or Code Owner can then go to GitHub to triage the Coverity issues. More details on the code related to the issue can be found by searching for the Coverity Issue ID in Coverity Connect Portal at https://scan9.coverity.com/

