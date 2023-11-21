# remoteHW implementation for up-extreme on blue shelf
_usbtta=root@usbtta-blue01.testnet
_pwrsw=pwrswitch-blue.testnet/outlet?1
_name=upx01
_ttydev="115200 /dev/ttyUSB2"
#pl203 w/ blue housing

source /dev/stdin <<EOF

remotehw-${_name}-reserve() {
        .remotehw-reserve ${_name}
};
export -f remotehw-${_name}-reserve;

remotehw-${_name}-release() {
        .remotehw-release ${_name} ${_ttydev}
};
export -f remotehw-${_name}-release;

remotehw-${_name}-power-off() {
	.remotehw-rsvchk ${_name} .remotehw-power-off ${_pwrsw}
};
export -f remotehw-${_name}-power-off;

remotehw-${_name}-power-on() {
	.remotehw-rsvchk ${_name} .remotehw-power-on ${_pwrsw}
};
export -f remotehw-${_name}-power-on;

remotehw-${_name}-power-off() {
	.remotehw-rsvchk ${_name} .remotehw-power-off ${_pwrsw}
};
export -f remotehw-${_name}-power-off;

remotehw-${_name}-get-console() {
	.remotehw-rsvchk ${_name} .remotehw-get-console ${_ttydev}
};
export -f remotehw-${_name}-get-console;

remotehw-${_name}-usb-grub() {
	.remotehw-rsvchk ${_name} .remotehw-usb-grub ${_usbtta} "\$1"
}
export -f remotehw-${_name}-usb-grub

remotehw-${_name}-usb-efi() {
        .remotehw-rsvchk ${_name} .remotehw-usb-efi ${_usbtta} "\$1"
}
export -f remotehw-${_name}-usb-efi

.remotehw-${_name}-get-tta() {
	.remotehw-get-tta ${_usbtta} "\$1"
}
export -f .remotehw-${_name}-get-tta

EOF
