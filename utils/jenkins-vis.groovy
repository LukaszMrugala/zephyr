// jenkins-vis.groovy
// zephyr devops jenkins-visualization/reporting functions

////////////////////////////////////////////////////////////////////////////////
// setJobInfo - displays commit & build env info in jenkins job summary
//	srcRepo - ssh or http url supported
//	srcBranch - branch name, tag or sha
//
def setJobInfo(jobName,srcBranch,branchBase) {
	def src_sha = sh label: 'git rev-parse', returnStdout: true, script: 'git -C $WORKSPACE/zephyrproject/zephyr rev-parse --short=5 HEAD'
	def ci_sha = sh label: 'git rev-parse', returnStdout: true, script: 'git -C $WORKSPACE/ci rev-parse --short=5 HEAD'
	def build_displayName = sprintf("%s","$jobName")
	def build_description = sprintf("branch: %s@%s\nbuild env: %s, ci@%s","$srcBranch",src_sha.trim(),"$branchBase",ci_sha.trim())
	currentBuild.description = build_description
	currentBuild.displayName = build_displayName
}

return this
