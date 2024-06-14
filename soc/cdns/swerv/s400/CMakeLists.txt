# Copyright (c) 2024 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

if(CONFIG_SOC_CDNS_SWERV_S400)
  zephyr_sources(
    startup.S
    soc.c
    )
endif()
