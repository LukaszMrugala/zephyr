#!/usr/bin/python

import pandas as pd
import os, json
from datetime import datetime
from .common import DirectoryParser
from app.config_local import *
from app.config import *

class Platform_Report:
    date_runs = []

    def __init__(self, branch=None, run=None, platform=None):
        try:
            self.test_failed = pd.DataFrame()

            source_data = DirectoryParser(branch, run)

            self.date_runs = source_data.date_runs
            self.branch_name = source_data.branch
            self.run_path = source_data.run_path
            self.run_date = source_data.run_date
            self.branch_dict = source_data.branch_dict
            platform_keys = list(source_data.platforms.keys())
            platform_keys.sort()
            self.platforms = {i: source_data.platforms[i] for i in platform_keys}
            self.environment = source_data.environment

            platform = [key for key in self.platforms.items() if key[0] == platform]

            self.platform = platform[0][0] if platform else next(iter(self.platforms))

            self.platform_path = os.path.join(self.run_path, self.platforms[self.platform])

        except Exception as err:
            print(f"Unexpected {err=}, {type(err)=}")
            raise


    def get_data(self):
        try:
            prefix = TESTCASE_PREFIX
            data_path = os.path.join(self.platform_path, TESTS_RESULT_FILE)

            with open(data_path, "r") as read_file:
                data = json.load(read_file)

                self.environment = data['environment']
                self.environment['run_date'] = datetime.strptime(self.environment['run_date'], DATE_FORMAT_TWISTER).strftime(DATE_FORMAT_LONG)
                self.environment['commit_date'] = datetime.strptime(self.environment['commit_date'], DATE_FORMAT_TWISTER).strftime(DATE_FORMAT_LONG)

                test_suites_df = pd.json_normalize(data["testsuites"], record_path=['testcases'], record_prefix=prefix
                                               , meta=['name', 'arch', 'platform', 'runnable', 'status', 'reason', 'log', 'execution_time']
                                               , errors='ignore')

                test_suites_df = test_suites_df.drop(test_suites_df[test_suites_df['runnable'] == False].index)
                test_suites_df = test_suites_df[test_suites_df['platform'] == self.platform]

                # add arch value to environment
                self.environment['arch'] = test_suites_df['arch'].iloc[0]

                # reorder columns
                test_suites_df = test_suites_df[['name', 'testcases_identifier', 'testcases_status', 'testcases_reason'
                                                , 'execution_time', 'status', 'reason', 'log']]

                test_summary = test_suites_df[['name', prefix+"status"]].groupby(prefix+"status").count()

                tests_result = dict(test_summary['name'])

                tests_result['test_cases'] = test_suites_df[['testcases_identifier']].count().values[0]

                if tests_result.get("passed") is None: tests_result["passed"] = 0
                if tests_result.get('failed') is None: tests_result['failed'] = 0
                if tests_result.get('blocked') is None: tests_result['blocked'] = 0
                if tests_result.get('error') is None: tests_result['error'] = 0
                if tests_result.get('skipped') is None: tests_result['skipped'] = 0

                tests_result['pass_rate'] = 0 if tests_result['passed'] == 0 else round(tests_result['passed'] / (tests_result['passed'] +
                                                                                        tests_result['failed'] + tests_result['blocked'])*100, 2)

                status = ['failed', 'blocked']

                self.test_failed = test_suites_df[test_suites_df[prefix+'status'].isin(status)].sort_values('name')
                self.tests_result = tests_result
                # ['name', 'testcases_identifier', 'run_id', 'testcases_status', 'testcases_reason', 'execution_time', 'status']

        except FileNotFoundError:
            print("%s: File %s doesn't exist"%(__name__, data_path))
        except LookupError:
            print("%s: File %s is not a valid twister.json format "%(__name__, data_path))
        except Exception as err:
            print(f"Unexpected {err=}, {type(err)=}")
            raise


class Daily_Platforms_Report:
    date_runs = []

    def __init__(self, branch:str=None, run:str=None):
        self.data_for_www = pd.DataFrame()

        try:
            self.failures_df = pd.DataFrame()

            source_data = DirectoryParser(branch, run)

            self.date_runs = source_data.date_runs
            self.branch_name = source_data.branch
            self.run_path = source_data.run_path
            self.run_date = source_data.run_date
            self.branch_dict = source_data.branch_dict
            self.environment = source_data.environment

            data = source_data.get_data()

            # ['name', 'arch', 'platform', 'path', 'run_id', 'runnable', 'retries', 'status', 'execution_time', 'build_time', 'testcases', 'component', 'sub_comp']
            test_suites_df = pd.json_normalize(data, record_path=['testcases'], record_prefix=TESTCASE_PREFIX
                                                , meta=['name', 'platform', 'runnable', 'run_id', 'retries', 'status', 'reason', 'log'
                                                , 'execution_time', 'component', 'sub_comp']
                                                , errors='ignore')


            try:
                test_suites_df = test_suites_df.drop(test_suites_df[test_suites_df['runnable'] == False].index)

                df2 = test_suites_df[test_suites_df['testcases_status'].isin(['failed'])]
                if not df2.empty:
                    self.failures_df = pd.concat([self.failures_df, df2[['platform', 'name', 'testcases_identifier', 'reason', 'log', 'testcases_status']]])

                df_sum = pd.DataFrame(test_suites_df, columns=['platform', f'{TESTCASE_PREFIX}status'])

                test_summary = df_sum.groupby(['platform', f'{TESTCASE_PREFIX}status']).size().unstack().fillna(0)

                if test_summary.get('passed') is None: test_summary['passed'] = test_summary.get('passed', 0)
                if test_summary.get('failed') is None: test_summary['failed'] = test_summary.get('failed', 0)
                if test_summary.get('blocked') is None: test_summary['blocked'] = test_summary.get('blocked', 0)
                if test_summary.get('error') is None: test_summary['error'] = test_summary.get('error', 0)
                if test_summary.get('skipped') is None: test_summary['skipped'] = test_summary.get('skipped', 0)

                test_summary = test_summary.assign(test_cases =
                    (test_summary['passed'] + test_summary['failed'] + test_summary['blocked'] + test_summary['error']))
                test_summary = test_summary.assign(pass_rate = round(test_summary['passed'] /
                                                                        (test_summary['passed'] + test_summary['failed'] + test_summary['blocked'])*100, 2))

                test_summary = test_summary.astype({'pass_rate': 'float', 'test_cases': 'int', 'passed': 'int'
                                                    , 'failed': 'int', 'error': 'int', 'blocked': 'int', 'skipped': 'int'})

                test_summary['platform'] = test_summary.index
                self.data_for_www = test_summary[['platform', 'pass_rate', 'test_cases', 'passed', 'failed', 'error', 'blocked', 'skipped']]

                if not self.failures_df.empty:
                    self.ts_failures = self.failures_df.sort_values(by=['platform', 'name', 'testcases_identifier'])

            except LookupError:
                print("%s: File %s is not a valid twister.json format "%(__name__, self.run_path))

        except Exception as err:
            print(f"Unexpected {err=}, {type(err)=}")
            raise