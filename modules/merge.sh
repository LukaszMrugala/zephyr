#!/bin/bash
set -e

#
#  Merge automation script for the master-intel and v1.14-branch-intel merges.
#  - Script attempts to merge the upstream branch into the *-intel branch
#  - Merge conflicts cause exit and manual intervention is required to resolve.
#  - If sanitycheck fails, manual intervetion is required.
#
####################################################################################################

# v1.14 or master
BRANCH="$1"
# true or false
GATE="$2"
# Runs subset of tests: qemu_x86, native_posix, etc.
TESTS="$3"


echo "GATE is: $GATE"
echo "TESTS: $TESTS"


if [ "$GATE" == "" ]; then
    echo "Gate is null. Will push and tag."
    GATE="false"
elif [ "$GATE" == "true" ]; then
    echo "Gate is true. Gating the push and tag."
elif [ "$GATE" == "false" ]; then
    echo "GATE is false. We will push and tag."
else
    echo "Gate value must be true, false, or null. I don't know what to do. Bye."
    exit 1
fi

# Set up some things based on which branch we are on.
if [ "$BRANCH" == "master" ]; then
    echo "Branch is master."
    export ZEPHYR_BRANCH_BASE="$BRANCH"
    export SDK_VER=zephyr-sdk-0.11.3
    MERGE_SOURCE="master"
    MERGE_TO="master-intel"
elif [ "$BRANCH" == "v1.14" ]; then
    echo "Branch is v1.14"
    export ZEPHYR_BRANCH_BASE="$BRANCH-branch-intel"
    export SDK_VER=zephyr-sdk-0.10.3
    MERGE_SOURCE="v1.14-branch"
    MERGE_TO="v1.14-branch-intel"
else
    echo "You gave me a weird branch. Must be either "v1.14" or" master." Check your args."
    echo "i.e. ./local_merge.sh v1.14 or ./local_merge.sh master"
    exit 1
fi

echo "SOURCE: $MERGE_SOURCE"
echo "MERGE_TO: $MERGE_TO"

export ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/$SDK_VER
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export CCACHE_DISABLE=1
export USE_CCACHE=0
export SCRIPT_PATH=$WORKSPACE/ci/modules

export PYTHONPATH="$(find /usr/local_$ZEPHYR_BRANCH_BASE/lib -name python3.* -print)/site-packages:$(find /usr/local_$ZEPHYR_BRANCH_BASE/lib64 -name python3.* -print)/site-packages"
export PATH=/usr/local_$ZEPHYR_BRANCH_BASE/lib/python3.6/site-packages/west:/usr/local_$ZEPHYR_BRANCH_BASE/bin:$PATH

ZEPHYRPROJECT_DIR="zephyrproject"
REPO_DIR="zephyr"
export ZEPHYR_BASE=$WORKSPACE/$ZEPHYRPROJECT_DIR/zephyr
export SANITY_OUT=$ZEPHYR_BASE/sanity-out
SC_STATUS_FILE=$SANITY_OUT/sc_status
export PATH=$ZEPHYR_BASE/scripts:"$PATH"

echo "ZEPHYR_BASE: $ZEPHYR_BASE"

REPO_URL="ssh://git@gitlab.devtools.intel.com:29418/zephyrproject-rtos/$REPO_DIR"

# echo critical env values
###############################################################################
echo ZEPHYR_SDK_INSTALL_DIR=$ZEPHYR_SDK_INSTALL_DIR
echo ZEPHYR_TOOLCHAIN_VARIANT=$ZEPHYR_TOOLCHAIN_VARIANT
echo ZEPHYR_BRANCH_BASE=$ZEPHYR_BRANCH_BASE
echo ZEPHYRPROJECT_DIR=$ZEPHYRPROJECT_DIR
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
# i.e. zephyr-v1.14.1-intel-rc3-ww11.3.2 or zephyr-v2.3.0-rc1-ww22.3

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

if [ "$EXTRA" == "" ]; then
    VERSION="v"$MAJOR"."$MINOR"."$PATCH
else
    VERSION="v"$MAJOR"."$MINOR"."$PATCH"-"$EXTRA
fi

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
if [ -f $SCRIPT_PATH/sanitycheck-runner.sh ]; then
    if [ "$TESTS" != "" ]; then
        echo "Tests is not empty"
        bash -c "$SCRIPT_PATH/sanitycheck-runner.sh 1 1 -p$TESTS"
    else
        bash -c "$SCRIPT_PATH/sanitycheck-runner.sh 1 1" 
    fi
else
    echo "Can't find the sanitycheck-runner.sh script. Quitting."
    exit 1
fi
}

# Check for the SDK required
echo "Checking for installed SDK."
if [ ! -d $ZEPHYR_SDK_INSTALL_DIR ]; then
    echo -e "I cannot find the SDK at $ZEPHYR_SDK_INSTALL_DIR! Quitting!"
    exit 1
else
    echo "SDK exists."
fi

# Create the zephyrproject directory
mkdir $ZEPHYRPROJECT_DIR
cd $ZEPHYRPROJECT_DIR
echo "Cloning repo $REPO_URL"
git clone $REPO_URL $REPO_DIR --branch "$MERGE_SOURCE"
echo

cd $REPO_DIR

echo "Getting $MERGE_TO"
if ! git checkout origin/$MERGE_TO -b $MERGE_TO; then
    echo "Couldn't check out $MERGE_TO branch! Dying on this hill"
    exit 1
fi

head_before=$(git rev-parse HEAD)

if ! git merge --no-ff $MERGE_SOURCE $MERGE_TO -m "Merge $MERGE_SOURCE to $MERGE_TO"; then
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

source zephyr-env.sh
set +e
run_sanity "$TESTS"

echo
echo "Back from sanitycheck-runner."

echo "Current dir: $PWD"
echo "WORKSPACE: $WORKSPACE"
echo "SCRIPT_PATH: $SCRIPT_PATH"
echo
echo "SANITY_OUT: $SANITY_OUT"
echo "Calling $SCRIPT_PATH/get_failed.py"
sleep 20
#set +e

python3 $SCRIPT_PATH/get_failed.py $SANITY_OUT 

set -e

# If the status files doesn't exist, we failed out of get_failed.py somewhere. If we don't fail out correctly from get_failed.py, try to catch that.
if [ -f "$SC_STATUS_FILE" ]; then
    SC_STATUS=`sed -n '1p' $SC_STATUS_FILE`
    echo "SC_STATUS: $SC_STATUS"
    if [ "$SC_STATUS" == "FAILED" ]; then
        echo "SanityCheck is FAILED. Manual intervention is required."
        exit 1
    else
        echo "Proceeding to push and tag."
    fi
else
    echo "Can't find the status file! Something went wrong. Manual intervention required."
    exit 1
fi
echo

if [ "$GATE" == "true" ]; then
    echo "You have selected to gate the push and merge, so we are done now. Follow up manually."
    exit 
elif [ "$GATE" == "false" ]; then
    echo "We are not gated, so pushing the merge and tagging. (Not really, gated for testing.)"
#    if ! git push origin HEAD:$MERGE_TO; then
#        echo "Merge/tag push failed for some reason. Manual intervention needed."
#       exit 1
#    fi

    echo "Tagging Branch: $MERGE_TO. (Also not really.)"
 
#    if ! make_tag; then
#        echo "Something failed when tagging. Manual intervention required. Quitting!"
#        exit 1
#    fi

#    git push origin $TAG
fi

echo "DONE!"
