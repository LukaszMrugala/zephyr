#!/bin/bash

BUILD=$1
FIRMWARE=${BUILD}/zephyr/zephyr.bin
FLASHER=$2
BOARD=ite-board-ci_01
DOWNLOAD_BOARD=ite-board-dbg_01

retry=0
while [ $retry -lt 3 ]; do
	echo "$(date): pid=$$ retry=$retry, flash start" >> ${BUILD}/ite_flash_result.txt
	sudo -S ${FLASHER} -f ${FIRMWARE} >> ${BUILD}/ite_flash_result.txt
	echo "$(date): pid=$$ retry=$retry, flash done" >> ${BUILD}/ite_flash_result.txt

	res=`grep -c -E "Verifying[\.: \t]+100%" \${BUILD}/ite_flash_result.txt`
	if [ "$res" != "1" ]; then

        python3  $ZEPHYR_BASE/scripts/support/labgrid_prepare_platform.py \
            --lg-place $BOARD \
            --lg-power cycle \
            --lg-crossbar $LG_CROSSBAR >> ${BUILD}/ite_flash_result.txt

        python3  $ZEPHYR_BASE/scripts/support/labgrid_prepare_platform.py \
            --lg-place $DOWNLOAD_BOARD \
            --lg-power cycle \
            --lg-crossbar $LG_CROSSBAR >> ${BUILD}/ite_flash_result.txt

        sleep 3
		retry=$((retry+1))
	else
		exit 0
	fi
done

echo "Flashing failed after 3 retries." >> ${BUILD}/ite_flash_result.txt
exit 1
