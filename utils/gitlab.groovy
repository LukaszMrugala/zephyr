// gitlab.groovy
// zephyr devops jenkins-gitlab interface

////////////////////////////////////////////////////////////////////////////////
// clone - performs in-place clone of srcRepo/srcBranch with timeoutMins (opt)
//	srcRepo - ssh or http url supported
//	srcBranch - branch name, tag or sha
//
def clone(srcRepo,srcBranch,timeoutMins) {

	//default 5 min timemout
	timeoutMins = timeoutMins ?: 5

	stage('gitlab-clone') {
		echo "stage: git-checkout, params:"
		echo "   srcRepo=${srcRepo}"
		echo "   srcBranch=${srcBranch}"
		//wrap git operation in a 5-minute timeout
		timeout(time: timeoutMins, unit: 'MINUTES') {
			checkout changelog: true, poll: false, scm: [
				$class: 'GitSCM',
				branches: [[name: "${srcBranch}"]],
				userRemoteConfigs: [[url: "${srcRepo}"]]
			]
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
// setStatus - set commit status on gitlab
//	jobStatus -  [pending, running, canceled, success, failed] ONLY
//	jobName - must be set as public
//
def setStatus(jobStatus,jobName) {

	updateGitlabCommitStatus name: "$jobName", state: "$jobStatus"
}

////////////////////////////////////////////////////////////////////////////////
// addMRComment - adds comment to merge request associated with gitlab commit
//	commentStr -  comment string
//	jobName - must be set as public
//
def addMRComment(commentStr) {
	stage("add MR comment") {
		addGitLabMRComment comment: "${commentStr}"
	}
}

return this
