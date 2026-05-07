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

# B20 (rwolk@g.hmc.edu)

import logging
import math
import random
from typing import TextIO, cast

import cover_float.common.constants as constants
import cover_float.common.log as log
from cover_float.common.util import generate_float, generate_test_vector, reproducible_hash, unpack_test_vector
from cover_float.reference import run_and_store_test_vector, run_test_vector, store_cover_vector
from cover_float.testgen.model import register_model

logger: log.ModelLogger = cast(log.ModelLogger, logging.getLogger("B1"))


def generate_div_tests(fmt: str, test_f: TextIO, cover_f: TextIO) -> None:
    # Generally, we want to look for two significands, sig1 and sig2 where
    # when reduced into lowest terms, sig2 only has factors of two. Now, when
    # sig2 is 2^k, we have nf - k trailing zeros.

    seed = reproducible_hash(f"B20 DIV {fmt}")
    random.seed(seed)

    nf = constants.MANTISSA_BITS[fmt]
    min_exp, max_exp = constants.UNBIASED_EXP[fmt]

    for trailing_zeros in range(nf + 1):
        s1 = random.getrandbits(nf - trailing_zeros) | 1 << (nf - trailing_zeros) | 1
        s2 = 1 << (nf - trailing_zeros)

        odd_factors = random.getrandbits(trailing_zeros)
        if odd_factors == 0:
            odd_factors = 1

        s1 *= odd_factors
        s2 *= odd_factors

        if s1.bit_length() < nf + 1:
            s1 <<= nf + 1 - s1.bit_length()
        if s2.bit_length() < nf + 1:
            s2 <<= nf + 1 - s2.bit_length()

        res = (s1 << nf) // s2 if s1 >= s2 else (s1 << nf + 1) // s2

        # Extract Number of trailing zeros for verification
        generated_trailing_zeros = len(bin(res)) - len(bin(res).rstrip("0"))
        if generated_trailing_zeros != trailing_zeros:
            logger.exception(
                f"Failed to Generate A Div Result for format {fmt} with exactly {trailing_zeros} trailing_zeros"
            )
            continue

        exp1, exp2 = random.randint(min_exp, max_exp), random.randint(min_exp, max_exp)
        while not min_exp < exp1 - exp2 < max_exp:
            exp1, exp2 = random.randint(min_exp, max_exp), random.randint(min_exp, max_exp)

        f1 = generate_float(random.randint(0, 1), exp1, s1, fmt)
        f2 = generate_float(random.randint(0, 1), exp2, s2, fmt)
        tv = generate_test_vector(constants.OP_DIV, f1, f2, 0, fmt, fmt, random.choice(constants.ROUNDING_MODES))

        run_and_store_test_vector(tv, test_f, cover_f)


def generate_sqrt_tests(fmt: str, test_f: TextIO, cover_f: TextIO) -> None:
    # We are looking for exact square root answers that are exact and have an exact number of trailing zeros
    # This makes the approach very easy: We generate the answers, then make sure they fit into a float
    # when squared. Clearly, because the multiplication result is 2.2nf, and the number of trailing zeros
    # in this result is 2k where k was the number in our desired answer, we need to have at least nf/2 zeros
    # in the answer we start with (so that the multiplication result is representable as a float)

    seed = reproducible_hash(f"B20 SQRT {fmt}")
    random.seed(seed)

    nf = constants.MANTISSA_BITS[fmt]
    min_exp, max_exp = constants.UNBIASED_EXP[fmt]

    for trailing_zeros in range(math.ceil(nf / 2), nf + 1):
        # Generate a random answer with nf bits and trailing_zero trailing zeros
        answer = random.getrandbits(nf - trailing_zeros) | 1 << (nf - trailing_zeros) | 1
        answer <<= trailing_zeros

        while trailing_zeros == nf // 2 and (answer * answer).bit_length() > 2 * nf + 1:
            answer = random.getrandbits(nf - trailing_zeros) | 1 << (nf - trailing_zeros) | 1
            answer <<= trailing_zeros

        sqrt_sig = answer * answer
        sqrt_sig >>= sqrt_sig.bit_length() - (nf + 1)

        exp = random.randint(min_exp, max_exp) // 2
        squared_exp = exp * 2
        if (answer * answer).bit_length() > 2 * nf + 1:
            squared_exp += 1

        f1 = generate_float(0, squared_exp, sqrt_sig & ((1 << nf) - 1), fmt)
        tv = generate_test_vector(constants.OP_SQRT, f1, 0, 0, fmt, fmt, random.choice(constants.ROUNDING_MODES))

        result = run_test_vector(tv)
        fields = unpack_test_vector(result)

        actual_answer = fields.result

        # Mantissa is in the last nf bits, the answer also cannot be subnormal
        mantissa = actual_answer & ((1 << nf) - 1)
        mantissa |= 1 << nf

        if mantissa != answer:
            logger.exception(
                f"Failed to Generate a SQRT Value for format: {fmt} and number of trailing zeros: {trailing_zeros}"
            )
            continue

        store_cover_vector(result, test_f, cover_f)


@register_model("B20")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    for fmt in constants.FLOAT_FMTS:
        generate_div_tests(fmt, test_f, cover_f)
        generate_sqrt_tests(fmt, test_f, cover_f)
