'''
Created on Oct 16, 2018

__author__ = "Tracy Graydon"
__copyright__ = "Copyright 2018 - 2020, Intel Corp."
__credits__ = ["Tracy Graydon"]
__license__ = "GPL"
__version__ = "2.0"
__maintainer__ = "Tracy Graydon"
__email__ = "tracy.graydon@intel.com"
'''

import os
import os.path
import pwd
import socket
import sys
import hashlib
import glob
import git

def get_list(dirname):
    dirlist = os.listdir(dirname)
    dirlist.sort()
    return dirlist

def split_thing(thing, marker):
    filebits = thing.split(marker)
    return filebits

def rejoin_thing(thing, marker):
    filebits = marker.join(thing)
    return filebits

def get_active_branch(sanity_out):
    # What branch are we on?
    os.chdir(sanity_out)
    repo = git.Repo(search_parent_directories=True)
    repo_object  = repo.active_branch
    branch = repo_object.name.split('\n')[0]
    return branch
