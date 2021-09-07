# Zephyr DevOps Jenkins Configuration Specification
**Purpose**
This docs aims to serve as as standard-operating-procedure for deploying & configuring Jenkins for internal zephyr production use.

**Target Audience**
DevOps Engineers

**Doc Change Process**
* Minor changes & documentation improvements may be submitted by anyone. 
* Major policy or configuration changes should be RFC'd @ FMOS_DevOps first.

**NOTE THIS DOC IS WIP & CHANGE POLICY IS NOT ACTIVE**

## Zephyr DevOps Jenkins Configuration Standard

### 0. Jenkins Service Options + SSL Config

#### Request/download .jks from https://certs.intel.com/aperture**

#### Edit /etc/default/jenkins:

    JENKINS_ARGS="--webroot=/var/cache/$NAME/war --httpPort=$HTTP_PORT --httpsPort=8443 --httpsKeyStore=/srv/jenkins/ssl/<machine>.intel.com.jks --httpsKeyStorePassword=<passwd>

#### Re-direct port 443 connections to 8443
    sudo iptables -I INPUT 1 -p tcp --dport 8443 -j ACCEPT
    sudo iptables -I INPUT 1 -p tcp --dport 8080 -j ACCEPT
    sudo iptables -I INPUT 1 -p tcp --dport 443 -j ACCEPT
    sudo iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
    sudo iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080
    sudo iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 8443
    sudo apt-get install iptables-persistent

### 1. System-Wide Environment Variables

**Rule:** Don't use system-wide environment variables (those specified in the "Manage Jenkins" configuration). Env should always been handled in the pipeline code or job runners.

**Exception:** Site or deployment specifics such as locale, for example:
~~~~
LANG=en_US.UTF-8
PYTHONIOENCODING=UTF-8
LANGUAGE=en_US:en
LC_ALL=en_US.UTF-8
~~~~

### 2. Plugins

**Rule:** In order to reduce DevOps cycles required for updates & overall CI execution risk, only install plug-ins from [approved list](https://gitlab.devtools.intel.com/zephyrproject-rtos/devops/infrastructure/ansible-playbooks/-/blob/current/jenkins-plugins.yaml)

### 3. Users/Security

**Option 1 - IT VAS + Jenkins PAM**

If Jenkins is executing on a system with functional IT VAS, select 'Unix user/group database' as Jenkins Security Realm. This will restrict logins to accounts in /etc/passwd. This means that users wishing to access the Jenkins UI must have first logged in over SSH for VAS to pickup their idsid & create a /etc/passwd entry.

**Option 2 - IT SAML**

TBD...

### 4. Jenkins Job Statuses

Jenkins implements status conditions to represent the global status of a build: SUCCESS, UNSTABLE, FAILURE, NOT_BUILT or ABORTED. Zephyr DevOps maps these statues to Zephyr CI/Automation jobs as follows:

**SUCCESS** - All tasks defined by job executed & returned success exit codes.

**UNSTABLE** - All tasks defined by job executed but at least one step returned non-zero exit code.

**FAILURE** - At least one task defined by job failed to execute.

**ABORTED** - Job was aborted either by a user or timeout.

**NOT_BUILT** - Unused currently.