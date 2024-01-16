#!/usr/bin/python

import os, re, json
from datetime import datetime
from app.config import *
from app.config_local import *

class DirectoryParser:
    date_runs = []
    branch_dict = BRANCH_DICT
    # server_mode is used to hide downloading logs options when we use this app locally
    server_mode = False

    def __init__(self, branch, run_date:str=None):
        run_dir = None
        self.branch = 'n/a'
        self.environment = None
        self.run_date = run_date
        self.platforms = {}

        try:
            source = os.path.join(os.path.curdir, DEFAULT_DATA_PATH, TESTS_RESULT_FILE)

            if os.path.exists(source):
                self.run_path = os.path.join(os.path.curdir, DEFAULT_DATA_PATH)
                self.branch = 'Source data: %s'%(self.run_path)
                print("Open twister.json from local %s directory: %s"%(DEFAULT_DATA_PATH, self.run_path))

            elif os.path.exists(os.path.join(TWISTER_OUT_PATH, TESTS_RESULT_FILE)):
                self.run_path = TWISTER_OUT_PATH
                self.branch = 'Source data: %s'%(self.run_path)
                print("Open twister.json from %s directory: %s"%(DEFAULT_DATA_PATH, self.run_path))

            else:
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
                        # get all files inside a specific folder
                        for run_path in os.scandir(branch_path):
                            if not run_path.is_file():
                                match = re.search("\d{4}-\d{2}-\d{2}$", run_path.name)
                                if match and len(os.listdir(run_path.path)):
                                    for subset_dir in os.scandir(run_path.path):
                                        source = os.path.join(subset_dir.path, TESTS_RESULT_FILE)
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

                    for item in data['testsuites']:
                        if item['runnable'] and not item['platform'] in self.platforms.keys() and os.path.exists(twister_json_file):
                            self.platforms[item['platform']] = twister_json_path

            except LookupError:
                print("%s: File %s is not a valid twister.json format "%(__name__, twister_json_file))


    def get_data(self):
        test_dict = []
        try:
            for subset_dir in os.scandir(self.run_path):
                source = subset_dir.path if subset_dir.is_file() and re.search(TESTS_RESULT_FILE,
                                            subset_dir.name) else os.path.join(subset_dir.path, TESTS_RESULT_FILE)

                if os.path.exists(source):
                    with open(source, "r") as f:
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
