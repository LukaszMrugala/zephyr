The script does the following:
Checks Whitelist status for Open Source projects listed in a TXT file.

Prints NOK if:
-Project review is to expire within 60 days or,
-Whitelist Status is Expired, Pending or Blacklist.

Prints CHECK if:
-Whitelist Status is Conditional. PSE approval needed!?

Prints OK if:
-Whitelist Status is Whitelist and,
-Project review is not to expire within 60 days.

The script has the following input parameters:
-f : File in TXT format with Open Source projects, as an example see open_source_projects.txt.
-l : Not required. Print only Open Source projects with status NOK or CHECK.

Example:
py check_whitelist_status.py -f "open_source_projects.txt"
Project: acme
Whitelist link: https://whitelisttool.amr.corp.intel.com/view.php?id=3844
Present Whitelist Status: Expired
Previous Whitelist Status: Not found
Number of days until review will expire: 0
Project status: NOK
Comment: None

Project: Boost C++ Libraries
Whitelist link: https://whitelisttool.amr.corp.intel.com/view.php?id=11896
Present Whitelist Status: Conditional
Previous Whitelist Status: Whitelist
Number of days until review will expire: 483
Project status: CHECK
Comment: Approved by PSE 2020-07-29

Project: EDG - Edison Design Group C++ and Fortran Front End
Whitelist link: https://whitelisttool.amr.corp.intel.com/view.php?id=11803
Present Whitelist Status: Pending
Previous Whitelist Status: Expired
Number of days until review will expire: 0
Project status: NOK
Comment: None

Project: expat
Whitelist link: https://whitelisttool.amr.corp.intel.com/view.php?id=10669
Present Whitelist Status: Conditional
Previous Whitelist Status: Expired
Number of days until review will expire: 322
Project status: CHECK
Comment: Approved by PSE 2020-09-07

Project: fuse
Whitelist link: https://whitelisttool.amr.corp.intel.com/view.php?id=10675
Present Whitelist Status: Whitelist
Previous Whitelist Status: Expired
Number of days until review will expire: 237
Project status: OK
Comment: None

Project: gcc c++
Whitelist link: https://whitelisttool.amr.corp.intel.com/view.php?id=11109
Present Whitelist Status: Whitelist
Previous Whitelist Status: Expired
Number of days until review will expire: 373
Project status: OK
Comment: None

Project: gcc
Whitelist link: https://whitelisttool.amr.corp.intel.com/view.php?id=10694
Present Whitelist Status: Whitelist
Previous Whitelist Status: Expired
Number of days until review will expire: 307
Project status: OK
Comment: None

Project: gdb
Whitelist link: https://whitelisttool.amr.corp.intel.com/view.php?id=10974
Present Whitelist Status: Whitelist
Previous Whitelist Status: Expired
Number of days until review will expire: 373
Project status: OK
Comment: None

Project: glibc
Whitelist link: https://whitelisttool.amr.corp.intel.com/view.php?id=10226
Present Whitelist Status: Whitelist
Previous Whitelist Status: Expired
Number of days until review will expire: 188
Project status: OK
Comment: None

Project: intelxed
Whitelist link: https://whitelisttool.amr.corp.intel.com/view.php?id=9666
Present Whitelist Status: Whitelist
Previous Whitelist Status: Expired
Number of days until review will expire: 64
Project status: OK
Comment: None

Project: LAPACK
Whitelist link: https://whitelisttool.amr.corp.intel.com/view.php?id=10668
Present Whitelist Status: Whitelist
Previous Whitelist Status: Expired
Number of days until review will expire: 236
Project status: OK
Comment: None

Project: libelf
Whitelist link: https://whitelisttool.amr.corp.intel.com/view.php?id=11342
Present Whitelist Status: Conditional
Previous Whitelist Status: Expired
Number of days until review will expire: 405
Project status: CHECK
Comment: Approved by PSE 2020-04-30

Project: libiconv
Whitelist link: https://whitelisttool.amr.corp.intel.com/view.php?id=11213
Present Whitelist Status: Whitelist
Previous Whitelist Status: Expired
Number of days until review will expire: 373
Project status: OK
Comment: None

Project: libpng
Whitelist link: https://whitelisttool.amr.corp.intel.com/view.php?id=11032
Present Whitelist Status: Whitelist
Previous Whitelist Status: Expired
Number of days until review will expire: 327
Project status: OK
Comment: None

Project: libxml2
Whitelist link: https://whitelisttool.amr.corp.intel.com/view.php?id=11210
Present Whitelist Status: Conditional
Previous Whitelist Status: Expired
Number of days until review will expire: 371
Project status: CHECK
Comment: Approved by PSE 2020-09-07
