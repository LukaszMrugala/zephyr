#!/usr/bin/python

import pandas as pd
import os, json
from datetime import datetime
from .common import DirectoryParser
from app.config_local import *
from app.config import *

date_format = DATE_FORMAT

class Platform_Report:
    data_path = DATA_PATH
    branch_dict = BRANCH_DICT
    tests_report = TESTS_RESULT_FILE

    test_failed = pd.DataFrame()
    environment = None
    tests_result = dict

    date_runs = []
    platforms = {}

    run_date = None
    branch_name = None
    platform = None

    def __init__(self, branch=None, run=None, platform=None):
        if branch in self.branch_dict:
            branch_dir = self.branch_dict[branch]
            self.branch_name = branch
        else:
            branch_dir = list(self.branch_dict.values())[0]
            self.branch_name = list(self.branch_dict.keys())[0]

        self.branch_path = os.path.join(self.data_path, branch_dir)

        self.date_runs = DirectoryParser.parse_runs_dir(self.branch_path, self.tests_report)

        # searching run date on run date list
        run = [ item for item in self.date_runs if item["date"] == run ]

        if run:
            run_dir = run[0]['path']
            self.run_date = run[0]['date']
        else:
            run_dir = self.date_runs[0]['path']
            self.run_date = self.date_runs[0]['date']

        self.run_path = os.path.join(self.branch_path, run_dir)

        self.platforms = DirectoryParser.read_platforms(self.run_path)

        platform = [key for key in self.platforms.items() if key[0] == platform]

        self.platform = platform[0][0] if platform else next(iter(self.platforms))

        self.platform_path = os.path.join(self.run_path, self.platforms[self.platform])


    def get_data(self):
        prefix = TESTCASE_PREFIX
        data_path = os.path.join(self.platform_path, self.tests_report)

        try:
            with open(data_path, "r") as read_file:
                data = json.load(read_file)

                self.environment = data['environment']
                date_obj = datetime.strptime(self.environment['run_date'], r"%Y-%m-%dT%H:%M:%S%z")
                self.environment['run_date'] = date_obj.strftime(date_format)
                date_obj = datetime.strptime(self.environment['commit_date'], r"%Y-%m-%dT%H:%M:%S%z")
                self.environment['commit_date'] = date_obj.strftime(date_format)

                test_suites_df = pd.json_normalize(data["testsuites"], record_path=['testcases'], record_prefix=prefix
                                               , meta=['name', 'arch', 'platform', 'run_id', 'runnable', 'status', 'execution_time'])

                test_suites_df = test_suites_df.drop(test_suites_df[test_suites_df['runnable'] == False].index)
                test_suites_df = test_suites_df[test_suites_df['platform'] == self.platform]

                # add arch value to environment
                self.environment['arch'] = test_suites_df['arch'].iloc[0]

                # reorder columns
                test_suites_df = test_suites_df[['name', 'testcases_identifier', 'run_id', 'testcases_status', 'testcases_reason'
                                                , 'execution_time', 'status']]

                test_summary = test_suites_df[['run_id', prefix+"status"]].groupby(prefix+"status").count()

                tests_result = dict(test_summary['run_id'])

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

        except FileNotFoundError:
            print("File %s doesn't exist", data_path)
        except LookupError:
            print("File %s is not a valid twister.json format ", data_path)


class Daily_Platforms_Report:
    data_path = DATA_PATH
    data_source = TESTS_RESULT_FILE
    branch_dict = BRANCH_DICT
    days_of_report = APP_SHOW_NDAYS

    data_for_www = pd.DataFrame()

    date_runs = []
    platforms = {}
    environment = []
    run_date = None
    branch_name = None

    def __init__(self, branch:str=None, run:str=None):
        if branch in self.branch_dict:
            branch_dir = self.branch_dict[branch]
            self.branch_name = branch
        else:
            branch_dir = list(self.branch_dict.values())[0]
            self.branch_name = list(self.branch_dict.keys())[0]

        platform_data = {}

        try: 
            self.branch_path = os.path.join(self.data_path, branch_dir)

            self.date_runs = DirectoryParser.parse_runs_dir(self.branch_path, self.data_source)

            # searching run date on run date list
            run = [ item for item in self.date_runs if item["date"] == run ]

            if run:
                run_dir = run[0]['path']
                self.run_date = run[0]['date']
            else:
                run_dir = self.date_runs[0]['path']
                self.run_date = self.date_runs[0]['date']

            self.run_path =  os.path.join(self.branch_path, run_dir)

            self.platforms = DirectoryParser.read_platforms(self.run_path)

            results_df = pd.DataFrame(data=None, index=None, columns=['platform', 'pass_rate', 'test_cases', 'passed', 'failed', 'error'
                                                 , 'blocked', 'skipped', 'path'])

            for platform in self.platforms:
                dir_name = self.platforms[platform]
                platform_path = os.path.join(self.run_path, dir_name, self.data_source)

                if os.path.exists(platform_path):
                    platform_data = self.get_data(platform_path, platform)

                    platform_dict = {"platform": platform, "path": dir_name}
                    for item in platform_data['test_results'].values():
                        platform_dict.update(item)

                    results_df.loc[len(results_df.index)] = platform_dict

            results_df.set_index('platform')

            self.environment = platform_data['environment']
            self.data_for_www = results_df

        except LookupError:
            print("File %s is not a valid twister.json format ", self.run_path)

    def get_data(self, data_path: str, platform: str):
        prefix = TESTCASE_PREFIX
        data_ret = {}

        try:
            with open(data_path, "r") as read_file:
                data = json.load(read_file)

                test_suites_df = pd.json_normalize(data["testsuites"], record_path=['testcases'], record_prefix=prefix
                                               , meta=['name', 'platform', 'runnable', 'run_id', 'retries', 'status', 'execution_time'])

                test_suites_df = test_suites_df.drop(test_suites_df[test_suites_df['runnable'] == False].index)
                test_suites_df = test_suites_df[test_suites_df['platform'] == platform]

                df_sum = pd.DataFrame(test_suites_df, columns=['platform', f'{prefix}status'])
                test_summary = df_sum.groupby(['platform', f'{prefix}status']).size().unstack().fillna(0)

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
                test_summary = test_summary[['platform', 'pass_rate', 'test_cases', 'passed', 'failed', 'error', 'blocked', 'skipped']]

                data_ret['test_results'] = test_summary.to_dict('index')
                data_ret['environment'] = data['environment']

                date_obj = datetime.strptime(data_ret['environment']['run_date'], r"%Y-%m-%dT%H:%M:%S%z")
                data_ret['environment']['run_date'] = date_obj.strftime(date_format)
                date_obj = datetime.strptime(data_ret['environment']['commit_date'], r"%Y-%m-%dT%H:%M:%S%z")
                data_ret['environment']['commit_date'] = date_obj.strftime(date_format)

            return data_ret

        except FileNotFoundError:
            print("File %s doesn't exist", data_path)
        except LookupError:
            print("File %s is not a valid twister.json format ", data_path)
