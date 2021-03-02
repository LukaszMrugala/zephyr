#!/bin/bash
#
# This script builds the application using the Coverity Scan build tool,
# and prepares the archive for uploading to the cloud static analyzer.
#inserting configurable python path (new DevOps method)
#ZEPHYR_BRANCH_BASE is normally set by detect_branch module but just hardcoding to misra-c-scans here

export ZEPHYR_BRANCH_BASE="master" #can also be "master" to select master-branch python deps+path
export PYTHONPATH="$(find /usr/local_$ZEPHYR_BRANCH_BASE/lib -name python3.* -print0)/site-packages:$(find /usr/local_$ZEPHYR_BRANCH_BASE/lib64 -name python3.* -print0)/site-packages"
export PATH=/usr/local_$ZEPHYR_BRANCH_BASE/bin:$PATH
if [ -d "zephyrproject" ]; then rm -rf zephyrproject; fi
if [ -d "cov-build-misra-c" ]; then rm -rf cov-build-misra-c; fi
mkdir cov-build-misra-c
west init zephyrproject
cd zephyrproject
west update
cd zephyr

COV_BIN=$WORKSPACE/cov-analysis-linux64-2019.06/bin
COV_CONF=${COV_BIN}/cov-configure
COV_BUILD=${COV_BIN}/cov-build
COV_BUILD_DIR=$WORKSPACE/cov-build-misra-c
COV_INT=${COV_BUILD_DIR}/cov-int
COV_ANALYZE=${COV_BIN}/cov-analyze
COV_FORMAT_ERRORS=${COV_BIN}/cov-format-errors
COV_COMMIT_DEFECTS=${COV_BIN}/cov-commit-defects

source zephyr-env.sh
export ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk-0.11.2
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
function die() { echo "$@" 1>&2; exit 1; }

export CCACHE_DISABLE=1
which ${COV_CONF} && which ${COV_BUILD} || die "Coverity Build Tool is not in PATH"

${COV_CONF} --comptype gcc --compiler arm-zephyr-eabi-gcc --template
${COV_BUILD} --emit-complementary-info --dir ${COV_INT} west build -p -b mimxrt1050_evk ./tests/benchmarks/footprints/

${COV_ANALYZE} --misra-config $WORKSPACE/ci/coverity/misra_c_scans/MISRA.config --tu-pattern "! file('.*/samples/.*') && ! file('.*\.cpp') && ! file('.*/tests/.*') && ! file('autoconf.h') && ! file('.*/drivers/*/') && ! file('.*/lib/libc/.*') && ! file('.*/lib/crc/.*') && ! file('.*/subsys/[fb|fs|app_memory|fs|blueooth|console|cpp|debug|dfu|disk|fb|fs|mgmt|net|power|random|settings|shell|stats|storage|usb]/.*')" --dir ${COV_INT}
${COV_FORMAT_ERRORS} --dir ${COV_INT} --json-output-v6 $WORKSPACE/errors.json

unset {http,https}_proxy
unset {HTTP,HTTPS}_PROXY

${COV_COMMIT_DEFECTS} --dir ${COV_INT} --host cov.ostc.intel.com --auth-key-file $USERPASS --stream zephyr-misra-c-scans

echo "Completed"
