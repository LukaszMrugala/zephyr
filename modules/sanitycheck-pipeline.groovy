//sanitycheck-pipeline.groovy
//	This is a Zephyr sanitycheck execution Jenkins pipeline supporting distributed execution.
//  Execution is distributed across all agents with label matching the agent type & location parameters.
//	Functions of this module:
//		1. Unstash previously prepared zephyr build context
//		2. Execute sanitycheck-runner in a parallel across agents
//		3. Collect junit files from each agent & report failures in Jenkins build
//		4. Report task status back to gitlab
//
//bugs/todo:
//  * break-out gitlab bits into it's own interface, make generic

//Pipeline variables
//	baseBranch - 'master', 'v1.14-branch-intel', etc
//  sdkVersion - Zephyr SDK version string, eg: '0.10.3'
//  agentType - specifies which type of agent to build, currently we support 'vm' or 'nuc'
//  buildLocation - specifies where to execute the build, currently we support 'jf' or 'sh'

//for @Field String
import groovy.transform.Field

//abort build() - our bail-out function. Important part is the gitlab status
//  to the zephyrci-XXXXX pipeline if we are bailing-out so that gitlab does
//  not show the pipeline as pending for the rest of time.
def abort_build(jobName) {
	updateGitlabCommitStatus name: "$JOB_NAME", state: "failed"
	currentBuild.result = 'ABORTED'
	error("Cannot continue, job aborted. Email SSP Zephyr DevOps with link to this page.")
}

//start() - entrypoint from the top-level job call.
//  distributes stashes to all avail agents matching ($agentType-$buildLocation) label
//  sanitycheck-runner.sh is called on each agent, with -B split options to divide & conquer the execution
//  after execution is complete, each agent stashes aritfacts (currently just junit.xml) & transfers back to master
//  Jenkins master then unstashes all artifacts & creates a junit composite for all tests
def run(branchBase,sdkVersion,agentType,buildLocation) {
	//job-wide globals
	def targetAgentLabel = "${agentType}-${buildLocation}"
	def availAgents = nodesByLabel "${targetAgentLabel}"
	int numAvailAgents = availAgents.size()

	//parallel expansion around available nodes
	echo "Preparing for distributed sanitycheck across all available nodes matching label: ${targetAgentLabel}"
	def nodejobs = [:]
	for (int i = 0; i < numAvailAgents; i++)
	{
		def batchNumber = i + 1
		def stageName = "sanitycheck-${batchNumber}/${numAvailAgents}"
		nodejobs[stageName] = { ->
		node("${targetAgentLabel}") {
			updateGitlabCommitStatus name: "$JOB_NAME-$stageName", state: "running"
			deleteDir()
			unstash "context"
				stage("${stageName}") {
					dir('zephyrproject/zephyr') {
						failed=false
						//call our runner shell script
						//withEnv block is temporary... debugging env vars not sticking from -runner.sh
						try {
							withEnv([	"ZEPHYR_BASE=$WORKSPACE/zephyrproject/zephyr",
										"ZEPHYR_TOOLCHAIN_VARIANT=zephyr",
										"ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk-${sdkVersion}",
										"ZEPHYR_BRANCH_BASE=${branchBase}"]) {
								sh "$WORKSPACE/ci/modules/sanitycheck-runner.sh ${numAvailAgents} ${batchNumber}"
							}
						}
						catch (err) {
							failed=true
							echo "SANITYCHECK_FAILED"
							updateGitlabCommitStatus name: "$JOB_NAME-$stageName", state: "failed"
							catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') { sh "false"}
						}
						finally {
							if(!failed) {
								echo "SANITYCHECK_SUCCESS"
								updateGitlabCommitStatus name: "$JOB_NAME-$stageName", state: "success"
								catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') { sh "true"}
							}
						}
						//stash junit output for transfer back to master
						dir ('junit') {
							stash name: "junit-${batchNumber}", includes: '*.xml'
						}
					}//dir
				}//stage
			}//node
		}//nodejobs
	}//for
	parallel nodejobs

//this block should probably move up one level...

	//back at the master, report final status back to gitlab
	node('master') {
		stage('junit report')
		{
			//expand array of nodes & unstash results
			dir('junit') {
				for (int j = 0; j < numAvailAgents; j++) {
					def batchNumber = j + 1
					unstash "junit-${batchNumber}"
				}
			}
			//publish junit results
			catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
				step([$class: 'JUnitResultArchiver', testResults: '**/junit/*.xml', healthScaleFactor: 1.0])
					publishHTML (target: [
					allowMissing: true,
					alwaysLinkToLastBuild: false,
					keepAll: false,
					reportDir: '',
					reportFiles: 'index.html',
					reportName: "Sanitycheck Junit Report"
				])
				sh "true"
			}
		}
	}
}//start
return this
