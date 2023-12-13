#!/usr/bin/env python3

# Copyright (c) 2023 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# This script upload fat test ci results to the zephyr ES instance for reporting and analysis.
# see https://kibana.zephyrproject.io/

from elasticsearch import Elasticsearch
from elasticsearch.helpers import bulk
import os
import json
import argparse
from datetime import datetime

def check_path_existence(path):
    return os.path.exists(path) or os.path.isdir(path) or os.path.isfile(path)

def load_json(file_path):
    with open(file_path, 'r') as file:
        data = json.load(file)
    return data

def append_json(existing_data, json_file_path):
    additional_data = load_json(json_file_path)
    existing_data["tests"].extend(additional_data)
    return existing_data

#for each test we get separate folder containing data, we need data from specific file - test_result.json
#the path for each result is always different cause of output from FAT tests, thats we need to scan everything
def find_json_files(directory_path):
    json_files = []

    for root, _dirs, files in os.walk(directory_path):
        for file in files:
            if file.endswith("test_result.json"):
                json_files.append(os.path.join(root, file))

    if not json_files:
        print("Error with parsing files into list")
    return json_files

def list_files(directory_path):
    files = [f for f in os.listdir(directory_path) if os.path.isfile(os.path.join(directory_path, f))]
    return files

def gendata(data, index, run_date=None):
    for t in data['tests']:
        t['run_date'] = run_date
        yield {
            "_index": index,
            "_source": t
            }

def main():
    args = parse_args()

    if args.index:
        index_name = args.index
    else:
        index_name = 'fat-test-1'

    selected_path = args.folder[0]
    if check_path_existence(selected_path):
        try:
            print(list_files(selected_path))
            combined_test_data = {"tests": []}
            json_files = find_json_files(selected_path)
            for json_file in json_files:
                append_json(combined_test_data,json_file)
        except FileNotFoundError as e:
            print(f"Error: {e}")
        except json.JSONDecodeError as e:
            print(f"Error decoding JSON: {e}")
    else:
        print(f"The path '{selected_path}' does not exists.")

    es = Elasticsearch(
        [os.environ['ELASTICSEARCH_SERVER']],
        api_key=os.environ['ELASTICSEARCH_KEY'],
        verify_certs=False
        )

    settings = {
            "index": {
                "number_of_shards": 4
                }
            }
    mappings = { }

    if args.create_index:
        es.indices.create(index=index_name, mappings=mappings, settings=settings)
    else:
        if args.run_date:
            print(f"Setting run date from command line: {args.run_date}")
        else:
            time = os.path.getmtime(args.folder[0])
            args.run_date = datetime.fromtimestamp(time).isoformat()

        bulk(es, gendata(combined_test_data, index_name, args.run_date))

def parse_args():
    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument('-y','--dry-run', action="store_true", help='Dry run.')
    parser.add_argument('-c','--create-index', action="store_true", help='Create index.')
    parser.add_argument('-i', '--index', help='index to push to.', required=True)
    parser.add_argument('-r', '--run-date', help='Run date in ISO format', required=False)
    parser.add_argument('folder', metavar='FILE', nargs='+', help='folder with test data.')

    args = parser.parse_args()

    return args


if __name__ == '__main__':
    main()
