# remoteHW implementation for ehl sku 11 on green shelf
_name=ehlsku11
_host=zephyrtest-blue.jf.intel.com
_usbtta=root@usbtta-blue03.testnet
_pwrsw=pwrswitch-blue.testnet/outlet?1
_ttydev="115200 /dev/serial/by-path/pci-0000:0b:00.2-usb-0:2.4:1.0-port0"

# only define commands on machines matching _host var
if [ "$HOSTNAME" != "$_host" ]; then
        return
fi

source /dev/stdin <<EOF

remotehw-${_name}-get-tty() {
        echo "$_ttydev" | awk '{print \$2}'
};
export -f remotehw-${_name}-get-tty;

.remotehw-${_name}-get-baud() {
        echo "$_ttydev" | awk '{print \$1}'
};
export -f .remotehw-${_name}-get-baud;

remotehw-${_name}-usb-get-p1() {
        .remotehw-usb-get-p1 ${_usbtta} ${_name}
};
export -f remotehw-${_name}-usb-get-p1;

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

remotehw-${_name}-usb-acrn() {
        .remotehw-rsvchk ${_name} .remotehw-usb-acrn ${_usbtta} "\$1" "\$2" "\$3"
}
export -f remotehw-${_name}-usb-acrn

remotehw-${_name}-usb-iso() {
        .remotehw-rsvchk ${_name} .remotehw-usb-iso ${_usbtta} "\$1"
}
export -f remotehw-${_name}-usb-iso

.remotehw-${_name}-get-tta() {
	.remotehw-get-tta ${_usbtta} "\$1"
}
export -f .remotehw-${_name}-get-tta

EOF
