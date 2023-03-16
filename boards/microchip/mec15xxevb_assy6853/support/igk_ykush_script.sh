#!/bin/bash

#[WIP]
#Script for resetting mec15 with ykush

#This is only workaround for ykush
ssh -o StrictHostKeyChecking=no -T zephyr@192.168.23.15 <<EOL
ykushcmd -d 1
sleep 2
ykushcmd -u 1

exit
EOL
