# remoteHW implementation for TGLRVP Chrome on blue shelf
# setup:
#  connect "debug micro usb" to USB port on shelf
#  has two ttyUSBx functions, the first appears to be the main console
_name=tglchr01
_host=DISABLED  #was on zephyrtest-blue.jf.intel.com
_pwrsw=pwrswitch-blue.testnet/outlet?2
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

remotehw-${_name}-power-off() {
	.remotehw-rsvchk ${_name} .remotehw-power-off ${_pwrsw}
};
export -f remotehw-${_name}-power-off;

remotehw-${_name}-get-console() {
	.remotehw-rsvchk ${_name} .remotehw-get-console ${_ttydev}
};
export -f remotehw-${_name}-get-console;

EOF
