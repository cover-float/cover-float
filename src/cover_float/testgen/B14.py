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

# By: Sisi Wang
# B14.py
# Fused Multiply-Add (FMA)
# B14 -> Multiply-Add: Shift
#
# Tests every possible value of the alignment shift between the multiplication
# result and the addend in a fused multiply-add (FMA) operation. The shift is
# defined as S = unbiased_exp(A*B) - unbiased_exp(C).

import logging
import random
from typing import TextIO, cast

import cover_float.common.constants as const
import cover_float.common.log as log
from cover_float.common.util import reproducible_hash
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model

logger: log.ModelLogger = cast(log.ModelLogger, logging.getLogger("B14"))

OPS = [const.OP_FMADD, const.OP_FMSUB, const.OP_FNMADD, const.OP_FNMSUB]


def decimalComponentsToHex(fmt: str, sign: int, biased_exp: int, mantissa: int) -> str:
    b_sign = f"{sign:01b}"
    b_exponent = f"{biased_exp:0{const.EXPONENT_BITS[fmt]}b}"
    b_mantissa = f"{mantissa:0{const.MANTISSA_BITS[fmt]}b}"
    b_complete = b_sign + b_exponent + b_mantissa
    h_complete = f"{int(b_complete, 2):032X}"
    return h_complete


def generate_b14_tests(test_f: TextIO, cover_f: TextIO, fmt: str) -> None:
    p = const.MANTISSA_BITS[fmt] + 1
    min_u, max_u = const.UNBIASED_EXP[fmt]
    bias = const.BIAS[fmt]

    # Build shift list: [small_anchor] + [mid_range] + [large_anchor]
    small_anchor = -(2 * p + 2)
    mid_range = list(range(-(2 * p + 1), (p + 1) + 1))
    large_anchor = p + 2
    shift_list = [small_anchor, *mid_range, large_anchor]

    for op in OPS:
        # Seed once per (fmt, op) pair, outside the shift loop
        rng = random.Random(reproducible_hash(f"B14 {fmt} {op}"))

        for target_shift in shift_list:
            # Section 5: Exponent Construction Algorithm

            # 1. Pick unbiased C exponent
            c_lo = max(min_u, 2 * min_u - target_shift)
            c_hi = min(max_u, 2 * max_u - target_shift)

            if c_lo > c_hi:
                continue

            c_u = rng.randint(c_lo, c_hi)

            # 2. Compute unbiased product exponent
            p_u = target_shift + c_u

            # 3. Split p_u into a_u + b_u
            a_lo = max(min_u, p_u - max_u)
            a_hi = min(max_u, p_u - min_u)

            if a_lo > a_hi:
                continue

            a_u = rng.randint(a_lo, a_hi)
            b_u = p_u - a_u

            # 4. Convert to biased exponents
            exp_a = a_u + bias
            exp_b = b_u + bias
            exp_c = c_u + bias

            # Section 7: Test Vector Assembly

            # Draw random signs and mantissas
            sign_a = rng.randint(0, 1)
            sign_b = rng.randint(0, 1)
            sign_c = rng.randint(0, 1)

            mant_a = rng.getrandbits(const.MANTISSA_BITS[fmt])
            mant_b = rng.getrandbits(const.MANTISSA_BITS[fmt])
            mant_c = rng.getrandbits(const.MANTISSA_BITS[fmt])

            # Encode operands to hex
            hex_a = decimalComponentsToHex(fmt, sign_a, exp_a, mant_a)
            hex_b = decimalComponentsToHex(fmt, sign_b, exp_b, mant_b)
            hex_c = decimalComponentsToHex(fmt, sign_c, exp_c, mant_c)

            # Emit test vector
            run_and_store_test_vector(
                f"{op}_{const.ROUND_NEAR_EVEN}_{hex_a}_{hex_b}_{hex_c}_{fmt}_{32 * '0'}_{fmt}_00",
                test_f,
                cover_f,
            )


@register_model("B14")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    for fmt in const.FLOAT_FMTS:
        generate_b14_tests(test_f, cover_f, fmt)
