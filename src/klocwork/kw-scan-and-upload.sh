
cd ~/kw-zephyrproject

KW_BIN_PATH=/home/cgturner/Klocwork/bin
KW_SERVER=https://klocwork-jf2.devtools.intel.com:8080
KW_PROJECT=FMOS

rm -f kwinject.out
rm -rf my_tables

$KW_BIN_PATH/kwinject sh build-zephyr.sh
$KW_BIN_PATH/kwbuildproject --force --url ${KW_SERVER}/$KW_PROJECT -o my_tables kwinject.out
$KW_BIN_PATH/kwadmin --url ${KW_SERVER}/ load $KW_PROJECT my_tables
