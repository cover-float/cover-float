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

# Lamarr
# B21 Model

import random
from random import seed
from typing import TextIO

from cover_float.common.constants import (
    BIASED_EXP,
    EXPONENT_BITS,
    FLOAT_FMTS,
    MANTISSA_BITS,
    OP_DIV,
    OP_REM,
    ROUNDING_MODES,
)
from cover_float.common.util import reproducible_hash
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model


def generate_FP(precision: str, input_sign: str, input_exponent: int, input_mantissa: int) -> str:
    m_bits = MANTISSA_BITS[precision]
    e_bits = EXPONENT_BITS[precision]

    # 1. Calculate and format the exponent
    exp_val = input_exponent
    exponent = f"{exp_val:0{e_bits}b}"

    mantissa = f"{input_mantissa:0{m_bits}b}"

    # 2. Check for Exponent Overflow/Underflow
    if len(exponent) != e_bits:
        raise ValueError(
            f"Alignment Error: Exponent binary '{exponent}' is {len(exponent)} bits long. "
            f"Expected exactly {e_bits} bits. (Calculated value was {exp_val})"
        )

    # 3. Validate Sign Bit
    if len(input_sign) != 1 or input_sign not in ("0", "1"):
        raise ValueError(f"Alignment Error: Sign bit must be exactly '0' or '1'. Got: '{input_sign}'")

    # 4. Construct the full binary string
    complete = input_sign + exponent + mantissa
    total_bits = len(complete)

    # 5. Validate total bit length is a clean multiple of 4 (for hex conversion)
    if total_bits % 4 != 0:
        raise ValueError(
            f"Alignment Error: Total bit length ({total_bits}) is not a multiple of 4. "
            f"Sign: 1, Exp: {e_bits}, Mantissa: {len(mantissa)}"
        )

    # 6. Convert to Hex AND explicitly pad to the correct number of characters
    hex_chars_needed = total_bits // 4
    fp_complete = format(int(complete, 2), "X").zfill(hex_chars_needed)

    return fp_complete


def getInput(precision: str, input_key: str, hashString: str) -> str:
    m_bits = MANTISSA_BITS[precision]
    min_exp = BIASED_EXP[precision][0]
    max_exp = BIASED_EXP[precision][1]

    hashval = reproducible_hash(hashString)
    seed(hashval)

    input_vals = {
        "0": {"biased_exp": 0, "mantissa": 0},
        "rand": {"biased_exp": random.randint(min_exp, max_exp), "mantissa": random.randint(1, (1 << m_bits) - 1)},
        "inf": {"biased_exp": max_exp + 1, "mantissa": 0},
        "nan": {"biased_exp": max_exp + 1, "mantissa": random.randint(1, (1 << m_bits) - 1)},
    }

    exp = input_vals[input_key]["biased_exp"]
    mantissa = input_vals[input_key]["mantissa"]

    return generate_FP(precision, str(random.randint(0, 1)), exp, mantissa)


def genTests(test_f: TextIO, cover_f: TextIO) -> None:
    for rounding_mode in ROUNDING_MODES:
        for precision in FLOAT_FMTS:
            for op in [OP_DIV, OP_REM]:
                for input_1 in ["0", "rand", "inf", "nan"]:
                    for input_2 in ["0", "rand", "inf", "nan"]:
                        a = getInput(precision, input_1, input_1 + op + input_2)
                        b = getInput(precision, input_2, input_2 + op + input_1)
                        run_and_store_test_vector(
                            f"{op}_{rounding_mode}_{a}_{b}_{32 * '0'}_{precision}_{32 * '0'}_{precision}_00",
                            test_f,
                            cover_f,
                        )


@register_model("B20")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    genTests(test_f, cover_f)
