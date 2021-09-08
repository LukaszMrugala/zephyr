#!/bin/sh
USERS='ajross  anashif  apboie  dleung5  ehlflash  jhe  jrissane  laperie  rveerama  tedann  tobur'
GROUPS='adm dialout cdrom sudo dip plugdev lpadmin lxd sambashare cleware disk'
for user in $USERS
do
for grp in $GROUPS
do
  usermod -a -G $grp $user
done
done




