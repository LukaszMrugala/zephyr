#!/bin/bash
echo $0 COMMAND WAIT TRIES CLEANUP
LOCKFILE=/tmp/$$-lock.lock
TRIES=$3
WAIT_COMPLETE=$2
COMMAND=$1 
CLEANUP=$4

set +m
try=0
while [ $try -le $TRIES ]
do

  /bin/bash << EOF &
	#run command
	echo my PID is $$

	echo CMD: sleeping
	$COMMAND

	echo CMD: Removing lockflile
	rm $LOCKFILE
EOF
  LAUNCHED=$!
  touch $LOCKFILE
  echo launched PID=$LAUNCHED
  #WAIT
  echo WD: Sleeping
  sleep $WAIT_COMPLETE
  echo WD: Done sleeping
  if test -f $LOCKFILE
  then
        echo Lockfile exists, damage control
	$CLEANUP
	kill -9 $LAUNCHED
	rm $LOCKFILE
	try=$(( $try + 1 ))
  else
	echo Hurrah, no lockfile
	break
  fi
done
if [ $try -le $TRIES ]
then
  echo COMMAND EXECUTED OK, done $try attempts
else
  echo too many tries!!!
fi
