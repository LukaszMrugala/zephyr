#!/usr/bin/python

import os, re, json
from datetime import datetime, timedelta
from app.config import *
from app.config_local import *

class DirectoryParser:
    branch_dict = BRANCH_DICT
    # server_mode is used to hide downloading logs options when we use this app locally
    server_mode = False

    def __init__(self, branch, run_date:str=None):
        run_dir = None
        self.branch = 'n/a'
        self.environment = None
        self.run_date = run_date
        self.was_commit = False
        self.platforms = {}
        self.date_runs = []

        try:
            if os.path.exists(os.path.join(os.path.curdir, DEFAULT_DATA_PATH, TESTS_RESULT_FILE)):
                # load data from <app_dir>/twister-out/twister.json
                self.run_path = os.path.join(os.path.curdir, DEFAULT_DATA_PATH)
                self.branch = 'Source data: %s'%(self.run_path)
                print("Open twister.json from local %s directory: %s"%(DEFAULT_DATA_PATH, self.run_path))

            elif os.path.exists(os.path.join(TWISTER_OUT_PATH, TESTS_RESULT_FILE)):
                # load data from <your_custom_path_to_twister-out>/twister.json
                self.run_path = TWISTER_OUT_PATH
                self.branch = 'Source data: %s'%(self.run_path)
                print("Open twister.json from %s directory: %s"%(DEFAULT_DATA_PATH, self.run_path))

            else:
                # load data from DATA_PATH/BRANCH/RUN_DATE/<artifact>/twister.json
                if not os.path.exists(DATA_PATH):
                    raise Exception("Source directory: {} doesn't exist", DATA_PATH)
                else:
                    if branch in BRANCH_DICT:
                        branch_dir = BRANCH_DICT[branch]
                    else:
                        branch_dir = list(BRANCH_DICT.values())[0]
                        branch = list(BRANCH_DICT.keys())[0]

                    self.branch = branch
                    branch_path = os.path.join(DATA_PATH, branch_dir)

                    if not os.path.exists(branch_path):
                        print("%s: File %s doesn't exist"%(__name__, branch_path))
                    else:
                        # get all files inside a specific folder (branch)
                        for run_path in os.scandir(branch_path):
                            if not run_path.is_file():
                                # in branch folder gets run_date folders ..../branch_name/yyyy-mm-dd/
                                match = re.search("\d{4}-\d{2}-\d{2}$", run_path.name)
                                if match and len(os.listdir(run_path.path)):
                                    for subset_dir in os.scandir(run_path.path):
                                        source = os.path.join(subset_dir.path, TESTS_RESULT_FILE)
                                        # getting subsets folder
                                        if os.path.exists(source):
                                            # create list of run dates
                                            # date_runs.append({'date':match.group(), 'path':source})
                                            if not match.group() in self.date_runs:
                                                self.date_runs.append(match.group())
                                            break

                        # searching run date on run date list
                        # run = [ item for item in date_runs if run_date and item["date"] == run_date ]
                        run = [ item for item in self.date_runs if run_date and item == run_date ]

                        # date_runs = sorted(date_runs, key=lambda x: x['date'], reverse=True)
                        self.date_runs = sorted(self.date_runs, reverse=True)

                        run_dir = run[0] if run else self.date_runs[0]

                        self.run_path = os.path.join(branch_path, run_dir)

                        self.server_mode = True

            if not os.path.exists(self.run_path):
                raise Exception("Source directory: %s doesn't exist"%self.run_path)

            for subset_dir in os.scandir(self.run_path):
                if subset_dir.name == TESTS_RESULT_FILE:
                    self.read_source_file(self.run_path)
                    break
                else:
                    self.read_source_file(os.path.join(subset_dir.path))

            if self.environment is None:
                raise Exception("Not found a %s file in source the directory: %s"%(TESTS_RESULT_FILE, self.run_path))

        except Exception as err:
            print(f"Unexpected {err=}, {type(err)=}")
            raise


    def read_source_file(self, twister_json_path: str):
        twister_json_file = os.path.join(twister_json_path, TESTS_RESULT_FILE)

        if os.path.exists(twister_json_file):
            try:
                with open(twister_json_file, "r") as f:
                    data = json.load(f)
                    if self.environment is None:
                        self.environment = data['environment']
                        self.environment['run_date'] = datetime.strptime(self.environment['run_date']
                                                                        , DATE_FORMAT_TWISTER).strftime(DATE_FORMAT_LONG)
                        self.environment['commit_date'] = datetime.strptime(self.environment['commit_date']
                                                                            , DATE_FORMAT_TWISTER).strftime(DATE_FORMAT_LONG)

                        # if application working in server mode, detecting zephyr version change is enabled
                        if self.server_mode:
                            self.detect_zephyr_verison_change()

                    for item in data['testsuites']:
                        if item['runnable']:
                            if item['platform'] in self.platforms.keys():
                                if not twister_json_path in self.platforms[item['platform']]:
                                    self.platforms[item['platform']].append(twister_json_path)
                            else:
                                self.platforms[item['platform']] = [twister_json_path]

            except Exception as e:
                print("%s: Exception: %s"%(__name__, e))


    def get_data(self):
        test_dict = []
        try:
            for platform in self.platforms:
                for platform_path in self.platforms[platform]:
                    data_path = os.path.join(platform_path, TESTS_RESULT_FILE)

                    if os.path.exists(data_path):
                        with open(data_path, "r") as f:
                            data = json.load(f)
                            for t in data['testsuites']:
                                if t['runnable']:
                                    name = t['name']
                                    _grouping = name.split("/")[-1]
                                    main_group = _grouping.split(".")[0]
                                    sub_group = _grouping.split(".")[1]

                                    # t[index] = main_group if index == 'component' else sub_group
                                    t['component'] = main_group
                                    t['sub_comp'] = sub_group

                                    # yield t
                                    test_dict.append(t)

            return test_dict

        except Exception as err:
            print(f"Unexpected {err=}, {type(err)=}")
            raise
    

    def detect_zephyr_verison_change(self):
        todays_run_summary_path = os.path.join(self.run_path, 'run_summary.json')
        if not os.path.exists(todays_run_summary_path):
            with open(todays_run_summary_path, 'w') as f:
                # Serializing json
                json_str = json.dumps(self.environment)
                f.write(json_str)

        try:
            yesterday = (datetime.strptime(self.environment['run_date'], DATE_FORMAT_LONG) - timedelta(days=1)).strftime(DATE_FORMAT_SHORT)
            yesterday_run_summary_path = os.path.join(DATA_PATH, BRANCH_DICT[self.branch], yesterday, 'run_summary.json')
            with open(yesterday_run_summary_path, 'r') as f:
                yesterday_run_summary = json.load(f)
        except FileNotFoundError as err:
            # summary of previous run is unavailabe
            # open any twister json file from yestarday's run and create summary file
            yesterdays_run_path = os.path.join(DATA_PATH, BRANCH_DICT[self.branch], yesterday)
            for subset_dir in os.scandir(yesterdays_run_path):
                yesterdays_run_data_path = os.path.join(subset_dir, TESTS_RESULT_FILE)
                if os.path.exists(yesterdays_run_data_path):
                    with open(yesterdays_run_data_path, 'r') as f_data:
                        data = json.load(f_data)
                        yesterday_run_summary = data['environment']
                        yesterday_run_summary['run_date'] = datetime.strptime(yesterday_run_summary['run_date']
                                                        , DATE_FORMAT_TWISTER).strftime(DATE_FORMAT_LONG)
                        yesterday_run_summary['commit_date'] = datetime.strptime(yesterday_run_summary['commit_date']
                                                                            , DATE_FORMAT_TWISTER).strftime(DATE_FORMAT_LONG)
                        with open(yesterday_run_summary_path, 'w') as f:
                            # Serializing json
                            json_str = json.dumps(yesterday_run_summary)
                            f.write(json_str)

                            break
        finally:
            if 'yesterday_run_summary' in locals():
                self.was_commit = yesterday_run_summary['commit_date'] != self.environment['commit_date']
