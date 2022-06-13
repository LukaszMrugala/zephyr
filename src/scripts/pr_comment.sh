#!/bin/bash

############################################################################
#
# Push a comment to a manifest rebase PR with the SHA and tag info.
#
# Usage: ./pr_comment <repo> <pr#> <tag>
# Zephyr Example:
#
# ./pr_comment zephyr 123 zephyr-3.0.99-intel-20220524
#
# Zephyr-intel Example:
#
# ./pr_comment zephyr-intel 456 zephyr-3.0.99-intel-20220524
#
# The tag must already exist in the zephyr repo.
#
# If the PR exists, a comment is generated for the PR noting the SHA and
# tag name for the main-intel revision we are "archiving."
#
# A comment is generated and then pushed to the PR.
#
# WARNING: THIS WILL GLEEFULLY PUSH THE COMMENT TO ANY VALID PR# YOU GIVE IT.
# MAKE SURE YOU GIVE IT THE RIGHT ONE OR YOU WILL NEED TO GO CLEAN THAT UP.
#
############################################################################

export WORKDIR=/srv/build    # or whatever your workdir is
PR_REPO="$1"
PR="$2"
TAG="$3"
ZEPHYR_REPO="git@github.com:intel-innersource/os.rtos.zephyr.zephyr.git"
ZEPHYR_INTEL_REPO="git@github.com:intel-innersource/os.rtos.zephyr.zephyr-intel.git"
BODY_FILE=$WORKDIR/body.txt

echo "You gave me:"
echo "PR_REPO: $PR_DIR"
echo "PR: $PR"
echo "TAG: $TAG"
echo

if [ "$PR_REPO" == "" ] || [ "$PR" == "" ] || [ "$TAG" == "" ]; then
   echo "Usage: ./pr_comment <repo> <pr#> <tag>"
   echo " ./pr_comment zephyr 123 zephyr-3.0.99-intel-20220524"
   echo "./pr_comment zephyr-intel 456 zephyr-3.0.99-intel-20220524"
   exit
fi


function clone_repo()
{
# If repo exists hard reset everything and reuse it
if [ -d $WORKDIR/$REPO_DIR ]; then
    echo "Found an existing repo. Reuse it? This will annihilate any unpushed changes."
    while true
        do
          read -r -p "REUSE IT? Y/N: " choice
          case "$choice" in
              n|N) echo "NOT reusing. Bye!"
                   exit
                   ;;
              y|Y) echo "You said DO IT. Resetting repo."
                   cd $REPO_DIR
                   echo "Refreshing branch"
                   git checkout $BRANCH
                   echo "Hard reset branch"
                   git reset --hard origin/$BRANCH
                   echo "Force clean"
                   git clean -d --force
                   # We only care about the tags if we are reusing zephyr repo.
                   # We never look at tags on zephyr-intel.
                   if [ "$REPO_DIR" == "zephyr" ]; then
                       echo "Refreshing tags"
                       git tag -l | xargs git tag -d > /dev/null 2>&1 && git fetch --tags > /dev/null 2>&1
                   fi
                   echo "Refresh Done."
                   break
                   ;;
              *) echo "Wut? Choose Y/n";;
          esac
        done
fi

echo
if [[ ! -d $WORKDIR/$REPO_DIR ]]; then
    echo "CLONE THE REPO"
    if ! git clone $REPO_URL $REPO_DIR; then
        echo "Failed to checkout $REPO_URL."
        exit
    else
        cd $REPO_DIR
    fi
fi
}

# Set up WORKDIR, if it doesn't already exist
if [ ! -d $WORKDIR ]; then
    mkdir -p $WORKDIR
    chmod 777 $WORKDIR
fi
cd $WORKDIR

# First we clone Zephyr, cuz we have to find the tag info.
REPO_DIR="zephyr"
BRANCH="main-intel"
REPO_URL=$ZEPHYR_REPO
clone_repo

# Does the tag exist?
if git rev-parse "$TAG" > /dev/null 2>&1; then
    FOUND="true"
    echo "FOUND TAG: $TAG"
else
    echo "Can't find tag $TAG. Did you push it?"
    exit
fi

# Uncomment this if you want to spew the tag details out to screen."
#git --no-pager show $TAG
#echo

# Get the SHA the tag points to.
SHA=`git rev-list -n 1 $TAG`
echo "SHA: $SHA"
echo

echo "Zephyr repo main-intel $SHA has been tagged as $TAG" > $BODY_FILE

# If we are commenting on zephyr-intel PR, get that repo.
if [ "$PR_REPO" == "zephyr-intel" ]; then
    cd $WORKDIR
    REPO_DIR="$PR_REPO"
    BRANCH="main"
    REPO_URL=$ZEPHYR_INTEL_REPO
    clone_repo
fi

# Does our PR exist??
# EXISTS DOESN'T GUARANTEE IT IS THE RIGHT ONE! Make sure you have the correct PR for the right repo!

if `gh pr view $PR > /dev/null 2>&1`; then
    echo "PR $PR exists";
else
    echo "Can't find PR $PR. Go Fish"
    exit
fi

# Write the comment to the PR
echo "Writing the comment to PR $PR."

while true
   do
     read -r -p "PUSH THE PR COMMENT? Y/N: " choice
     case "$choice" in
         n|N) echo "NOT PUSHING THE COMMENT to $PR_REPO $PR. Bye!"
              exit
              ;;
         y|Y) echo "PUSHING THE PR COMMENT to $PR_REPO $PR."
              gh pr comment $PR -F $BODY_FILE
              cat $BODY_FILE
              break
              ;;
         *) echo "Wut? Choose Y/n";;
     esac
   done

rm $BODY_FILE
