# Zephyr DevOps CI Modules

This directory contains modules that implement the internal CI functions for Zephyr Project at Intel

## sanitycheck-runner.sh

This is a shell script that implements a standardized, parallel-executed Zephyr sanitycheck validation across all internal CI functions. It is intended to be branch, build-environment & CI flow agnostic.

* Input is a west initialized & updated Zephyr tree in the CWD. 
* It accepts parameters to configure the parallel execution
* Output is junit xml intended for consumption by upstream data visualization & reporting tools.
* Return status reflects total pass/fail of the sanitycheck default cases after three retries.

### Notes

Sanitycheck for v1.14 branch has known issues with qemu false-positives. Like external CI, this runner implements two retries on failures to confirm failures before reporting a failure on the entire run. **

## sanitycheck-pipeline.groovy 

This is a Jenkins pipeline script wrapper for the sanitycheck-runner.sh script that implements a Gitlab CI flow for internal Zephyr CI functions. It supports parallel build expansion across Jenkins build agents & is intended to be called from a Jenkins job.

See source for addition documentation & calling convention.
