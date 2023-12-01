# Settings for local environment

# *****************************
# Environment specific settings
# *****************************

# DO NOT use "DEBUG = True" in production environments
DEBUG = True

# Paths settings

DATA_PATH = r'/media/dskpool/ws-ztest/zephyrproject/daily_report/sumreport'
# { 'branch name': 'branch_dir_name' }
BRANCH_DICT = {"main-intel": "master", "v3.2-branch-intel": "v3_2_intel"}
TESTS_RESULT_FILE = 'twister.json'
COVERAGE_FILE = 'code_coverage.json'
# this file is creating during upload test results from Github and
# includes relation between platform name and directory name with twister.json file
PLATFORM_LIST_FILE = 'platform_list.txt'
