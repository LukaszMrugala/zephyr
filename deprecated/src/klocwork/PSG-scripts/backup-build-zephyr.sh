PROJECT_NAME="building-zephyr-project"
BOARD="intel_socfpga_agilex_socdk"
EXAMPLE="samples/hello_world"

#if [ -d $PROJECT_NAME ];
#then
#	echo "BUILD SH WARNING :: Folder $PROJECT_NAME Exists, Not running west init and west update"
	cd $PROJECT_NAME
#else
#	west init $PROJECT_NAME
#	cd $PROJECT_NAME
#	west update
#fi

if [ -d "zephyr-socfpga" ]
then
	echo "BUILD SH WARNING :: zephyr-socfpga exist, Not runing git clone from  gitlab"
	cd zephyr
else
	git clone ssh://git@gitlab.devtools.intel.com:29418/psg-opensource/zephyr-socfpga.git
	cd zephyr-socfpga
	git format-patch -8
	mv 0001* 0002* 0003* 0004* 0005* 0006* 0007* ../zephyr
	cd ../zephyr
	git am *.patch
fi

rm -rf build
west build -b $BOARD $EXAMPLE
