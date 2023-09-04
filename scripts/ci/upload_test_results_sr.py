#!/usr/bin/env python3

# scripts\ci\upload_test_results_sr.py

# Copyright (c) 2023 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# This script will unzip twister.json file from artifact, get platforms name from json
# for runnable testsuites and create platform list in test run directory.

import os, json, re
import argparse, sys, shutil

class RunResult:
    data_source = 'twister.json'
    platform_list_file = 'platform_list.txt'
    platform_list = {}

    def __init__(self):
        args = parse_args()

        if args.workflow == 'Run tests on Hardware (Intel)':
            subset_name_pattern = r'Unit Test Results \(Subset \d+\)'
        elif args.workflow == 'Run Twister - Intel':
            subset_name_pattern = r'artifacts_\d+'
        else:
            sys.exit('Workflow name is not valid.')

        try:
            self.f_path = os.getcwd()
            platform_list_path = os.path.join(self.f_path, self.platform_list_file)

            if os.path.exists(platform_list_path):
                with open(platform_list_path, 'r') as f:
                    self.platform_list = json.load(f)

            for item in os.scandir(self.f_path):
                if re.match(subset_name_pattern, item.name):
                    # ./master/2023-08-31/Unit Test Results (Subset 13)
                    # ./master/2023-08-31/Subset13
                    # remove spaces and () from subset name
                    dest_dir_name = re.sub(r'[ \(\)_\\]', '', item.name)
                    dest_dir_path = os.path.join(self.f_path, dest_dir_name)

                    if os.path.exists(dest_dir_path):
                        shutil.rmtree(dest_dir_path, ignore_errors=True)

                    os.rename(item.path, dest_dir_path)

                    # Add platform name to platform_list_file
                    self.add_platform_to_list(dest_dir_path, dest_dir_name)

            with open(platform_list_path, 'w') as f:
                f.write(json.dumps(self.platform_list))

        except FileNotFoundError:
            print(f"File doesn't exist: {item.path}")
        except OSError as err:
            print(f'OS error: {err}')
        except Exception as err:
            print(f'Unexpected error: {err} ({type(err)})')

    # Parse twister.json for get platform name and toolchain
    def add_platform_to_list(self, dir_path: str, dir_name: str):
        try:
            data_file = os.path.join(dir_path, self.data_source)

            with open(data_file, "r") as read_file:
                body = json.load(read_file)
                for testsuite in body['testsuites']:
                    if testsuite['runnable']:
                        self.platform_list[testsuite['platform']] = dir_name

        except FileNotFoundError:
            print(f"File doesn't exist: {data_file}")
        except LookupError:
            print(f'File is not a valid {self.data_source} format')


def parse_args():
    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument('-w', '--workflow', help='workflow name.', required=True,
                        choices=['Run tests on Hardware (Intel)', 'Run Twister - Intel'])

    args = parser.parse_args()

    return args

if __name__ == '__main__':
    RunResult()
