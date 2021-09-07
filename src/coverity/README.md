###### This Directory explains the process of Running Static Scan Analysis using Coverity on Zephyr. 

# Coverity Process

## Coverity Installation

Coverity Toolkit can be download from here : https://scan.coverity.com/download

## Coverity Build
Run Sanity check for all the tests on all the architectures using the script "run-cov.sh" from inside the zephyr tree to kick off the Coverity Build. The emitted files will be compressed in a tar file to be used for Coverity Analysis.

###### Command to execute Coverity Script : run-cov.sh.

``` ./run-cov.sh "Path to Coverity Bin Directory" "Path to Coverity Build Directory" "Path to Most Recent Version of Zephyr SDK Install Directory" ```

Example : ``` ./run-cov.sh $HOME/cov-analysis-linux64-2019.03/bin $HOME/cov-build /opt/zephyr-sdk-0.10.3 ```


### Things to Remember:
•	Update the Zephyr SDK to the Most Recent Version. Check if a newer SDK version is released at https://www.zephyrproject.org/developers/#downloads and then follow the instructions to setup the development environment setup for Zephyr here: Getting started guide at https://www.zephyrproject.org/developers/#downloads

•	Check if you are passing all the arguments while running run-cov.sh. 

1st Argument:  Path to Coverity Bin Installation Example: $HOME/cov-analysis-linux64-2019.03/bin

2nd argument:  Path to Coverity Build Directory. Create a directory like $HOME/cov-build before passing this argument.

3rd Argument:  Path to the Most Recent Version of Zephyr SDK install directory

The environment variables needed for running Coverity Build are passed as arguments to Script run-cov.sh.

•	Do ```west update``` and ```west upgrade``` and have the most updated Zephyr code (Git pull) from https://github.com/zephyrproject-rtos/zephyr before kicking off the build process. 

•	The build process takes about 1-2 days to complete.

•	Every time run-cov.sh script is run, a clean Zephyr code is initiated each time for build process. The Script ensures to remove the existing Zephyr Code in $PWD.


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

