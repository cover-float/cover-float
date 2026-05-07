# Copyright (C) 2025-26 Harvey Mudd College
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, any work distributed under the
# License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific language governing permissions
# and limitations under the License.

import logging
from typing import TextIO, cast

import cover_float.common.constants as const
import cover_float.common.log as log
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model

logger: log.ModelLogger = cast(log.ModelLogger, logging.getLogger("B1"))

SRC1_OPS = [const.OP_SQRT, const.OP_CLASS]

CVT_OPS = [const.OP_CFI, const.OP_CFF]

SRC2_OPS = [
    const.OP_ADD,
    const.OP_SUB,
    const.OP_MUL,
    const.OP_DIV,
    const.OP_REM,
    const.OP_FEQ,
    const.OP_FLT,
    const.OP_FLE,
    const.OP_MIN,
    const.OP_MAX,
    const.OP_FSGNJ,
    const.OP_FSGNJN,
    const.OP_FSGNJX,
]

# superset ops (no designated test)
# const.OP_QC,
# const.OP_SC,
# const.OP_CSN,

SRC3_OPS = [const.OP_FMADD, const.OP_FMSUB, const.OP_FNMADD, const.OP_FNMSUB]

# superset ops (no designated test)
# const.OP_FMA,

RES_OPS = [
    const.OP_ADD,
    const.OP_SUB,
    const.OP_MUL,
    const.OP_DIV,
    const.OP_REM,
    const.OP_MIN,
    const.OP_MAX,
    const.OP_FSGNJ,
    const.OP_FSGNJN,
    const.OP_FSGNJX,
    const.OP_FMADD,
    const.OP_FMSUB,
    const.OP_FNMADD,
    const.OP_FNMSUB,
    const.OP_SQRT,
]

#    const.OP_CSN,
#    const.OP_FMA,

# INVERSE_OPS = {
#     const.OP_ADD    : const.OP_SUB
#     const.OP_SUB    : const.OP_ADD
#     const.OP_MUL    : const.OP_DIV
#     const.OP_DIV    : const.OP_MUL
#     const.OP_REM    :
#     const.OP_MIN    :
#     const.OP_MAX    :
#     const.OP_FSGNJ  :
#     const.OP_FSGNJN :
#     const.OP_FSGNJX :
#     const.OP_FMADD  :
#     const.OP_FMSUB  :
#     const.OP_FNMADD :
#     const.OP_FNMSUB :
#     const.OP_SQRT   :


# }

# Chooses +-0, +-1, +-min norm, +-max norm, +-max subnorm, +-mid subnorm, +-min subnorm, +-infinity, +-default nan,
# and one SNaN, and one QNaN. These are the minimal requirements from Aharoni et al. The full coverage model includes
# the complete set of basic types
minimal_set = [0, 1, 2, 3, 8, 9, 10, 11, 16, 17, 18, 19, 20, 21, 26, 27, 28, 29, 30, 32]

