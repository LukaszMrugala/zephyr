//sanitycheck-pipeline.groovy
//	This is a Zephyr sanitycheck execution Jenkins pipeline supporting distributed execution
//	Functions of this module:
//		1. Clone source-branch
//		2. Run west init & update
//		3. Create a build-context stash & distribute to build agents
//		4. Execute sanitycheck-runner in a parallel across agents
//		5. Collect junit files from each agent & report failures in Jenkins build
//		8. Report overall CI status back to gitlab
//
//bugs/todo:
//	* replace hardcoding of hw-agents, threads & batch-split with call to agent-registry.getConfig call
//  * break-out gitlab bits into it's own interface, make generic

//Pipeline variables
//	srcRepo - url to src repo, ssh:// urls recommended
//		** Zephyr Dev-Ops automation account must have Gitlab 'Developer' role for CI to function **
//	srcBranch - branch name, must exist
//	jobName - short name for job to report to gitlab, eg: merge-production.
//	buildNodeLabel - Jenkins agent label to match for this build, eg: zephyr_swarm
//	sanitycheckThreads - Number of threads for sanitycheck execution, for tuning node load
//		** buildNodeLabel & sanitycheckThreads options don't fit here & will be replaced by a call to our agent regsitry service, soon.
//  sanitycheckParallel - Number of nodes to spread sanitycheck execution across, should be <= # of build agents of least execution time

//for @Field String
import groovy.transform.Field

//abort build() - our bail-out function. Important part is the gitlab status
//  to the zephyrci-XXXXX pipeline if we are bailing-out so that gitlab does
//  not show the pipeline as pending for the rest of time.
def abort_build(jobName) {
	updateGitlabCommitStatus name: "$jobName", state: "failed"
	currentBuild.result = 'ABORTED'
	error("Cannot continue, job aborted. Email SSP Zephyr DevOps with link to this page.")
}

//start() - entrypoint from the top-level job call.
//  clone + west on master node, stashes wrkspc & then spins-off santitycheck
//  run across mulitple agents/containers. This is intended to speed-up the CI results
//  for developer UX.
def start(srcRepo,srcBranch,jobName,buildAgentType,buildLocation) {
	node('master') {
		echo sh(returnStdout: true, script: 'env') //dump env
		skipDefaultCheckout() //we do our own parameterized checkout, below
		deleteDir() //clean workspace
		try {
			stage('setup') {
				updateGitlabCommitStatus name: "$jobName", state: "running"
				unstash 'ci'
			}
			stage('git') {
				timeout(time: 5, unit: 'MINUTES') {
					echo "srcRepo: ${srcRepo}"
					echo "srcBranch: ${srcBranch}"
					dir('zephyrproject/zephyr') {
						checkout changelog: true, poll: false, scm: [
							$class: 'GitSCM',
							branches: [[name: "${srcBranch}"]],
							userRemoteConfigs: [[url: "${srcRepo}"]]
						]
					}
				}
			}
			stage('west') {
				dir('zephyrproject') {
					//wrap in a retry + timeout block since these are external repo hits
					//todo: git-cache
					retry(5) {
						timeout(time:  5, unit: 'MINUTES') {
							sh "rm -rf .west && ~/.local/bin/west init -l zephyr && ~/.local/bin/west update" 
						}
					}
				}
			}
			stage('stash') {
				sh "du -sch;"
				stash name: 'context'
			}
		}//try
		catch(err) {
			abort_build(jobName)
		}
	}//master node end

	//parallel expansion around available nodes
	echo "Preparing for distributed sanitycheck across all available ${buildAgentType}-${buildLocation}-64gb nodes"
	def nodejobs = [:]
	//hardcoded for prototyping
	//todo: continue dev around Jenkins nodesByLabel() method
	for (int i = 0; i < 2; i++) //SEE ALSO HARDCODED 2 IN RUNNER SCRIPT PARAMS & MASTER UNSTASH
	{
		def stageName = "sanitycheck-batch${i}"
		def batchNumber = i + 1
		nodejobs[stageName] = { ->
		node("${buildAgentType}-${buildLocation}-64gb") {
			deleteDir()
			unstash "ci"
			unstash "context"
				stage("${stageName}") {
					dir('zephyrproject/zephyr') {
						failed=false
						//call our runner shell script
						//withEnv block is temporary... debugging env vars not sticking from -runner.sh
						try {
							withEnv([	"ZEPHYR_BASE=$WORKSPACE/zephyrproject/zephyr",
										"ZEPHYR_TOOLCHAIN_VARIANT=zephyr",
										"ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk-0.10.3"]) {
								sh "$WORKSPACE/ci/modules/sanitycheck-runner.sh 2 ${batchNumber}"
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
						dir ('junit') {
							stash name: "junit-${batchNumber}", includes: '*.xml'
						}
					}//dir
				}//stage
			}//node
		}//nodejobs
	}//for
	parallel nodejobs

	//back at the master, report final status back to gitlab
	node('master') {
		//expand array of nodes & unstash results
		dir('junit') {
			for (int j = 0; j < 2; j++) 
			{
				def batchNumber = j + 1
				unstash "junit-${batchNumber}"
			}
		}
		step([$class: 'JUnitResultArchiver', testResults: '**/junit/*.xml', healthScaleFactor: 1.0])
			publishHTML (target: [
			allowMissing: true,
			alwaysLinkToLastBuild: false,
			keepAll: false,
			reportDir: '',
			reportFiles: 'index.html',
			reportName: "Sanitycheck Junit Report"
		])
		updateGitlabCommitStatus name: "$jobName", state: "success"
	}
}//start
return this
