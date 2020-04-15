//hwtest-pipeline.groovy
//---=== this is a prototype ===---
//(will be integrated into main pipeline in the future)
//
//	This is a Zephyr sanitycheck execution Jenkins pipeline dedicated to HW testing
//	Functions of this module:
//		1. Distribute previously assembled build-context across all build agents
//		2. Execute hwtest-runner
//		3. Collect junit files & report failures to Jenkins master
//		4. Report task status back to gitlab
//
//
// How to use:
//  This module should be run as pipeline script in a parent Jenkins job, with the following parameters set:
//  	baseBranch - 'v1.14-branch-intel','master'...
//  	sdkVersion - Zephyr SDK version string, eg: '0.10.3'
//		testLocation - Which infrastructure? Current options are 'sh' and 'jf'
//		agentType - Jenkins agent label type to match for this build, eg: 'vm' or 'nuc_64gb'
//  	sanitycheckPlatforms - Sanitycheck option for platform specification, if any
//
//  Example Pipeline script call:
//
//		import groovy.transform.Field
//		//hwtest config & entrypoint
//		node('master') {
//		    //select sanitycheck platforms to run on this job
//		    @Field String[] sanitycheckPlatforms = ['nucleo_f103rb','frdm_k64f']
//
//		    //load hwtest pipeline from ci.git & call with parameters
//		    def hwtest = load "${WORKSPACE}/ci/modules/hwtest-pipeline.groovy"
//
//		    stash name: "context"
//		    hwtest.run(baseBranch,sdkVersion,testLocation,agentType,sanitycheckPlatforms)
//		}
//
//  Dev-Ops Hint: This job & its siblings are created automatically, see ansible playbooks.
//
// Bugs/todo:
//  * break-out gitlab bits into it's own interface, make generic

//for @Field String
import groovy.transform.Field

//temp
hwtestPorts = [
  nucleo_f103rb:'ttyACM0',
  frdm_k64f: 	'ttyACM0',
  iotdk:		'ttyUSB0',
  reel_board:	'ttyACM0']

//abort build() - our bail-out function. Important part is the gitlab status
//  to the zephyrci-XXXXX pipeline if we are bailing-out so that gitlab does
//  not show the pipeline as pending for the rest of time.
def abort_build(jobName) {
	updateGitlabCommitStatus name: "$jobName", state: "failed"
	currentBuild.result = 'ABORTED'
	error("Cannot continue, job aborted. Email SSP Zephyr DevOps with link to this page.")
}

//run() - entrypoint from the top-level job call.
//  distributes stashes to all avail agents matching agent label
//  hwtest-runner.sh is called on each agent matching node label
//  after execution is complete, each agent stashes aritfacts (currently just junit.xml) & transfers back to master
def run(branchBase,sdkVersion,sanitycheckPlatforms) {
	//parallel expansion around target platform array
	echo "Begin node expansion on target platforms: ${sanitycheckPlatforms}"
	def nodejobs = [:]
	for (int i = 0; i < sanitycheckPlatforms.size(); i++) {
		def sanitycheckPlatform = sanitycheckPlatforms[i]
		def hwtestPort =  hwtestPorts[sanitycheckPlatform]
		def nodeLabel = "hwtest-${sanitycheckPlatform}"
		//how many nodes do we have for this platform...
//		def availAgents = nodesByLabel "${nodeLabel}"
//		for (int j = 0; j < availAgents.size(); j++) {
//			def stageName = "hwtest-${sanitycheckPlatform}_${j}"
			def stageName = "hwtest-${sanitycheckPlatform}"
			nodejobs[stageName] = { ->
				node("hwtest-${sanitycheckPlatform}") {
					failed=false
					//"new" unstash (workaround)
					sh 'rm -rf ci/ zephyrproject/ && tar xzf ~/zephyr.tar.gz'
					stage("${stageName}") {
						//call our runner shell script from zephyr tree
						dir('zephyrproject/zephyr') {
							try {
								//this env block is temporary. debugging env vars not sticking from runner script
								withEnv([	"ZEPHYR_BASE=${WORKSPACE}/zephyrproject/zephyr",
											"ZEPHYR_TOOLCHAIN_VARIANT=zephyr",
											"ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk-${sdkVersion}",
											"ZEPHYR_BRANCH_BASE=${branchBase}"]) {
//									sh "${WORKSPACE}/ci/modules/hwtest-runner.sh ${sanitycheckPlatform} ${availAgents.size()*10} ${j}  ${hwtestPort}"
									sh "${WORKSPACE}/ci/modules/hwtest-runner.sh ${sanitycheckPlatform} 10 1 ${hwtestPort}"
								}
							}
							catch (err) {
								failed=true
								echo "SANITYCHECK_FAILED"
								catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') { sh "false"}
							}
							finally {
								if(!failed) {
									echo "SANITYCHECK_SUCCESS"
									catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') { sh "true"}
								}
							}
							//stash junit output for transfer back to master
							dir ('sanity-out') {
								stash name: "junit-${sanitycheckPlatform}", includes: '*.xml'
							}//dir
						}//dir
					}//stage
				}//node
			}//nodejobs
//		}//for availAgents
	}//for platforms
	parallel nodejobs

	//back at the master, report final status back to gitlab
	//todo: this code should be moved-up one level... have two implementations in two places right now
	node('master') {

		stage("recover junits agents") {

			//expand array of platforms & unstash results from each test
			echo "Recovering stashes from distributed run on platforms: ${sanitycheckPlatforms}"
			dir('junit') {
				for (int k = 0; k < sanitycheckPlatforms.size(); k++) {
					catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
						unstash "junit-${sanitycheckPlatforms[k]}"
						sh 'true'
					}
				}	
			}
		}

		stage("publish test results") {
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
//				xunit thresholds: [passed(failureNewThreshold: '0', failureThreshold: '0', unstableNewThreshold: '0', unstableThreshold: '0')], tools: [JUnit(deleteOutputFiles: true, failIfNotNew: false$
				sh "true"
			}//catcherror
		}//stage
	}//node
}//start
return this