BASIC_TYPES = {
    const.FMT_SINGLE: [
        "00000000000000000000000000000000",  # Positive 0
        "00000000000000000000000080000000",  # Negative 0
        "0000000000000000000000003f800000",  # Positive 1
        "000000000000000000000000bf800000",  # Negative 1
        "0000000000000000000000003fc00000",  # Positive 1.5
        "000000000000000000000000bfc00000",  # Negative 1.5
        "00000000000000000000000040000000",  # Positive 2
        "000000000000000000000000c0000000",  # Negative 2
        "00000000000000000000000000800000",  # Positive Min Norm
        "00000000000000000000000080800000",  # Negative Min Norm
        "0000000000000000000000007f7fffff",  # Positive Max Norm
        "000000000000000000000000ff7fffff",  # Negative Max Norm
        "00000000000000000000000000800001",  # Positive Min Norm + 1
        "0000000000000000000000007f7ffffe",  # Positive Max Norm - 1
        "00000000000000000000000080800001",  # Negative Min Norm + 1
        "000000000000000000000000ff7ffffe",  # Negative Max Norm - 1
        "000000000000000000000000007fffff",  # Positive Max Subnorm
        "000000000000000000000000807fffff",  # Negative Max Subnorm
        "00000000000000000000000000400000",  # Positive Mid Subnorm
        "00000000000000000000000080400000",  # Negative Mid Subnorm
        "00000000000000000000000000000001",  # Positive Min Subnorm
        "00000000000000000000000080000001",  # Negative Min Subnorm
        "00000000000000000000000000000002",  # Positive Min Subnorm + 1
        "000000000000000000000000007ffffe",  # Positive Max Subnorm - 1
        "00000000000000000000000080000002",  # Negative Min Subnorm + 1
        "000000000000000000000000807ffffe",  # Negative Max Subnorm - 1
        "0000000000000000000000007f800000",  # Positive Infinity
        "000000000000000000000000ff800000",  # Negative Infinity
        "0000000000000000000000007fc00000",  # Positive QNaN Min
        "0000000000000000000000007fffffff",  # Positive QNaN Max
        "0000000000000000000000007f800001",  # Positive SNaN Min
        "0000000000000000000000007fbfffff",  # Positive SNaN Max
        "000000000000000000000000ffc00000",  # Negative QNaN Min
        "000000000000000000000000ffffffff",  # Negative QNaN Max
        "000000000000000000000000ff800001",  # Negative SNaN Min
        "000000000000000000000000ffbfffff",  # Negative SNaN Max
    ],
    const.FMT_DOUBLE: [
        "00000000000000000000000000000000",  # Positive 0
        "00000000000000008000000000000000",  # Negative 0
        "00000000000000003FF0000000000000",  # Positive 1
        "0000000000000000BFF0000000000000",  # Negative 1
        "00000000000000003FF8000000000000",  # Positive 1.5
        "0000000000000000BFF8000000000000",  # Negative 1.5
        "00000000000000004000000000000000",  # Positive 2
        "0000000000000000c000000000000000",  # Negative 2
        "00000000000000000010000000000000",  # Positive Min Norm
        "00000000000000008010000000000000",  # Negative Min Norm
        "00000000000000007FEFFFFFFFFFFFFF",  # Positive Max Norm
        "0000000000000000FFEFFFFFFFFFFFFF",  # Negative Max Norm
        "00000000000000000010000000000001",  # Positive Min Norm + 1
        "00000000000000007FEFFFFFFFFFFFFE",  # Positive Max Norm - 1
        "00000000000000008010000000000001",  # Negative Min Norm + 1
        "0000000000000000FFEFFFFFFFFFFFFE",  # Negative Max Norm - 1
        "0000000000000000000FFFFFFFFFFFFF",  # Positive Max Subnorm
        "0000000000000000800FFFFFFFFFFFFF",  # Negative Max Subnorm
        "00000000000000000000000000000001",  # Positive Min Subnorm
        "00000000000000008000000000000001",  # Negative Min Subnorm
        "00000000000000000000000000000002",  # Positive Min Subnorm + 1
        "0000000000000000000FFFFFFFFFFFFE",  # Positive Max Subnorm - 1
        "00000000000000008000000000000002",  # Negative Min Subnorm + 1
        "0000000000000000800FFFFFFFFFFFFE",  # *Negative Max Subnorm - 1
        "00000000000000000008000000000000",  # Positive Mid Subnorm
        "00000000000000008008000000000000",  # Negative Mid Subnorm
        "00000000000000007FF0000000000000",  # Positive Infinity
        "0000000000000000FFF0000000000000",  # Negative Infinity
        "00000000000000007FF8000000000000",  # Positive QNaN Min
        "00000000000000007FFFFFFFFFFFFFFF",  # Positive QNaN Max
        "00000000000000007FF0000000000001",  # Positive SNaN Min
        "00000000000000007FF7FFFFFFFFFFFF",  # Positive SNaN Max
        "0000000000000000FFF8000000000000",  # Negative QNaN Min
        "0000000000000000FFFFFFFFFFFFFFFF",  # Negative QNaN Max
        "0000000000000000FFF0000000000001",  # Negative QNaN Min
        "0000000000000000FFF7FFFFFFFFFFFF",  # Negative QNaN Max
    ],
    const.FMT_QUAD: [
        "00000000000000000000000000000000",  # Positive 0
        "80000000000000000000000000000000",  # Negative 0
        "3FFF0000000000000000000000000000",  # Positive 1
        "BFFF0000000000000000000000000000",  # Negative 1
        "3FFF8000000000000000000000000000",  # Positive 1.5
        "BFFF8000000000000000000000000000",  # Negative 1.5
        "40000000000000000000000000000000",  # Positive 2
        "c0000000000000000000000000000000",  # Negative 2
        "00010000000000000000000000000000",  # Positive Min Norm
        "80010000000000000000000000000000",  # Negative Min Norm
        "7FFEFFFFFFFFFFFFFFFFFFFFFFFFFFFF",  # Positive Max Norm
        "FFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFF",  # Negative Max Norm
        "00010000000000000000000000000001",  # Positive Min Norm + 1
        "7FFEFFFFFFFFFFFFFFFFFFFFFFFFFFFE",  # Positive Max Norm - 1
        "80010000000000000000000000000001",  # Negative Min Norm + 1
        "FFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFE",  # Negative Max Norm - 1
        "0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF",  # Positive Max Subnorm
        "8000FFFFFFFFFFFFFFFFFFFFFFFFFFFF",  # Negative Max Subnorm
        "00000000000000000000000000000001",  # Positive Min Subnorm
        "80000000000000000000000000000001",  # Negative Min Subnorm
        "00000000000000000000000000000001",  # Positive Min Subnorm
        "0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF",  # Positive Max Subnorm
        "80000000000000000000000000000001",  # Negative Min Subnorm
        "8000FFFFFFFFFFFFFFFFFFFFFFFFFFFF",  # Negative Max Subnorm
        "0000E000000000000000000000000000",  # Positive Mid Subnorm
        "8000E000000000000000000000000000",  # Negative Mid Subnorm
        "7FFF0000000000000000000000000000",  # Positive Infinity
        "FFFF0000000000000000000000000000",  # Negative Infinity
        "7FFF8000000000000000000000000000",  # Positive QNaN Min
        "7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",  # Positive QNan Max
        "7FFF0000000000000000000000000001",  # Positive SNaN Min
        "7FFF7FFFFFFFFFFFFFFFFFFFFFFFFFFF",  # Positive SNaN Max
        "FFFF8000000000000000000000000000",  # Negative QNaN Min
        "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",  # Negative QNaN Max
        "FFFF0000000000000000000000000001",  # Negative SNaN Min
        "FFFF7FFFFFFFFFFFFFFFFFFFFFFFFFFF",  # Negative SNaN Max
    ],
    const.FMT_HALF: [
        "00000000000000000000000000000000",  # Positive 0
        "00000000000000000000000000008000",  # Negative 0
        "00000000000000000000000000003C00",  # Positive 1
        "0000000000000000000000000000BC00",  # Negative 1
        "00000000000000000000000000003E00",  # Positive 1.5
        "0000000000000000000000000000BE00",  # Negative 1.5
        "00000000000000000000000000004000",  # Positive 2
        "0000000000000000000000000000C000",  # Negative 2
        "00000000000000000000000000000400",  # Positive Min Norm
        "00000000000000000000000000008400",  # Negative Min Norm
        "00000000000000000000000000007BFF",  # Positive Max Norm
        "0000000000000000000000000000FBFF",  # Negative Max Norm
        "00000000000000000000000000000401",  # Positive Min Norm + 1
        "00000000000000000000000000007BFE",  # Positive Max Norm - 1
        "00000000000000000000000000008401",  # Negative Min Norm + 1
        "0000000000000000000000000000FBFE",  # Negative Max Norm - 1
        "000000000000000000000000000003FF",  # Positive Max Subnorm
        "000000000000000000000000000083FF",  # Negative Max Subnorm
        "00000000000000000000000000000001",  # Positive Min Subnorm
        "00000000000000000000000000008001",  # Negative Min Subnorm
        "00000000000000000000000000000002",  # Positive Min Subnorm + 1
        "000000000000000000000000000003FE",  # Positive Max Subnorm - 1
        "00000000000000000000000000008002",  # Negative Min Subnorm + 1
        "000000000000000000000000000083FE",  # Negative Max Subnorm - 1
        "00000000000000000000000000000200",  # Positive Mid Subnorm
        "00000000000000000000000000008200",  # Negative Mid Subnorm
        "00000000000000000000000000007C00",  # Positive Infinity
        "0000000000000000000000000000FC00",  # Negative Infinity
        "00000000000000000000000000007E00",  # Positive QNaN Min
        "00000000000000000000000000007FFF",  # Positive QNaN Max
        "00000000000000000000000000007C01",  # Positive SNaN Min
        "00000000000000000000000000007DFF",  # Positive SNaN Max
        "0000000000000000000000000000FE00",  # Negative QNaN Min
        "0000000000000000000000000000FFFF",  # Negative QNaN Max
        "0000000000000000000000000000FC01",  # Negative SNaN Min
        "0000000000000000000000000000FDFF",  # Negative SNaN Max
    ],
    const.FMT_BF16: [
        "00000000000000000000000000000000",  # Positive 0
        "00000000000000000000000000008000",  # Negative 0
        "00000000000000000000000000003f80",  # Positive 1
        "0000000000000000000000000000bf80",  # Negative 1
        "00000000000000000000000000003fc0",  # Positive 1.5
        "0000000000000000000000000000bfc0",  # Negative 1.5
        "00000000000000000000000000004000",  # Positive 2
        "0000000000000000000000000000c000",  # Negative 2
        "00000000000000000000000000000080",  # Positive Min Norm
        "00000000000000000000000000008080",  # Negative Min Norm
        "00000000000000000000000000007f7f",  # Positive Max Norm
        "0000000000000000000000000000ff7f",  # Negative Max Norm
        "00000000000000000000000000000081",  # Positive Min Norm + 1
        "00000000000000000000000000007f7e",  # Positive Max Norm - 1
        "00000000000000000000000000008081",  # Negative Min Norm + 1
        "0000000000000000000000000000ff7e",  # Negative Max Norm - 1
        "0000000000000000000000000000007f",  # Positive Max Subnorm
        "0000000000000000000000000000807f",  # Negative Max Subnorm
        "00000000000000000000000000000001",  # Positive Min Subnorm
        "00000000000000000000000000008001",  # Negative Min Subnorm
        "00000000000000000000000000000002",  # Positive Min Subnorm + 1
        "0000000000000000000000000000007e",  # Positive Max Subnorm - 1
        "00000000000000000000000000008002",  # Negative Min Submorm + 1
        "0000000000000000000000000000807e",  # Negative Max Subnorm - 1
        "00000000000000000000000000000040",  # Positive Mid Subnorm
        "00000000000000000000000000008040",  # Negative Mid Subnorm
        "00000000000000000000000000007f80",  # Positive Infinity
        "0000000000000000000000000000ff80",  # Negative Infinity
        "00000000000000000000000000007fc0",  # Positive QNaN Min
        "00000000000000000000000000007fff",  # Positive QNaN Max
        "00000000000000000000000000007f81",  # Positive SNaN Min
        "00000000000000000000000000007fbf",  # Positive SNaN Max
        "0000000000000000000000000000ffc0",  # Negative QNaN Min
        "0000000000000000000000000000ffff",  # Negative QNaN Max
        "0000000000000000000000000000ff81",  # Negative SNaN Min
        "0000000000000000000000000000ffbf",  # Negative SNaN Max
    ],
}


