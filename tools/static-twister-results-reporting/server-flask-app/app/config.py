# Settings common for all environments

# Application settings
APP_NAME = "FMOS - Static Reports for Twister logs"
APP_SYSTEM_ERROR_SUBJECT_LINE = APP_NAME + " system error"

# Pareser settings
TESTCASE_PREFIX = 'testcases_'
APP_SHOW_NDAYS = 14
DATE_FORMAT_LONG = f'%m/%d/%Y %H:%M:%S'
DATE_FORMAT_SHORT = f'%Y-%m-%d'
DATE_FORMAT_TWISTER = f'%Y-%m-%dT%H:%M:%S%z'

# Default settings
DEFAULT_DATA_PATH = 'twister-out'
TESTS_RESULT_FILE = 'twister.json'
COVERAGE_FILE = 'code_coverage.json'
