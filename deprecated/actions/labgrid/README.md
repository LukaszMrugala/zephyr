# FMOS github-labgrid actions API

FMOS DevOps-maintained Github Actions that interface to labgrid coordinators for CI & test-automation functions

## Function Summary 

**[reserve](./reserve/action.yml)** - acquire FMOS target by name & geo

**[power](./power/action.yml)** - control AC-mains power of a target

**[release](./release/action.yml)** - release a FMOS target to the pool

## Usage

Actions should be called from a Github workflow:

  

  steps:

      - uses: actions/checkout@v2

      - name: reserve systems

        uses: intel-innersource/os.rtos.zephyr.devops.ci/actions/labgrid/reserve@main

        with:

          systemName: ${{ systemName }}

          timeoutSecs: 60

  

See the [included test-bench](../../.github/workflows/labgrid-actions-test-bench.yml) for a functioning Github workflow example.

## Deployment 

This API must execute on a Github Actions runner with direct network access to a labgrid coordinator.

**Important:** If power-control commands do not function, confirm that the 'no_proxy=.testnet' environment is set. While this environment variable is properly set on all FMOS infrastructure, the devtool-assisted Github Actions Runner installer ignores it so we must set it manually. 