def write1SrcTests(test_f: TextIO, cover_f: TextIO, fmt: str, choices: list[int]) -> None:

    rm = const.ROUND_NEAR_EVEN

    # print("\n//", file=f)
    print("// 1 source operations, all basic type input combinations", file=test_f)
    # print("//", file=f)
    for op in SRC1_OPS:
        logger.status(f"OP IS: {op}")
        # print(f"FMT IS: {fmt}")
        for i in choices:
            val = BASIC_TYPES[fmt][i]
            run_and_store_test_vector(
                f"{op}_{rm}_{val}_{32 * '0'}_{32 * '0'}_{fmt}_{32 * '0'}_{fmt}_00", test_f, cover_f
            )


def writeCvtTests(test_f: TextIO, cover_f: TextIO, fmt: str, choices: list[int]) -> None:

    rm = const.ROUND_NEAR_EVEN

    # print("\n//", file=f)
    print("// 1 source convert operations, all basic type input and result format combinations", file=test_f)
    # print("//", file=f)
    for op in CVT_OPS:
        logger.status(f"OP IS: {op}")
        # print(f"FMT IS: {fmt}")
        fmts = const.FLOAT_FMTS if op == const.OP_CFF else const.INT_FMTS
        for resultFmt in fmts:
            if resultFmt != fmt:
                for i in choices:
                    val = BASIC_TYPES[fmt][i]
                    run_and_store_test_vector(
                        f"{op}_{rm}_{val}_{32 * '0'}_{32 * '0'}_{fmt}_{32 * '0'}_{resultFmt}_00", test_f, cover_f
                    )


