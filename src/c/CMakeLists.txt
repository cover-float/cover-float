# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
#
# SPDX-License-Identifier: Apache-2.0

set(cover_float_warning_flags
    -Wall
    -Wextra
    -Werror
    -Wno-format
)

# Reference library with rounding result tracking modifications

add_library(coverfloat STATIC coverfloat.cpp)
target_compile_features(coverfloat PUBLIC cxx_std_14)
target_link_libraries(coverfloat PUBLIC softfloat Boost::multiprecision)
target_compile_options(coverfloat PRIVATE ${cover_float_warning_flags})
target_include_directories(coverfloat PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
set_target_properties(coverfloat PROPERTIES POSITION_INDEPENDENT_CODE ON)

# Softfloat taken directly from spike, without any modifications

add_library(unmodified_coverfloat STATIC coverfloat.cpp)
target_compile_features(unmodified_coverfloat PUBLIC cxx_std_14)
target_link_libraries(unmodified_coverfloat PUBLIC unmodified_softfloat Boost::multiprecision)
target_compile_options(unmodified_coverfloat PRIVATE ${cover_float_warning_flags})
target_compile_definitions(unmodified_coverfloat PUBLIC UNMODIFIED_SOFTFLOAT)
target_include_directories(unmodified_coverfloat PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
set_target_properties(unmodified_coverfloat PROPERTIES POSITION_INDEPENDENT_CODE ON)

# Python Modules

pybind11_add_module(_reference MODULE reference.cpp)
target_link_libraries(_reference PRIVATE coverfloat)
target_compile_options(_reference PRIVATE ${cover_float_warning_flags})

pybind11_add_module(_unmodified_reference MODULE unmodified_reference.cpp)
target_link_libraries(_unmodified_reference PRIVATE unmodified_coverfloat)
target_compile_options(_unmodified_reference PRIVATE ${cover_float_warning_flags})

install(TARGETS _reference _unmodified_reference DESTINATION ${SKBUILD_PROJECT_NAME})
