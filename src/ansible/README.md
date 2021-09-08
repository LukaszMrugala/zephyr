# Zephyr DevOps Infrastructure Automation

This repo contains ansible playbooks that Zephyr DevOps uses to apply configuration templates across our physical & virtual infrastructure.

## How to run

    # clone DevOps Keys repo & run deploy_keys.sh
    git clone ssh://<teamforge-repo>/zdevops-keys
    cd zdevops-keys
    ./deploy_keys.sh

    # If your keys have passphrases, use ssh-agent to automate key-entry during playbook execution
    eval "$(ssh-agent -s)"
    ssh-add <your ssh identity>    

    # Install ansible - use python package to ensure latest version
    pip3 install --user cryptography==3.3.2
    pip3 install --user jinja2
    pip3 install --user --no-deps ansible==2.9.17
    
    # run ansible playbook
    ansible-playbook ansible-playbook -i <inventory> --limit=<pattern*> <playbook>
    # Where:
	<inventory> = File containing ansible_host definitions, key locations & group vars. See inventory.* in this repo.
	<limiter> = Limit all steps to this machine or group (specified in inventory), optional.

## Playbook Summaries

| playbook				| function                                                      |
|---------------------------------------|---------------------------------------------------------------|
| nativeBuild00-python-bootstrap.yaml	| Ansible requires python, bootstrap w/ raw ssh apt install	|
| nativeBuild01-distroDeps.yaml		| Zephyr required apt packages + setup of jenkins user & creds	|
| nativeBuild02-pythonDeps.yaml		| Python pkg installs, per branch. DELETES /usr/local_<branch>!	|
| nativeBuild03-sdk.yaml		| Manages SDK installation & which versions are active		|
| nativeBuild04-registerNodes.yaml	| Registers build agents/nodes with Jenkins master using CLI	|
| maint-apt-get-update-reboot.yaml	| Runs apt-get update/upgrade & then REBOOTS agent		|
| maint-disk-cleanup.yaml		| Skeleton for disk clean-up playbook. Use caution.		|
| maint-disk-space-check.yaml		| Checks disk-space on all agents & reports results		|
| maint-memtest.yaml			| Runs user-space memtest on all agents.			|
| maint-ping.yaml			| Pings agents							|
| gitlabRunner00-install.yaml		| Installs gitlab-runner from PPA & sets-up automation user     |
| gitlabRunner01-register.yaml		| Register runner with gitlab instance                          |
| dockersvc_01-setupDocker.yaml		| Install docker & prereqs                                      |
| dockersvc_02-setupSwarm.yaml		| Set up docker swarm nodes & enroll                            |                
| dockersvc_03-sanitycheckService.yaml	| Creates sanitycheck swarm service		                |       
| dockersvc_99-killSwarm.yaml		| Shutdown swarm service & unregister nodes                     |

