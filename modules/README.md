# Zephyr DevOps CI Documentation

This directory contains modules that implement the internal CI functions for Zephyr Project at Intel. 

See individual files for latest documentation & usage for each module.

## sanitycheck-runner.sh

This is a shell script that implements a standardized, parallel-executed Zephyr sanitycheck validation across all internal CI functions. It is intended to be branch, build-environment & CI flow agnostic.

* Input is a west initialized & updated Zephyr tree in the CWD. 
* It accepts parameters to configure the parallel execution
* Output is junit xml intended for consumption by upstream data visualization & reporting tools.
* Return status reflects total pass/fail of the sanitycheck default cases after three retries.

## sanitycheck-pipeline.groovy 

This is a Jenkins pipeline script wrapper for the sanitycheck-runner.sh script that implements a Gitlab CI flow for internal Zephyr CI functions. It supports parallel build expansion across Jenkins build agents & is intended to be called from a top-level Jenkins CI job with parameters set for:

* Source Repo URL
* Source Branch URL
* Zephyr SDK Version
* Job Name
* Build Agent Type
* Build Location

## hwtest-pipeline.groovy
## hwtest-runner.sh

These modules implement CI-triggered HW-testing & are in active development.  See source for documentation.

