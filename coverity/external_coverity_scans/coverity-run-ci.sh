#!/bin/bash

# run this script in a zephyr tree. It will generate a file named coverity.tgz
# that you will need to upload to coverity server.

if [ -d "zephyrproject" ]; then rm -rf zephyrproject; fi
if [ -d "cov-build-external" ]; then rm -rf cov-build-external; fi
mkdir cov-build-external
west init zephyrproject
cd zephyrproject
west update
cd zephyr

COV_BIN=$WORKSPACE/cov-analysis-linux64-2019.03/bin

COV_BUILD_DIR=$WORKSPACE/cov-build-external
COV_INT=${COV_BUILD_DIR}/cov-int
SAN_OPT=" -b -N -j96"
COV_CONF=${COV_BIN}/cov-configure
COV_BUILD=${COV_BIN}/cov-build

mkdir -p sanity.out.trash
rm -rf ${COV_INT}
export USE_CCACHE=0

source zephyr-env.sh
export ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-0.10.3
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
#export PATH=$PATH:$COV_BIN


# Build for native_posix/x86_64 with host compiler

function build_with_host_compiler() {
	board=$1
	${COV_CONF} --comptype gcc --compiler gcc --template
	${COV_BUILD} --dir ${COV_INT} sanitycheck -x=USE_CCACHE=0 -p ${board} ${SAN_OPT} --log-file sanity-${board}.log
	mv sanity-out sanity.out.trash/${board}
}

function build_cross() {

	ARCHES="x86 arm arc riscv32 xtensa nios2"

	for ARCH in ${ARCHES};  do
		# First we collect test cases with platforms that provide full
		# coverage on kernel tests
		if [ $ARCH = "x86" ]; then
			COMPILER=i586-zephyr-elf-gcc
			sanitycheck -b -N -j96 -p qemu_x86 -t kernel --save-tests tests_001.txt
		elif [ $ARCH = "arm" ]; then
			COMPILER=arm-zephyr-eabi-gcc
			sanitycheck -b -N -j96 -p frdm_k64f -t kernel --save-tests tests_001.txt
		else
			COMPILER=${ARCH}-zephyr-elf-gcc
			sanitycheck -b -N -j96 -a ${ARCH} -t kernel --save-tests tests_001.txt
		fi
		# Then we lists all tests on all remaining platform excluding
		# kernel tests.
		sanitycheck -b -N -j96 -a ${ARCH} --all -e kernel --save-tests tests_002.txt
		# Here we create the final test manifest
                head -n 1 tests_002.txt > tests.txt
		tail -q -n +2 tests_0*.txt | sort | uniq >> tests.txt
		rm -f tests_0*.txt


		${COV_CONF} --comptype gcc --compiler ${COMPILER} --template
		${COV_BUILD} --dir ${COV_INT} sanitycheck -N -j96 --load-tests tests.txt -a ${ARCH} -b --log-file sanity-${ARCH}.log
		rm -f tests.txt
		mv sanity-out sanity-out.1.$ARCH
	done
}

build_with_host_compiler qemu_x86_64
build_with_host_compiler native_posix
build_cross


VERSION=$(git describe)

cd ${COV_BUILD_DIR}
tar -czvf coverity-${VERSION}.tgz cov-int

echo "Done. Please submit the archive to Coverity Scan now."

