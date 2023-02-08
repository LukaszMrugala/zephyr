#!/bin/bash

#
#  Weekly Tagging script.
#  - Used by Jenkins to tag the v1.14-branch-intel branch if there are 
#    changes since the last automated merge from upstream.
#  - Runs on Wednesdays, for use by EHL. 
#  
######################################################################

export ZEPHYR_BRANCH_BASE=v1.14-branch-intel

REPO_DIR="zephyr"
BRANCH="v1.14-branch-intel"
TAG_STATUS=tag_status

REPO_URL="ssh://git@gitlab.devtools.intel.com:29418/zephyrproject-rtos/$REPO_DIR"

TAG=""

if [ -f $TAG_STATUS ]; then
    rm -f $TAG_STATUS 
fi


function clone_repo()
{

git clone $REPO_URL $REPO_DIR
cd $REPO_DIR

# Checkout the branch.
echo "Checking out $BRANCH"
if ! git checkout origin/$BRANCH -b $BRANCH; then
    echo "Can't find a $BRANCH branch!"
    exit 1
fi
}


function get_rc()
{
RC=`echo $EXTRA | awk -F "-" '{print $2}'`
echo
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
    elif [ $string == "EXTRAVERSION" ]; then
        EXTRA=$value
   fi
done < VERSION
VERSION="v"$MAJOR"."$MINOR"."$PATCH"-"$EXTRA
}


latest_tag()
{
# Find the most recent merge tag and get the commit id
LATEST_TAG=`git describe --abbrev=0`
TAG_COMMIT=`git show $LATEST_TAG | grep commit | awk '{print $2}'`
echo "LATEST TAG: $LATEST_TAG"
echo "TAG COMMIT: $TAG_COMMIT" 
}


function get_workweek()
{
# Get the workweek and workday for the tag
WW="ww"$(date +%V)
WD=$WW"."$(date +%u)
}

function make_tag()
{
# Generate tag in format of: zephyr-VERSION_MAJOR.VERSION_MINOR.PATCHLEVEL-EXTRAVERSION-ww.wd.p
# i.e. zephyr-v1.14.1-intel-rc3-ww11.3.2

# Get the workweek and workday for the tag
#WD="ww"$(date +%V)"."$(date +%u) 

TAG=$REPO_DIR"-"$VERSION"-"$WD

# See if the default is good, and if not, create one that is.
FOUND=FALSE
while true; do
    CHECK=`git show-ref --tags | egrep "refs/tags/$TAG"`
    if [ "$CHECK" ] ; then
        FOUND="TRUE"
    else
        FOUND="FALSE"
    fi
    if [  "$FOUND" == "TRUE" ]; then
        IFS=. VER=(${WD}) 
        IFS=
        NUM=${#VER[@]}
        if [ "$NUM" == "2" ]; then
            WD=$WD.1
            TAG=$REPO_DIR"-"$VERSION"-"$WD
        elif [ "$NUM" == "3" ]; then
            ((index=$NUM-1))
            ((VER[$index]++))
            WD=$( IFS=$'.'; echo "${VER[*]}" )  
            TAG=$REPO_DIR"-"$VERSION"-"$WD
            IFS=
        fi
    elif [ "$FOUND" == "FALSE" ]; then
        break
    fi
done 

echo "Tag: $TAG"
git tag -a -m "$TAG" $TAG
git push origin $TAG
}


clone_repo
read_version
get_rc
latest_tag
get_workweek


head_rev=$(git rev-parse HEAD)
echo "HEAD: $head_rev"

if [ $head_rev == $TAG_COMMIT ]; then
    #echo "There is nothing new on the $BRANCH branch. NOT TAGGING."
    echo "Weekly_tagger_v1.14-branch-intel: no changes for this week. NO TAG FOR $WW." > $TAG_STATUS
else
    echo -e "There are changes on the v1.14-branch-intel branch. Tagging.\n"
    make_tag
    echo -e "Weekly_tagger_v1.14-branch-intel: New changes for $WW\n" > $TAG_STATUS
    echo "NEW TAG: $TAG" >> $TAG_STATUS
fi
echo

while read -r line; do 
    echo $line
done < $TAG_STATUS
