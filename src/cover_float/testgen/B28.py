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
# License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific language governing permissions
# and limitations under the License.

# B28: RFI Special Values (rwolk@g.hmc.edu)

import random
from typing import TextIO

import cover_float.common.constants as constants
from cover_float.common.config import Config
from cover_float.common.util import generate_float, generate_test_vector, reproducible_hash
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model


def generate_B28(fmt: str, test_f: TextIO, cover_f: TextIO, config: Config) -> None:
    nf = constants.MANTISSA_BITS[fmt]
    p = nf + 1
    bias = constants.EXPONENT_BIAS[fmt]

    for sign in [0, 1]:
        # Category 1/10: ±0
        f = generate_float(sign, -bias, 0, fmt)
        tv = generate_test_vector(constants.OP_RFI, f, 0, 0, fmt, fmt, constants.ROUND_NEAR_EVEN)
        run_and_store_test_vector(tv, test_f, cover_f, config)

        # Category 2/11: Random in (±0, ±1)
        biased_exp = random.randint(0, bias - 1)
        fraction = random.randint(1, (1 << nf) - 1)
        f = generate_float(sign, biased_exp - bias, fraction, fmt)
        tv = generate_test_vector(constants.OP_RFI, f, 0, 0, fmt, fmt, constants.ROUND_NEAR_EVEN)
        run_and_store_test_vector(tv, test_f, cover_f, config)

        # Category 3/12: ±1
        f = generate_float(sign, 0, 0, fmt)
        tv = generate_test_vector(constants.OP_RFI, f, 0, 0, fmt, fmt, constants.ROUND_NEAR_EVEN)
        run_and_store_test_vector(tv, test_f, cover_f, config)

    # Category 4/13: Quarter-steps
    # Values: 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75
    # Format: (unbiased_exp, fraction_bits, num_bits)
    quarter_steps = [
        (0, 0b01, 2),  # 1.25 = 1.01_2
        (0, 0b10, 2),  # 1.5 = 1.1_2
        (0, 0b11, 2),  # 1.75 = 1.11_2
        (1, 0b00, 2),  # 2.0 = 1.0_2 x 2^1
        (1, 0b001, 3),  # 2.25 = 1.001_2 x 2^1
        (1, 0b01, 2),  # 2.5 = 1.01_2 x 2^1
        (1, 0b011, 3),  # 2.75 = 1.011_2 x 2^1
    ]

    for sign in [0, 1]:
        for unbiased_exp, frac_bits, num_bits in quarter_steps:
            frac_shifted = frac_bits << (nf - num_bits)
            f = generate_float(sign, unbiased_exp, frac_shifted, fmt)
            tv = generate_test_vector(constants.OP_RFI, f, 0, 0, fmt, fmt, constants.ROUND_NEAR_EVEN)
            run_and_store_test_vector(tv, test_f, cover_f, config)

    for sign in [0, 1]:
        # Category 5/14: Random in (±1, ±MaxIntFP)
        biased_exp = random.randint(bias + 1, bias + p - 1)
        fraction = random.getrandbits(nf)
        f = generate_float(sign, biased_exp - bias, fraction, fmt)
        tv = generate_test_vector(constants.OP_RFI, f, 0, 0, fmt, fmt, constants.ROUND_NEAR_EVEN)
        run_and_store_test_vector(tv, test_f, cover_f, config)

        # Category 6/15: ±MaxIntFP
        f = generate_float(sign, p, (1 << nf) - 1, fmt)
        tv = generate_test_vector(constants.OP_RFI, f, 0, 0, fmt, fmt, constants.ROUND_NEAR_EVEN)
        run_and_store_test_vector(tv, test_f, cover_f, config)

        # Category 7/16: ±∞
        all_ones_exp = (1 << constants.EXPONENT_BITS[fmt]) - 1
        inf = (sign << (constants.EXPONENT_BITS[fmt] + nf)) | (all_ones_exp << nf)
        tv = generate_test_vector(constants.OP_RFI, inf, 0, 0, fmt, fmt, constants.ROUND_NEAR_EVEN)
        run_and_store_test_vector(tv, test_f, cover_f, config)

    # Category 8: QNaN (sign=0, biased_exp=all-ones, fraction MSB=1, rest=0)
    all_ones_exp = (1 << constants.EXPONENT_BITS[fmt]) - 1
    qnan = (all_ones_exp << nf) | (1 << (nf - 1))
    tv = generate_test_vector(constants.OP_RFI, qnan, 0, 0, fmt, fmt, constants.ROUND_NEAR_EVEN)
    run_and_store_test_vector(tv, test_f, cover_f, config)

    # Category 9: SNaN (sign=0, biased_exp=all-ones, fraction MSB=0, LSB=1)
    snan = (all_ones_exp << nf) | 1
    tv = generate_test_vector(constants.OP_RFI, snan, 0, 0, fmt, fmt, constants.ROUND_NEAR_EVEN)
    run_and_store_test_vector(tv, test_f, cover_f, config)


@register_model("B28")
def main(config: Config, test_f: TextIO, cover_f: TextIO) -> None:
    seed = reproducible_hash("B28")
    random.seed(seed)
    for fmt in constants.FLOAT_FMTS:
        generate_B28(fmt, test_f, cover_f, config)
