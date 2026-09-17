# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
#
# SPDX-License-Identifier: Apache-2.0

include(FetchContent)

FetchContent_Declare(
    boost_multiprecision
    URL "https://github.com/boostorg/multiprecision/archive/refs/tags/Boost_1_92_0.tar.gz"
    URL_HASH "SHA256=d53a907779b1ba88c80c15953c24106bf92b1b4731678441a8655e527c9d3df1"
)
FetchContent_MakeAvailable(boost_multiprecision)
