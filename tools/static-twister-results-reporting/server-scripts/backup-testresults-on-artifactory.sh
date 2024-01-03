#!/bin/bash

# Script for uploading logs to the artifactory.

usage () {
	cat <<HELP_USAGE

NAME:
	$0 - upload test results to zephyr artifactory

SYNOPSIS:
	$0 -a <APIKEY> -s <PATH> -d <DESTINATION> [-r <RUNDATE>]

DESCRIPTION:
	-a <APIKEY>
		API key to X-JFrog-Artifactory
	-s <PATH>
		Path to all test results
	-d <DESTADDRESS>
		Address of destination artifactory folder
	-r <RUNDATE>
		Optional. Date of run the script uses for setting pattern for find files.
		Format yyyy-mm-dd. 2023-12-30

	If run date is to equal:
		- 2023-11-01 then pattern is equal to 2023-10-3 and backuping the test results
			will cover days from 2023-10-30 to 2023-10-31
		- 2023-11-20 then pattern is equal to 2023-11-1 and backuping the test results
			will cover days from 2023-11-10 to 2023-11-19

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

while getopts a:s:d:r: flag; do
		case "${flag}" in
				a) api=${OPTARG};;
				s) src_dir=${OPTARG};;
				d) artifactory_dir=${OPTARG};;
				r) run_date=${OPTARG};;
		esac
done

# day of run script
if [ $run_date ]; then
	if ! [[ $run_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
		echo "The input -r is NOT in the yyyy-mm-dd date format."
		exit 1
	fi
else
	run_date=$(date '+%Y-%m-%d')
fi

# pattern for searching results files, ex. 2023-10-1 if run date is 2023-10-20
day=$(date -d "$run_date - 1 day" '+%d')
dir_pattern=$(date -d "$run_date - 1 day" '+%Y-%m-')${day%%[0-9]}

echo -e "$(timeStamp)Pattern for find files: $dir_pattern"

# loop through all branch folder
for branch_dir in $src_dir*; do
	if [ -d "$branch_dir" ]; then
		branch_name=${branch_dir##*/}
		[ $branch_name == "test_branch" ] && { continue; }
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
			echo -e "\n$(timeStamp)No files to archive for $branch_name"
		fi
	fi
done

exit 0
