#!/bin/bash
set -e

#
#  Merge automation script for:
#   * master-intel
#   * v1.14-branch-intel
#   * testsuite-intel
#  - Script attempts to merge the upstream branch into the *-intel branch
#  - Merge conflicts cause exit and manual intervention is required to resolve.
#  - If sanitycheck fails, manual intervetion is required.
#  - No sanitycheck is run for testsuite, nor do we tag that branch.
#
#    GATE should ALWAYS block a tag and push.
#
#    BLIND = true will skip sanity check and just merge, tag if applicable, and push. This will allow a run that just does a plain merge
#    without having to run sanity check first. This differs from FORCE in that FORCE will run sanitycheck, then push even if there's failures.
#
#    FORCE is used to ONLY bypass a bad sanitycheck in special cases where we want to always run sanity but
#    don't want to block the push. For example a branch where we want to know what sanitycheck looks like but we
#    always want to push the merge regardless. Special case situations.
#
#    TESTS will let you run a subset of sanitycheck. i.e. Just qemu_x86 or just native_posix or XYZ platform only.
#
#    Default is to run sanity, bail out on sanitycheck failures, and if sanity is good, push and tag (if applicable).
#    Passing just the branch gets you the defaults.
#
#    TODO: proper usage/help
#
####################################################################################################

# DEFAULTS
BRANCH=""
GATE="false"
FORCE="false"
TESTS=""

while [ "$1" != "" ]; do
    case $1 in
        -b | --branch)          shift
                                BRANCH="$1"
                                ;;
        -g | --gate )           shift
                                GATE="$1"
                                ;;
        -f | --force )          shift
                                FORCE="$1"
                                ;;
        -t | --tests )          shift
                                TESTS="$1"
                                ;;
        -m | --blind)           shift
                                BLIND="$1"
                                ;;
        *)                      echo "You gave me a weird option of $1. Check your options."
                                exit 1
                                ;;
    esac
    shift
done
echo

if [ "$BRANCH" == "" ]; then
    echo "You must at least specify the branch.
    i.e. ./local_merge.sh -b <branch>
    ./local_merge.sh -b master
     Use master for master-intel, v1.14 for v1.14-branch-intel, or testsuite for testsuite-intel."
    exit 1
fi

echo "Branch: $BRANCH"
echo "GATE: $GATE"
echo "If TESTS is empty, running ALL."
echo "TESTS: $TESTS"
echo "FORCE: $FORCE"
echo "BLIND: $BLIND"
echo

if [ "$BLIND" != "true" ] && [ "$BLIND" != "false" ]; then
    echo "BLIND is not true or false. You gave me: $BLIND. Setting to FALSE."
    BLIND="false"
fi

DO_TAG=""   # We will use this to exclude tagging for certain branches, like testsuite-intel.

if [ "$GATE" == "" ]; then
    echo "Gate is null. Will push."
    GATE="false"
elif [ "$GATE" == "true" ]; then
    echo "Gate is true. Gating the push."
elif [ "$GATE" == "false" ]; then
    echo "GATE is false. We will push."
else
    echo "Gate value must be true, false, or null. I don't know what to do. Bye."
    exit 1
fi

if [ "$FORCE" != "true" ] && [ "$FORCE" != "false" ]; then
    echo "FORCE must be either true or false. You gave me $FORCE."
    echo "Setting FORCE to FALSE for safety."
    FORCE="false"
fi
   
# Cannot GATE and FORCE at the same time. GATE will ALWAYS WIN.
if [ "$GATE" == "true" ] && [ "$FORCE" == "true" ]; then
    echo "GATE is true AND FORCE is true. You can't have it both ways, so we will GATE."
    FORCE="false"
fi
echo

# Set up some things based on which branch we are on.
if [ "$BRANCH" == "master" ]; then
    echo "Branch: master-intel."
    MERGE_SOURCE="master"
    MERGE_TO="master-intel"
    export ZEPHYR_BRANCH_BASE="$BRANCH"
    export SDK_VER=zephyr-sdk-0.11.4
    DO_TAG="true"
