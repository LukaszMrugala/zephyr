# Zephyr DevOps Gitlab Plugin Info & Configuration

**Purpose**
This docs provides background information & configuration guidance for implementing Jenkins-Gitlab CI leveraging the gitlab plugin.

**Target Audience**
DevOps Engineers

**Doc Change Process**
* Minor changes & documentation improvements may be submitted by anyone. 
* Major policy or configuration changes should be RFC'd @ FMOS_DevOps first.

## 1. Gitlab Plugin Parameters & Jenkins Jobs

RTM @ https://plugins.jenkins.io/gitlab-plugin/#parameter-configuration

When a merge-request is opened on a project configured with Jenkins integration enabled, gitlab automatically transmits variables that specify the merge source repo & branch in the JSON webhook payload. DevOps also operates manually triggered jobs that allow user-provided parameters via the "Build with Parameters" option in Jenkins. 

In order for these methods to coexist in the same job, we must support different paths for manual & automated execution: 
1.)	automated trigger via gitlab plugin with gitlabSrcBranch & gitlabSrcRepo vars provided.
2.)	manual trigger w/ user-provided srcBranch & srcRepo from “Build with Parameters” function.

When the MRV starts, it first populates vars from the job parameters into srcRepo + srcBranch:
~~~~
//default to override values from Jenkins Job "Build with Parameters" dialog 
def srcRepo="${env.overrideSourceRepo}"
def srcBranch="${env.overrideSourceBranch}"
~~~~

Then we check for gitlab… vars & if set from a plugin trigger, use those instead

~~~~
//now override with gitlab-webhook supplied values, if they exist
if (env.gitlabSourceBranch)
{
	echo "Triggered by gitlab merge-request webhook"
	srcBranch="${env.gitlabSourceBranch}"
	srcRepo="${env.gitlabSourceRepoSshUrl}"
}
~~~~

At this point, the job can continue with srcBranch & srcRepo set correctly for either manual or automated triggers.