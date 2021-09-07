#!/bin/bash

#inserting configurable python path (new DevOps method)
#ZEPHYR_BRANCH_BASE is normally set by detect_branch module but just hardcoding to v1.14-branch-intel here
export ZEPHYR_BRANCH_BASE="v1.14-branch-intel" #can also be "master" to select master-branch python deps+path
export PYTHONPATH="$(find /usr/local_$ZEPHYR_BRANCH_BASE/lib -name python3.* -print0)/site-packages:$(find /usr/local_$ZEPHYR_BRANCH_BASE/lib64 -name python3.* -print0)/site-packages"
export PATH=/usr/local_$ZEPHYR_BRANCH_BASE/bin:$PATH

export USE_CCACHE=0
export CCACHE_DISABLE=1

# run this script in a zephyr tree. It will generate a file named coverity.tgz
# that you will need to upload to coverity server.

if [ -d "zephyr" ]; then rm -rf zephyr; fi
if [ -d "cov-build-1.14-branch-intel" ]; then rm -rf cov-build-1.14-branch-intel; fi
mkdir cov-build-1.14-branch-intel
git clone -b v1.14-branch-intel https://gitlab.devtools.intel.com/zephyrproject-rtos/zephyr.git zephyr
west init -l zephyr
west update

cd zephyr

echo "Environment Variables"
echo "======================================"
echo "ZEPHYR_BASE: $ZEPHYR_BASE"
echo "ZEPHYR_SDK_INSTALL_DIR: $ZEPHYR_SDK_INSTALL_DIR"
echo "ZEPHYR_TOOLCHAIN_VARIANT: $ZEPHYR_TOOLCHAIN_VARIANT"
echo "PATH: $PATH"
echo "PYTHONPATH: $PYTHONPATH"

COV_BIN=$WORKSPACE/cov-analysis-linux64-2019.06/bin

COV_BUILD_DIR=$WORKSPACE/cov-build-1.14-branch-intel
COV_INT=${COV_BUILD_DIR}/cov-int
COV_CONF=${COV_BIN}/cov-configure
COV_BUILD=${COV_BIN}/cov-build
COV_ANALYZE=${COV_BIN}/cov-analyze
COV_FORMAT_ERRORS=${COV_BIN}/cov-format-errors
COV_COMMIT_DEFECTS=${COV_BIN}/cov-commit-defects

mkdir -p sanity.out.trash
rm -rf ${COV_INT}

#define sanitycheck base cmd for use across all calls
SC_BASE_CMD="scripts/sanitycheck -x=USE_CCACHE=0 -x=CCACHE_DISABLE=1 -b -N -j96"

#disabling distro env script... it can pickup incorrect env settings so it's best to configure the ZEPHYR_xxxx env vars explictly
#source zephyr-env.sh

# Build for native_posix/x86_64 with host compiler
function build_with_host_compiler() {
	board=$1
	${COV_CONF} --comptype gcc --compiler gcc --template
	${COV_BUILD} --dir ${COV_INT} $SC_BASE_CMD -p ${board} --log-file sanity-${board}.log
	mv sanity-out sanity.out.trash/${board}
}

function build_cross() {

	ARCHES="x86 arm arc riscv32 xtensa nios2"

	for ARCH in ${ARCHES};  do
		# First we collect test cases with platforms that provide full
		# coverage on kernel tests
		if [ $ARCH = "x86" ]; then
			COMPILER=i586-zephyr-elf-gcc
			$SC_BASE_CMD -p qemu_x86 -t kernel --save-tests tests_001.txt
		elif [ $ARCH = "arm" ]; then
			COMPILER=arm-zephyr-eabi-gcc
			$SC_BASE_CMD -p frdm_k64f -t kernel --save-tests tests_001.txt
		else
			COMPILER=${ARCH}-zephyr-elf-gcc
			$SC_BASE_CMD -a ${ARCH} -t kernel --save-tests tests_001.txt
		fi
		# Then we lists all tests on all remaining platform excluding
		# kernel tests.
		$SC_BASE_CMD -a ${ARCH} --all -e kernel --save-tests tests_002.txt
		# Here we create the final test manifest
		head -n 1 tests_002.txt > tests.txt
		tail -q -n +2 tests_0*.txt | sort | uniq >> tests.txt
		rm -f tests_0*.txt


		${COV_CONF} --comptype gcc --compiler ${COMPILER} --template
		${COV_BUILD} --dir ${COV_INT} $SC_BASE_CMD --load-tests tests.txt -a ${ARCH} --log-file sanity-${ARCH}.log
		rm -f tests.txt
		mv sanity-out sanity-out.1.$ARCH
	done
}

build_with_host_compiler qemu_x86_64
build_with_host_compiler native_posix
build_cross


${COV_ANALYZE} --tu-pattern "! file('.*/samples/.*') && ! file('.*\.cpp') && ! file('.*/tests/.*') && ! file('autoconf.h') && ! file('.*/drivers/*/') && ! file('.*/lib/libc/.*') && ! file('.*/lib/crc/.*') && ! file('.*/subsys/[fb|fs|app_memory|fs|blueooth|console|cpp|debug|dfu|disk|fb|fs|mgmt|net|power|random|settings|shell|stats|storage|usb]/.*')" --dir ${COV_INT} --all


${COV_FORMAT_ERRORS} --dir ${COV_INT} --json-output-v6 $WORKSPACE/errors.json   

unset {http,https}_proxy
unset {HTTP,HTTPS}_PROXY

${COV_COMMIT_DEFECTS} --dir ${COV_INT} --host cov.ostc.intel.com --auth-key-file $USERPASS --stream zephyr-1.14-branch-intel-stream


echo "Done."

