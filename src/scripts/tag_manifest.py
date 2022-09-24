""" Tag Repos for Manifest Update Process

This script will create and push a tag in the correct format for tagging the
zephyr and zephyr-intel repos for main-intel and main branches, respectively.

Working dir is set to /srv/buid/manifest. Change to your liking.

Script takes up to three arguments. First, which is required, is the path to y
our ssh key for git repo access in the format of:

    python3 tag_manifest.py /path/to/your/key/key_name

The second (optional) argument is the base branch to be tagged. The default is
to use main/main-intel. If you wish to tag say, v2.7-branch-intel, you can 
specify that.

    python3 tag_manifest.py /path/to/your/key/key_name -b <branch>

    i.e. 
    python3 tag_manifest.py /path/to/your/key/key_name -b v2.7-branch-intel

The third (optional) argument is the rebase branch name, if there is one. There
should pretty much always be one. The script takes that branch name and 
extracts the date stamp portion for use in creating the tag. This way the tag 
and the rebase branch datestamp match. This will match the PR information for 
easier backtracking should we need to revert. Pass the branch like so....

    python3 tag_manifest.py /path/to/your/key/key_name -b <branch> -r <rebase_branch>

    i.e.
    python3 tag_manifest.py /path/to/your/key/key_name -b v2.7-branch-intel -r v2.7-branch-intel-20220916

If you do not pass a rebase branch name, the current date will be used. If you
use this THE SAME DAY as the rebase branch creation, all is well. If the branch
was created a day or more prior, pass the branch name in.

If the tag already exists on one or both of the remote repos, the script will
notify and exit.

If the tag exists in the local repos but not on the remotes, it will use the
existing tags. Since the local repos get nuked each time, this is kind of moot
right now, but intent is to be able to reuse a repo or recover a failed run.
i.e. To skip cloning repos again, since that is time consuming and GitPython
is notoriously slow. It's useful for debug and testing as well.

Script prompts for option to display tags before pushing. Also prompts to
confirm push of tags.

Error checking is non-existent at present, so checking on end result is a
great idea.

TODO:
    - Error checking
    - Find rebase branches, get the most recent, and prompt for use, else generate.
    - Reuse of repos, rather than blind nuke
    - Deal with corner cases like tag on one (remote) repo, but not on other
    - Allow passing in of working dir or use cwd.

"""

import os
import sys
import argparse
from shutil import rmtree
from git import Repo
from git import Git
from datetime import datetime


class ManifestRepo:

    def __init__(self, repo):

        name = repo[0]
        branch = repo[1]

        repo_base = "git@github.com:intel-innersource/os.rtos.zephyr"
        repo_url = repo_base + "." + name

        self.name = name
        self.repo_url = repo_url
        self.branch = branch
        self.version = ""
        self.pr = ""
        self.tag_exists = "false"


def clean_workspace(workspace, repo_list):

    print("Cleaning workspace: ", workspace)
    os.chdir(workspace)
    for repo in repo_list:
        repo_name = repo[0]
        repo_path = os.path.join(workspace, repo_name)
        if os.path.exists(repo_path):
            # This doesn't always print: why???
            print(f"Found an existing {repo_name} repo. Nuking it.")
            rmtree(repo_path)


def clone_repo(workspace, repo, git_ssh_identity_file):

    print(f"Cloning {repo.name}...", end =" ")
    git_ssh_cmd = 'ssh -i %s' % git_ssh_identity_file
    Repo.clone_from(repo.repo_url, os.path.join(workspace, repo.name), branch=repo.branch, env=dict(GIT_SSH_COMMAND=git_ssh_cmd))
    print("Done.")


def tag_repo(tag, repos):

    # Note that local_repo here is not the checked out repo dir. It's just
    # name mangling to distinguish the manifest repo object from a git/gitpython repo object.
    # The local_repo.git.ls_remote line is looking at the remote for tags and not in
    # the checked out directory.
    for repo in repos:
        local_repo = Repo(os.path.join(workspace, repo.name))
        tags = local_repo.git.ls_remote("--tags", "origin")
        if tag in tags:
            repo.tag_exists  = True
        else:
            repo.tag_exists = False

    if repos[0].tag_exists == True and repos[1].tag_exists == True:
        print(f"Tag exists on both {repos[0].name} and {repos[1].name} remotes. Already tagged.")
        sys.exit(1)
    elif repos[0].tag_exists == True or repos[1].tag_exists == True:
        if repos[0].tag_exists == True:
            print(f"Tag exists on {repos[0].name} remote. Manual intervention required.")
        else:
            print(f"Tag exists on {repos[1].name} remote. Manual intervention required.")
        sys.exit(1)
    elif repos[0].tag_exists == False and repos[1].tag_exists == False:
        print(f"No pre-existing tag exists on either remote repo. Good to go.")
        for repo in repos:
            local_repo = Repo(os.path.join(workspace, repo.name))
            # Branch name will generally match across both repos, but zephyr has  main-intel and zephyr-intel has main.
            # So we have to account for that and set accordingly. 
            if repo.name == "zephyr":
                ref_name = repo.branch 
            else:
                ref_name = repo.branch
            local_tags = local_repo.tags
            if tag in local_tags:
                print(f"{repo.name.title()}: {tag} tag exists locally but not on remote. Using it.")
            else:
                print(f"{repo.name.title()}: No local {tag} tag. Creating it.")
                the_tag = local_repo.create_tag(tag, ref=ref_name, message=tag)

    return


