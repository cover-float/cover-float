# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
#
# SPDX-License-Identifier: Apache-2.0

include(FetchContent)

set(cover_float_spike_source_dir "${CMAKE_CURRENT_LIST_DIR}/spike")

FetchContent_Declare(
    unmodified_spike
    GIT_REPOSITORY https://github.com/riscv-software-src/riscv-isa-sim.git
    GIT_TAG b6a84e1f3a51800d8354489b6493723742abff9a
    GIT_SHALLOW
    GIT_SUBMODULES "berkeley-softfloat-3"
)

FetchContent_GetProperties(unmodified_spike)
if(NOT unmodified_spike_POPULATED)
    FetchContent_Populate(unmodified_spike)
endif()

file(GLOB SOFTFLOAT_SOURCES CONFIGURE_DEPENDS "${cover_float_spike_source_dir}/softfloat/*.c")

add_library(softfloat STATIC ${SOFTFLOAT_SOURCES})
target_compile_options(softfloat PRIVATE
    -Wall
    -Wextra
    -Werror
    -Wno-sign-compare
    -Wno-implicit-fallthrough
)
target_include_directories(softfloat PUBLIC "${cover_float_spike_source_dir}")
set_target_properties(softfloat PROPERTIES POSITION_INDEPENDENT_CODE ON)

file(GLOB UNMODIFIED_SOFTFLOAT_SOURCES CONFIGURE_DEPENDS "${unmodified_spike_SOURCE_DIR}/softfloat/*.c")

add_library(unmodified_softfloat STATIC ${UNMODIFIED_SOFTFLOAT_SOURCES})
target_compile_options(unmodified_softfloat PRIVATE
    -Wall
    -Wextra
    -Werror
    -Wno-sign-compare
    -Wno-implicit-fallthrough
    -Wno-unused-parameter
    -Wno-unused-variable
)
target_include_directories(unmodified_softfloat
    PUBLIC
        "${unmodified_spike_SOURCE_DIR}"
        "${CMAKE_CURRENT_SOURCE_DIR}/config_fix"
)
set_target_properties(unmodified_softfloat PROPERTIES POSITION_INDEPENDENT_CODE ON)
