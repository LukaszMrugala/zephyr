//stateless/pipeline.groovy
//      A pipeline for parallel-executed Zephyr-project testing with sanitycheck/twister methods. 
//      Call from Jenkins build after 'git clone..', 'west init/update' & finally creating build context stash with 'stash: context'
//      Parameters:
//		test_skip_div - sets testcase skipping, set to 1 for normal operation, N will limit execution to 1 in N cases
//              baseBranch - 'master', 'v1.14-branch', etc
//              sdkVersion - Zephyr SDK version to use, eg: '0.10.3'
//              agentType - specifies which type of agent to build, currently we support 'ubuntu_vm', 'zbuild' or 'nuc64GB'
//              buildLocation - specifies where to execute the build, currently we support 'jf' or 'sh'
//		sc_option - extra string to insert in twister/sanitycheck cmdline
//      Returns:
//              Each parallel node is run as Jenkins stage & status is reflected by the stage result:
//                      SUCCESS (green) ------- Test executed normally & no failures detected.
//                      UNSTABLE (yellow) ----- Test executed normally but test-case failures were detected.
//                      FAILED (red) ---------- Test execution failed. DevOps intervention required.
//                      TIMEOUT/CANCEL (grey) - Test executed was cancelled or timed-out. DevOp intervention required.
//
//      Functions of this module:
//              1. Search for available nodes matching the supplied agentType + buildLocation pattern.
//              2. Use Jenkins parallel expansion + twister/sanitycheck batch option to distribute build across all available nodes:
//                      a. Unstash prepared zephyr build, named 'context'
//                      b. Detect which generation of zephyr test method, sanitycheck or twister
//                      c. Run ci.git/<THIS METHOD>/runner.sh wrapper script, which sets env & passes along batch options
//                      d. Collect log + junit.xml files from each agent & transfer back to calling pipeline
//                      e. Report overall build result, setting the stage UNSTABLE on failure
//              3. Back at the master node, report overall job status, using above color/status map

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
def run(test_skip_div,branchBase,sdkVersion,agentType,buildLocation,sc_option) {

	//job-wide globals
	def targetAgentLabel = "${agentType}-${buildLocation}"
	def availAgents = nodesByLabel "${targetAgentLabel}"
	int numAvailAgents = availAgents.size()
	int denominator = numAvailAgents*test_skip_div.toInteger()

	//parallel expansion around available nodes
	echo "Preparing for distributed sanitycheck across all available nodes matching label: ${targetAgentLabel}"
	def nodejobs = [:]
	for (int i = 0; i < numAvailAgents; i++)
	{
		def batchNumber = i + 1
		def stageName = "ci-${batchNumber}/${numAvailAgents}"
		nodejobs[stageName] = { ->
		node("${targetAgentLabel}") {
			deleteDir()
			unstash "context"
				stage("${stageName}") {
					//call runner.sh with catchError block setup for UNSTABLE, not FAILED status
					catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') { 
						withEnv(["ZEPHYR_BASE=$WORKSPACE/zephyrproject/zephyr",
								"ZEPHYR_TOOLCHAIN_VARIANT=zephyr",
								"ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-${sdkVersion}",
								"ZEPHYR_BRANCH_BASE=${branchBase}"]) {
							sh "ci/stateless/runner.sh ${denominator} ${batchNumber} \"${sc_option}\""
						}
					}
					echo "currentBuild.currentResult for this node = ${currentBuild.currentResult}"
					//stash junit output for transfer back to master
					if(branchBase=="v1.14-branch") {
						dir ('zephyrproject/zephyr/sanity-out') {
							stash allowEmpty: true, name: "junit-${batchNumber}", includes: 'sanitycheck.xml'
						}
					}
					else {
						dir ('zephyrproject/zephyr/twister-out') {
							stash allowEmpty: true, name: "junit-${batchNumber}", includes: 'twister.xml'
						}
					}
				}//stage
			}//node
		}//nodejobs
	}//for
	parallel nodejobs

	//back at the master, expand junit archives from build nodes
	node('master') {
		deleteDir()
		stage('ci junit') {
			//expand array of nodes & unstash results into directories
			for (int j = 0; j < numAvailAgents; j++) {
				def batchNumber = j + 1
				dir("junit-${batchNumber}") {
					unstash "junit-${batchNumber}"
				}
			}

			//publish junit results.
			//wrap in catchError block w/ buildResult=null to prevent failing entire build if there are no junit files
			catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
				step([$class: 'JUnitResultArchiver', testResults: '**/junit*/*.xml', healthScaleFactor: 1.0])
					publishHTML (target: [
					allowMissing: true,
					alwaysLinkToLastBuild: false,
					keepAll: false,
					reportDir: '',
					reportFiles: 'index.html',
					reportName: "Sanitycheck Junit Report"])
			}

//			xunit thresholds: [passed(	failureNewThreshold: '0',
//							failureThreshold: '0',
//							unstableNewThreshold: '0',
//							unstableThreshold: '0')],
//				tools: [JUnit(	deleteOutputFiles: true,
//						failIfNotNew: false,
//						pattern: '**/junit*/*.xml',
//						skipNoTestFiles: true,
//						stopProcessingIfError: true)]
		}
	}
}//start
return this
