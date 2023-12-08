# FMOS static twister results reporting server - scripts

FMOS static twister results reporting server that web page for presenting results of twister run.
All data are pulling from twister.json file stored in twister-out directory after twister ends tests.

## Function Summary

1. backup-testresults-on-artifactory.sh -a <API key to X-JFrog-Artifactory> -s <path_to_all_test_results> -d <address_of_artifactory_folder>
   Script for uploading logs to the artifactory.

2. gh-api-download-artifacts.py
   This is a temporary script to pull daily test results from github CI. After merged the PR which  include the new steps for pushing artifacts to static reporting server in workflow, this script will be sign as deprecated.

## Usage

For both scripts are set cron jobs

1. backup-testresults-on-artifactory.sh
   - 45 23 10 * * /usr/bin/backup-testresults-on-artifactory.sh -a <API key to X-JFrog-Artifactory> -s <path_to_all_test_results> -d <address_of_artifactory_folder> 2>&1
     1 - 9 day of month
   - 45 23 20 * * /usr/bin/backup-testresults-on-artifactory.sh -a <API key to X-JFrog-Artifactory> -s <path_to_all_test_results> -d <address_of_artifactory_folder> 2>&1
     10 - 19 day of month
   - 45 23 30 * * /usr/bin/backup-testresults-on-artifactory.sh -a <API key to X-JFrog-Artifactory> -s <path_to_all_test_results> -d <address_of_artifactory_folder> 2>&1
     20 - 29 day of month
   - 45 23 1 * * /usr/bin/backup-testresults-on-artifactory.sh -a <API key to X-JFrog-Artifactory> -s <path_to_all_test_results> -d <address_of_artifactory_folder> 2>&1
     30 - 31 day of month

2. gh-api-download-artifacts.py
   - 30 14 * * * python3 /usr/bin/gh-api-download-artifacts.py -b <branch_name> -w <all|hw|sim> -d <destination_dir_path> -t <GITHUB_TOKEN>
  

## Deployment 

These scripts must execute on a Static Reporting Server

**Important:** destination_dir_path must be exists. 

**Contacts: Artur Wilczak