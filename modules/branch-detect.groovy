//Zephyr Internal Build Environment Detection Module
//Zephyr Dev-Ops
//
// This file implements a commit ancestor search to set the build environment
// from a groovy branch-to-build-environement mapping. 

// This module is designed to be called from the base directory of any git
// repo. The branchConfigs array (below) must be configured for your zephyr repo.

// Configuration: Define your branches & build-environment mappings.
//   Defined as:
//		"<branch_name>": ["<sdk_version>","<branch_sha>"]
//
//	branch sha is found by checking-out feature branch (eg v1.14-branch-intel)
//		and doing visual search with git log --graph -OR- by running:
//			git log --reverse --boundary --format=%h HEAD ^origin/master | head -1
//		then selecting the *next* commit sha (todo: insert more git-fu here)
//	You must validate that this method works for your repo & target branches! This is
//		an intentionally simple method but maybe unsuitable for some repos.
//
branchConfigs = [ 
	"v1.14-branch-intel": [sdkVersion:"0.10.3",sha:"247330d62a4b89fcf3900a160fbb195be78a55a9"],
	"master": [sdkVersion:"0.11.4",sha:"0"]
	]
// master branch entry must be present & in last position, sha is a dont-care

def start() {
	//look for the uncommon ancestor commit to identify branch lineage & select the correct build environment
	stage('branch-detect') {
		//iterate over our SDK config map, looking for a common-ancestor+1 in the feature branches... else is master
		foundBranch="none"
		for (key in branchConfigs.keySet()) {
			//fall-thru to master if none of the other branches match... this could be better but will work for now.
			if (key=="master")
				break

			//for all other branches, we check for the ancestor sha
			try {
				sh "git -C ${WORKSPACE}/zephyrproject/zephyr merge-base --is-ancestor ${branchConfigs[key]['sha']} HEAD"
				echo "sha ${branchConfigs[key]['sha']} FOUND, looks like branch ${key}."
				foundBranch=key
			}
			catch (err) {
				echo "${branchConfigs[key]['sha']} (branch ${key}) not found in srcBranch."
			}
		}
		if(foundBranch=="none") {
			echo "Did not find any ancestors for the configured set of branches ${branchConfigs.keySet()}."
			echo "Assuming that srcBranch is based on master & continuing. CI build errors may occur if we're wrong."
			foundBranch="master"
		}

		//always pass this stage
		catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') { sh "true"}

		//inject baseBranch into this matched branch & return it
		branchConfigs[foundBranch].put('branchBase',foundBranch)
		return branchConfigs[foundBranch]
	}
}
return this
