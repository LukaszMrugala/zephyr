#!/usr/bin/python

import pandas as pd
import os, json
from datetime import datetime
from .common import DirectoryParser
from app.config_local import *
from app.config import *

date_format = DATE_FORMAT

class ComponentStatus:
    data_path = DATA_PATH
    branch_dict = BRANCH_DICT
    tests_report = TESTS_RESULT_FILE
    prefix = TESTCASE_PREFIX
    show_last_ndays = APP_SHOW_NDAYS

    ts_component_summary = pd.DataFrame()
    ts_failures = pd.DataFrame()
    tc_component_summary = pd.DataFrame()

    date_runs = []
    platforms = {}
    environment = None
    run_date = None
    branch_name = None

    def __init__(self, branch:str=None, run:str=None):
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

        self.run_path =  os.path.join(self.branch_path, run_dir)

        self.platforms = DirectoryParser.read_platforms(self.run_path)

        self.ts_component_summary = self.get_test_suites_data()
        self.tc_component_summary = self.get_test_cases_data()


    def get_test_cases_data(self):
        component_summary = pd.DataFrame()

        try:
            for platform in self.platforms:
                dir_name = self.platforms[platform]
                data_path = os.path.join(self.run_path, dir_name, self.tests_report)

                if os.path.exists(data_path):

                    data = self.get_data_from_json(data_path)

                    tests_df = pd.json_normalize(data, record_path=['testcases'], record_prefix=self.prefix, meta=['run_id', 'component', 'sub_comp'])
                    tests_df = pd.DataFrame(tests_df, columns=['run_id', 'component', 'sub_comp', f'{self.prefix}status'])

                    tests_df.set_index(['component', 'sub_comp'], inplace = True)
                    test_cases_count = tests_df.groupby(['component', 'sub_comp', f'{self.prefix}status']).size().unstack().fillna(0)

                    if test_cases_count.get('passed') is None: test_cases_count['passed'] = test_cases_count.get('passed', 0)
                    if test_cases_count.get('failed') is None: test_cases_count['failed'] = test_cases_count.get('failed', 0)
                    if test_cases_count.get('blocked') is None: test_cases_count['blocked'] = test_cases_count.get('blocked', 0)
                    if test_cases_count.get('error') is None: test_cases_count['error'] = test_cases_count.get('error', 0)
                    if test_cases_count.get('skipped') is None: test_cases_count['skipped'] = test_cases_count.get('skipped', 0)
                    if test_cases_count.get('started') is None: test_cases_count['started'] = test_cases_count.get('started', 0)

                    if component_summary.empty:
                        component_summary = test_cases_count.copy()
                    else:
                        component_summary = component_summary.add(test_cases_count, axis=0, fill_value=0)

            component_summary = component_summary.assign(pass_rate = round(component_summary['passed']/(component_summary['passed'] + component_summary['failed'] 
                                            + component_summary['blocked'] + component_summary['started'] + component_summary['error'])*100, 2))

            component_summary = component_summary.assign(tests_count = (component_summary['passed'] + component_summary['failed'] + component_summary['error']
                                            + component_summary['blocked'] + component_summary['started']))
            
            component_summary = component_summary.assign(uniqe_suites = self.unique_features_suites['name'])

            component_summary = component_summary.astype({'pass_rate': 'float', 'tests_count': 'int32', 'passed': 'int32', 'failed': 'int32'
                                                          , 'error': 'int32', 'blocked': 'int32', 'skipped': 'int32', 'started': 'int32', 'uniqe_suites': 'int32'})

            component_summary.reset_index(inplace=True)

            component_summary = component_summary[['component', 'sub_comp', 'pass_rate', 'uniqe_suites', 'tests_count', 'passed', 'failed', 'error'
                                                   , 'blocked', 'skipped', 'started']]

            return component_summary

        except LookupError:
            print("File %s is not a valid twister.json format ", data_path)

    def get_test_suites_data(self):
        component_summary = pd.DataFrame()
        components_list_df = pd.DataFrame()
        failures_df = pd.DataFrame()

        try:
            dir_name = ''
            for platform in self.platforms:
                if dir_name != self.platforms[platform]:
                    dir_name = self.platforms[platform]
                    data_path = os.path.join(self.run_path, dir_name, self.tests_report)

                    data = self.get_data_from_json(data_path)

                    if os.path.exists(data_path):
                        tests_df = pd.json_normalize(data, meta=['component', 'sub_comp', 'status'])

                        df2 = tests_df[tests_df['status'] == 'failed']
                        if not df2.empty:
                            failures_df = pd.concat([failures_df, df2[['component', 'sub_comp', 'name', 'reason', 'log', 'platform']]])
                        
                        df1 = pd.DataFrame(tests_df, columns=['component', 'sub_comp', 'name'])

                        components_list_df = df1.copy() if components_list_df.empty else pd.concat([components_list_df, df1])

                        # count tests results per component
                        test_cases_df = pd.DataFrame(tests_df, columns=['component', 'sub_comp', 'status'])
                        test_cases_df.set_index(['component', 'sub_comp'], inplace = True)
                        test_cases_count = test_cases_df.groupby(['component', 'sub_comp', 'status']).size().unstack().fillna(0)

                        if test_cases_count.get('passed') is None: test_cases_count['passed'] = test_cases_count.get('passed', 0)
                        if test_cases_count.get('failed') is None: test_cases_count['failed'] = test_cases_count.get('failed', 0)
                        if test_cases_count.get('error') is None: test_cases_count['error'] = test_cases_count.get('error', 0)
                        if test_cases_count.get('skipped') is None: test_cases_count['skipped'] = test_cases_count.get('skipped', 0)

                        if component_summary.empty:
                            component_summary = test_cases_count.copy()
                        else:
                            component_summary = component_summary.add(test_cases_count, axis=0, fill_value=0)

            components_list_df = components_list_df.drop_duplicates()
            components_list_df.reset_index(inplace=True)
            components_list_df = components_list_df.groupby(['component', 'sub_comp'])['name'].count().to_frame()
            components_list_df.reset_index(inplace=True)
            components_list_df = components_list_df[['component', 'sub_comp', 'name']]
            components_list_df.set_index(['component', 'sub_comp'], inplace = True)
            self.unique_features_suites = components_list_df

            component_summary = component_summary.assign(pass_rate = round(component_summary['passed']/(component_summary['passed']
                                                            + component_summary['failed'] + component_summary['error'])*100, 2))

            component_summary = component_summary.assign(tests_count = (component_summary['passed'] + component_summary['failed']
                                                            + component_summary['error']))

            component_summary = component_summary.assign(uniqe_suites = components_list_df['name'])


            component_summary = component_summary.astype({'tests_count': 'int32', 'passed': 'int32', 'failed': 'int32', 'error': 'int32'
                                                          , 'skipped': 'int32', 'uniqe_suites': 'int32'})

            component_summary.reset_index(inplace=True)

            component_summary = component_summary[['component', 'sub_comp', 'pass_rate', 'uniqe_suites', 'tests_count', 'passed', 'failed'
                                                   , 'error', 'skipped']]

            self.ts_failures = failures_df.sort_values(by=['component', 'sub_comp'])
            
            return component_summary

        except LookupError:
            print("File %s is not a valid twister.json format "%data_path)


    def get_data_from_json(self, data_path):
        try: 
            with open(data_path, "r") as f:
                data = json.load(f)

                for t in data['testsuites']:
                    if t['runnable']:
                        name = t['name']
                        _grouping = name.split("/")[-1]
                        main_group = _grouping.split(".")[0]
                        sub_group = _grouping.split(".")[1]

                        if self.environment is None:
                            self.environment = data['environment']
                            date_obj = datetime.strptime(self.environment['run_date'], r"%Y-%m-%dT%H:%M:%S%z")
                            self.environment['run_date'] = date_obj.strftime(date_format)
                            date_obj = datetime.strptime(self.environment['commit_date'], r"%Y-%m-%dT%H:%M:%S%z")
                            self.environment['commit_date'] = date_obj.strftime(date_format)

                        # t[index] = main_group if index == 'component' else sub_group
                        t['component'] = main_group
                        t['sub_comp'] = sub_group

                        yield t
        except FileExistsError:
            print("File %s doesn't exist", data_path)
        except LookupError:
            print("File %s is not a valid twister.json format ", data_path)
