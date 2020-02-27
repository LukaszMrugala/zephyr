//Zephyr Dev-Ops Example CI Implementation
// This file defines configuration & infrastruture entry-points for Intel's
// internal Jenkins-Gitlab CI processes. This is the top-level configuration
// file that defines branches supported and build/test-infrastructure.
// This groovy script is intended to be executed from a Jenkins master as a
// "Pipeline script" job, triggered from a gitlab/hub webhook with source repo
// & branch-name as parameters.
//
// You must configure this script to suit your branches & infrastructure.
//
// Configuration Instructions:
//
// Step 1: Define the CI repo URL
def ciRepoURL = "ssh://git@gitlab.devtools.intel.com:29418/zephyrproject-rtos/ci.git"

// Step 2: Define a unique job name to display in the CI pipeline:
def jobName = "staging-sanitycheck-test"

// Step 3: Define the branches & SDKs this job (& infrastructure!) supports
//   Defined as:
//		<map-key>: ["<branch_name>","<sdk version>","<uncommon_ancestor sha>"],
//
//	uncommon_ancestor is found by checking-out feature branch (eg v1.14-branch-intel)
//		and doing visual search with git log --graph -OR- by running: 
//			git log --reverse --boundary --format=%h HEAD ^origin/master | head -1
//		then selecting the next commit (todo: some git-fu here)
//
//	You must validate that this method works for your repo & target branches! This is 
//		a hastily implemented but simple method that's suitable for the tested repo.
//
def branchConfigs = [ 
	"v1.14-branch-intel": ["0.10.3","247330d62a4b89fcf3900a160fbb195be78a55a9"],
	"master": ["0.11.3","0"]
//  master branch entry must be present & in last position, sha is a dont-care
//  
]

// Step 4: Target infrastructure for this job, where the job will execute:
def agentType = 'nuc_64gb'	//prefix of target Jenkins node label
							//should be in format, <type>_<subtype>. 
							//current support:
							//  'vm_ssp' - SSP Ops VMs
							//  'nuc_64gb' - NUC w/ 64GB RAM
							
def buildLocation = 'jf' 	//suffix of target Jenkins node label,
							//indicates physical location of the 
							//build agent
							//current support:
							//	'jf' - Jones-Farm/Oregon, USA
							//  'sh' - Shanghai, China

// begin pipeline on the CI master...
node('master') {
	skipDefaultCheckout()
	deleteDir()

	//clone ci repo & stash for use by downstream build agents
	//  we're intentionally not using Jenkins internal git methods to keep 
	//  some poorly implemented plugins from latching onto our ci repo for 
	//  polling later in the job
	//
	sh "git clone --depth 1 --single-branch --branch master ${ciRepoURL} ci"        
	stash name: 'ci'

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
	stage('git-checkout') {
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
			}
		}
	}

	//now we look for the uncommon ancestor commit to identify branch lineage & select the correct build environment
	stage('flavor detection') {
		//iterate over our SDK config map, looking for a common-ancestor+1 in the feature branches... else is master
		found=false
		for (key in branchConfigs.keySet()) {
			//check to see if we're at the end of the list
			if (key=="master")
				break

			//for all other branches, we check for the ancestor sha
			try {
				sh "git -C $WORKSPACE/zephyrproject/zephyr merge-base --is-ancestor ${branchConfigs[key][1]} HEAD"
				echo "sha ${branchConfigs[key][1]} FOUND, looks like branch ${key}."
				found=true
			}
			catch (err) {
				echo "${branchConfigs[key][1]} (branch ${key}) not found in srcBranch."
				found=false
			}
		}
		if(found==false)
			echo "Did not find any ancestors for the configured set of branches ${branchConfigs.keySet()}. Making the dangerous assumption that srcBranch can built with master env..."

	//WIP... need to set build env on these results...

		//always pass this silly stage
		catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') { sh "true"}

	}
	//disable while testing
	//def zephyr_ci = load "$WORKSPACE/ci/modules/sanitycheck-pipeline.groovy"
	//zephyr_ci.start(srcRepo,srcBranch,sdkVersion,jobName,agentType,buildLocation) 
}
