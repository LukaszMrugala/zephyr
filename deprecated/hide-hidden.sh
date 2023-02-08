#!/bin/bash
#
# this script tars the contents of ./hidden, runs git secret add, and stages an encryted hidden.tar.secret for git commit.
#
# -> user running this script must have trusted gpg identity enrolled in git-secret

export PATH=/usr/local/bin:$PATH

if [ -f hidden.tar.secret ]; then
	echo hidden.tar.secret already exists, refusing to overwrite.
	exit;
fi

if [ -d hidden/ ]; then
	tar -czf hidden.tar hidden/ && git secret hide && git add hidden.tar.secret && rm -f hidden.tar && rm -rf hidden/
else
	echo hidden/ is missing, try reveal-hidden.sh first
	exit;
fi
