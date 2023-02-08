#!/bin/bash

#
#  Tagging script.
#  - Simply creates a tag for the v1.14-branch-intel branch.
#  - Can be used anytime you just need to tag in the 
#     zephyr-1.14.1-intel-rc<x>-ww<xx.x.x> format.
#  - Typically used to generate and push the tag after the atuomated 
#    merge happens with a gated push.
#  
######################################################################


export ZEPHYR_BRANCH_BASE=v1.14-branch-intel
#export WORKDIR=/srv/build
export WORKDIR=/srv/tgraydon

REPO_DIR="zephyr"
BRANCH="v1.14-branch-intel"
REPO_URL="ssh://git@gitlab.devtools.intel.com:29418/zephyrproject-rtos/$REPO_DIR"

TAG=""


function clone_repo()
{
# Nuke pre-existing repo, if any.
if [ -d $REPO_DIR ]; then
    echo "Nuking pre-existing zephyr repo."
    rm -rf  $REPO_DIR
    echo -e "Done\n"
fi

git clone $REPO_URL $REPO_DIR
cd $REPO_DIR

# Checkout the branches. Assumes that both branches exist.
echo "Checking out $BRANCH"
if ! git checkout origin/$BRANCH -b $BRANCH; then
    echo "Can't find a $BRANCH branch!"
    exit 1
fi
}


function get_rc()
{
RC=`echo $EXTRA | awk -F "-" '{print $2}'`
echo "RC: $RC"
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
get_rc
get_workweek
make_tag
echo "Tag Created: $TAG"
