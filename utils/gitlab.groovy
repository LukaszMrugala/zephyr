// gitlab.groovy
// zephyr devops jenkins-gitlab interface

////////////////////////////////////////////////////////////////////////////////
// clone - performs in-place clone of srcRepo/srcBranch with timeoutMins (opt)
//	srcRepo - ssh or http url supported
//	srcBranch - branch name, tag or sha
//
def clone(sourceRepo,sourceBranch,timeoutMins) {
	stage('gitlab-clone') {
		echo "stage: git-checkout, params:"
		echo "   sourceRepo=$sourceRepo"
		echo "   sourceBranch=$sourceBranch"
		timeout(time: timeoutMins, unit: 'MINUTES') {
			dir('zephyrproject/zephyr') {
				checkout changelog: true, poll: false, scm: [
					$class: 'GitSCM',
					branches: [[name: "$sourceBranch"]],
					userRemoteConfigs: [[url: "$sourceRepo"]]
				]
			}
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
// setStatus - set commit status on gitlab
//	jobStatus -  [pending, running, canceled, success, failed] ONLY
//	jobName - should be set to $env.JOB_NAME
//
def setStatus(jobName,jobStatus) {
	updateGitlabCommitStatus name: "$jobName", state: "$jobStatus"
}

////////////////////////////////////////////////////////////////////////////////
// addMRComment - adds comment to merge request associated with gitlab commit
//	commentStr -  comment string
//
def addMRComment(commentStr) {
	stage("add MR comment") {
		addGitLabMRComment comment: "$commentStr"
	}
}
return this
