#!/bin/bash

# Script for uploading logs to the artifactory.
# Each cron job upload data from last ten days except last cron job.
# cron jobs
# 45 23 10 * * /usr/bin/backup-testresults-on-artifactory.sh ...
#   1 - 9 day of month
# 45 23 20 * * /usr/bin/backup-testresults-on-artifactory.sh ...
#   10 - 19 day of month
# 45 23 30 * * /usr/bin/backup-testresults-on-artifactory.sh ...
#   20 - 29 day of month
# 45 23 1 * * /usr/bin/backup-testresults-on-artifactory.sh ...
#   30 - 31 day of month

usage () {
  cat <<HELP_USAGE
Script for uploading logs to the artifactory.

Usage:
$0 -a <API key to X-JFrog-Artifactory> -s <path_to_all_test_results> -d <address_of_artifactory_folder>

HELP_USAGE
}

function timeStamp() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): "
}

if [ $# -lt 6 ]; then
  usage;
  args_count=$(($#/2))
  echo "ERROR($0): only $args_count arguments are given"
  exit 1
fi

# day of run script
day=$(date -d 'yesterday' '+%d')
# pattern for searching results files, ex. 2023-10-1 if run date is 2023-10-20
dir_pattern=$(date -d 'yesterday' '+%Y-%m-')${day%%[0-9]}

while getopts a:s:d: flag
do
    case "${flag}" in
        a) api=${OPTARG};;
        s) src_dir=${OPTARG};;
        d) artifactory_dir=${OPTARG};;
    esac
done

# loop through all branch folder
for branch_dir in $src_dir*; do
    if [[ -d "$branch_dir" && $f != *"test"* ]]; then
        branch_name=${branch_dir##*/}
        backup_file="${branch_dir}/${branch_name}-${dir_pattern}x.tar.gz"
        cd ${branch_dir}
        # find -type f -mtime +20 -name "static-reports-backup-*.tar.gz"

        find ~+ -type d -name "${dir_pattern}*" > dirlist.txt
        if [ -s "dirlist.txt" ]; then
            echo -e "$(timeStamp)Compressing log files:"
            tar --ignore-failed-read --absolute-name --checkpoint=.1000 -czf $backup_file -T dirlist.txt

            if [ -f "$backup_file" ]; then
                echo -e "\n$(timeStamp)Uploading to artifactory:"
                echo -e "\t"$(ls -sh $backup_file)

                CHECKSUM=$(md5sum $backup_file | awk '{ print $1 }')
                curl --header "X-JFrog-Art-Api:${api}" --header "X-Checksum-MD5:${CHECKSUM}" --upload-file $backup_file $artifactory_dir
            fi
            echo -e "\n$(timeStamp)Done"
        else
            echo -e "\n$(timeStamp)No files to archive"
        fi
    fi
done

exit 0
