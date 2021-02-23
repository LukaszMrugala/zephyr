// west.groovy
// zephyr devops west interface

////////////////////////////////////////////////////////////////////////////////
// run - performs west init-update with timeoutMins (opt)
//   branchBase - build env, v1.14-branch-intel, master, etc
//   timeoutMins - how long to allow for west operations before timing-out
//
def run(branchBase,timeoutMins) {
	stage('west init+update')
	{
		dir('zephyrproject') {
			//wrap in a retry + timeout block since these are external repos & may timeout
			retry(3) {
				timeout(time: timeoutMins, unit: 'MINUTES') {
					withEnv(["ZEPHYR_BRANCH_BASE=$branchBase"]) {
						sh "$WORKSPACE/ci/utils/west-init-update.sh"
					}
				}
			}
		}
	}
}

return this
