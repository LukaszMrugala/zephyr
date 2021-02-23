// west.groovy
// zephyr devops west interface

////////////////////////////////////////////////////////////////////////////////
// run - performs west init-update with timeoutMins (opt)
//	requires 'buildConfig' defined @Field & set from previous call to detect-branch
//
def run(timeoutMins) {
	//default 15 min timemout
	timeoutMins = timeoutMins ?: 15

	stage('west')
	{
		dir('zephyrproject') {
			//wrap in a retry + timeout block since these are external repos & may timeout
			retry(3) {
				timeout(time: timeoutMins, unit: 'MINUTES') {
					withEnv(["ZEPHYR_BRANCH_BASE=${buildConfig['branchBase']}"]) {
						sh "../ci/utils/west-init-update.sh"
					}
				}
			}
		}
	}
}

return this
