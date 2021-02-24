"""
Check Whitelist Status and if review is to expire within 60 days.
"""
import os
import sys
import configparser
import argparse
import json
import ssl
import re
import urllib.request
from urllib.error import URLError, HTTPError
import urllib.parse
from datetime import datetime
from dateutil.parser import parse

SERVER = 'https://whitelisttool.amr.corp.intel.com//'
URL_GET_REQUEST_WITH_NAME = 'api.php/get_request/?prj-name='
REQUIRED_STATS = ['id', 'project', 'expiration', 'status']

def read_whitelist(name):
    """
    Read from the Whitelist tool.
    """
    try:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        stats_json = urllib.request.urlopen(SERVER + URL_GET_REQUEST_WITH_NAME + name, context=ctx)
    except HTTPError as err:
        print("Whitelist server not available. HTTPError:", err.code)
        sys.exit(1)
    except URLError as err:
        print("Whitelist server not available. URLError:", err.reason)
        sys.exit(1)

    try:
        stats = json.load(stats_json)
    except ValueError:
        return []

    for stat in stats:
        for required in REQUIRED_STATS:
            if required not in stat:
                # pylint: disable=line-too-long
                print("Missing required field in answer from server: %s" %  required + ': ' + repr(stat.keys()))
                # pylint: enable=line-too-long
                return []
    #print("Stats: ", stats, "\n")        
    return stats

def get_previous_status(stats, latest_id):
    """
    Get previous Whitelist Status.
    """
    previous_id = 0
    previous_stat = []

    for stat in stats:
        if stat['id'] > previous_id and stat['id'] != latest_id:
            previous_id = stat['id']
            previous_stat = stat

    return previous_stat

def get_latest_status(stats):
    """
    Get latest Whitelist Status.
    """
    latest_id = 0
    latest_stat = []

    for stat in stats:
        if stat['id'] > latest_id:
            latest_id = stat['id']
            latest_stat = stat

    return latest_stat

def check_projects(settings): # pylint: disable=R0914
    """
    Check Whitelist Status and if review is to expire within 60 days.
    """
    file_pointer = open(settings["file"], 'r')
    for row in file_pointer:
        splitted = row.split("//", 1)
        project = (re.sub(r'(?<=[,])(?=[^\s])', r' ', splitted[0]))
        project = project.strip()
        comment = "None"
        if len(splitted) > 1:
            comment = splitted[1]
            comment = comment.strip()
        valid = False
        response = "OK"
        previous_status = "Not found"
        int_diff_days = 0

        stats = read_whitelist(urllib.parse.quote(project, safe=''))
        if stats:
            stat = get_latest_status(stats)
            if stat:
                valid = True

                previous_stat = get_previous_status(stats, stat['id'])
                        

                if previous_stat:
                    previous_status = previous_stat['status']
                    previous_stat_id = previous_stat['id']

                    # pylint: disable=line-too-long
                    if ((previous_stat['status'] == 'Whitelist' and stat['status'] == 'Conditional') or
                        (previous_stat['status'] == 'Expired' and stat['status'] == 'Conditional')):
                    # pylint: enable=line-too-long
                        response = "CHECK"
                else:
                    previous_stat_id = "None"
                    

                if stat['status'] == 'Expired' or \
                   stat['status'] == 'Pending' or \
                   stat['status'] == 'Blacklist':
                    response = "NOK"
                else:
                    present_date = datetime.now()
                    parsed_date = parse(stat['expiration'])
                    diff_date = parsed_date - present_date
                    int_diff_days = int(diff_date.days)

                    if int_diff_days < 60:
                        response = "NOK"

        if valid is True:
            if response == "NOK" or response == "CHECK" or settings["printLess"] == "false":
                print("Project: %s" % project)
                # pylint: disable=line-too-long
                print("Whitelist link: %s" % "https://whitelisttool.amr.corp.intel.com/view.php?id=" + str(stat['id']))
                # pylint: enable=line-too-long
                print("Project ID:", stat['id'])
                print("Whitelist Status: %s" % stat['status'])
                print("Previous ID:", previous_stat_id)      
                print("Previous Whitelist Status: %s" % previous_status)
                print("Expiration Date: ", stat['expiration'])
                print("Expires in:", int_diff_days, "day(s).")
                print("Project status: ", response)
                print("Comment: %s\n" % comment)
        else:
            print("Project:", project, "NOT FOUND")
            #print("Project: %s" % project)
            #print("Whitelist link: Project not found")
            #print("Whitelist Status: Project not found")
            #print("Previous Whitelist Status: Project not found")
            #print("Number of days until review will expire: Project not found")
            #print("Project status: NOK")
            print("Comment: %s\n" % comment)

def check_arguments(settings):
    """
    Check arguments.
    """
    parser = argparse.ArgumentParser()
    # pylint: disable=line-too-long
    parser.add_argument('-f', '--file', required=True, help="File in TXT format with Open Source projects")
    parser.add_argument('-l', '--printLess', default='false', required=False, choices=('true', 'false'), help="Print only Open Source projects with status NOK or CHECK")
    # pylint: enable=line-too-long
    args = parser.parse_args()

    if os.path.isfile(args.file) is False:
        print("File not found: %s" % args.file)
        sys.exit(1)
    else:
        settings["file"] = args.file
        settings["printLess"] = args.printLess

    #print("Settings File: ", settings["file"])    

if __name__ == '__main__':
    settings_dict = {
        "parser" : configparser.ConfigParser(),
        "file" : [],
        "printLess" : "false"
    }
    check_arguments(settings_dict)
    check_projects(settings_dict)
