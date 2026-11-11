# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
#
# SPDX-License-Identifier: Apache-2.0

set(cover_float_spike_source_dir "${CMAKE_CURRENT_LIST_DIR}/spike")

set(unmodified_spike_tag b6a84e1f3a51800d8354489b6493723742abff9a)
cover_float_vendored_dependency(unmodified_spike "${unmodified_spike_tag}")

FetchContent_Declare(
    unmodified_spike
    GIT_REPOSITORY https://github.com/riscv-software-src/riscv-isa-sim.git
    GIT_TAG ${unmodified_spike_tag}
    GIT_SHALLOW
    GIT_SUBMODULES "berkeley-softfloat-3"
    PATCH_COMMAND  ${CMAKE_COMMAND} -E rm -f VERSION
    ${SOURCE_DIR_ARGS}
)

FetchContent_GetProperties(unmodified_spike)
if(NOT unmodified_spike_POPULATED)
    FetchContent_Populate(unmodified_spike)
endif()

# Upstream softfloat/ has symlinks into the berkeley-softfloat-3 submodule. Replace them with
# copies, so that the sdist needs only softfloat/ and has no symlinks.
if(SKBUILD_STATE STREQUAL "sdist")
    file(GLOB unmodified_softfloat_files LIST_DIRECTORIES false "${unmodified_spike_SOURCE_DIR}/softfloat/*")
    foreach(softfloat_file IN LISTS unmodified_softfloat_files)
        if(IS_SYMLINK "${softfloat_file}")
            get_filename_component(softfloat_file_target "${softfloat_file}" REALPATH)
            file(REMOVE "${softfloat_file}")
            configure_file("${softfloat_file_target}" "${softfloat_file}" COPYONLY)
        endif()
    endforeach()
endif()
cover_float_vendored_dependency_done(unmodified_spike "${unmodified_spike_tag}")

file(GLOB SOFTFLOAT_SOURCES CONFIGURE_DEPENDS "${cover_float_spike_source_dir}/softfloat/*.c")

add_library(softfloat STATIC ${SOFTFLOAT_SOURCES})
target_compile_options(softfloat PRIVATE
    -Wall
    -Wextra
    ${cover_float_werror}
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
    ${cover_float_werror}
    -Wno-sign-compare
    -Wno-implicit-fallthrough
    -Wno-unused-parameter
    -Wno-unused-variable
    -Wno-uninitialized-const-pointer
)
target_include_directories(unmodified_softfloat
    PUBLIC
        "${unmodified_spike_SOURCE_DIR}"
        "${CMAKE_CURRENT_SOURCE_DIR}/config_fix"
)
set_target_properties(unmodified_softfloat PROPERTIES POSITION_INDEPENDENT_CODE ON)
