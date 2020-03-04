//Zephyr CI
//Internal Branches 
// This file defines configuration & infrastruture entry-points for Intel's
// internal Jenkins-Gitlab CI processes. This is the top-level configuration
// file that defines branches supported, targets build/test-infrastructure and
// performs initial checkout of srcBranch.

// This code is designed to be executed from a Jenkins master as a "Pipeline script" 
// job, triggered from a gitlab/hub webhook with source repo & branch-name params.
//
// You must configure this script to suit your branches & infrastructure!
//
// Instructions:
//
// Step 1: Define the CI repo URL
def ciRepoURL = "ssh://git@gitlab.devtools.intel.com:29418/zephyrproject-rtos/ci.git"

// Step 2: Define a unique job name to display in the CI pipeline, suggest $JOB_NAME to pickup Jenkins string:
def jobName = "${JOB_NAME}"

// Step 3: In branch-detect.groovy, see instructions for configuring your branches & SD mappings

//buildConfig map global- receives detected branchBase, SDK version, etc
def buildConfig= [:]

// begin pipeline on the CI master...
node('master') {
	skipDefaultCheckout()
	deleteDir()

	//clone *CI* repo & stash for use by build agents
	//  we're intentionally not using Jenkins internal git methods to keep 
	//  some poorly implemented plugins from latching onto our ci repo for 
	//  polling later in the job
	//
	sh "git clone --depth 1 --single-branch --branch branch-detect ${ciRepoURL} ci"        
	//stash ci repo for use by other agents
	stash name: 'ci'
	//load modules from ci.git
	def hwtest = load "${WORKSPACE}/ci/modules/hwtest-pipeline.groovy"
	def sanitycheck = load "${WORKSPACE}/ci/modules/hwtest-pipeline.groovy"
	def detect_branch = load "${WORKSPACE}/ci/modules/branch-detect.groovy"

	//Parameter processing
	// This pipeline is designed to be triggered via webhook with params
	// for source repo & source branch. These parameters can be overridden
	// in the Jenkins web UI using the "Build with Parameters" option.
	// In this section, we start with default params from Jenkins & then 
	// override with webhook-injected parameters, if they exist. 

	//default to override values from Jenkins Job "Build with Parameters" dialog 
	def srcRepo="${overrideSourceRepo}"
	def srcBranch="${overrideSourceBranch}"

	//now override with gitlab-webhook supplied values, if they exist
	if (env.gitlabSourceBranch)
	{
		echo "Triggered by gitlab merge-request webhook"
		srcBranch="${env.gitlabSourceBranch}"
		srcRepo="${env.gitlabSourceRepoSshUrl}"
	}

	//at this point, we have everything we need to checkout the source...
	stage('git') {
		updateGitlabCommitStatus name: "$jobName", state: "running"
		echo "stage: git-checkout, params:"
		echo "   srcRepo=${srcRepo}"
		echo "   srcBranch=${srcBranch}"
		//wrap git operation in a 5-minute timeout
		timeout(time: 5, unit: 'MINUTES') {
			dir('zephyrproject/zephyr') {
				checkout changelog: true, poll: false, scm: [
					$class: 'GitSCM',
					branches: [[name: "${srcBranch}"]],
					userRemoteConfigs: [[url: "${srcRepo}"]]
				]
				//now we have a branch, but we don't know which build env to use
				buildConfig=detect_branch.start()
				echo "buildConfig: ${buildConfig}"
				//safety-valve to prevent unsupported branches from crashing downstream agents. Here we fail nicely.
				if( (buildConfig['branchBase']!="master") && (buildConfig['branchBase']!="v1.14-branch-intel") ) {
					echo "Unexpected branchBase. ABORTING"
					sh "false"
				}
			}
		}
	}
	//run west init & update then stash build context for distribution to build/test agents
	stage('west')
	{
		dir('zephyrproject') {
			//wrap in a retry + timeout block since these are external repos & may timeout (todo: git-cache)
			retry(5) {
				timeout(time:  10, unit: 'MINUTES') {
					sh "rm -rf .west && ~/.local/bin/west init -l zephyr && ~/.local/bin/west update"
				}
			}
		}
		tgtJob="hwtest-jf-v1.14-branch-intel"
		sh "rm -rf ${WORKSPACE}/../${tgtJob} && mkdir -p ${WORKSPACE}/../${tgtJob} && cp -a zephyrproject ci ${WORKSPACE}/../${tgtJob}"
		tgtJob="sanitycheck-jf-v1.14-branch-intel"
		sh "rm -rf ${WORKSPACE}/../${tgtJob} && mkdir -p ${WORKSPACE}/../${tgtJob} && cp -a zephyrproject ci ${WORKSPACE}/../${tgtJob}"
		//todo: array & iterate ... also make this less dangerous to jobs that may be running asap: fixme:
	}

	//now run set of Zephyr CI Jenkins jobs...
	stage("call jobs") {
		echo "buildConfig: ${buildConfig}"

		if(buildConfig['branchBase']=="v1.14-branch-intel") {
			//run sanitycheck
			build job: 'sanitycheck-jf-v1.14-branch-intel', parameters: [
				string(name: 'branchBase', value: "${buildConfig['branchBase']}"), 
				string(name: 'sdkVersion', value: "${buildConfig['sdkVersion']}"),
				string(name: 'buildLocation', value: "jf"),
				string(name: 'agentType', value: "nuc_64gb")
			]
			//run hardware-test
			build job: 'hwtest-jf-v1.14-branch-intel', parameters: [
				string(name: 'branchBase', value: "${buildConfig['branchBase']}"), 
				string(name: 'sdkVersion', value: "${buildConfig['sdkVersion']}"),
				string(name: 'testLocation', value: "jf")
			]
		}
	}
}//node
