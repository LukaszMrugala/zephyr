#!/usr/bin/python

import pandas as pd
from .common import DirectoryParser
from app.config_local import *
from app.config import *


class ComponentStatus:
    ts_component_summary = pd.DataFrame()
    ts_failures = pd.DataFrame()
    tc_component_summary = pd.DataFrame()

    platforms_dict = {}
    environment = None
    branch_name = None
    branch_dict = BRANCH_DICT

    def __init__(self, branch:str=None, run:str=None):
        self.failures_df = pd.DataFrame()

        source_data = DirectoryParser(branch, run)

        self.date_runs = source_data.date_runs
        self.branch_name = source_data.branch
        self.run_path = source_data.run_path
        self.run_date = source_data.run_date
        self.environment = source_data.environment

        data = source_data.get_data()

        self.ts_component_summary = self.get_test_suites_data(data)
        self.tc_component_summary = self.get_test_cases_data(data)


    def get_test_cases_data(self, data):
        component_summary = pd.DataFrame()
        components_list_df = pd.DataFrame()
        failures_df = pd.DataFrame(columns=['component', 'sub_comp', f'{TESTCASE_PREFIX}identifier', f'{TESTCASE_PREFIX}reason'
                                                           , f'{TESTCASE_PREFIX}log', 'platform', f'{TESTCASE_PREFIX}status'])

        try:
            tests_df = pd.json_normalize(data, record_path=['testcases'], record_prefix=TESTCASE_PREFIX, meta=['run_id', 'component', 'sub_comp', 'platform'])

            # get failures of test case from data
            # get test case with status equal `failed` or `None`
            # df2 = tests_df[(tests_df[f'{TESTCASE_PREFIX}status'] == 'failed') | (tests_df[f'{TESTCASE_PREFIX}status'].isna())]
            # if not df2.empty:
            #     failures_df = pd.concat([failures_df, df2[['component', 'sub_comp', f'{TESTCASE_PREFIX}identifier', f'{TESTCASE_PREFIX}reason'
            #                                                , f'{TESTCASE_PREFIX}log', 'platform', f'{TESTCASE_PREFIX}status']]], ignore_index=True)

            df2 = tests_df[(tests_df[f'{TESTCASE_PREFIX}status'] == 'failed') | (tests_df[f'{TESTCASE_PREFIX}status'].isna())]

            failures_df = pd.concat([failures_df, df2])

            df1 = pd.DataFrame(tests_df, columns=['component', 'sub_comp', f'{TESTCASE_PREFIX}identifier'])
            components_list_df = df1.copy() if components_list_df.empty else pd.concat([components_list_df, df1])

            tests_df = pd.DataFrame(tests_df, columns=['run_id', 'component', 'sub_comp', f'{TESTCASE_PREFIX}status'])
            tests_df.set_index(['component', 'sub_comp'], inplace = True)
            test_cases_count = tests_df.groupby(['component', 'sub_comp', f'{TESTCASE_PREFIX}status']).size().unstack().fillna(0)

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

            if not component_summary.empty:
                components_list_df = components_list_df.drop_duplicates()
                components_list_df.reset_index(inplace=True)
                components_list_df = components_list_df.groupby(['component', 'sub_comp'])[f'{TESTCASE_PREFIX}identifier'].count().to_frame()
                components_list_df.reset_index(inplace=True)
                components_list_df = components_list_df[['component', 'sub_comp', f'{TESTCASE_PREFIX}identifier']]
                components_list_df.set_index(['component', 'sub_comp'], inplace = True)
                self.unique_features_cases = components_list_df


                component_summary = component_summary.assign(pass_rate = round(component_summary['passed']/(component_summary['passed'] + component_summary['failed']
                                                + component_summary['blocked'] + component_summary['started'] + component_summary['error'])*100, 2))

                component_summary = component_summary.assign(tests_count = (component_summary['passed'] + component_summary['failed'] + component_summary['error']
                                                + component_summary['blocked'] + component_summary['started']))

                # unique_features_suites is setting in get_test_suites_data()
                component_summary = component_summary.assign(uniqe_suites = self.unique_features_suites['name'])
                component_summary = component_summary.assign(unique_cases = self.unique_features_cases[f'{TESTCASE_PREFIX}identifier'])

                component_summary = component_summary.astype({'pass_rate': 'float', 'tests_count': 'int32', 'passed': 'int32', 'failed': 'int32'
                                                            , 'error': 'int32', 'blocked': 'int32', 'skipped': 'int32', 'started': 'int32'
                                                            , 'uniqe_suites': 'int32', 'unique_cases': 'int32'})

                component_summary.reset_index(inplace=True)

                component_summary = component_summary[['component', 'sub_comp', 'pass_rate', 'uniqe_suites', 'unique_cases', 'tests_count', 'passed', 'failed', 'error'
                                                   , 'blocked', 'skipped', 'started']]

                failures_df = failures_df[['component', 'sub_comp', f'{TESTCASE_PREFIX}identifier', f'{TESTCASE_PREFIX}reason'
                                                        , f'{TESTCASE_PREFIX}log', 'platform', f'{TESTCASE_PREFIX}status']]
                self.tc_failures = failures_df.sort_values(by=['component', 'sub_comp'])

            return component_summary

        except LookupError as error:
            print("%s: %s\n"%(__name__, error))


    def get_test_suites_data(self, data):
        component_summary = pd.DataFrame()
        components_list_df = pd.DataFrame()
        failures_df = pd.DataFrame()

        try:
            tests_df = pd.json_normalize(data, meta=['component', 'sub_comp', 'status'])

            # get failures of test suite from data
            # get test suites with status equal `failed` or `None`
            df2 = tests_df[(tests_df['status'] == 'failed') | (tests_df['status'].isna())]
            if not df2.empty:
                failures_df = pd.concat([failures_df, df2[['component', 'sub_comp', 'name', 'reason', 'log', 'platform', 'status']]])

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

            if not component_summary.empty:
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

                if not failures_df.empty:
                    self.ts_failures = failures_df.sort_values(by=['component', 'sub_comp'])

            return component_summary

        except LookupError as error:
            print("%s: %s\n"%(__name__, error))
