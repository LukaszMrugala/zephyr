#!/bin/bash
#
# script to reveal contents of hidden directory using git-secret
#
# -> user running this script must have trusted gpg identity enrolled in git-secret

export PATH=/usr/local/bin:$PATH

if [ -d hidden/ ]; then
	echo hidden/ already exists, refusing to overwrite.
	exit;
fi

git secret reveal && tar -xzf hidden.tar && rm -f hidden.*
