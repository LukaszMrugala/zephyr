# SPDX-License-Identifier: Apache-2.0

# The ACE_SIM_DIR environment variable specifies the directory
# where the simulator was put, it is $HOME/acesim by default
# if ACE_SIM_DIR is not assign.
if(DEFINED ENV{ACE_SIM_DIR})
  set(SIM_DIR $ENV{ACE_SIM_DIR})
else()
  set(SIM_DIR ${ZEPHYR_STD_SIM_MODULE_DIR})
endif()

find_program(
  ACESIM
  PATHS ${SIM_DIR}
  NO_DEFAULT_PATH
  NAMES acesim.py
  )

set(ACESIM_FLAGS
  --soc ${CONFIG_SOC}
  --rimage ${APPLICATION_BINARY_DIR}/zephyr/zephyr.ri
  --cpus ${CONFIG_MP_MAX_NUM_CPUS}
  )

add_custom_target(run_acesim
  COMMAND
  ${ACESIM}
  ${ACESIM_FLAGS}
  WORKING_DIRECTORY ${APPLICATION_BINARY_DIR}
  DEPENDS zephyr.ri
  USES_TERMINAL
  )

add_custom_target(debugserver_acesim
  COMMAND
  ${ACESIM}
  ${ACESIM_FLAGS}
  --start-halted
  WORKING_DIRECTORY ${APPLICATION_BINARY_DIR}
  DEPENDS zephyr.ri
  USES_TERMINAL
  )

add_custom_target(trace_acesim
  COMMAND
  ${ACESIM}
  ${ACESIM_FLAGS}
  --trace
  WORKING_DIRECTORY ${APPLICATION_BINARY_DIR}
  DEPENDS zephyr.ri
  USES_TERMINAL
  )
