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

# B26 (rwolk@g.hmc.edu)

import random
from typing import TextIO

import cover_float.common.constants as constants
from cover_float.common.util import generate_test_vector, reproducible_hash
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model


def generate_B26(int_fmt: str, test_f: TextIO, cover_f: TextIO) -> None:
    bits = constants.INT_MAX_EXPS[int_fmt]

    for float_fmt in constants.FLOAT_FMTS:
        seed = reproducible_hash(f"B26 {int_fmt} {float_fmt}")
        random.seed(seed)
        for msb in range(bits):
            unsigned = 1 << msb | random.getrandbits(msb)
            tv = generate_test_vector(
                constants.OP_CIF, unsigned, 0, 0, int_fmt, float_fmt, random.choice(constants.ROUNDING_MODES)
            )
            run_and_store_test_vector(tv, test_f, cover_f)

            if constants.INT_SIGNED[int_fmt]:
                signed = -(1 << msb | random.getrandbits(msb))
                unsigned = signed & (
                    (1 << constants.INT_SIZES[int_fmt]) - 1
                )  # This gives a twos complement representation
                tv = generate_test_vector(
                    constants.OP_CIF, unsigned, 0, 0, int_fmt, float_fmt, random.choice(constants.ROUNDING_MODES)
                )
                run_and_store_test_vector(tv, test_f, cover_f)


@register_model("B26")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    for fmt in constants.INT_FMTS:
        generate_B26(fmt, test_f, cover_f)
