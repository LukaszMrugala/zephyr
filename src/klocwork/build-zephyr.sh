unset CROSS_COMPILE

PROJECT_NAME="kw-zephyr-poc"
BOARD="up_squared"
EXAMPLE="samples/hello_world"
ZEPHYR_FOLDER="zephyr"

cd $PROJECT_NAME

rm -rf $ZEPHYR_FOLDER
git clone https://github.com/intel-innersource/os.rtos.zephyr.zephyr.git $ZEPHYR_FOLDER
cd $ZEPHYR_FOLDER

west init -l
west update

rm -rf build
west build -b $BOARD $EXAMPLE
