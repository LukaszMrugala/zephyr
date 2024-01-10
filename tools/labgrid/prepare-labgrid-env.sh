#!/bin/bash
# Check connection to each labgrid PLACE defined in labgrid-$coordinator

# Variables
INSTALL=""
LABGRID_COORDINATOR=""
P_SCOPE="smoke"
USE_PROXY=false
IS_ROOT=false
LOCKED_PLACES=()  # locked places that will not be touched
POWER_PLACES=()   # power available places
SSH_PLACES=()     # ssh available places
FAILED_PLACES=()  # failed places
IGK_PROXY="admin-fmos.igk.intel.com"
DOCKER_IGK_HOST="docker-igk-host"
HF_PROXY="admin-fmos.hf.intel.com"
DOCKER_HF_HOST="docker-host"

while getopts ":hi:l:p:s:" option; do
    case $option in
        h) # Display Help
            echo "Labgrid automation script will prepare the environment for the user."
            echo
            echo "Syntax: prepare-labgrid-env.sh [-h|-i|-l|-p|-s]"
            echo "options:"
            echo "-h     Help."
            echo "-i     Download labgrid repository and install labgrid with pip. Default: false"
            echo "-l     Labgrid coordinator to which connection is requested. Required."
            echo "-p     Tell script to use proxy or not. Default: false"
            echo "-s     Test scope if set to 'full' full scope will be tested. Default: 'smoke'"
            echo
            exit;;
        i) # Install labgrid
            INSTALL=$OPTARG
            echo "INSTALL=$INSTALL";;
        l) # Labgrid coordinator IP
            LABGRID_COORDINATOR=$OPTARG
            echo "LABGRID_CORRDINATOR=$LABGRID_COORDINATOR";;
        p) # use proxy
            USE_PROXY=$OPTARG
            echo "USE_PROXY=$USE_PROXY";;
        s) # Scope
            P_SCOPE=$OPTARG
            echo "SCOPE=$P_SCOPE";;
        \?) # Invalid options
            echo "Error: Invalid option"
            exit;;
    esac
done

labgridCloneGithubRepo () {
    local labgrid_path=$1
    local labgrid_repository=$2
    printf "cloning labgird into %s\n" "$labgrid_path"
    git clone $labgrid_repository $labgrid_path
}

labgridInstall () {
    local labgrid_path=$1
    if $IS_ROOT; then
        printf "Installing labgrid in: %s\n" "$labgrid_path"
        cd "$labgrid_path" && /usr/bin/env python3 -m pip install .
    else
        pip install --proxy $http_proxy labgrid
    fi
    # check if labgrid was installed
    labgrid-client > /dev/null 2>&1
}

labgridSetStrictHostKeyChecking () {
    if $IS_ROOT; then
        for python_ver in $(ls /usr/local/lib | grep '^python*'); do
            labgrid_ssh_path="/usr/local/lib/$python_ver/dist-packages/labgrid/util/ssh.py"
            sed -i 's/"StrictHostKeyChecking=yes",/"StrictHostKeyChecking=no",/' $labgrid_ssh_path
        done
    else
        for python_ver in $(ls $HOME/.local/lib | grep '^python*'); do
            labgrid_ssh_path="$HOME/.local/lib/$python_ver/site-packages/labgrid/util/ssh.py"
            sed -i 's/"StrictHostKeyChecking=yes",/"StrictHostKeyChecking=no",/' $labgrid_ssh_path
        done
    fi
}

