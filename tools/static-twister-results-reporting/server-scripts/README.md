# FMOS static twister results reporting server - scripts

FMOS static twister results reporting server that web page for presenting results from twister.

## Function Summary

Script for uploading logs to the artifactory.
backup-testresults-on-artifactory.sh -a <API key to X-JFrog-Artifactory> -s <path_to_all_test_results> -d <address_of_artifactory_folder>


## Usage

Cron job confifiguration:
   - 45 23 10 * * /usr/bin/backup-testresults-on-artifactory.sh -a <API key to X-JFrog-Artifactory> -s <path_to_all_test_results> -d <address_of_artifactory_folder> 2>&1
     1 - 9 day of month
   - 45 23 20 * * /usr/bin/backup-testresults-on-artifactory.sh -a <API key to X-JFrog-Artifactory> -s <path_to_all_test_results> -d <address_of_artifactory_folder> 2>&1
     10 - 19 day of month
   - 45 23 30 * * /usr/bin/backup-testresults-on-artifactory.sh -a <API key to X-JFrog-Artifactory> -s <path_to_all_test_results> -d <address_of_artifactory_folder> 2>&1
     20 - 29 day of month
   - 45 23 1 * * /usr/bin/backup-testresults-on-artifactory.sh -a <API key to X-JFrog-Artifactory> -s <path_to_all_test_results> -d <address_of_artifactory_folder> 2>&1
     30 - 31 day of month
  

## Deployment 

This script is used on a Static Reporting Server

**Contacts: Artur Wilczak