# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
#
# SPDX-License-Identifier: Apache-2.0

if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

include(FetchContent)

# Downloaded dependencies are vendored into the sdist, so that the sdist builds offline.
# When CMake runs for the sdist, they are downloaded into this folder (ignored by git).
# Other builds use the vendored copy if its pin is current, and download otherwise.
set(cover_float_vendor_dir "${CMAKE_CURRENT_LIST_DIR}/_vendor")

# Set SOURCE_DIR_ARGS in the caller to the extra FetchContent_Declare arguments for <name>.
function(cover_float_vendored_dependency name pin)
    string(TOUPPER "${name}" upper_name)
    set(vendor_source_dir "${cover_float_vendor_dir}/${name}")
    set(vendor_pin_file "${cover_float_vendor_dir}/${name}.pin")

    unset(FETCHCONTENT_SOURCE_DIR_${upper_name} CACHE)
    set(SOURCE_DIR_ARGS "" PARENT_SCOPE)

    if(SKBUILD_STATE STREQUAL "sdist")
        # Always download a fresh copy. Also remove the FetchContent state of earlier runs.
        file(REMOVE_RECURSE "${vendor_source_dir}" "${FETCHCONTENT_BASE_DIR}/${name}-subbuild")
        file(REMOVE "${vendor_pin_file}")
        set(SOURCE_DIR_ARGS SOURCE_DIR "${vendor_source_dir}" PARENT_SCOPE)
    elseif(EXISTS "${vendor_pin_file}")
        file(READ "${vendor_pin_file}" vendored_pin)
        if(vendored_pin STREQUAL pin)
            message(STATUS "Using vendored ${name} from ${vendor_source_dir}")
            set(FETCHCONTENT_SOURCE_DIR_${upper_name} "${vendor_source_dir}" CACHE PATH "" FORCE)
        else()
            message(STATUS "Vendored ${name} is out of date. Downloading it.")
        endif()
    endif()
endfunction()

# Call after <name> is populated. In the sdist build, record the pin of the vendored copy.
function(cover_float_vendored_dependency_done name pin)
    if(SKBUILD_STATE STREQUAL "sdist")
        file(WRITE "${cover_float_vendor_dir}/${name}.pin" "${pin}")
    endif()
endfunction()

add_subdirectory(boost)
add_subdirectory(softfloat)