getLockedPlaces () {
    local coordinator=$1
    # Create list of acquired places so no acquired PLACE will be affected
    for locked_place in $($LABGRID_BIN -x $coordinator who | awk 'NR>1 { print $3 }'); do
        LOCKED_PLACES[${#LOCKED_PLACES[@]}]+=$locked_place
    done
}

checkConnection () {
    coordinator=$1
    place=$2
    proxy=$3
    echo -e "$LABGRID_BIN -x $coordinator $proxy -p $place ssh hostname"
    if $($LABGRID_BIN -x $coordinator $proxy -p $place ssh hostname > /dev/null 2>&1); then
        echo -e "\tSSH: \033[32mavailable\033[0m"
        SSH_PLACES[${#SSH_PLACES[@]}]+=$place
    else
        echo -e "\tSSH: \033[31munavailable\033[0m"
        FAILED_PLACES[${#FAILED_PLACES[@]}]+=$place
    fi
}

checkPower () {
    coordinator=$1
    place=$2
    proxy=$3
    if $($LABGRID_BIN -x $coordinator $proxy -p $place pw get | grep -q 'power'); then
        echo -e "\tPWR: \033[32mavailable\033[0m"
        POWER_PLACES[${#POWER_PLACES[@]}]+=$place
    else
        echo -e "\tPWR: \033[31munavailable\033[0m"
        FAILED_PLACES[${#FAILED_PLACES[@]}]+=$place
    fi
}

getConnectionState () {
    local coordinator=$1
    local place=$2
    if [[ "$USE_PROXY" = true ]]; then
        if $($LABGRID_BIN -x $coordinator -p $place show | grep -q $DOCKER_IGK_HOST); then
            proxy="-P ${IGK_PROXY}"
        elif $($LABGRID_BIN -x $coordinator -p $place show | grep -q $DOCKER_HF_HOST); then
            proxy="-P ${HF_PROXY}"
        fi
    else
        proxy=""
    fi
    if $($LABGRID_BIN -x $coordinator -p $place show | grep -q 'NetworkService' > /dev/null 2>&1); then
        checkConnection "$coordinator" "$place" "$proxy"
    else
        echo -e "\tSSH: \033[31munavailable\033[0m"
    fi
    if $($LABGRID_BIN -x $coordinator -p $place show | grep -q 'Power' > /dev/null 2>&1); then
        checkPower "$coordinator" "$place" "$proxy"
    else
        echo -e "\tPWR: \033[31munavailable\033[0m"
    fi
}

labgridLockUnlock () {
    local coordinator=$1
    local lockunlock=$2
    local place=$3
    if [[ $lockunlock = 'lock' ]]; then
        $LABGRID_BIN -x $coordinator -p $place lock --allow-unmatched > /dev/null 2>&1
    elif [[ $lockunlock = 'unlock' ]]; then
        $LABGRID_BIN -x $coordinator -p $place unlock > /dev/null 2>&1
    else
        printf "Provide lock/unlock!\n"
        echo 1
    fi
}

backupSshConfig () {
    if [[ -f "$_HOME/.ssh/config" ]]; then
        cp -b "$_HOME/.ssh/config" "$_HOME/.ssh/config-bkp"
    fi
}

configureSshConfig () {
    local coordinator=$1
    places=$2
    if ! [[ -f "$_HOME/.ssh" ]]; then
        mkdir -p "$_HOME/.ssh"
    else
        backupSshConfig
    fi
    printf "\nHost %s\n\tUser %s\n\tHostname %s\n" "$DOCKER_IGK_HOST" "$USER" "$IGK_PROXY" >> $_HOME/.ssh/config
    printf "\nHost %s\n\tUser %s\n\tHostname %s\n" "$DOCKER_HF_HOST" "$USER" "$HF_PROXY" >> $_HOME/.ssh/config
    for place in ${places[@]}; do
        place_user=$($LABGRID_BIN -x $coordinator -p $place show | awk '/username/ { print $2 }' | sed -e "s:'::g" -e "s:}::g")
        place_ip=$($LABGRID_BIN -x $coordinator -p $place show | awk '/address/ { print $3 }' | sed -e "s:'::g" -e "s:,::g")
        if [[ ! $place_user == "" && ! $place_ip == "" ]]; then
            printf "\nHost %s\n\tUser %s\n\tHostname %s\n" "$place" "$place_user" "$place_ip" >> $_HOME/.ssh/config
        fi
    done
    printf "\nHost *\n\tUser zephyr\n" >> $_HOME/.ssh/config
}

cleanup () {
    rm -rf $1
}

main () {
    local _PWD=$PWD
    local labgrid_path="$_PWD/labgrid-tmp"
    local labgrid_repo="https://github.com/labgrid-project/labgrid"
    if [[ $(whoami) == "root" ]]; then
        IS_ROOT=true
        _HOME=/root
        LABGRID_BIN=/usr/local/bin/labgrid-client
    else
        _HOME=$HOME
        LABGRID_BIN=labgrid-client
    fi
    set -e
    if [[ "$INSTALL" = true ]]; then
        if [[ ! $(labgrid-client > /dev/null 2>&1) ]]; then
            if $IS_ROOT; then
                labgridCloneGithubRepo $labgrid_path $labgrid_repo
            fi
            labgridInstall $labgrid_path
        else
            printf "\nLabgrid already installed in %s\n" "$(which labgrid-client)"
        fi
    else
        printf "\nLabgrid already installed in %s\n" "$(which labgrid-client)"
    fi
    # get places from labgrid $coordinator and store them in buffer
    for place in $($LABGRID_BIN -x $LABGRID_COORDINATOR places); do
        places[${#places[@]}]+=$place
    done
    # set stricthostkeyckeching to no
    labgridSetStrictHostKeyChecking
    # create ssh_config file for user
    configureSshConfig $LABGRID_COORDINATOR ${places[*]}
    set +e
    # get locked places
    getLockedPlaces $LABGRID_COORDINATOR
    # For each PLACE listed by labgrid check it availability over ssh
    # since some of duts/hosts does not have networkservice record
    # in this case iteration will fail
    if [ "$P_SCOPE" = "smoke" ]; then
        SCOPE=("${places[@]:0:5}")
        printf "Running smoke tests on first 5 places...\n"
    else
        SCOPE=("${places[*]}")
        printf "Testing full scope...\n"
    fi
    for place in ${SCOPE[@]}; do
        #check if PLACE is not acquired
        if [[ ! ${LOCKED_PLACES[*]} =~ "$place" ]]; then
            printf "%s:\n" "$place"
            # acquire PLACE for execution
            if labgridLockUnlock $LABGRID_COORDINATOR 'lock' $place; then
                getConnectionState $LABGRID_COORDINATOR $place
                # release resource
                labgridLockUnlock $LABGRID_COORDINATOR 'unlock' $place
            else
                printf "%s\033[31mnot supported\033[0m\n" "$place"
                FAILED_PLACES[${#FAILED_PLACES[@]}]+=$place
            fi
        fi
    done

    printf "\nOmitted places which were acquired by someone else:\n%s\n" "${LOCKED_PLACES[*]}"
    printf "\nSSH available places:\n%s\n" "${SSH_PLACES[*]}"
    printf "\nPower mgmt available places:\n%s\n" "${POWER_PLACES[*]}"
    printf "\nNot available places:\n%s\n" "${FAILED_PLACES[*]}"

    if [[ "$INSTALL" = true ]]; then
        cleanup $labgrid_path
    fi
}

main
