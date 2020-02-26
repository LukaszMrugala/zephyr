//hwtest-pipeline.groovy
//---=== this is a prototype ===---
//(will be integrated into main pipeline in the future)
//
//	This is a Zephyr sanitycheck execution Jenkins pipeline dedicated to HW testing
//	Functions of this module:
//		1. Clone source-branch
//		2. Run west init & update
//		3. Create a build-context stash & distribute to build agent
//		4. Execute hwtest-runner
//		5. Collect junit files & report failures to Jenkins master
//		8. Report overall CI status back to gitlab
//
//bugs/todo:
//  * break-out gitlab bits into it's own interface, make generic

//Pipeline variables
//	srcRepo - url to src repo, ssh:// urls recommended
//		** Zephyr Dev-Ops automation account must have Gitlab 'Developer' role for CI to function **
//	srcBranch - branch name, must exist
//  sdkVersion - Zephyr SDK version string, eg: '0.10.3'
//	jobName - short name for job to report to gitlab, eg: merge-validation
//	buildNodeLabel - Jenkins agent label to match for this build, eg: zephyr_swarm
//  sanitycheckPlatforms - Sanitycheck option for platform specification, if any

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
//  run across mulitple agent containers. This is intended to speed-up the CI results
//  for developer UX.
def start(srcRepo,srcBranch,sdkVersion,testLocation,sanitycheckPlatforms) {
	node('master') {
		echo sh(returnStdout: true, script: 'env') //dump env
		skipDefaultCheckout() //we do our own parameterized checkout, below
		deleteDir() //clean workspace
		def jobName = "hwtest-${testLocation}"
		try {
			stage('git-west-stash') {
				updateGitlabCommitStatus name: "$jobName", state: "running"
				unstash 'ci'
				timeout(time: 5, unit: 'MINUTES') {
					echo "srcRepo: ${srcRepo}"
					echo "srcBranch: ${srcBranch}"
					echo "sdkVersion: ${sdkVersion}"
					dir('zephyrproject/zephyr') {
						checkout changelog: true, poll: false, scm: [
							$class: 'GitSCM',
							branches: [[name: "${srcBranch}"]],
							userRemoteConfigs: [[url: "${srcRepo}"]]
						]
					}
				}
				dir('zephyrproject') {
					//wrap in a retry + timeout block since these are external repo hits
					//todo: git-cache
					retry(5) {
						timeout(time:  5, unit: 'MINUTES') {
							sh "rm -rf .west && ~/.local/bin/west init -l zephyr && ~/.local/bin/west update" 
						}
					}
				}
				sh "du -sch;"
				stash name: 'context'
			}//stage
		}//try
		catch(err) {
			abort_build(jobName)
		}
	}//master node end

	echo "Begin node expansion on target platforms: ${sanitycheckPlatforms}"
	def nodejobs = [:]
	for (int i = 0; i < sanitycheckPlatforms.size(); i++)
	{
		def sanitycheckPlatform = sanitycheckPlatforms[i]
		def stageName = "hwtest-${testLocation}-${sanitycheckPlatform}"
		nodejobs[stageName] = { ->
			node("hwtest-${testLocation}-${sanitycheckPlatform}") {
				failed=false

				stage("${stageName}") {
					unstash 'context'
					unstash 'ci'
					//call our runner shell script from zephyr tree
					dir('zephyrproject/zephyr') {
						//withEnv block is temporary... debugging env vars not sticking from -runner.sh
						try {
							withEnv([	"ZEPHYR_BASE=${WORKSPACE}/zephyrproject/zephyr",
										"ZEPHYR_TOOLCHAIN_VARIANT=zephyr",
										"ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk-${sdkVersion}"]) {
								sh "${WORKSPACE}/ci/modules/hwtest-runner.sh ${sanitycheckPlatform}"
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
						sh "pwd"
						dir ('junit') {
							stash name: "junit-${testLocation}-${sanitycheckPlatform}", includes: '*.xml'
						}//dir
					}//dir
				}//stage
			}//node
		}//nodejobs
	}//for platforms
	parallel nodejobs

	//back at the master, report final status back to gitlab
	node('master') {
		def jobName = "hwtest-${testLocation}"
		//expand array of platforms & unstash results from each test
		dir('junit') {
            for (int j = 0; j < sanitycheckPlatforms.size(); j++)
            {
				def plat = sanitycheckPlatforms[j]
                unstash "junit-${testLocation}-${plat}"
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
