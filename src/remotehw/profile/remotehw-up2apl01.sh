# remoteHW implementation for Up2 (upsquared) APL E3940 #1
#  a PXE boot target with SSH 

_name=up2-apl01
_host=zephyrtest-blue.jf.intel.com
_pwrsw=pwrswitch-orange.testnet/outlet?8

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

EOF
