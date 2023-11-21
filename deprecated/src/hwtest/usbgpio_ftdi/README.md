# Simple USB-GPIO using FTDI FT232R Cable

## Summary
This is a simple program that allows a FTDI USB-UART cable to act as 
a general-purpose output (GPO). Simply connect the orange TX wire to
a signal you wish to control & use this application to set the state
from the command-line.

## Supported Cables
Developed & tested soley with FTDI part-number TTL-232R-RPi.
Any FTDI cable based on the FT232R ASIC should function though.

## Prerequisites
libftdi development libraries are required to build/run. Naming
for this component varies across distros:

**Fedora:** sudo dnf install libftdi-devel

**Ubuntu:** sudo apt-get install libftdi1 libftdi1-dev libftdi-dev

**ClearLinux:** sudo swupd bundle-add maker-basic

## Note on voltage levels (IMPORTANT)
FTDI USB-UART cables are available in different I/O voltage levels. Most
are 3.3V output but 5V cables are also common in the wild. 5V applied to 
a 3.3V I/O input on a microcontroller (even briefly) may cause damage. 
Check the output of your cable BEFORE connecting to a device.

## Usage 
**Step 1:** Connect the TX signal (orange wire) to the input signal.

**Step 2:** Connect the GND wire (black) to common ground, this is required.

**Step 3:** Run the usbgpio_ftdi application to set the output:
	sudo usbgpio_ftdi high # set TX output high
		- OR -
	sudo usbgpio_ftdi low  # set TX output low

**NOTE:** sudo is required unless the running user has libusb permissions.
It is possible to setup udev to allow libusb access from users but this is 
outside the scope of this doc.

## Timing
On ClearLinux, pulse-widths of 2mS are possible.

## Configuration
No run-time configuration is supported but the USB VID/PID & GPO output
can be customized in the source & rebuilt for custom applications.	

## Compilation
gcc -o usbgpio_ftdi -Wall usbgpio_ftdi.c $(pkg-config --cflags --libs libftdi1)

## References
https://www.ftdichip.com/Support/Documents/DataSheets/Cables/DS_TTL-232R_RPi.pdf

https://hackaday.com/2009/09/22/introduction-to-ftdi-bitbang-mode/

