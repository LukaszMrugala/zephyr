#!/usr/bin/python

import os, re, json
from app.config_local import *

class DirectoryParser:

    def parse_runs_dir(branch_path, data_source):
        date_runs = []

        try:
            # get all files inside a specific folder
            for run_path in os.scandir(branch_path):
                if not run_path.is_file():
                    match = re.search("\d{4}-\d{2}-\d{2}$", run_path.name)
                    if match and len(os.listdir(run_path.path)):
                        for platform_path in os.scandir(run_path.path):
                            if not platform_path.is_file() and os.path.exists(f'{platform_path.path}/{data_source}'):
                                date_runs.append({'date':match.group(), 'path':run_path.name})
                                break

            return sorted(date_runs, key=lambda x: x['date'], reverse=True)

        except FileExistsError:
            print("File %s doesn't exist", branch_path)
        except LookupError:
            print("File %s is not a valid twister.json format ", run_path)


    def read_platforms(run_path):
        try:
            platform_list_path = os.path.join(run_path, PLATFORM_LIST_FILE)
            # reading the data from the file
            with open(platform_list_path) as f:
                data = f.read()

            # reconstructing the data as a dictionary
            platforms = json.loads(data)

            return platforms
        
        except FileExistsError:
            print("File %s doesn't exist", run_path)
