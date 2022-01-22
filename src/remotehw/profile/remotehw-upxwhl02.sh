# remoteHW implementation for Up Xtreme i11 WHL #2
#  a PXE boot target with SSH + virtual USB flash functions

_name=upx-whl02
_host=zephyrtest-blue.jf.intel.com
_pwrsw=pwrswitch-orange.testnet/outlet?4
_usbtta=root@usbtta-gray-01.testnet

# only define commands on machines matching _host var
if [ "$HOSTNAME" != "$_host" ]; then
        return
fi

source /dev/stdin <<EOF

remotehw-${_name}-rsvrst() {
        .remotehw-rsvrst ${_name}
};
export -f remotehw-${_name}-rsvrst;

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

remotehw-${_name}-reset() {
        .remotehw-rsvchk ${_name} .remotehw-reset ${_pwrsw} ${_name} ${_ttydev}
        sleep 3
};
export -f remotehw-${_name}-reset;

remotehw-${_name}-usb-get-p1() {
        .remotehw-usb-get-p1 ${_usbtta} ${_name}
};
export -f remotehw-${_name}-usb-get-p1;

remotehw-${_name}-usb-grub() {
        .remotehw-rsvchk ${_name} .remotehw-usb-grub ${_usbtta} "\$1"
}
export -f remotehw-${_name}-usb-grub

remotehw-${_name}-usb-efi() {
        .remotehw-rsvchk ${_name} .remotehw-usb-efi ${_usbtta} "\$1"
}
export -f remotehw-${_name}-usb-efi

remotehw-${_name}-usb-acrn() {
        .remotehw-rsvchk ${_name} .remotehw-usb-acrn ${_usbtta} "\$1" "\$2" "\$3"
}
export -f remotehw-${_name}-usb-acrn

.remotehw-${_name}-get-tta() {
        .remotehw-get-tta ${_usbtta} "\$1"
}
export -f .remotehw-${_name}-get-tta

EOF
