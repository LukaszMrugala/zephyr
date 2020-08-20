#!/bin/bash

# Zephyr DevOps PYTHONPATH settin' script

# Usage:
#	set-python-path.sh <build env type>
#
# Where:
#	build-env-type = "master", "v1.14-branch-intel"
#		(or other branch flavor defined in branch-detect.groovy)

PYPTH=""
#search for base lib path...
if [ -d "/usr/local_$1/lib" ]; then
	 PYPTH="$(find /usr/local_$1/lib -type d -regex .*python3.*/site-packages)"
fi
#append lib64 path if it exists too
if [ -d "/usr/local_$1/lib64" ]; then
	PYPTH+=":$(find /usr/local_$1/lib64 -type d -regex .*python3.*/site-packages)"
fi

#return on stdout for upstream consumption
echo "$PYPTH"
