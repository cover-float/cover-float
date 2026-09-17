# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
#
# SPDX-License-Identifier: Apache-2.0

if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

add_subdirectory(boost)
add_subdirectory(softfloat)
