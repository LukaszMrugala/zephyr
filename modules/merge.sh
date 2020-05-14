#!/bin/bash

#
#  Merge automation script for the v1.14-branch -> v1.14-branch-intel merge
#  - Script attempts to merge the upstream v1.14-branch into the v1.14-branch-intel branch
#  - Merge conflicts cause exit and manual intervention is required to resolve.
#  - Merge push and tag push is currently gated pending a couple of changes that will follow shortly.
#  - Manual push of merge and tag is required after successful sanitycheck run.
#  - If sanitycheck fails, manual intervetion is required.
#
####################################################################################################

export ZEPHYR_BRANCH_BASE=v1.14-branch-intel
export SDK_VER=zephyr-sdk-0.10.3
export ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/$SDK_VER
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export CCACHE_DISABLE=1
export USE_CCACHE=0
export WORKDIR=/srv/build
export SCRIPT_PATH=$WORKSPACE/ci/scripts

export PYTHONPATH="$(find /usr/local_$ZEPHYR_BRANCH_BASE/lib -name python3.* -print)/site-packages:$(find /usr/local_$ZEPHYR_BRANCH_BASE/lib64 -name python3.* -print)/site-packages"
export PATH=/usr/local_$ZEPHYR_BRANCH_BASE/lib/python3.6/site-packages/west:/usr/local_$ZEPHYR_BRANCH_BASE/bin:$PATH

ZEPHYRPROJECT_DIR="zephyrproject"
REPO_DIR="zephyr"
export ZEPHYR_BASE=$WORKDIR/$ZEPHYRPROJECT_DIR/zephyr
export SANITY_OUT=$ZEPHYR_BASE/sanity-out
export PATH=$ZEPHYR_BASE/scripts:"$PATH"

MERGE_SOURCE="v1.14-branch"
MERGE_TO="v1.14-branch-intel"
REPO_URL="ssh://git@gitlab.devtools.intel.com:29418/zephyrproject-rtos/$REPO_DIR"

# echo critical env values
###############################################################################
echo ZEPHYR_SDK_INSTALL_DIR=$ZEPHYR_SDK_INSTALL_DIR
echo ZEPHYR_TOOLCHAIN_VARIANT=$ZEPHYR_TOOLCHAIN_VARIANT
echo ZEPHYR_BRANCH_BASE=$ZEPHYR_BRANCH_BASE
echo PYTHONPATH=$PYTHONPATH
echo PATH=$PATH
echo cmake="path:$(which cmake), version: $(cmake --version)"
echo http_proxy=$http_proxy
echo https_proxy=$https_proxy
echo no_proxy=$no_proxy

function make_tag()
{

if ! git fetch --tags; then
    echo "Wasn't able to fetch the tags. Manual intervention required."
    exit 1
fi

# Generate tag in format of: zephyr-VERSION_MAJOR.VERSION_MINOR.PATCHLEVEL-EXTRAVERSION-ww.wd.p
# i.e. zephyr-v1.14.1-intel-rc3-ww11.3.2

# Get the workweek and workday for the tag
WD="ww"$(date +%V)"."$(date +%u)

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
echo
VERSION="v"$MAJOR"."$MINOR"."$PATCH"-"$EXTRA

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

}

function run_sanity()
{
    bash -c "$SCRIPT_PATH/sanitycheck-runner.sh 1 1" || error=true
}

# Check for the SDK required
echo "Checking for installed SDK."
if [ ! -d $ZEPHYR_SDK_INSTALL_DIR ]; then
    echo -e "I cannot find the SDK at $ZEPHYR_SDK_INSTALL_DIR! Quitting!"
    exit 1
else
    echo "SDK exists."
fi

# Set up WORKDIR, if it doesn't already exist
if [ ! -d $WORKDIR ]; then
    mkdir -p $WORKDIR
    chmod 777 $WORKDIR
fi

cd $WORKDIR

# If repo dir already exists, move it. For testing and comparison, handy to have
# previous runs. Eventually we'll just nuke them.
if [ -d $ZEPHYRPROJECT_DIR ]; then
    STAMP=`date "+%Y%m%d_%T"`
    echo "Found an existing zephyrproject dir. Moving it."
    mv $ZEPHYRPROJECT_DIR $ZEPHYRPROJECT_DIR"_"$STAMP
    echo "Moved $WORKDIR/$ZEPHYRPROJECT_DIR to $WORKDIR/$ZEPHYRPROJECT_DIR"_"$STAMP"
fi

# Create the zephyrproject directory
mkdir $ZEPHYRPROJECT_DIR
cd $ZEPHYRPROJECT_DIR
git clone $REPO_URL $REPO_DIR
echo

cd $REPO_DIR

# Checkout the branches. Assumes that both branches exist.
echo "Getting $MERGE_SOURCE"
if ! git checkout origin/$MERGE_SOURCE -b $MERGE_SOURCE; then
    echo "Can't find a $MERGE_SOURCE branch!"
    exit 1
else
    echo "Getting $MERGE_TO"
    if ! git checkout origin/$MERGE_TO -b $MERGE_TO; then
        echo "Can't find a $MERGE_TO branch!"
        exit 1
    fi
fi

head_before=$(git rev-parse HEAD)

if ! git merge $MERGE_SOURCE $MERGE_TO -m "Merge $MERGE_SOURCE to $MERGE_TO"; then
    echo "E: $MERGE_SOURCE: automatic merge failed -- manual intervention needed"
    exit 1
fi

# Now we check to see if there is actually anything to merge.
# If HEAD revision hasn't changed, there was nothing new on the source branch.
head_after=$(git rev-parse HEAD)
echo "HEAD Before: $head_before"
echo "HEAD After: $head_after"

if [ $head_before == $head_after ]; then
    echo "There is nothing new on the $MERGE_SOURCE branch to merge."
    exit 0
else
    echo -e "Merge successful.\n"
fi
echo

echo -e "Initializing West.\n"
west init -l
west update
echo
#pip3 install --user -r zephyr/scripts/requirements.txt

source zephyr-env.sh
run_sanity

if ! python3 $SCRIPT_PATH/get_failed.py $SANITY_OUT; then
    echo "Failed to run the get_failed.py script. Giving up."
    exit 1
fi

echo
echo "Temporarily Gated Merge for Safety During Deployment of Job. Do the Manual Thing."
echo


#echo
#echo "Pushing the merge."
#if ! git push origin HEAD:$MERGE_TO; then
#    echo "Merge/tag push failed for some reason. Manual intervention needed."
#   exit 1
#fi

#echo "Tagging Branch: $MERGE_TO"
#
#if ! make_tag; then
#    echo "Something failed when tagging. Manual intervention required. Quitting!"
#    exit 1
#fi

#git push origin $TAG