def write2SrcTests(test_f: TextIO, cover_f: TextIO, fmt: str, choices: list[int]) -> None:

    rm = const.ROUND_NEAR_EVEN

    print("// 2 source operations, all basic type input combinations", file=test_f)
    for op in SRC2_OPS:
        logger.status(f"OP IS: {op}")
        for i in choices:
            val1 = BASIC_TYPES[fmt][i]
            for j in choices:
                val2 = BASIC_TYPES[fmt][j]
                run_and_store_test_vector(
                    f"{op}_{rm}_{val1}_{val2}_{32 * '0'}_{fmt}_{32 * '0'}_{fmt}_00", test_f, cover_f
                )


def write3SrcTests(test_f: TextIO, cover_f: TextIO, fmt: str, choices: list[int]) -> None:

    rm = const.ROUND_NEAR_EVEN

    print("// 3 source operations, all basic type input combinations", file=test_f)
    for op in SRC3_OPS:
        logger.status(f"OP IS: {op}")
        for i in choices:
            val1 = BASIC_TYPES[fmt][i]
            for j in choices:
                val2 = BASIC_TYPES[fmt][j]
                for k in choices:
                    val3 = BASIC_TYPES[fmt][k]
                    run_and_store_test_vector(
                        f"{op}_{rm}_{val1}_{val2}_{val3}_{fmt}_{32 * '0'}_{fmt}_00", test_f, cover_f
                    )


