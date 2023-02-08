#!/bin/bash
# Sanitycheck CI Validation Script
# cvondra, Zephyr DevOps @ Intel
#
# This script uses the Jenkins CLI to trigger an arbitrary set of sanitycheck
# jobs with configurable parameters against git-history of a branch. The goal
# is to run mass validation of sanitycheck jobs under Jenkins, across commits
# for the purposes of end-to-end CI validation and/or populating CI history.
#
# While there are Jenkins plugins that do this, this script aims to be
# more self-contained & flexible.
#
# Although this script was written specifically to validate sanitycheck jobs,
# there's nothing sanitycheck-specific here & this code is likely useful for
# other automation & testing needs.
#
# Warning: This is a tool intended for use by DevOps engineers in a staging
# environment. You should:
# 1. Not be on production.
# 2. Have Jenkins admin credentials
# 3. Understand Jenkins file-system mechanics & be ok with  rm -rf in
#    /var/lib/jenkins/jobs/xxxxx
# 4. Your *own* test-jobs with disposable history
#    >>> All job history & artifacts will be deleted!
# 5. Not be on production. :-P
#
# Prerequisites:
#  0. Have created the jobs & tested them in Jenkins web-UI with the
#     expected range of parameters (if any)
#  0. Have a Jenkins token for your username on the master
#  0. Be in the shell of a jenkins master
#  0. Have sudo -u jenkins rights
#  0. Have a target repo & branch with git history that you wish to
#     test against.
#
# Instructions:
# 1. Clone the git repo & checkout branch
# 2. Set the commit depth you wish to test here:
export GIT_COMMIT_DEPTH=10
# 3. Confirm your Jenkins instance is accessible here:
export JENKINS_URL=http://127.0.0.1:8080
# 4. Configure your Jenkins username + token here
export JENKINS_USER_ID=<your Jenkins username>
export JENKINS_API_TOKEN=<your Jenkins token>
# 5. Set the target job names here:
export JOBS=(sanitycheck-test1 sanitycheck-test2 sanitycheck-test3)
# 6. Configure your job parameters below, (search for "STEP 6")
# 7. cd into the git repo directory & run:
#    sudo -u jenkins <path-to-this-script>/sanitycheck-ci-test.sh
# 8. Confirm jobs are staged & running in the Jenkins webUI
# 9. If there are errors or jobs do not start, check the Jenkins log for errors
###############################################################################
export JENKINS_JAR=/tmp/jenkins-cli.jar
if [ "$(whoami)" != "jenkins" ]; then
        echo "Script should be run as user jenkins, try sudo -u jenkins <this script>"
        exit -1
fi

#get last N commits, in reverse order
COMMITS=($(git log -n $GIT_COMMIT_DEPTH --reverse --pretty=format:"%H"))

#get jenkins cli
wget -q --no-proxy $JENKINS_URL/jnlpJars/jenkins-cli.jar -O $JENKINS_JAR

#wipe old job status & reset nextBuildNumber
for job in "${JOBS[@]}"
do
	rm -rf /var/lib/jenkins/jobs/$job/builds
	rm -rf /var/lib/jenkins/jobs/$job/htmlreports
	rm /var/lib/jenkins/jobs/$job/nextBuildNumber
	echo "1" > /var/lib/jenkins/jobs/$job/nextBuildNumber
	#reload jenkins job to capture disk changes
	java -jar $JENKINS_JAR -s $JENKINS_URL reload-job $job
done

for commit in "${COMMITS[@]}"
do
	for job in "${JOBS[@]}"
	do
###############################################################################
# STEP 6 - CONFIGURE YOUR JOB PARAMETERS HERE                                 #
###############################################################################
	        java -jar $JENKINS_JAR -s $JENKINS_URL build $job \
# example with commit	-p srcRepo=ssh://git@gitlab.devtools.intel.com:29418/zephyrproject-rtos/zephyr.git \
#  as parameter       	-p srcBranch=$commit
	done
done

