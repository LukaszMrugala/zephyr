#!/bin/bash
# Zephyr CI Self-Test Script, cvondra
#   - Runs Zephyr DevOps parallel pipeline (merge-request-validation) on a set of commits & expected status.
#   - Intended to be run periodicially to check CI health & qualify new build environments
# Pre-reqs:
#   0. run from shell of Jenkins main instance
#   0. Configured JENKINS_USER_ID & JENKINS_API_TOKEN for your Jenkins user
#   0. Configure SRC_REPO_URL & commit shas test-matrix below

# MUST CONFIGURE THESE!!!
export JENKINS_USER_ID=<your_jenkins_username>
export JENKINS_API_TOKEN=<your_jenkins_auth_token>

export JENKINS_JOB=zephyr-production/merge-request-validation
export SRC_REPO_URL=ssh://git@gitlab.devtools.intel.com:29418/zephyrproject-rtos/zephyr.git
export JENKINS_URL=http://127.0.0.1:8080
export JENKINS_JAR=/tmp/jenkins-cli.jar

# get jenkins cli
wget -q --no-proxy $JENKINS_URL/jnlpJars/jenkins-cli.jar -O $JENKINS_JAR

# jenkins cli build wrapper
#   params:
#     $1 = commit, branch or tag to build
#     $2 = expected result code (0=pass)
#   env (must be exported before call)
#     JENKINS_JAR = location of jenkins-cli.jar
#     JENKINS_URL = http://<jenkins-instance>
#     JENKINS_JOB = name of jenkins job on instance above
#     SRC_REPO_URL = git url, eg: ssh://git@gitlab.devtools.intel.com:29418/<your repo>
function jenkins_cli_build () {
	echo "building $1 (expected result: $2)..."
	java -jar "$JENKINS_JAR" -s "$JENKINS_URL" build "$JENKINS_JOB" \
		-p overrideSourceRepo="$SRC_REPO_URL" -p overrideSourceBranch="$1" -f
		BUILD_RESULT="$?"
		echo "    build result: $BUILD_RESULT"
	if [ "$BUILD_RESULT" != "$2" ]; then
		echo "    UNEXPECTED RESULT: $BUILD_RESULT (expected $2)"
	else
		echo "    RESULT: $BUILD_RESULT (expected $2)"
	fi
}
#
# Zephyr CI Self-Test
#   known-cases for WW05 2021, earliest first
#			<commit>                                 <exp. result>  <note or link>
jenkins_cli_build	fc1b5de4c307a97023520f27058f19db09c4face	0	#https://buildkite.com/zephyr/zephyr/builds/17893
jenkins_cli_build	99a4af6c4ae8183fc117b8a2760b309ac7f51231	0	#https://buildkite.com/zephyr/zephyr/builds/19487
jenkins_cli_build	30de4b5dd95271d1451f98b7f8f139ed1f740480 	1	#https://buildkite.com/zephyr/zephyr/builds/19496
jenkins_cli_build	d4666f537cc642e5e0618e4143a263e4979c33a5	1 	#https://buildkite.com/zephyr/zephyr/builds/19531
jenkins_cli_build	0cafde63549ac9a3d87f43824b0ff2390d6ca223	0	#https://buildkite.com/zephyr/zephyr/builds/19532
jenkins_cli_build	016b580bebc1f3051b0015e52f29f50ca6bef445 	0
jenkins_cli_build	c14da53772366cde8e42f3e3b59cf7f4db7ce8e4	0
jenkins_cli_build	1778e117d77c929ba6eb7dc74ab03041dcbb36b3	0
jenkins_cli_build	c07bb77247f8690cb3060195ccc14142e34a7206	0
jenkins_cli_build	6a012301e6ab34153aa2342687f5c26e79fa4b3a	0
jenkins_cli_build	95712bd4988930760cddd95ad7c3fc4065ebccbb	0
jenkins_cli_build	3740f6063148c0510ecaa207031a4f0e6c3bc894	0
jenkins_cli_build	941af213d3f074d060d60184af80403dbfe5913e	0
jenkins_cli_build	ea2ab69cf57f08d62f7a62ae139c58ea762c3888	0
