/*********************************************************
usbgpio_ftdi.c - FTDI USB-GPIO Application
  requires a genunine FT232R cable, tested with 3-wire "-RPI" version
  adapted from: https://hackaday.com/2009/09/22/introduction-to-ftdi-bitbang-mode/
**********************************************************/

#include <stdio.h>
#include <ftdi.h>
#include <string.h>

#define CHAR_BUF_SZ 128

#define GPIO_TX 0x01  //orange wire
#define GPIO_RX 0x02  //yellow wire, not used here

//USB vendor & product IDs that we search for
#define TARGET_VID 0x0403
#define TARGET_PID 0x6001

//select wire on cable here
unsigned char target_gpio=GPIO_TX;

int main(int argc, char *argv[])
{
	int i;
	int r;
	unsigned char state;
	struct ftdi_context ftdic;
	struct ftdi_device_list *ftdis, *ftdi;
	char strManuf[CHAR_BUF_SZ],strDesc[CHAR_BUF_SZ],strSerial[CHAR_BUF_SZ];
	int target_ftdi_index;

	//check args
	if(argc != 3) {
		printf("\nUsage: ftdi_usbgpio <serial number> <gpio_state> ");
		printf("\n\tWhere:\n\t\t<serial number> FTDI serial-number or 'list' to search.\n\t\t<gpio_state> is 'high' or 'low'.\n\n");
		return 1;
	}

	//validate gpio_state param
	if(strcmp(argv[2],(char*)"low")==0)
		state=0;
	else if(strcmp(argv[2],(char*)"high")==0)
		state=1;
	else {
		printf("\nError with parameter parsing. Can't continue.\n\n");
		return 1;
	}


	printf("\nSearching for connected FTDI devices with USB VID:PID=0x%04x:0x%04x...",TARGET_VID,TARGET_PID);
	ftdi_init(&ftdic);
	target_ftdi_index=-1;

	//validate serial number param against what's connected. If not match, list available cables
	if( (r=ftdi_usb_find_all(&ftdic, &ftdis, TARGET_VID, TARGET_PID)) < 0) {
		printf("\nError searching for connected FTDI devices. Exiting.\n\n");
		return 1;
	}

	if(r==0) {
		printf("\nNo FTDI connected devices found. Exiting.\n\n");
		return 1;
	}

	for(ftdi=ftdis; ftdi!=NULL; i++) {
		if( (r=ftdi_usb_get_strings(&ftdic, ftdi->dev, &strManuf, CHAR_BUF_SZ, strDesc, CHAR_BUF_SZ, strSerial, CHAR_BUF_SZ)) < 0) {
			printf("\nError: Failed getting connected device info. Check libusb permissions or run with sudo. Exiting.\n\n");
			return 1;
		}
		if(strcmp(argv[1],strSerial)==0) {
			printf("\nMATCH: FTDI device %d (%s %s, Serial #: %s)",i,strManuf,strDesc,strSerial);
			target_ftdi_index=i;
		}
		else
			printf("\nSKIPPING: FTDI device %d (%s %s, Serial #: %s)",i,strManuf,strDesc,strSerial);
		ftdi=ftdi->next;
	}
	ftdi_list_free(&ftdis);

	if(target_ftdi_index<0) {
		printf("\nError: No FTDI devices matching serial number found. Exiting.\n\n");
		return 1;
	}

	if(ftdi_usb_open_desc(&ftdic, TARGET_VID, TARGET_PID,NULL,argv[1]) < 0) {
		printf("\nError: Can't open matched FTDI device. Check libusb permissions or run with sudo. Exiting.\n\n");
		return 1;
	}

	//set mode using non-deprecated bitmode func
	ftdi_set_bitmode(&ftdic, GPIO_TX,BITMODE_BITBANG);

	printf("\nSetting GPIO 0x%02x to %d.",target_gpio,state);
	ftdi_write_data(&ftdic, &state, 1);

	ftdi_deinit(&ftdic);

	printf("\nDone!\n\n");
	return 0;
}