@register_model("B1")
def main(test_vectors: TextIO, cover_vectors: TextIO) -> None:
    choices = list(range(len(BASIC_TYPES[const.FMT_SINGLE]))) if const.config.FULL_COVERAGE_TESTGEN else minimal_set

    for fmt in const.FLOAT_FMTS:
        write1SrcTests(test_vectors, cover_vectors, fmt, choices)
        write2SrcTests(test_vectors, cover_vectors, fmt, choices)
        write3SrcTests(test_vectors, cover_vectors, fmt, choices)
        writeCvtTests(test_vectors, cover_vectors, fmt, choices)
        # writeResultTests(f, fmt)


"""

import subprocess
import random

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

TEST_VECTOR_WIDTH_HEX  = 144
TEST_VECTOR_WIDTH_HEX_WITH_SEPARATORS = TEST_VECTOR_WIDTH_HEX + 8

ROUND_NEAR_EVEN = "00"

# Opcodes
const.OP_ADD    = "00000010"
const.OP_SUB    = "00000020"
const.OP_MUL    = "00000030"
const.OP_DIV    = "00000040"
const.OP_FMADD  = "00000051"
const.OP_FMSUB  = "00000052"
const.OP_FNMADD = "00000053"
const.OP_FNMSUB = "00000054"
const.OP_SQRT   = "00000060"
const.OP_REM    = "00000070"
const.OP_CFI    = "00000080"
const.OP_CFF    = "00000090"
const.OP_FEQ    = "000000B1"
const.OP_FLT    = "000000C1"
const.OP_FLE    = "000000C2"
const.OP_CLASS  = "000000D0"
const.OP_MIN    = "000000E0"
const.OP_MAX    = "000000F0"
const.OP_FSGNJ  = "00000101"
const.OP_FSGNJN = "00000102"
const.OP_FSGNJX = "00000103"

# Formats
const.FMT_HALF   = "00"
const.FMT_SINGLE = "01"
const.FMT_DOUBLE = "02"
const.FMT_QUAD   = "03"
const.FMT_BF16   = "04"
const.FMT_INT    = "81"
const.FMT_UINT   = "C1"
const.FMT_LONG   = "82"
const.FMT_ULONG  = "C2"

FMTS     = [const.FMT_SINGLE, const.FMT_DOUBLE, const.FMT_QUAD, const.FMT_HALF, const.FMT_BF16]
INT_FMTS = [const.FMT_INT, const.FMT_UINT, const.FMT_LONG, const.FMT_ULONG]

SRC1_OPS = [const.OP_SQRT, const.OP_CLASS]
SRC2_OPS = [
    const.OP_ADD, const.OP_SUB, const.OP_MUL, const.OP_DIV, const.OP_REM,
    const.OP_FEQ, const.OP_FLT, const.OP_FLE,
    const.OP_MIN, const.OP_MAX,
    const.OP_FSGNJ, const.OP_FSGNJN, const.OP_FSGNJX
]
SRC3_OPS = [const.OP_FMADD, const.OP_FMSUB, const.OP_FNMADD, const.OP_FNMSUB]
CVT_OPS  = [const.OP_CFI, const.OP_CFF]

RES_OPS = [
    const.OP_ADD, const.OP_SUB, const.OP_MUL, const.OP_DIV, const.OP_REM,
    const.OP_MIN, const.OP_MAX,
    const.OP_FSGNJ, const.OP_FSGNJN, const.OP_FSGNJX,
    const.OP_FMADD, const.OP_FMSUB, const.OP_FNMADD, const.OP_FNMSUB,
    const.OP_SQRT
]

# -----------------------------------------------------------------------------
# BASIC_TYPES (unchanged - REQUIRED)
# -----------------------------------------------------------------------------

BASIC_TYPES = {

    const.FMT_SINGLE : [
        "00000000000000000000000000000000",
        "00000000000000000000000080000000",
        "0000000000000000000000003f800000",
        "000000000000000000000000bf800000",
        "0000000000000000000000003fc00000",
        "000000000000000000000000bfc00000",
        "00000000000000000000000040000000",
        "000000000000000000000000c0000000",
        "00000000000000000000000000800000",
        "00000000000000000000000080800000",
        "0000000000000000000000007f7fffff",
        "000000000000000000000000ff7fffff",
        "00000000000000000000000000800000",
        "0000000000000000000000007f7fffff",
        "00000000000000000000000080800000",
        "000000000000000000000000ff7fffff",
        "000000000000000000000000007fffff",
        "000000000000000000000000807fffff",
        "00000000000000000000000000400000",
        "00000000000000000000000080400000",
        "00000000000000000000000000000001",
        "00000000000000000000000080000001",
        "00000000000000000000000000000001",
        "000000000000000000000000007fffff",
        "00000000000000000000000080000001",
        "000000000000000000000000807fffff",
        "0000000000000000000000007f800000",
        "000000000000000000000000ff800000",
        "0000000000000000000000007fc00000",
        "0000000000000000000000007fffffff",
        "0000000000000000000000007f800001",
        "0000000000000000000000007fbfffff",
        "000000000000000000000000ffc00000",
        "000000000000000000000000ffffffff",
        "000000000000000000000000ff800001",
        "000000000000000000000000ffbfffff"
    ],
    const.FMT_DOUBLE : [
        "00000000000000000000000000000000",
        "00000000000000008000000000000000",
        "00000000000000003FF0000000000000",
        "0000000000000000BFF0000000000000",
        "00000000000000003FF8000000000000",
        "0000000000000000BFF8000000000000",
        "00000000000000004000000000000000",
        "0000000000000000c000000000000000",
        "00000000000000000010000000000000",
        "00000000000000008010000000000000",
        "00000000000000007FEFFFFFFFFFFFFF",
        "0000000000000000FFEFFFFFFFFFFFFF",
        "00000000000000000010000000000000",
        "00000000000000007FEFFFFFFFFFFFFF",
        "00000000000000008010000000000000",
        "0000000000000000FFEFFFFFFFFFFFFF",
        "0000000000000000000FFFFFFFFFFFFF",
        "0000000000000000800FFFFFFFFFFFFF",
        "00000000000000000000000000000001",
        "00000000000000008000000000000001",
        "00000000000000000000000000000001",
        "0000000000000000000FFFFFFFFFFFFF",
        "00000000000000008000000000000001",
        "0000000000000000800FFFFFFFFFFFFF",
        "00000000000000000008000000000000",
        "00000000000000008008000000000000",
        "00000000000000007FF0000000000000",
        "0000000000000000FFF0000000000000",
        "00000000000000007FF8000000000000",
        "00000000000000007FFFFFFFFFFFFFFF",
        "00000000000000007FF0000000000001",
        "00000000000000007FF7FFFFFFFFFFFF",
        "0000000000000000FFF8000000000000",
        "0000000000000000FFFFFFFFFFFFFFFF",
        "0000000000000000FFF0000000000001",
        "0000000000000000FFF7FFFFFFFFFFFF"
    ],
    const.FMT_QUAD   : [
        "00000000000000000000000000000000",
        "80000000000000000000000000000000",
        "3FFF0000000000000000000000000000",
        "BFFF0000000000000000000000000000",
        "3FFF8000000000000000000000000000",
        "BFFF8000000000000000000000000000",
        "40000000000000000000000000000000",
        "c0000000000000000000000000000000",
        "00010000000000000000000000000000",
        "80010000000000000000000000000000",
        "7FFEFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "FFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "00010000000000000000000000000000",
        "7FFEFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "80010000000000000000000000000000",
        "FFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "8000FFFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "00000000000000000000000000000001",
        "80000000000000000000000000000001",
        "00000000000000000000000000000001",
        "0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "80000000000000000000000000000001",
        "8000FFFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "0000E000000000000000000000000000",
        "8000E000000000000000000000000000",
        "7FFF0000000000000000000000000000",
        "FFFF0000000000000000000000000000",
        "7FFF8000000000000000000000000000",
        "7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "7FFF0000000000000000000000000001",
        "7FFF7FFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "FFFF8000000000000000000000000000",
        "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "FFFF0000000000000000000000000001",
        "FFFF7FFFFFFFFFFFFFFFFFFFFFFFFFFF"
    ],
    const.FMT_HALF   : [
        "00000000000000000000000000000000",
        "00000000000000000000000000008000",
        "00000000000000000000000000003C00",
        "0000000000000000000000000000BC00",
        "00000000000000000000000000003E00",
        "0000000000000000000000000000BE00",
        "00000000000000000000000000004000",
        "0000000000000000000000000000C000",
        "00000000000000000000000000000400",
        "00000000000000000000000000008400",
        "00000000000000000000000000007BFF",
        "0000000000000000000000000000FBFF",
        "00000000000000000000000000000400",
        "00000000000000000000000000007BFF",
        "00000000000000000000000000008400",
        "0000000000000000000000000000FBFF",
        "000000000000000000000000000003FF",
        "000000000000000000000000000083FF",
        "00000000000000000000000000000001",
        "00000000000000000000000000008001",
        "00000000000000000000000000000001",
        "000000000000000000000000000003FF",
        "00000000000000000000000000008001",
        "000000000000000000000000000083FF",
        "00000000000000000000000000000200",
        "00000000000000000000000000008200",
        "00000000000000000000000000007C00",
        "0000000000000000000000000000FC00",
        "00000000000000000000000000007E00",
        "00000000000000000000000000007FFF",
        "00000000000000000000000000007C01",
        "00000000000000000000000000007DFF",
        "0000000000000000000000000000FE00",
        "0000000000000000000000000000FFFF",
        "0000000000000000000000000000FC01",
        "0000000000000000000000000000FDFF"
    ],
    const.FMT_BF16   : [
        "00000000000000000000000000000000",
        "00000000000000000000000000008000",
        "00000000000000000000000000003f80",
        "0000000000000000000000000000bf80",
        "00000000000000000000000000003fc0",
        "0000000000000000000000000000bfc0",
        "00000000000000000000000000004000",
        "0000000000000000000000000000c000",
        "00000000000000000000000000000080",
        "00000000000000000000000000008080",
        "00000000000000000000000000007f7f",
        "0000000000000000000000000000ff7f",
        "00000000000000000000000000000080",
        "00000000000000000000000000007f7f",
        "00000000000000000000000000008080",
        "0000000000000000000000000000ff7f",
        "0000000000000000000000000000007f",
        "0000000000000000000000000000807f",
        "00000000000000000000000000000001",
        "00000000000000000000000000008001",
        "00000000000000000000000000000001",
        "0000000000000000000000000000007f",
        "00000000000000000000000000008001",
        "0000000000000000000000000000807f",
        "00000000000000000000000000000040",
        "00000000000000000000000000008040",
        "00000000000000000000000000007f80",
        "0000000000000000000000000000ff80",
        "00000000000000000000000000007fc0",
        "00000000000000000000000000007fff",
        "00000000000000000000000000007f81",
        "00000000000000000000000000007fbf",
        "0000000000000000000000000000ffc0",
        "0000000000000000000000000000ffff",
        "0000000000000000000000000000ff81",
        "0000000000000000000000000000ffbf",
    ]
}


# -----------------------------------------------------------------------------
# Format metadata
# -----------------------------------------------------------------------------

FMT_BITS = {
    const.FMT_HALF:   16,
    const.FMT_BF16:   16,
    const.FMT_SINGLE: 32,
    const.FMT_DOUBLE: 64,
    const.FMT_QUAD:   128,
}

ZERO = {fmt: "0" * 32 for fmt in FMTS}

# -----------------------------------------------------------------------------
# Reference model helpers
# -----------------------------------------------------------------------------

def run_ref(line):
    p = subprocess.run(
        ["./build/coverfloat_reference", "-", "-", "--no-error-check"],
        input=line + "\n",
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=True
    )
    return p.stdout.strip()

def extract_result(out):
    return out.split("_")[-3]

def emit(f, line):
    out = run_ref(line)
    f.write(out[:TEST_VECTOR_WIDTH_HEX_WITH_SEPARATORS] + "\n")

# -----------------------------------------------------------------------------
# Random operand generation
# -----------------------------------------------------------------------------

def random_fp(fmt):
    bits = FMT_BITS[fmt]
    val  = random.getrandbits(bits)
    return f"{val:0{bits//4}x}".rjust(32, "0")

# -----------------------------------------------------------------------------
# Triviality filtering
# -----------------------------------------------------------------------------

def is_trivial(op, fmt, a, b=None, c=None):
    z = ZERO[fmt]

    if op == const.OP_SQRT:
        return a == z

    if op in [const.OP_ADD, const.OP_SUB]:
        return b == z

    if op == const.OP_MUL:
        return b in BASIC_TYPES[fmt][2:4]  # ±1

    if op == const.OP_DIV:
        return b in BASIC_TYPES[fmt][2:4]

    if op in SRC3_OPS:
        return b == z or c == z

    return False

# -----------------------------------------------------------------------------
# Result-driven operand solver (FIXED)
# -----------------------------------------------------------------------------

def find_operands_for_result(op, fmt, desired, max_attempts=20, refine_steps=5):
    '''
    Find operands that produce the desired result using the reference model.
    Algorithm:
        1. Pick a random first operand (or first two for 3-operand ops).
        2. Let the reference model compute the other operand(s) to hit 'desired'.
        3. Compare actual result to desired.
        4. If mismatch, adjust the computed operand(s) slightly and retry.
        5. After max_attempts, pick a new random starting operand.
    '''
    for _ in range(max_attempts):
        if op == const.OP_SQRT:
            a = random_fp(fmt)
            line = f"{op}_{ROUND_NEAR_EVEN}_{a}_{32*'0'}_{32*'0'}_{fmt}_{ZERO[fmt]}_{fmt}_00"
            result_line = run_ref(line)
            if extract_result(result_line) == desired:
                return (a,)

        elif op in SRC2_OPS:
            a = random_fp(fmt)
            # Try to iteratively refine b
            b = ZERO[fmt]
            for _ in range(refine_steps):
                line = f"{op}_{ROUND_NEAR_EVEN}_{a}_{b}_{32*'0'}_{fmt}_{ZERO[fmt]}_{fmt}_00"
                result_line = run_ref(line)
                actual = extract_result(result_line)
                if actual == desired:
                    return (a, b)
                # Slightly adjust b toward desired (use int representation for deterministic tweak)
                b = hex((int(b, 16) + int(desired, 16)) // 2)[2:].rjust(len(b), '0')

        elif op in SRC3_OPS:
            a, b = random_fp(fmt), random_fp(fmt)
            # Try to iteratively refine c
            c = ZERO[fmt]
            for _ in range(refine_steps):
                line = f"{op}_{ROUND_NEAR_EVEN}_{a}_{b}_{c}_{fmt}_{ZERO[fmt]}_{fmt}_00"
                result_line = run_ref(line)
                actual = extract_result(result_line)
                if actual == desired:
                    return (a, b, c)
                # Slightly adjust c toward desired
                c = hex((int(c, 16) + int(desired, 16)) // 2)[2:].rjust(len(c), '0')
    return None


# -----------------------------------------------------------------------------
# Exhaustive tests (unchanged behavior)
# -----------------------------------------------------------------------------

def write1SrcTests(f, fmt):
    for op in SRC1_OPS:
        for a in BASIC_TYPES[fmt]:
            emit(f, f"{op}_{ROUND_NEAR_EVEN}_{a}_{32*'0'}_{32*'0'}_{fmt}_{ZERO[fmt]}_{fmt}_00")

def write2SrcTests(f, fmt):
    for op in SRC2_OPS:
        for a in BASIC_TYPES[fmt]:
            for b in BASIC_TYPES[fmt]:
                emit(f, f"{op}_{ROUND_NEAR_EVEN}_{a}_{b}_{32*'0'}_{fmt}_{ZERO[fmt]}_{fmt}_00")

def write3SrcTests(f, fmt):
    for op in SRC3_OPS:
        for a in BASIC_TYPES[fmt]:
            for b in BASIC_TYPES[fmt]:
                for c in BASIC_TYPES[fmt]:
                    emit(f, f"{op}_{ROUND_NEAR_EVEN}_{a}_{b}_{c}_{fmt}_{ZERO[fmt]}_{fmt}_00")

def writeCvtTests(f, fmt):
    for op in CVT_OPS:
        targets = FMTS if op == const.OP_CFF else INT_FMTS
        for tfmt in targets:
            if tfmt == fmt:
                continue
            for a in BASIC_TYPES[fmt]:
                emit(f, f"{op}_{ROUND_NEAR_EVEN}_{a}_{32*'0'}_{32*'0'}_{fmt}_{ZERO[fmt]}_{tfmt}_00")

# -----------------------------------------------------------------------------
# Result-driven designated tests
# -----------------------------------------------------------------------------

def writeResultTests(f, fmt):
    for op in RES_OPS:
        for desired in BASIC_TYPES[fmt]:
            print(f"trying to find operands for operation {op} to get result {desired}")
            ops = find_operands_for_result(op, fmt, desired)
            if ops is None:
                print("FAILED")
                continue

            if len(ops) == 1:
                a, = ops
                line = f"{op}_{ROUND_NEAR_EVEN}_{a}_{32*'0'}_{32*'0'}_{fmt}_{ZERO[fmt]}_{fmt}_00"
            elif len(ops) == 2:
                a, b = ops
                line = f"{op}_{ROUND_NEAR_EVEN}_{a}_{b}_{32*'0'}_{fmt}_{ZERO[fmt]}_{fmt}_00"
            else:
                a, b, c = ops
                line = f"{op}_{ROUND_NEAR_EVEN}_{a}_{b}_{c}_{fmt}_{ZERO[fmt]}_{fmt}_00"

            emit(f, line)

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

def main():
    random.seed(1)
    with open("./tests/testvectors/B1_tv.txt", "w") as f:
        for fmt in FMTS:
            # write1SrcTests(f, fmt)
            # write2SrcTests(f, fmt)
            # write3SrcTests(f, fmt)
            # writeCvtTests(f, fmt)
            writeResultTests(f, fmt)

if __name__ == "__main__":
    main()
"""
