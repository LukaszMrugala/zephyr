# Zephyr DevOps Stateless Sanitycheck/Twister Module

## runner.sh

This is a shell script that implements a standardized, parallel-executed Zephyr twister/sanitycheck validation across all internal CI functions. 
It is intended to be branch, build-environment & CI platform agnostic.
* Input is a west initialized & updated Zephyr tree in the CWD.
* It accepts parameters to configure the parallel execution
* Output is junit xml intended for consumption by upstream data visualization & reporting tools.
* Return status reflects total pass/fail of the sanitycheck default cases after three retries.

## pipeline.groovy

This is a Jenkins pipeline script wrapper for the above runner.sh script that implements a Gitlab CI flow for internal Zephyr CI functions. It supports parallel build expansion across Jenkins build agents & is intended to be called from a top-level Jenkins CI job with parameters set for:
* Source Repo URL
* Source Branch URL
* Zephyr SDK Version
* Job Name
* Build Agent Type
* Build Location
