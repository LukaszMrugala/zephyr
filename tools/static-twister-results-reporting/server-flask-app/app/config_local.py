# Settings for local environment

# *****************************
# Environment specific settings
# *****************************

# DO NOT use "DEBUG = True" in production environments
DEBUG = False

# Paths settings
## Only for server version. Path to all branches.
DATA_PATH = r'/media/dskpool/ws-ztest/zephyrproject/daily_report/sumreport'
## For standalone version. Path to the twister-out directory.
## Example: /home/zephyr/zephyrproject/
TWISTER_OUT_PATH = r'/home/zephyr/zephyrproject'

# Branch settings
## branch dictionary for matching branch name to his directory name
## for server version
## { 'branch name': 'branch_dir_name' }
BRANCH_DICT = {"main-intel": "master", "v3.2-branch-intel": "v3_2_intel"}
