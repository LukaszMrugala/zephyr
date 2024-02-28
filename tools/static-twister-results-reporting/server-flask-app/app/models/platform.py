#!/usr/bin/python

import pandas as pd
import os, json
from datetime import datetime
from .common import DirectoryParser
from app.config_local import *
from app.config import *

# Returning a view versus a copy
# https://pandas.pydata.org/pandas-docs/stable/user_guide/indexing.html#returning-a-view-versus-a-copy
pd.options.mode.copy_on_write = True

class Platform_Report:
    date_runs = []
    show_download_btn = False

    def __init__(self, branch=None, run=None, platform=None):
        try:
            self.test_failed = pd.DataFrame()

            source_data = DirectoryParser(branch, run)

            self.server_mode = source_data.server_mode
            self.date_runs = source_data.date_runs
            self.branch_name = source_data.branch
            self.run_path = source_data.run_path
            self.run_date = source_data.run_date
            self.branch_dict = source_data.branch_dict
            platform_keys = list(source_data.platforms.keys())
            platform_keys.sort()
            self.platforms = {i: source_data.platforms[i] for i in platform_keys}
            self.environment = source_data.environment
            self.was_commit = source_data.was_commit

            platform = [key for key in self.platforms.items() if key[0] == platform]

            self.platform = platform[0][0] if platform else next(iter(self.platforms))

        except Exception as err:
            print(f"Unexpected {err=}, {type(err)=}")
            raise


    def get_data(self):
        try:
            prefix = TESTCASE_PREFIX

            for platform_path in self.platforms[self.platform]:

                # self.platform_path = self.run_path if self.run_path == self.platforms[self.platform] else os.path.join(self.run_path, self.platforms[self.platform])

                data_path = os.path.join(platform_path, TESTS_RESULT_FILE)

                with open(data_path, "r") as read_file:
                    data = json.load(read_file)

                    self.environment = data['environment']
                    self.environment['run_date'] = datetime.strptime(self.environment['run_date'], DATE_FORMAT_TWISTER).strftime(DATE_FORMAT_LONG)
                    self.environment['commit_date'] = datetime.strptime(self.environment['commit_date'], DATE_FORMAT_TWISTER).strftime(DATE_FORMAT_LONG)

                    df = pd.json_normalize(data["testsuites"], record_path=['testcases'], record_prefix=prefix
                                                , meta=['name', 'arch', 'platform', 'runnable', 'status', 'reason', 'log', 'execution_time', 'dut']
                                                , errors='ignore')

                    # remove not runnable test suites and filter by current platform
                    df = df.drop(df[df['runnable'] == False].index)
                    df = df[df['platform'] == self.platform]

                    # add arch value to environment
                    self.environment['arch'] = df['arch'].iloc[0]

                    test_suites_df = pd.DataFrame(df, columns=['name', 'testcases_identifier', 'testcases_status', 'testcases_reason'
                                                    , 'execution_time', 'status', 'reason', 'log', 'dut'])

                    test_summary = test_suites_df[['name', prefix+"status"]].groupby(prefix+"status").count()

                    tests_result = dict(test_summary['name'])

                    # tests_result['test_cases'] = test_suites_df[['testcases_identifier']].count().values[0]

                    if tests_result.get("passed") is None: tests_result["passed"] = 0
                    if tests_result.get('failed') is None: tests_result['failed'] = 0
                    if tests_result.get('blocked') is None: tests_result['blocked'] = 0
                    if tests_result.get('error') is None: tests_result['error'] = 0
                    if tests_result.get('skipped') is None: tests_result['skipped'] = 0

                    tests_result['test_cases'] = tests_result['passed'] + tests_result['failed'] + tests_result['blocked'] + tests_result['error']

                    tests_result['pass_rate'] = 0 if tests_result['passed'] == 0 else round(tests_result['passed'] / (tests_result['passed']
                                                                                        + tests_result['failed'] + tests_result['blocked']) * 100, 2)

                    status = ['failed', 'blocked']

                    self.test_failed = test_suites_df[test_suites_df[prefix+'status'].isin(status)].sort_values('name')
                    self.tests_result = tests_result
                    # ['name', 'testcases_identifier', 'run_id', 'testcases_status', 'testcases_reason', 'execution_time', 'status']

        except FileNotFoundError:
            print("%s: File %s doesn't exist"%(__name__, data_path))
        except LookupError:
            print("%s: File %s is not a valid %s format "%(__name__, data_path, TESTS_RESULT_FILE))
        except Exception as err:
            print(f"Unexpected {err=}, {type(err)=}")
            raise


