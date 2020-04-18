#!/usr/bin/python
#
# Copyright (c) 2017 Intel Corporation
#
# Coverity Automation code is designed to automate the coverity github issue
# creation when there is new issues seen in the coverity webpage based on the
# scan results for the Zephyr project, by eliminating the previously
# existing issues and to create GitHub issues for the new once.

import re
import csv
import tempfile
import os
import sys
import getpass
import requests
import github.GithubException
import traceback
import extract_msg

# Fetching the environmental variables set for GitHub Personal Access Token
token = os.environ.get("GITHUB_TOKEN")

# Fetching the environmental variables set for Coverity Username and Password
c_userid = os.environ.get("COV_USER")
c_userpass = os.environ.get("COV_PASSWORD")

# If environmental variables are not found the get the input from command prompt
if (not token) or (not c_userid and not c_userpass):
    print("Unable to get User credentials, Enter GitHub Personal Access Token")

    # Using getpass with or without a Terminal
    if sys.stdin.isatty():
        # Use Personal access token instead of Github password
        token = getpass.getpass('Enter token :')
        print("Enter Coverity Username and Password")
        c_userid = getpass.getpass('Enter username :')
        c_userpass = getpass.getpass('Enter password: ')
    else:
        token = sys.stdin.readline().rstrip()
        print("Enter Coverity Username and Password")
        c_userid = sys.stdin.readline().rstrip()
        c_userpass = sys.stdin.readline().rstrip()

# Initialize an empty set to store unique CIDs
cids = set()

# Access zephyrproject-ros/zephyr repository on Github using access token
git = github.Github(token)
org = git.get_organization('zephyrproject-rtos')
repo = org.get_repo('zephyr')

def make_github_issue(title1, body1 = None, labels1 = None):
    """
    The make_github_issue() function is designed to create Github issues
    in a particular github repository and get the status if it is
    successfully created or not
    """
    try:
        repo.create_issue(title = title1, body = body1, labels = labels1)
    except github.GithubException as e:
        traceback.format_exc()
        raise


# Here we are reading the coverity issues from CSV file exported from the coverity website.
# The environment variable REPORT_PATH should point to csv file path

with open(os.environ.get("REPORT_PATH")) as csv_file:
    mycsv = csv.reader(csv_file, delimiter=",")
    mycsvl = list(mycsv)

email_path=os.environ.get("EMAIL_PATH")
f = r'email_path'
print(f)
msg = extract_msg.Message(f)
msg_message = msg.body

dictionary ={}
list_of=re.split("[*]{3}",msg_message)
for i in list_of:
    pattern = r'^\sCID.*[}]'
    second = re.search(pattern,i,re.MULTILINE | re.DOTALL)
    if second:
        pattern1 = r'^\WCID\s[\d]+'
        pattern2 = r'.*[:].*[}]'
        third = re.search(pattern1,i,re.MULTILINE | re.DOTALL)
        fourth = re.search(pattern2,i,re.MULTILINE | re.DOTALL)
        key = third.group(0)
        value = "```"+fourth.group(0)+"```"
        dictionary[key]=value

# Compose a global search query to get a handler to paginated list of issues.
# Create a final list by filtering all issues to just extract Coverity related issues
# so that mapping them with the new coverity defects will be easier.
try:
    issues = git.search_issues("coverity in:title label:bug repo:zephyrproject-rtos/zephyr")
    for ii in issues:
        cid = re.compile("CID[ ]?:[ ]?(?P<cid>[0-9]+)")
        match = cid.search(ii.title)
        if not match:
            continue
        cid = int(match.groupdict()['cid'])
        cids.add(cid)

    # Retrieving each and every row of the newly identified coverity issues until the last count
    # to match with the existing issues in GitHub. Removing headers(index 0)
    for row in mycsvl[1:]:
        cid = int(row[0])

        # check if the cid in csv file that matches with the cids retreived
        # from the github webpage. If matches then do nothing, if not match
        # create a new github issue with all the details by calling
        # make_github_issue function
        if cid in cids:
            continue # if exists

        # not existing so create the github issue by calling make_github_issue()
        else:
             if cid in dictionary:
                code=dictionary[cid]
                body = "Static code scan issues seen in File: {r[11]}" \
                   + "\n Category: {r[10]}\n Function: {r[12]}" \
                   + "\n Component: {r[9]}\n CID: {r[0]}" \
                   + "\n Please fix or provide comments to square " \
                   +"Details:\n"+"```"+"code"+"```" \
                   + "it off in coverity in the link: " \
                   + "https://scan9.coverity.com/reports.htm#v32951/p12996"
             else:
                  body = "Static code scan issues seen in File: {r[11]}" \
                   + "\n Category: {r[10]}\n Function: {r[12]}" \
                   + "\n Component: {r[9]}\n CID: {r[0]}" \
                   + "\n Please fix or provide comments to square " \
                   + "it off in coverity in the link: " \
                   + "https://scan9.coverity.com/reports.htm#v32951/p12996"
 
             title = "[Coverity CID :{r[0]}]{r[10]} in {r[11]}"
             make_github_issue(title.format(r = row),
                              body.format(r = row),
                              ['bug', 'Coverity', 'area: '+ row[9]])

except Exception as Exp:
    print Exp
    sys.exit(1)