elif [ "$BRANCH" == "v1.14" ]; then
    echo "Branch: v1.14-branch-intel"
    MERGE_SOURCE="v1.14-branch"
    MERGE_TO="v1.14-branch-intel"
    export ZEPHYR_BRANCH_BASE="$BRANCH-branch-intel"
    export SDK_VER=zephyr-sdk-0.10.3
    DO_TAG="true"
elif [ "$BRANCH" == "testsuite" ]; then
    # This is always a blind merge.
    BLIND="true"
    echo "Branch: testsuite-intel"
    export ZEPHYR_BRANCH_BASE="$BRANCH-intel"
    MERGE_SOURCE="master"
    MERGE_TO="testsuite-intel"
    DO_TAG="false" # We don't take testsuite-intel
else
    echo "You gave me a weird branch. Must be v1.14, master, or testsuite. Check your args."
    echo "i.e. ./merge.sh v1.14 or ./merge.sh master or ./merge.sh testsuite"
    exit 1
fi

echo "SOURCE: $MERGE_SOURCE"
echo "MERGE_TO: $MERGE_TO"

export SCRIPT_PATH=$WORKSPACE/ci/modules
#export SCRIPT_PATH=$WORKSPACE/ci/scripts/prod

export PYTHONPATH="$(find /usr/local_$ZEPHYR_BRANCH_BASE/lib -name python3.* -print)/site-packages:$(find /usr/local_$ZEPHYR_BRANCH_BASE/lib64 -name python3.* -print)/site-packages"
export PATH=/usr/local_$ZEPHYR_BRANCH_BASE/lib/python3.6/site-packages/west:/usr/local_$ZEPHYR_BRANCH_BASE/bin:$PATH

ZEPHYRPROJECT_DIR="zephyrproject"
REPO_DIR="zephyr"
export ZEPHYR_BASE=$WORKSPACE/$ZEPHYRPROJECT_DIR/zephyr

# For testing
#REPO_URL="ssh://git@gitlab.devtools.intel.com:29418/tgraydon1/$REPO_DIR"

# PRODUCTION
REPO_URL="ssh://git@gitlab.devtools.intel.com:29418/zephyrproject-rtos/$REPO_DIR"

function make_tag()
{
set +e
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
    if [ "$CHECK" ]; then
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
set -e
}

function run_sanity()
{
if [ -f $SCRIPT_PATH/sanitycheck-runner.sh ]; then
    if [ "$TESTS" != "" ]; then
        bash -c "$SCRIPT_PATH/sanitycheck-runner.sh 1 1 -p$TESTS"
    else
        bash -c "$SCRIPT_PATH/sanitycheck-runner.sh 1 1"
    fi
else
    echo "Can't find the sanitycheck-runner.sh script. Quitting."
    exit 1
fi
}

function do_merge()
{
set +e
cd $ZEPHYRPROJECT_DIR
echo "Cloning repo $REPO_URL"
git clone $REPO_URL $REPO_DIR --branch "$MERGE_SOURCE"
echo
cd $REPO_DIR

source_head=$(git rev-parse HEAD)

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
set -e
}