class Daily_Platforms_Report:
    date_runs = []
    show_download_btn = False

    def __init__(self, branch:str=None, run:str=None):
        self.tc_summary = pd.DataFrame()

        try:
            self.ts_fails_df = pd.DataFrame()
            self.tc_fails_df = pd.DataFrame()

            self.ts_failures = pd.DataFrame()
            self.tc_failures = pd.DataFrame()

            source_data = DirectoryParser(branch, run)

            self.server_mode = source_data.server_mode
            self.date_runs = source_data.date_runs
            self.branch_name = source_data.branch
            self.run_path = source_data.run_path
            self.run_date = source_data.run_date
            self.branch_dict = source_data.branch_dict
            self.environment = source_data.environment
            self.was_commit = source_data.was_commit

            data = source_data.get_data()

            # ['name', 'arch', 'platform', 'path', 'run_id', 'runnable', 'retries', 'status', 'execution_time', 'build_time', 'testcases', 'component', 'sub_comp']
            tests_df = pd.json_normalize(data, record_path=['testcases'], record_prefix=TESTCASE_PREFIX
                                                , meta=['name', 'platform', 'runnable', 'run_id', 'retries', 'status', 'reason', 'log'
                                                , 'execution_time', 'component', 'sub_comp']
                                                , errors='ignore')

            try:
                self.tests_df = tests_df.drop(tests_df[tests_df['runnable'] == False].index)

                self.preparing_data_for_dt('suite')
                self.preparing_data_for_dt('case')

            except LookupError:
                print("%s: File %s is not a valid twister.json format "%(__name__, self.run_path))

        except Exception as err:
            print(f"Unexpected {err=}, {type(err)=}")
            raise

    def preparing_data_for_dt(self, count_by:str='suite'):
        # status test_suit: passed | failed | blocked | skipped
        if count_by == 'suite':
            status = ['failed', 'blocked', 'error']

            # get test cases with status exist in status list only
            df2 = self.tests_df[(self.tests_df['status'].isin(status)) | (self.tests_df['status'].isna())]
            # df2 = self.tests_df[self.tests_df['status'].isin(status)].sort_values('name')

            if not df2.empty:
                failures_df = df2[['platform', 'name', 'reason', 'status']]
                failures_df.sort_values(['platform', 'name', 'status'])
                failures_df.drop_duplicates(['platform', 'name', 'status'], inplace=True, keep='first')

                if not failures_df.empty:
                    self.ts_failures = failures_df.sort_values(by=['platform', 'name'])
                    # pd.set_option("display.max_colwidth", None)

            df2 = self.tests_df[['platform', 'name', 'status']]
            # df2.set_index(['platform', 'name'], inplace=True)
            df2.sort_values(['platform', 'name'])
            df2.drop_duplicates(['name', 'platform'], inplace=True, keep='first')

            df_sum = pd.DataFrame(df2, columns=['platform', f'status'])

            test_summary = df_sum.groupby(['platform', f'status']).size().unstack().fillna(0)

            if test_summary.get('passed') is None: test_summary['passed'] = test_summary.get('passed', 0)
            if test_summary.get('failed') is None: test_summary['failed'] = test_summary.get('failed', 0)
            if test_summary.get('blocked') is None: test_summary['blocked'] = test_summary.get('blocked', 0)
            if test_summary.get('error') is None: test_summary['error'] = test_summary.get('error', 0)
            if test_summary.get('skipped') is None: test_summary['skipped'] = test_summary.get('skipped', 0)

            test_summary = test_summary.assign(test_suites =
                (test_summary['passed'] + test_summary['failed'] + test_summary['blocked'] + test_summary['error']))
            test_summary = test_summary.assign(pass_rate = round(test_summary['passed']/ (test_summary['passed'] + test_summary['failed']
                                                                                          + test_summary['blocked'] + test_summary['error'])*100, 2))

            test_summary = test_summary.astype({'pass_rate': 'float', 'test_suites': 'int', 'passed': 'int'
                                                , 'failed': 'int', 'error': 'int', 'blocked': 'int', 'skipped': 'int'})

            test_summary['platform'] = test_summary.index
            self.ts_summary = test_summary[['platform', 'pass_rate', 'test_suites', 'passed', 'failed', 'error', 'blocked', 'skipped']]

        elif count_by == 'case':
            status = ['failed', 'blocked', 'error']

            # get test cases with status exist in status list only
            df2 = self.tests_df[(self.tests_df['status'].isin(status)) | (self.tests_df['status'].isna())]
            # df2 = self.tests_df[self.tests_df['testcases_status'].isin(status)].sort_values('name')

            if not df2.empty:
                failures_df = pd.concat([self.tc_fails_df, df2[['platform', 'name', 'testcases_identifier', 'reason', 'log', 'testcases_status']]])

                # pd.set_option("max_columns", 2) #Showing only two columns
                # pd.set_option('display.max_rows', None)

                if not failures_df.empty:
                    self.tc_failures = failures_df.sort_values(by=['platform', 'name', 'testcases_identifier'])
                    # pd.set_option("display.max_colwidth", None)

            df_sum = pd.DataFrame(self.tests_df, columns=['platform', f'{TESTCASE_PREFIX}status'])

            test_summary = df_sum.groupby(['platform', f'{TESTCASE_PREFIX}status']).size().unstack().fillna(0)

            if test_summary.get('passed') is None: test_summary['passed'] = test_summary.get('passed', 0)
            if test_summary.get('failed') is None: test_summary['failed'] = test_summary.get('failed', 0)
            if test_summary.get('blocked') is None: test_summary['blocked'] = test_summary.get('blocked', 0)
            if test_summary.get('error') is None: test_summary['error'] = test_summary.get('error', 0)
            if test_summary.get('skipped') is None: test_summary['skipped'] = test_summary.get('skipped', 0)

            test_summary = test_summary.assign(test_cases = (test_summary['passed'] + test_summary['failed']
                                                             + test_summary['blocked'] + test_summary['error']))
            test_summary = test_summary.assign(pass_rate = round(test_summary['passed'] / (test_summary['passed'] + test_summary['failed']
                                                                                           + test_summary['blocked'])*100, 2))

            test_summary = test_summary.astype({'pass_rate': 'float', 'test_cases': 'int', 'passed': 'int'
                                                , 'failed': 'int', 'error': 'int', 'blocked': 'int', 'skipped': 'int'})

            test_summary['platform'] = test_summary.index
            self.tc_summary = test_summary[['platform', 'pass_rate', 'test_cases', 'passed', 'failed', 'error', 'blocked', 'skipped']]
