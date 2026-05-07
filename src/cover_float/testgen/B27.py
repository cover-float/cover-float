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

# B27 (rwolk@g.hmc.edu)

import itertools
import random
from typing import TextIO

import cover_float.common.constants as constants
from cover_float.common.util import generate_test_vector, reproducible_hash
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model


def generate_B27(fmt: str, test_f: TextIO, cover_f: TextIO) -> None:
    # We need a QNaN, SNaN, Patterns in Other Bits, and Variations in Sign Bit

    for to_fmt in constants.FLOAT_FMTS:
        seed = reproducible_hash(f"B27 {fmt} {to_fmt}")
        random.seed(seed)

        if constants.MANTISSA_BITS[fmt] <= constants.MANTISSA_BITS[to_fmt]:
            # We only want narrowing conversions
            continue

        for q_nan_bit, other_frac_bits, sign_bit in itertools.product([0, 1], repeat=3):
            if q_nan_bit == 0 and other_frac_bits == 0:
                continue  # This generates +- Inf

            exp = (1 << constants.EXPONENT_BIAS[fmt]) - 1
            f = (sign_bit << constants.EXPONENT_BITS[fmt] | exp) << constants.MANTISSA_BITS[fmt]
            f |= q_nan_bit << constants.MANTISSA_BITS[fmt] - 1

            if other_frac_bits:
                bits = random.getrandbits(constants.MANTISSA_BITS[fmt] - 1)
                while bits == 0:  # Make it actually generate something non-zero
                    bits = random.getrandbits(constants.MANTISSA_BITS[fmt] - 1)
                f |= bits

            tv = generate_test_vector(constants.OP_CFF, f, 0, 0, fmt, to_fmt)  # Rounding mode does not matter
            run_and_store_test_vector(tv, test_f, cover_f)


@register_model("B27")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    for fmt in constants.FLOAT_FMTS:
        generate_B27(fmt, test_f, cover_f)
