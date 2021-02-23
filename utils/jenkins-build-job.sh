#!/bin/bash

# jenkins-build-job.sh <jenkins
#   bash method for starting a job on LOCALHOST jenkins with parameters
#   0.) expects JENKINS_USER_ID & JENKINS_API_TOKEN env vars to be set
#   1.) blocks until job completes
#   2.) returns build status


export JENKINS_URL=http://127.0.0.1:8080
export JENKINS_JAR=/tmp/jenkins-cli.jar

#get jenkins cli
wget -q --no-proxy $JENKINS_URL/jnlpJars/jenkins-cli.jar -O $JENKINS_JAR

java -jar $JENKINS_JAR -s $JENKINS_URL build $1 -f
