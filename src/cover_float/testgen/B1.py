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
from cover_float.common.config import Config
from cover_float.common.util import generate_float, generate_test_vector
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model

logger: log.ModelLogger = cast(log.ModelLogger, logging.getLogger("B1"))

SRC1_OPS = [const.OP_SQRT, const.OP_CLASS, const.OP_RFI]

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


def write1SrcTests(test_f: TextIO, cover_f: TextIO, config: Config, fmt: str, choices: list[int]) -> None:

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
                f"{op}_{rm}_{val}_{32 * '0'}_{32 * '0'}_{fmt}_{32 * '0'}_{fmt}_00", test_f, cover_f, config
            )


def writeCvtTests(test_f: TextIO, cover_f: TextIO, config: Config, fmt: str, choices: list[int]) -> None:

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
                        f"{op}_{rm}_{val}_{32 * '0'}_{32 * '0'}_{fmt}_{32 * '0'}_{resultFmt}_00",
                        test_f,
                        cover_f,
                        config,
                    )


def write2SrcTests(test_f: TextIO, cover_f: TextIO, config: Config, fmt: str, choices: list[int]) -> None:

    rm = const.ROUND_NEAR_EVEN

    print("// 2 source operations, all basic type input combinations", file=test_f)
    for op in SRC2_OPS:
        logger.status(f"OP IS: {op}")
        for i in choices:
            val1 = BASIC_TYPES[fmt][i]
            for j in choices:
                val2 = BASIC_TYPES[fmt][j]
                run_and_store_test_vector(
                    f"{op}_{rm}_{val1}_{val2}_{32 * '0'}_{fmt}_{32 * '0'}_{fmt}_00", test_f, cover_f, config
                )


def write3SrcTests(test_f: TextIO, cover_f: TextIO, config: Config, fmt: str, choices: list[int]) -> None:

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
                        f"{op}_{rm}_{val1}_{val2}_{val3}_{fmt}_{32 * '0'}_{fmt}_00", test_f, cover_f, config
                    )


def writeResultTests(test_f: TextIO, cover_f: TextIO, config: Config, fmt: str, full_coverage: bool) -> None:
    if not full_coverage:
        return

    # sqrt tests do not naturally do +2 and +1.5 in their tests

    # Generate a +2 result (input is 4)
    exp = 2
    mantissa = 0
    a = generate_float(0, exp, mantissa, fmt)
    tv = generate_test_vector(const.OP_SQRT, a, 0, 0, fmt, fmt)
    run_and_store_test_vector(tv, test_f, cover_f, config)

    # Generate a +1.5 result (input is 2.25)
    exp = 1
    mantissa = 1 << (const.MANTISSA_BITS[fmt] - 3)
    a = generate_float(0, exp, mantissa, fmt)
    tv = generate_test_vector(const.OP_SQRT, a, 0, 0, fmt, fmt)
    run_and_store_test_vector(tv, test_f, cover_f, config)


@register_model("B1")
def main(config: Config, test_vectors: TextIO, cover_vectors: TextIO) -> None:
    choices = list(range(len(BASIC_TYPES[const.FMT_SINGLE]))) if config.full_coverage_testgen else minimal_set

    for fmt in const.FLOAT_FMTS:
        write1SrcTests(test_vectors, cover_vectors, config, fmt, choices)
        write2SrcTests(test_vectors, cover_vectors, config, fmt, choices)
        write3SrcTests(test_vectors, cover_vectors, config, fmt, choices)
        writeCvtTests(test_vectors, cover_vectors, config, fmt, choices)
        writeResultTests(test_vectors, cover_vectors, config, fmt, config.full_coverage_testgen)
