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

from typing import TextIO

import cover_float.common.constants as const
from cover_float.common.config import Config
from cover_float.common.util import generate_float, generate_test_vector
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import get_model_logger, register_model

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


minimal_set = [
    "Positive 0",
    "Negative 0",
    "Positive 1",
    "Negative 1",
    "Positive Min Norm",
    "Negative Min Norm",
    "Positive Max Norm",
    "Negative Max Norm",
    "Positive Max Subnorm",
    "Negative Max Subnorm",
    "Positive Mid Subnorm",
    "Negative Mid Subnorm",
    "Positive Min Subnorm",
    "Negative Min Subnorm",
    "Positive Infinity",
    "Negative Infinity",
    "Negative QNaN Min",
    "Positive QNaN Min",
    "Positive QNaN Max",
    "Positive SNaN Min",
]

# Old index-based minimal_set that references FMT_SINGLE
# minimal_set = [0, 1, 2, 3, 8, 9, 10, 11, 16, 17, 18, 19, 20, 21, 26, 27, 28, 29, 30, 32]

BASIC_TYPES = {
    const.FMT_SINGLE: {
        "Positive 0": "00000000000000000000000000000000",
        "Negative 0": "00000000000000000000000080000000",
        "Positive 1": "0000000000000000000000003f800000",
        "Negative 1": "000000000000000000000000bf800000",
        "Positive 1.5": "0000000000000000000000003fc00000",
        "Negative 1.5": "000000000000000000000000bfc00000",
        "Positive 2": "00000000000000000000000040000000",
        "Negative 2": "000000000000000000000000c0000000",
        "Positive Min Norm": "00000000000000000000000000800000",
        "Negative Min Norm": "00000000000000000000000080800000",
        "Positive Max Norm": "0000000000000000000000007f7fffff",
        "Negative Max Norm": "000000000000000000000000ff7fffff",
        "Positive Min Norm + 1": "00000000000000000000000000800001",
        "Positive Max Norm - 1": "0000000000000000000000007f7ffffe",
        "Negative Min Norm + 1": "00000000000000000000000080800001",
        "Negative Max Norm - 1": "000000000000000000000000ff7ffffe",
        "Positive Max Subnorm": "000000000000000000000000007fffff",
        "Negative Max Subnorm": "000000000000000000000000807fffff",
        "Positive Mid Subnorm": "00000000000000000000000000400000",
        "Negative Mid Subnorm": "00000000000000000000000080400000",
        "Positive Min Subnorm": "00000000000000000000000000000001",
        "Negative Min Subnorm": "00000000000000000000000080000001",
        "Positive Min Subnorm + 1": "00000000000000000000000000000002",
        "Positive Max Subnorm - 1": "000000000000000000000000007ffffe",
        "Negative Min Subnorm + 1": "00000000000000000000000080000002",
        "Negative Max Subnorm - 1": "000000000000000000000000807ffffe",
        "Positive Infinity": "0000000000000000000000007f800000",
        "Negative Infinity": "000000000000000000000000ff800000",
        "Positive QNaN Min": "0000000000000000000000007fc00000",
        "Positive QNaN Max": "0000000000000000000000007fffffff",
        "Positive SNaN Min": "0000000000000000000000007f800001",
        "Positive SNaN Max": "0000000000000000000000007fbfffff",
        "Negative QNaN Min": "000000000000000000000000ffc00000",
        "Negative QNaN Max": "000000000000000000000000ffffffff",
        "Negative SNaN Min": "000000000000000000000000ff800001",
        "Negative SNaN Max": "000000000000000000000000ffbfffff",
    },
    const.FMT_DOUBLE: {
        "Positive 0": "00000000000000000000000000000000",
        "Negative 0": "00000000000000008000000000000000",
        "Positive 1": "00000000000000003FF0000000000000",
        "Negative 1": "0000000000000000BFF0000000000000",
        "Positive 1.5": "00000000000000003FF8000000000000",
        "Negative 1.5": "0000000000000000BFF8000000000000",
        "Positive 2": "00000000000000004000000000000000",
        "Negative 2": "0000000000000000c000000000000000",
        "Positive Min Norm": "00000000000000000010000000000000",
        "Negative Min Norm": "00000000000000008010000000000000",
        "Positive Max Norm": "00000000000000007FEFFFFFFFFFFFFF",
        "Negative Max Norm": "0000000000000000FFEFFFFFFFFFFFFF",
        "Positive Min Norm + 1": "00000000000000000010000000000001",
        "Positive Max Norm - 1": "00000000000000007FEFFFFFFFFFFFFE",
        "Negative Min Norm + 1": "00000000000000008010000000000001",
        "Negative Max Norm - 1": "0000000000000000FFEFFFFFFFFFFFFE",
        "Positive Max Subnorm": "0000000000000000000FFFFFFFFFFFFF",
        "Negative Max Subnorm": "0000000000000000800FFFFFFFFFFFFF",
        "Positive Min Subnorm": "00000000000000000000000000000001",
        "Negative Min Subnorm": "00000000000000008000000000000001",
        "Positive Min Subnorm + 1": "00000000000000000000000000000002",
        "Positive Max Subnorm - 1": "0000000000000000000FFFFFFFFFFFFE",
        "Negative Min Subnorm + 1": "00000000000000008000000000000002",
        "Negative Max Subnorm - 1": "0000000000000000800FFFFFFFFFFFFE",
        "Positive Mid Subnorm": "00000000000000000008000000000000",
        "Negative Mid Subnorm": "00000000000000008008000000000000",
        "Positive Infinity": "00000000000000007FF0000000000000",
        "Negative Infinity": "0000000000000000FFF0000000000000",
        "Positive QNaN Min": "00000000000000007FF8000000000000",
        "Positive QNaN Max": "00000000000000007FFFFFFFFFFFFFFF",
        "Positive SNaN Min": "00000000000000007FF0000000000001",
        "Positive SNaN Max": "00000000000000007FF7FFFFFFFFFFFF",
        "Negative QNaN Min": "0000000000000000FFF8000000000000",
        "Negative QNaN Max": "0000000000000000FFFFFFFFFFFFFFFF",
        "Negative SNaN Min": "0000000000000000FFF0000000000001",
        "Negative SNaN Max": "0000000000000000FFF7FFFFFFFFFFFF",
    },
    const.FMT_QUAD: {
        "Positive 0": "00000000000000000000000000000000",
        "Negative 0": "80000000000000000000000000000000",
        "Positive 1": "3FFF0000000000000000000000000000",
        "Negative 1": "BFFF0000000000000000000000000000",
        "Positive 1.5": "3FFF8000000000000000000000000000",
        "Negative 1.5": "BFFF8000000000000000000000000000",
        "Positive 2": "40000000000000000000000000000000",
        "Negative 2": "c0000000000000000000000000000000",
        "Positive Min Norm": "00010000000000000000000000000000",
        "Negative Min Norm": "80010000000000000000000000000000",
        "Positive Max Norm": "7FFEFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "Negative Max Norm": "FFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "Positive Min Norm + 1": "00010000000000000000000000000001",
        "Positive Max Norm - 1": "7FFEFFFFFFFFFFFFFFFFFFFFFFFFFFFE",
        "Negative Min Norm + 1": "80010000000000000000000000000001",
        "Negative Max Norm - 1": "FFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFE",
        "Positive Max Subnorm": "0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "Negative Max Subnorm": "8000FFFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "Positive Min Subnorm": "00000000000000000000000000000001",
        "Negative Min Subnorm": "80000000000000000000000000000001",
        "Positive Min Subnorm + 1": "00000000000000000000000000000002",
        "Positive Max Subnorm - 1": "0000FFFFFFFFFFFFFFFFFFFFFFFFFFFE",
        "Negative Min Subnorm + 1": "80000000000000000000000000000002",
        "Negative Max Subnorm - 1": "8000FFFFFFFFFFFFFFFFFFFFFFFFFFFE",
        "Positive Mid Subnorm": "0000E000000000000000000000000000",
        "Negative Mid Subnorm": "8000E000000000000000000000000000",
        "Positive Infinity": "7FFF0000000000000000000000000000",
        "Negative Infinity": "FFFF0000000000000000000000000000",
        "Positive QNaN Min": "7FFF8000000000000000000000000000",
        "Positive QNaN Max": "7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "Positive SNaN Min": "7FFF0000000000000000000000000001",
        "Positive SNaN Max": "7FFF7FFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "Negative QNaN Min": "FFFF8000000000000000000000000000",
        "Negative QNaN Max": "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
        "Negative SNaN Min": "FFFF0000000000000000000000000001",
        "Negative SNaN Max": "FFFF7FFFFFFFFFFFFFFFFFFFFFFFFFFF",
    },
    const.FMT_HALF: {
        "Positive 0": "00000000000000000000000000000000",
        "Negative 0": "00000000000000000000000000008000",
        "Positive 1": "00000000000000000000000000003C00",
        "Negative 1": "0000000000000000000000000000BC00",
        "Positive 1.5": "00000000000000000000000000003E00",
        "Negative 1.5": "0000000000000000000000000000BE00",
        "Positive 2": "00000000000000000000000000004000",
        "Negative 2": "0000000000000000000000000000C000",
        "Positive Min Norm": "00000000000000000000000000000400",
        "Negative Min Norm": "00000000000000000000000000008400",
        "Positive Max Norm": "00000000000000000000000000007BFF",
        "Negative Max Norm": "0000000000000000000000000000FBFF",
        "Positive Min Norm + 1": "00000000000000000000000000000401",
        "Positive Max Norm - 1": "00000000000000000000000000007BFE",
        "Negative Min Norm + 1": "00000000000000000000000000008401",
        "Negative Max Norm - 1": "0000000000000000000000000000FBFE",
        "Positive Max Subnorm": "000000000000000000000000000003FF",
        "Negative Max Subnorm": "000000000000000000000000000083FF",
        "Positive Min Subnorm": "00000000000000000000000000000001",
        "Negative Min Subnorm": "00000000000000000000000000008001",
        "Positive Min Subnorm + 1": "00000000000000000000000000000002",
        "Positive Max Subnorm - 1": "000000000000000000000000000003FE",
        "Negative Min Subnorm + 1": "00000000000000000000000000008002",
        "Negative Max Subnorm - 1": "000000000000000000000000000083FE",
        "Positive Mid Subnorm": "00000000000000000000000000000200",
        "Negative Mid Subnorm": "00000000000000000000000000008200",
        "Positive Infinity": "00000000000000000000000000007C00",
        "Negative Infinity": "0000000000000000000000000000FC00",
        "Positive QNaN Min": "00000000000000000000000000007E00",
        "Positive QNaN Max": "00000000000000000000000000007FFF",
        "Positive SNaN Min": "00000000000000000000000000007C01",
        "Positive SNaN Max": "00000000000000000000000000007DFF",
        "Negative QNaN Min": "0000000000000000000000000000FE00",
        "Negative QNaN Max": "0000000000000000000000000000FFFF",
        "Negative SNaN Min": "0000000000000000000000000000FC01",
        "Negative SNaN Max": "0000000000000000000000000000FDFF",
    },
    const.FMT_BF16: {
        "Positive 0": "00000000000000000000000000000000",
        "Negative 0": "00000000000000000000000000008000",
        "Positive 1": "00000000000000000000000000003f80",
        "Negative 1": "0000000000000000000000000000bf80",
        "Positive 1.5": "00000000000000000000000000003fc0",
        "Negative 1.5": "0000000000000000000000000000bfc0",
        "Positive 2": "00000000000000000000000000004000",
        "Negative 2": "0000000000000000000000000000c000",
        "Positive Min Norm": "00000000000000000000000000000080",
        "Negative Min Norm": "00000000000000000000000000008080",
        "Positive Max Norm": "00000000000000000000000000007f7f",
        "Negative Max Norm": "0000000000000000000000000000ff7f",
        "Positive Min Norm + 1": "00000000000000000000000000000081",
        "Positive Max Norm - 1": "00000000000000000000000000007f7e",
        "Negative Min Norm + 1": "00000000000000000000000000008081",
        "Negative Max Norm - 1": "0000000000000000000000000000ff7e",
        "Positive Max Subnorm": "0000000000000000000000000000007f",
        "Negative Max Subnorm": "0000000000000000000000000000807f",
        "Positive Min Subnorm": "00000000000000000000000000000001",
        "Negative Min Subnorm": "00000000000000000000000000008001",
        "Positive Min Subnorm + 1": "00000000000000000000000000000002",
        "Positive Max Subnorm - 1": "0000000000000000000000000000007e",
        "Negative Min Subnorm + 1": "00000000000000000000000000008002",
        "Negative Max Subnorm - 1": "0000000000000000000000000000807e",
        "Positive Mid Subnorm": "00000000000000000000000000000040",
        "Negative Mid Subnorm": "00000000000000000000000000008040",
        "Positive Infinity": "00000000000000000000000000007f80",
        "Negative Infinity": "0000000000000000000000000000ff80",
        "Positive QNaN Min": "00000000000000000000000000007fc0",
        "Positive QNaN Max": "00000000000000000000000000007fff",
        "Positive SNaN Min": "00000000000000000000000000007f81",
        "Positive SNaN Max": "00000000000000000000000000007fbf",
        "Negative QNaN Min": "0000000000000000000000000000ffc0",
        "Negative QNaN Max": "0000000000000000000000000000ffff",
        "Negative SNaN Min": "0000000000000000000000000000ff81",
        "Negative SNaN Max": "0000000000000000000000000000ffbf",
    },
}


