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
# Fuse Multiply Add(FMA)
# B14 -> Multiply-Add: Shift


# This model tests every possible value for a shift between the addends of the multiply-add operation.
# For the difference between the unbiased exponent of the addend and the unbiased exponent of the result of the
# multiplication, test the following values:
# 1.A value smaller than -(2* p + 1)
# 2.All the values in the range:[-(2*p +1), (p +1) ]
# 3.A value larger than (p + 1)


import logging
import random
from random import seed
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
    _p = const.MANTISSA_BITS[fmt] + 1  # defines the precision we are working with
    bias = (1 << (const.EXPONENT_BITS[fmt] - 1)) - 1  # calculates the correct bias depending on fmt
    min_exp = const.BIASED_EXP[fmt][0]
    max_exp = const.BIASED_EXP[fmt][1]

    # Define Format-Specific Shift Limits
    # This defines the sweep range [ -limit, +limit ]
    # We want to cover the full range of (ExpA + ExpB) - ExpC
    SHIFT_LIMITS = {
        const.FMT_HALF: 31,  # Max exp diff is ~30. We use 31
        const.FMT_BF16: 256,  # Max exp diff is ~255. We use 256
        const.FMT_SINGLE: 256,  # Max exp diff is ~255. We use 256
        const.FMT_DOUBLE: 2050,  # Max exp diff is ~2047. We use 2050
        const.FMT_QUAD: 32001,  # Max exp diff is ~32001
    }

    # Get the limit (default to 500 if format missing)
    limit = SHIFT_LIMITS.get(fmt, 500)

    start_shift = -limit
    end_shift = limit

    with logger.progress_bar(f"{fmt} Shifts", show_m_of_n=True) as pbar:
        for target_shift in pbar.track(range(start_shift, end_shift + 1)):
            for op in OPS:
                hashval = reproducible_hash(op + fmt + "b14")  # Unique hash for (op, fmt) seed
                seed(hashval)  # Seed the random generator for reproducibility
                # Randomize & generate 15 variations per shift
                for _ in range(15):
                    ##Part 1: Randomize a and b exponents (and make sure their product is valid)
                    # a:
                    # safe margin defined to keep 'a' somewhat central to avoid immediate overflows
                    safe_margin = int(max_exp / 4)
                    exp_a = random.randint(min_exp + safe_margin, max_exp - safe_margin)
                    # b:
                    low_bound = max(min_exp, bias - 50)
                    high_bound = min(max_exp, bias + 50)
                    # Pick 'b' near the bias (so product exponent is close to exp_a) or random. This is simplified;
                    # we might want more range here.
                    exp_b = random.randint(low_bound, high_bound)

                    ##Part 2: Calculate the addends
                    # Calculate product exponent:Exp_Prod = Exp_A + Exp_B - Bias
                    exp_prod = exp_a + exp_b - bias

                    # Calculate required Exp_C to hit the Target Shift: target_shift = Exp_C - Exp_Prod
                    exp_c = target_shift + exp_prod

                    # Quick validity check -> If the calculated exp_c is invalid (too big/small), skip this variation
                    if exp_c < min_exp or exp_c > max_exp:
                        continue

                    ##Part 3: Generate mantissa componenets + Assemble >:3
                    # Create random signs (0 or 1)
                    sign_a = random.randint(0, 1)
                    sign_b = random.randint(0, 1)
                    sign_c = random.randint(0, 1)

                    # Randomize mantissas -> Uses random bits to trigger different carry/rounding paths.
                    mant_a = random.getrandbits(const.MANTISSA_BITS[fmt])
                    mant_b = random.getrandbits(const.MANTISSA_BITS[fmt])
                    mant_c = random.getrandbits(const.MANTISSA_BITS[fmt])

                    # Converts the components created above to hex
                    hex_a = decimalComponentsToHex(fmt, sign_a, exp_a, mant_a)
                    hex_b = decimalComponentsToHex(fmt, sign_b, exp_b, mant_b)
                    hex_c = decimalComponentsToHex(fmt, sign_c, exp_c, mant_c)

                    run_and_store_test_vector(
                        f"{op}_{const.ROUND_NEAR_EVEN}_{hex_a}_{hex_b}_{hex_c}_{fmt}_{32 * '0'}_{fmt}_00",
                        test_f,
                        cover_f,
                    )


@register_model("B14")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    for fmt in const.FLOAT_FMTS:
        generate_b14_tests(test_f, cover_f, fmt)
