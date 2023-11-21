unset CROSS_COMPILE

PROJECT_NAME="building-zephyr-project"
BOARD="intel_socfpga_agilex_socdk"
EXAMPLE="samples/hello_world"
ZEPHYR_FOLDER="zephyr"

cd $PROJECT_NAME

rm -rf $ZEPHYR_FOLDER
git clone ssh://git@gitlab.devtools.intel.com:29418/psg-opensource/zephyr-socfpga.git $ZEPHYR_FOLDER
cd $ZEPHYR_FOLDER

rm -rf build
west build -b $BOARD $EXAMPLE