def write1SrcTests(test_f: TextIO, cover_f: TextIO, config: Config, fmt: str, choices: list[str]) -> None:

    rm = const.ROUND_NEAR_EVEN

    # print("\n//", file=f)
    print("// 1 source operations, all basic type input combinations", file=test_f)
    # print("//", file=f)
    for op in SRC1_OPS:
        get_model_logger("B1").status(f"OP IS: {op}")
        # print(f"FMT IS: {fmt}")
        for i in choices:
            val = BASIC_TYPES[fmt][i]
            run_and_store_test_vector(
                f"{op}_{rm}_{val}_{32 * '0'}_{32 * '0'}_{fmt}_{32 * '0'}_{fmt}_00", test_f, cover_f, config
            )


def writeCvtTests(test_f: TextIO, cover_f: TextIO, config: Config, fmt: str, choices: list[str]) -> None:

    rm = const.ROUND_NEAR_EVEN

    # print("\n//", file=f)
    print("// 1 source convert operations, all basic type input and result format combinations", file=test_f)
    # print("//", file=f)
    for op in CVT_OPS:
        get_model_logger("B1").status(f"OP IS: {op}")
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


def write2SrcTests(test_f: TextIO, cover_f: TextIO, config: Config, fmt: str, choices: list[str]) -> None:

    rm = const.ROUND_NEAR_EVEN

    print("// 2 source operations, all basic type input combinations", file=test_f)
    for op in SRC2_OPS:
        get_model_logger("B1").status(f"OP IS: {op}")
        for i in choices:
            val1 = BASIC_TYPES[fmt][i]
            for j in choices:
                val2 = BASIC_TYPES[fmt][j]
                run_and_store_test_vector(
                    f"{op}_{rm}_{val1}_{val2}_{32 * '0'}_{fmt}_{32 * '0'}_{fmt}_00", test_f, cover_f, config
                )


def write3SrcTests(test_f: TextIO, cover_f: TextIO, config: Config, fmt: str, choices: list[str]) -> None:

    rm = const.ROUND_NEAR_EVEN

    print("// 3 source operations, all basic type input combinations", file=test_f)
    for op in SRC3_OPS:
        get_model_logger("B1").status(f"OP IS: {op}")
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
    choices = list(BASIC_TYPES[const.FMT_SINGLE].keys()) if config.full_coverage_testgen else minimal_set

    for fmt in const.FLOAT_FMTS:
        write1SrcTests(test_vectors, cover_vectors, config, fmt, choices)
        write2SrcTests(test_vectors, cover_vectors, config, fmt, choices)
        write3SrcTests(test_vectors, cover_vectors, config, fmt, choices)
        writeCvtTests(test_vectors, cover_vectors, config, fmt, choices)
        writeResultTests(test_vectors, cover_vectors, config, fmt, config.full_coverage_testgen)
