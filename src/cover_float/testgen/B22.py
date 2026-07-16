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
# B22: CvtFP2Int Special Input Exponents

import random
from typing import TextIO

import cover_float.common.constants as constants
from cover_float.common.config import Config
from cover_float.common.util import generate_float, generate_test_vector, reproducible_hash
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model


def generate_B22(test_f: TextIO, cover_f: TextIO, config: Config) -> None:
    # Seed the RNG for deterministic mantissas
    seed = reproducible_hash("B22")
    random.seed(seed)

    # Define src formats and dest formats
    src_formats = constants.FLOAT_FMTS
    dest_formats = [constants.FMT_INT, constants.FMT_UINT, constants.FMT_LONG, constants.FMT_ULONG]

    # For each (src, dest, sign) combination
    for src_fmt in src_formats:
        for dest_fmt in dest_formats:
            # Determine int_width from destination format
            int_width = constants.INT_SIZES[dest_fmt]

            # Get source format properties
            nf = constants.MANTISSA_BITS[src_fmt]
            exp_min, exp_max = constants.UNBIASED_EXP[src_fmt]

            for sign in [0, 1]:
                # Low region: E < -3
                # Pick E_Low = -4 (or any single exponent < -3)
                e_low = max(-4, exp_min)
                fraction = random.getrandbits(nf)
                f_low = generate_float(sign, e_low, fraction, src_fmt)
                tv = generate_test_vector(constants.OP_CFI, f_low, 0, 0, src_fmt, dest_fmt, constants.ROUND_NEAR_EVEN)
                run_and_store_test_vector(tv, test_f, cover_f, config)

                # Mid region: -3 <= E <= int_width + 3
                # For each integer exponent in this range
                mid_max_exp = min(int_width + 3, exp_max)
                for e_mid in range(-3, mid_max_exp + 1):
                    fraction = random.getrandbits(nf)
                    f_mid = generate_float(sign, e_mid, fraction, src_fmt)
                    tv = generate_test_vector(
                        constants.OP_CFI, f_mid, 0, 0, src_fmt, dest_fmt, constants.ROUND_NEAR_EVEN
                    )
                    run_and_store_test_vector(tv, test_f, cover_f, config)

                # High region: E > int_width + 3
                # Pick E_High = int_width + 4, only if reachable
                e_high = int_width + 4
                if e_high <= exp_max:
                    fraction = random.getrandbits(nf)
                    f_high = generate_float(sign, e_high, fraction, src_fmt)
                    tv = generate_test_vector(
                        constants.OP_CFI, f_high, 0, 0, src_fmt, dest_fmt, constants.ROUND_NEAR_EVEN
                    )
                    run_and_store_test_vector(tv, test_f, cover_f, config)


@register_model("B22")
def main(config: Config, test_f: TextIO, cover_f: TextIO) -> None:
    generate_B22(test_f, cover_f, config)