def create_tag(workspace, repo, rebase_branch):

    # Tag format:
    # zephyr-3.1.99-intel-yyymmdd
    # VERSION = PREFIX-MAJOR.MINOR.PATCH-SUFFIX-date_stamp

    PREFIX = repo.name + '-'
    SUFFIX = "intel"

    # If we didn't pass in a rebase branch, generate today's date. If we have a
    # rebase branch already, we take the date_stamp from that so the tag date
    # matches the branch date. This makes finding correct version easier in
    # case we have to restore from a tag.

    if rebase_branch  == "":
        date_stamp = datetime.today().strftime('%Y%m%d')
    else:
        date_stamp = rebase_branch.split('-')[-1]

    print(f"Date Stamp: {date_stamp}")

    repo_dir = os.path.join(workspace, repo.name)
    os.chdir(repo_dir)

    # We don't care about these lines in VERSION file
    del_list = ["VERSION_TWEAK", "EXTRAVERSION"]

    with open("VERSION") as f:
        version_dict = { k.strip(): v.strip() for line in f for (k, v) in [line.rstrip().split("=")]}
        [version_dict.pop(key) for key in del_list]

    version = '.'.join(str(val) for key, val in version_dict.items())

    tag = PREFIX + version + "-" + SUFFIX + "-" + date_stamp
    print("TAG: ", tag)

    return tag


def show_tag(tag, repos):

    # Note that local_repo here is not the checked out repo dir. It's just
    # name mangling to distinguish the manifest repo object from a git/gitpython repo object.
    # The local_repo.git.ls_remote line is looking at the remote for tags and not in
    # the checked out directory.
    for repo in repos:
        local_repo = Repo(os.path.join(workspace, repo.name))
        print("repo: ", repo.name)
        local_tags = local_repo.tags
        print(f"{repo.name} tag info: {local_repo.git.show(tag)}: \n")

    return


def push_tag(tag, repos):

    # TODO: add some error checking here.
    # Check for failure.
    # Check for tag on remote.

    answer = input("\nDo you want to push the tags? y/n: ").lower()
    if answer == "y":
        for repo in repos:
            local_repo = Repo(os.path.join(workspace, repo.name))
            print(f"Pushing {repo.name} tag. ", end="")
            local_repo.remotes.origin.push(tag)
            print("Done.")

    return


os.system("clear")


# Create the parser and add arguments
parser = argparse.ArgumentParser()
parser.add_argument(dest='key_path', help="/path/to/key/key_name")
parser.add_argument('-b', '--branch',
                    required = False, dest='branch',
                    help="The base branch to be rebased if not main. i.e. v2.7-branch-intel.")
parser.add_argument('-r', '--rebase_branch',
                    required = False , dest='rbranch',
                    help="i.e. main-intel-20220916 or v2.7-branch-intel-20220921")

# Parse and print the results
args = parser.parse_args()
print(f"Key Path: {args.key_path}")
print(f"Base Branch: {args.branch}")
print(f"Rebase Branch: {args.rbranch}")

git_ssh_identity_file = args.key_path

if args.branch:
    base_branch = args.branch
else:
    base_branch = "main"

if args.rbranch:
    rebase_branch = args.rbranch
else:
    rebase_branch = ""

workspace  = "/srv/build/manifest"    # or whatever your workdir is


if base_branch == "main" or base_branch == "main-intel":
    repo_list = [['zephyr', 'main-intel'], ['zephyr-intel', 'main']]
else:    
    repo_list = [['zephyr', base_branch], ['zephyr-intel', base_branch]]

print(f"REPO_LIST: {repo_list}")

# Check workspace exists. Create/Clean it.
if not os.path.exists(workspace):
    print(f"Creating workspace {workspace}.")
    os.mkdir(workspace)
elif os.path.exists(workspace):
    print(f"Cleaning workspace {workspace}.")
    clean_workspace(workspace, repo_list)

# Create some repo objects and set some things
for repo in repo_list:
    if repo[0] == "zephyr":
        zephyr_repo = ManifestRepo(repo)
    elif repo[0] == "zephyr-intel":
        zephyr_intel_repo = ManifestRepo(repo)

repos = [zephyr_repo, zephyr_intel_repo]

# Clone the repos
for repo in repos:
    print(f"Cloning {repo.name}.")
    clone_repo(workspace, repo, git_ssh_identity_file)

# Create the tag
tag = create_tag(workspace, zephyr_repo, rebase_branch)
tag_repo(tag, repos)

# Make this better. Like don't just quit if y/n not selected.
answer = input("\nDo you want to see the tag info? y/n: ").lower()

if answer == "y":
    show_tag(tag, repos)

push_tag(tag, repos)


