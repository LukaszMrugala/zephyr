# remoteHW implementation for Up Xtreme i11 TGL #1
#  SSD boot target with console but no USB functions

_name=upx-tgl01
_host=zephyrtest-blue.jf.intel.com
_pwrsw=pwrswitch-orange.testnet/outlet?1

# system console at ttyUSB3
_ttydev="115200 /dev/serial/by-path/pci-0000:0b:00.2-usb-0:3.1.4:1.0-port0"

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

remotehw-${_name}-reset() {
        .remotehw-rsvchk ${_name} .remotehw-reset ${_pwrsw} ${_name} ${_ttydev}
        sleep 3
};
export -f remotehw-${_name}-reset;

remotehw-${_name}-get-console() {
	.remotehw-rsvchk ${_name} .remotehw-get-console ${_ttydev}
};
export -f remotehw-${_name}-get-console;

EOF