function do_sanity()
{
export ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/$SDK_VER
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export CCACHE_DISABLE=1
export USE_CCACHE=0

export SANITY_OUT=$ZEPHYR_BASE/sanity-out
SC_STATUS_FILE=$SANITY_OUT/sc_status
export PATH=$ZEPHYR_BASE/scripts:"$PATH"

# echo critical env values
###############################################################################
echo ZEPHYR_SDK_INSTALL_DIR=$ZEPHYR_SDK_INSTALL_DIR
echo ZEPHYR_TOOLCHAIN_VARIANT=$ZEPHYR_TOOLCHAIN_VARIANT
echo ZEPHYR_BRANCH_BASE=$ZEPHYR_BRANCH_BASE
echo ZEPHYRPROJECT_DIR=$ZEPHYRPROJECT_DIR
echo "ZEPHYR_BASE: $ZEPHYR_BASE"
echo PYTHONPATH=$PYTHONPATH
echo PATH=$PATH
echo cmake="path:$(which cmake), version: $(cmake --version)"
echo http_proxy=$http_proxy
echo https_proxy=$https_proxy
echo no_proxy=$no_proxy

# Check for the SDK required
echo "Checking for installed SDK."
if [ ! -d $ZEPHYR_SDK_INSTALL_DIR ]; then
   echo -e "I cannot find the SDK at $ZEPHYR_SDK_INSTALL_DIR! Quitting!"
    exit 1
else
    echo "SDK exists."
fi

echo -e "Initializing West.\n"
west init -l
west update
echo
#pip3 install --user -r scripts/requirements.txt

source zephyr-env.sh

set +e   # Don't catch sanitycheck-runner errors.

run_sanity "$TESTS"

echo
echo "Back from sanitycheck-runner."

# Pause to allow things to finish writing out and settle before trying to run the parser.
sleep 10

echo "Calling $SCRIPT_PATH/get_failed.py"
python3 $SCRIPT_PATH/get_failed.py $SANITY_OUT

set -e   # Now put it back

# If the status files doesn't exist, we failed out of get_failed.py somewhere. If we don't fail out correctly from get_failed.py, try to catch that.
if [ -f "$SC_STATUS_FILE" ]; then
    SC_STATUS=`sed -n '1p' $SC_STATUS_FILE`
    echo "SC_STATUS: $SC_STATUS"
    if [ "$SC_STATUS" == "FAILED" ]; then
        echo "SanityCheck is FAILED. Manual intervention is required."
        exit 1
    fi
else
    echo "Can't find the status file! Something went wrong. Manual intervention required."
    exit 1
fi
}

function do_push()
{
set +e
echo "Pushing the merge."
if ! git push origin HEAD:$MERGE_TO; then
    echo "Push failed for some reason. Manual intervention needed."
    exit 1
fi
set -e
}

function print_commits()
{
echo
echo "$MERGE_SOURCE HEAD: $source_head"
echo "$MERGE_TO HEAD: $head_before"
echo -e "Merge commit: $head_after\n"
}

# Set up WORKDIR, if it doesn't already exist
if [ ! -d $WORKDIR ]; then
    mkdir -p $WORKDIR
    chmod 777 $WORKDIR
fi

# Create the zephyrproject directory
mkdir $ZEPHYRPROJECT_DIR

do_merge

if [ "$BLIND" == "true" ] && [ "$GATE" == "true" ]; then
    echo "BLIND: $BLIND"
    echo "GATE: $GATE"
    echo "GATE is true so we are done. NOT PUSHING. Follow up manually if necessary."
    print_commits
    exit 1
elif [ "$BLIND" == "true" ] && [ "$GATE" == "false" ]; then
    echo "BLIND: $BLIND"
    echo "GATE: $GATE"
    do_push
    if [ "$DO_TAG" == "true" ]; then
        make_tag
    fi
elif [ "$BLIND" == "false" ]; then
    echo "BLIND is FALSE"
    do_sanity
    if [ "$GATE" == "true" ]; then
        echo "GATE is true so we are done. NOT PUSHING. Follow up manually if necessary."
        print_commits
        exit 1
    elif [ "$GATE" == "false" ]; then
        if [ "$SC_STATUS" == "CLEAN" ]; then
            echo "SC_STATUS: $SC_STATUS and FORCE: $FORCE"
            do_push
            if [ "$DO_TAG" == "true" ]; then
                make_tag
            fi
        fi
        if [ "$SC_STATUS" == "FAILED" ] && [ "$FORCE" == "true" ]; then
            echo "SC_STATUS: $SC_STATUS and FORCE: $FORCE"
            do_push
            if [ "$DO_TAG" == "true" ]; then
                make_tag
            fi
        fi
    fi
fi

print_commits
echo "DONE!"
