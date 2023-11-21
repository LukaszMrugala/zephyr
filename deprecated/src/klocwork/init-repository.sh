PROJECT_NAME="kw-zephyr-poc"
BOARD="up_squared"
EXAMPLE="samples/hello_world"


if [ -d $PROJECT_NAME ];
then
	echo "BUILD SH WARNING :: Folder $PROJECT_NAME Exists, Not running west init and west update"
	cd $PROJECT_NAME
else
	west init $PROJECT_NAME
	cd $PROJECT_NAME
	west update
fi
