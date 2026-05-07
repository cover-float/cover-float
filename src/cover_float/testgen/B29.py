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

# B29 (rwolk@g.hmc.edu)

import logging
import random
from typing import TextIO, cast

import cover_float.common.constants as constants
import cover_float.common.log as log
from cover_float.common.util import generate_float, generate_test_vector, reproducible_hash, unpack_test_vector
from cover_float.reference import run_test_vector, store_cover_vector
from cover_float.testgen.model import register_model

logger: log.ModelLogger = cast(log.ModelLogger, logging.getLogger("B1"))


def generate_tests(fmt: str, test_f: TextIO, cover_f: TextIO) -> None:
    targets = [{"Sign": x & 1, "LSB": (x & 2) >> 1, "Guard": (x & 4) >> 2, "Sticky": (x & 8) >> 3} for x in range(16)]

    nf = constants.MANTISSA_BITS[fmt]
    _exp_min, exp_max = constants.UNBIASED_EXP[fmt]

    for mode in constants.ROUNDING_MODES:
        seed = reproducible_hash(f"B29 {fmt} {mode}")
        random.seed(seed)

        for target in targets:
            exp = random.randint(1, min(nf - 2, exp_max))

            sticky_length = nf - exp - 1
            sticky = random.randint(1, (1 << sticky_length) - 1) if target["Sticky"] else 0
            integer_bits = exp
            integer_part = random.getrandbits(integer_bits - 1) << 1
            if target["LSB"]:
                integer_part |= 1

            sig = ((integer_part << 1) | target["Guard"]) << (sticky_length) | sticky
            f1 = generate_float(target["Sign"], exp, sig, fmt)
            tv = generate_test_vector(constants.OP_RFI, f1, 0, 0, fmt, fmt, mode)

            results = run_test_vector(tv)
            fields = unpack_test_vector(results)

            mantissa = f"{fields.interm_sig:0{constants.INTER_SIGNIFICAND_LENGTH}b}"
            rounding_bits = mantissa[-constants.RFI_DECIMAL_POINT :]

            computed_lsb = int(mantissa[-constants.RFI_DECIMAL_POINT - 1] == "1")
            computed_guard = int(rounding_bits[0] == "1")
            computed_sticky = int(any(x == "1" for x in rounding_bits[1:]))
            computed_sign = fields.interm_sign

            computed_info = {
                "Sign": computed_sign,
                "LSB": computed_lsb,
                "Guard": computed_guard,
                "Sticky": computed_sticky,
            }

            if computed_info == target:
                store_cover_vector(results, test_f, cover_f)
            else:
                logger.exception(f"Failed to Generate for fmt={fmt} and target={target}")


@register_model("B29")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    for fmt in constants.FLOAT_FMTS:
        generate_tests(fmt, test_f, cover_f)
