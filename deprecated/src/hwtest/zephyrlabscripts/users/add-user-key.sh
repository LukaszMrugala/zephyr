#!/bin/sh
USERNAME=$1
GROUPS='adm dialout cdrom sudo dip plugdev lpadmin lxd sambashare cleware disk'
useradd -m -d /home/$USERNAME -s /bin/bash $USERNAME
mkdir /home/$USERNAME/.ssh
cp $2 /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
chmod 700 /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/authorized_keys
for grp in $GROUPS
do
   #adduser $USERNAME $grp
   usermod -a -G $grp  $USERNAME
done
  




