# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
#
# SPDX-License-Identifier: Apache-2.0

set(boost_multiprecision_url "https://github.com/boostorg/multiprecision/archive/refs/tags/Boost_1_92_0.tar.gz")
set(boost_multiprecision_hash "SHA256=d53a907779b1ba88c80c15953c24106bf92b1b4731678441a8655e527c9d3df1")
cover_float_vendored_dependency(boost_multiprecision "${boost_multiprecision_hash}")

FetchContent_Declare(
    boost_multiprecision
    URL "${boost_multiprecision_url}"
    URL_HASH "${boost_multiprecision_hash}"
    ${SOURCE_DIR_ARGS}
)
FetchContent_MakeAvailable(boost_multiprecision)
cover_float_vendored_dependency_done(boost_multiprecision "${boost_multiprecision_hash}")
