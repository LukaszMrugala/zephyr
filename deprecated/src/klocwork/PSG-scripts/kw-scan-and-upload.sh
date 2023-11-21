
cd /home/swiplab/build/zephyr

KW_BIN_PATH=/home/swiplab/Klocwork/bin
KW_SERVER=https://klocwork-jf25.devtools.intel.com:8195 
KW_PROJECT=zephyr-socfpga

rm -f kwinject.out
rm -rf my_tables

$KW_BIN_PATH/kwinject sh build-zephyr.sh
$KW_BIN_PATH/kwbuildproject --force --url ${KW_SERVER}/$KW_PROJECT -o my_tables kwinject.out
$KW_BIN_PATH/kwadmin --url ${KW_SERVER}/ load $KW_PROJECT my_tables

# python getTeamFiles.py zephyr building-zephyr-project zephyr-socfpga
# cat result.txt |  mail -s "KW runnig result of zephyr project" elly.siew.chin.lim@intel.com,boon.khai.ng@intel.com,xiaohui.lv@intel.com
# cat result.txt |  mail -s "KW runnig result of zephyr project" xiaohui.lv@intel.com
