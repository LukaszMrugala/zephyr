SHELL=/bin/bash

# force release of ehlsku11 at 01:58 PST
58 01 * * * root (. /etc/profile.d/remotehw00-lib.sh; . /etc/profile.d/remotehw-ehlsku11-green.sh; remotehw-ehlsku11-rsvrst) 2>&1 | logger -t remotehw
# reserve ehlsku11 for QA/chenp1 at 01:59 PST
59 01 * * * chenp1 (. /etc/profile.d/remotehw00-lib.sh; . /etc/profile.d/remotehw-ehlsku11-green.sh; remotehw-ehlsku11-reserve) 2>&1 | logger -t remotehw
# force release of ehlsku11 at 09:59 PST
59 09 * * * root (. /etc/profile.d/remotehw00-lib.sh; . /etc/profile.d/remotehw-ehlsku11-green.sh; remotehw-ehlsku11-rsvrst) 2>&1 | logger -t remotehw




