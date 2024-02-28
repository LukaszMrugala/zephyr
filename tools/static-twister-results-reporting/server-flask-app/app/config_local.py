# Settings for local environment

# *****************************
# Environment specific settings
# *****************************

# DO NOT use "DEBUG = True" in production environments
DEBUG = False

# Paths settings
## Only for server version. Path to all branches.
DATA_PATH = r'/path-to-directory-with-branches'
## For desktop version. Path to the twister-out directory.
## Example: /home/user/zephyrproject/twister-out.1
TWISTER_OUT_PATH = r'/home/user/zephyrproject/twister-out.1'

# Branch settings
## branch dictionary for matching branch name to his directory name
## for server version
## { 'branch name': 'branch_dir_name' }
BRANCH_DICT = {"main-intel": "master", "main": "upstream"}
