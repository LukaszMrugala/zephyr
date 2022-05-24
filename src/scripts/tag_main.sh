#!/bin/bash

########################################################################
#
# Can use this script to create the tag for a main-intel rebase. This
# should technically work for any branch but it has NOT been tested with
# other than main-intel.
#
# If you want to reuse an existing repo, this script makes an attempt to
# clean up. It will nuke, or should, ANYTHING that hasn't been pushed to
# remote. It deletes existing local tags and fetches them fresh. Don't be
# alarmed at the "Deleting tag spew at the command line. It is not nuking
# remote tags.
#
# Generates the tag and then shows the details, then prompts for the push
# at the end.
#
#########################################################################

export WORKDIR=/srv/build    # or whatever your workdir is
REPO_DIR="zephyr"
BRANCH="main-intel"
REPO_URL="git@github.com:intel-innersource/os.rtos.zephyr.zephyr.git"

TAG=""

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
                   git fetch origin --tags
                   git checkout $BRANCH
                   git reset --hard origin/$BRANCH
                   git clean -d --force
                   git tag -l | xargs git tag -d && git fetch --tags
                   break
                   ;;
              *) echo "Wut? Choose Y/n";;
          esac
        done
fi

echo
if [[ ! -d $WORKDIR/$REPO_DIR ]]; then
    echo "CLONE THE REPO"
    if ! git clone --branch $BRANCH $REPO_URL $REPO_DIR; then
        echo "Failed to checkout $REPO_URL or couldn't get the $BRANCH branch."
        exit
    else
        cd $REPO_DIR
    fi
fi
}

read_version()
{
# Snag the version information for the tag, from VERSION file.
while read -r line; do
    string=`echo $line | awk '{print $1}'`
    value=`echo $line | awk '{print $3}'`
    if [ $string == "VERSION_MAJOR" ]; then
        MAJOR=$value
    elif [ $string == "VERSION_MINOR" ]; then
        MINOR=$value
    elif [ $string == "PATCHLEVEL" ]; then
        PATCH=$value
    fi
done < VERSION

DATE_STAMP=`date "+%Y%m%d"`
echo "DATE: $DATE_STAMP"
VERSION="v"$MAJOR"."$MINOR"."$PATCH"-intel"
echo "VERSION: $VERSION"
}


function make_tag()
{
# Generate tag in format of: zephyr-VERSION_MAJOR.VERSION_MINOR.PATCHLEVEL
# i.e. zephyr-v3.0.99-intel-<date>   zephyr-3.0.99-intel-20220524


TAG=$REPO_DIR"-"$VERSION"-"$DATE_STAMP
echo "TAG: $TAG"

# See if the default is good, and if not, create one that is.
echo "Checking to see if tag already exists."
FOUND=FALSE
while true; do
    CHECK=`git show-ref --tags | egrep "refs/tags/$TAG"`
    if [ "$CHECK" ] ; then
        FOUND="TRUE"
    else
        FOUND="FALSE"
    fi
    if [  "$FOUND" == "TRUE" ]; then
       echo "TAG $TAG already exists. You need to do sumthin sumthin 'bout that."
       exit
    elif [ "$FOUND" == "FALSE" ]; then
        echo "No pre-existing tag. Good to go."
        break
    fi
done

git tag -a -m "$TAG" $TAG
#git push origin $TAG
}

echo; echo
echo "WORKDIR: $WORKDIR"
echo "REPO_DIR: $REPO_DIR"

# Set up WORKDIR, if it doesn't already exist
if [ ! -d $WORKDIR ]; then
    mkdir -p $WORKDIR
    chmod 777 $WORKDIR
fi

cd $WORKDIR

clone_repo
read_version
make_tag
echo
echo "Tag Created: $TAG"
git --no-pager show $TAG
echo

while true
   do
     read -r -p "PUSH THE TAG? Y/N: " choice
     case "$choice" in
         n|N) echo "NOT PUSHING TAG. Bye!"
              exit
              ;;
         y|Y) echo "PUSHING THE TAG."
              git push origin $TAG
              break
              ;;
         *) echo "Wut? Choose Y/n";;
     esac
   done
