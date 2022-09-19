""" Generate the PR comments for the tagging

This scrip generates the PR comment to be added to both the zephyr and
zephyr-intel_PRs for the manifest update.

Working dir should be same as for tag_manifest.py.

This needs to run AFTER the tagging script.

Takes an argument of the tag that was pushed. i.e. zephyr-3.1.99-intel-20220902

Currently just splats the text to the screen for copy and paste. Will eventually
just push the comments to the respective PRs.

"""

import os
import sys
import argparse
from git import Repo
from git import Git


os.system("clear")


# Create the parser and add arguments
parser = argparse.ArgumentParser()
parser.add_argument(dest='tag', help="tag to create PR comments for")

# Parse and print the results
args = parser.parse_args()
print(args.tag)


tag = args.tag

# For testing
#tag = 'zephyr-3.1.99-intel-20220902'
#tag = "fmos-self-test"

workspace  = "/srv/build/manifest"    # or whatever your workdir is

for repo_name in ['zephyr', 'zephyr-intel']:
    repo_path = os.path.join(workspace, repo_name)
    repo = Repo(repo_path)
    tags = repo.tags
    for thing in tags:
        if tag == thing.name:
            print(f"{repo_name.title()} {thing.commit} has been tagged as {thing.name}")
