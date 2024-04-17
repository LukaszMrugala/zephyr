#!/bin/bash
install=false
user_installation=false
configure=false
test_labgrid=false
ssh_key_path=0
labgrid_coordinator=0
generate_report=false
report_location=0

options=$(getopt -l "help,configure,install,user-install,ssh-key:,labgrid-coordinator:,generate-report,report-location:,test-labgrid" -o "hcius:l:gr:t" -a -- "$@")

eval set -- "$options"
while true
do
case "$1" in
-h|--help) 
    echo "Help string will be printed here"
    exit 0
    ;;
-c|--configure)
    export configure=true
    ;;
-i|--install)
    export install=true
    ;;
-u|--user-install)
    export user_installation=true
    ;;
-s|--ssh-key)
    shift
    export ssh_key_path="$1"
    ;;
-l|--labgrid-coordinator)
    shift
    export labgrid_coordinator="$1"
    export LG_CROSSBAR="$labgrid_coordinator"
    ;;
-g|--generate-report)
    export generate_report=true
    ;;
-r|--report-location)
    shift
    export report_location="$1"
    ;;
-t|--test-labgrid)
    export test_labgrid=true
    ;;
--)
    shift
    break;;
esac
shift
done

# Check if ansible is available if not sourcing venv
if [[ ! -n "$VIRTUAL_ENV" ]]; then
    if [[ ! "$(which ansible)" ]]; then
        echo "ansible is not installed! install it with: apt-get install -y ansible or with pip install ansible"
        exit 1
    fi
    if [[ ! "$(which git)" ]]; then
        echo "git is not installed! install it with: apt-get install -y git"
        exit 1
    fi
    if [[ ! "$(which pip)" ]]; then
        echo "ansible is not installed! install it with: apt-get install -y python3-pip"
        exit 1
    fi
fi
# Install labgrid: global installation or user installation is supported
if [[ "$install" = true || "$user_installation" = true ]]; then
    ansible-playbook install-labgrid.yml -e "global_installation=$install" -e "user_installation=$user_installation"
fi

# Prepare var files and config files for user
if [[ ! "$labgrid_coordinator" = 0 ]]; then
    ansible-playbook prepare-labgrid.yml -e "labgrid_coordinator=$labgrid_coordinator"
fi

# Configure ssh config for user with data fetched from coordinator
if [[ "$configure" = true ]]; then
    if [[ "$ssh_key_path" = 0 ]]; then
        echo "Please provide ssh-key!"
        exit 1
    fi
    ansible-playbook configure-labgrid.yml -e "ssh_key_path=$ssh_key_path"
fi

# Test ssh connectiona and power management
if [[ "$test_labgrid" = true || "$generate_report" = true ]]; then
    ansible-playbook test-labgrid.yml -e "labgrid_coordinator=$labgrid_coordinator" -e "generate_report=$generate_report" -e "report_location=$report_location"
fi

echo "Done"
