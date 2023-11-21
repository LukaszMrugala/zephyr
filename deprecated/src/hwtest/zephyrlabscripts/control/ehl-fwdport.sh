#!/bin/sh

LOCALPORT=54333
REMOTEPORT=54321
MACHINE=ehl04
REMOTECOMMAND="nc -l localhost $REMOTEPORT </srv/tftp/$MACHINE/reserved/pty  >/srv/tftp/$MACHINE/reserved/pty"
LOCALTTY=$HOME/$MACHINE-tty
echo $REMOTECOMMAND 
echo $LOCALTTY
echo running SSH 
#ssh -vv -fCo "ExitOnForwardFailure yes" -L $LOCALPORT:localhost:$REMOTEPORT laperie@black.fi.intel.com $REMOTECOMMAND
#echo running SOCAT
#socat pty,link=$LOCALTTY,wait-slave tcp:localhost:$LOCALPORT
#echo 1. ssh -vv -fCo "ExitOnForwardFailure yes" -L $LOCALPORT:localhost:$REMOTEPORT black.fi.intel.com $REMOTECOMMAND 
#echo 2. socat -d -d -d pty,link=$LOCALTTY,wait-slave tcp:localhost:$LOCALPORT

echo ssh -fCo "ExitOnForwardFailure yes" -L $LOCALPORT:localhost:$REMOTEPORT black.fi.intel.com $REMOTECOMMAND
echo Looping socat. Please terminate the script and (sic) kill ssh  to black once finished
#while /bin/true
do
echo 	socat -d -d -d pty,link=/home/laperie/ehl04-tty,wait-slave tcp:localhost:54333;  
done
socat pty,link=$LOCALTTY,wait-slave tcp:localhost:$LOCALPORT



 
