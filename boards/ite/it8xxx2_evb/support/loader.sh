#!/bin/sh

BUILD=$1/zephyr/zephyr.bin
FLASHER=$2
use_ykush_via_ssh () {
ssh -o StrictHostKeyChecking=no -T zephyr@192.168.23.4 <<EOL
sudo ykushcmd $3 $4
sleep 2
exit
EOL
}
mkdir ./tmp

IS_WATCHDOG=`cat ./tmp/is_watchdog.txt`

if [ "$IS_WATCHDOG" = "1" ];
then
use_ykush_via_ssh -u 1
fi

IS_WATCHDOG=`grep wdt_basic_test_suite $BUILD | grep -c matches`
echo $IS_WATCHDOG > ./tmp/is_watchdog.txt

retry=0
while [ $retry -lt 3 ]
do
	sudo -S ${FLASHER} -f ${BUILD} > ./tmp/flash_result.txt
	cat ./tmp/flash_result.txt >> ./tmp/flash_log.txt
	res=`grep -c "Verifying...     : 100%" ./tmp/flash_result.txt`
	echo `grep Verifying ./tmp/flash_result.txt` >> ./tmp/flash_log.txt
	if [ "$res" != "1" ];
	then
use_ykush_via_ssh -d a
use_ykush_via_ssh -u a

		retry=$((retry+1))
	else
		echo "is_watchdog = "$IS_WATCHDOG
		if [ "$IS_WATCHDOG" = "1" ];
		then
use_ykush_via_ssh -d a
use_ykush_via_ssh -u 2
		fi
		exit 0
	fi
done
