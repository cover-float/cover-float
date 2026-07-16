# Copyright (C) 2025-26 Harvey Mudd College, Ryan Wolk (rwolk@g.hmc.edu)
#
# B17.py: B17 Test Generation
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

from __future__ import annotations

import logging
import random
from typing import TextIO, cast

from cover_float.common.config import Config
import cover_float.common.constants as constants
import cover_float.common.log as log
from cover_float.common.util import (
    bezout_inverse,
    generate_float,
    generate_test_vector,
    reproducible_hash,
    unpack_test_vector,
)
from cover_float.reference import run_test_vector, store_cover_vector
from cover_float.testgen.model import register_model

logger: log.ModelLogger = cast(log.ModelLogger, logging.getLogger("B17"))


def mul_sigs_with_trailing(
    target: int, bit_length: int, fmt: str, *, mul_sig_length: int | None = None
) -> tuple[int, int]:
    nf = constants.MANTISSA_BITS[fmt]

    for _ in range(1000):
        sig_a = 1 << nf | random.getrandbits(nf) | 1  # A must be odd, this is a place for randomization in the future
        sig_a_inv = bezout_inverse(sig_a, 2 ** (bit_length))

        sig_b = (sig_a_inv * target) % (2 ** (bit_length))

        if sig_b.bit_length() != nf + 1:
            continue

        if mul_sig_length is not None and (sig_a * sig_b).bit_length() != mul_sig_length:
            continue

        return (sig_a, sig_b)

    return (0, 0)


def generate_case(
    op: str, fmt: str, subnorm_exp: int, cancellation: int, test_f: TextIO, cover_f: TextIO, config: Config
) -> None:
    # cancellation = INTERM_X - max(ADDEND, MULTIPLICATION_RESULT)
    # In practice, this means that we need an addend and a multiplication result with the same exponent
    # Thus, max(ADDEND, MULTIPLICATION_RESULT) = INTERM_X - cancellation

    addend_exp = subnorm_exp - cancellation - constants.EXPONENT_BIAS[fmt]
    nf = constants.MANTISSA_BITS[fmt]

    for _ in range(100):
        if cancellation > -nf:
            sig1 = random.getrandbits(nf)
            sig2 = random.getrandbits(nf)

            m1 = sig1 | (1 << nf)
            m2 = sig2 | (1 << nf)
        elif cancellation == -(2 * nf + 1):
            target = 1
            # Another bit of precision is the only way to get this case specifically
            m1, m2 = mul_sigs_with_trailing(target, nf + 2, fmt, mul_sig_length=2 * nf + 2)
            assert m1 != 0 and m2 != 0

            sig1 = m1 & ((1 << nf) - 1)
            sig2 = m2 & ((1 << nf) - 1)
        else:
            # mul_sigs_with_trailing generates m1, m2 such that (m1 * m2).bit_length() == 2 * nf + 1
            # We need to use mul_sig_length here as this function generates a trailing significand with the desired
            # properties, not a leading significand with a one after how ever many bits (which is what we truly want)
            set_bit = 2 * nf + cancellation
            m1 = m2 = 0
            while m1 == 0 or m2 == 0:  # Ensure that we generate something useful
                target = 1 << (set_bit) | random.getrandbits(set_bit)
                m1, m2 = mul_sigs_with_trailing(target, nf + 2, fmt, mul_sig_length=2 * nf + 1)

            sig1 = m1 & ((1 << nf) - 1)
            sig2 = m2 & ((1 << nf) - 1)

        multiplication_result = m1 * m2
        shift = 1 if multiplication_result.bit_length() > (nf * 2 + 1) else 0

        opposite_signs = True
        if cancellation >= 0:
            # Generate an effective addition case where we have a carry (cancellation = 1 or
            # nothing interesting cancellation = 0).
            opposite_signs = False
            subnorm_amount = (
                0 if addend_exp > -constants.EXPONENT_BIAS[fmt] else -(addend_exp + constants.EXPONENT_BIAS[fmt]) + 1
            )  # Take into account the shift associated with subnormals
            addend_sig = random.getrandbits(nf - subnorm_amount - 1) if subnorm_amount != nf else 0
            addend_sig |= 1 << (nf - subnorm_amount)
            multiplication_exp = addend_exp - shift
            if cancellation == 0:
                multiplication_exp -= 2
        else:
            multiplication_exp = addend_exp - shift
            # We want to cancel the first -cancellation bits
            if cancellation >= -(nf + 1):
                leading_bits = multiplication_result >> (multiplication_result.bit_length() + cancellation)
            else:
                leading_bits = multiplication_result >> (multiplication_result.bit_length() - nf - 1)

            # Ensure that we have a mismatch after the last addend bit
            addend_greater = False
            if (
                cancellation >= -nf
                and multiplication_result & (1 << (multiplication_result.bit_length() + cancellation - 1)) == 0
            ):
                addend_greater = True

                leading_bits <<= 1
                leading_bits |= 1

                # This prevents any borrow chain from causing a borrow that removes the one that we placed
                next_bit = 2
                while (
                    multiplication_result & (1 << (multiplication_result.bit_length() + cancellation - next_bit)) != 0
                ):
                    leading_bits <<= 1
                    leading_bits |= 1
                    next_bit += 1

                    if multiplication_result.bit_length() + cancellation - next_bit < 0:
                        # Then there is no more potential to have a borrow resulting in a drop in precision
                        break

                # One extra one ensures that after matching all of the ones, we have a buffer bit to borrow from
                leading_bits <<= 1
                leading_bits |= 1

            subnorm_amount = (
                0 if addend_exp > -constants.EXPONENT_BIAS[fmt] else -(addend_exp + constants.EXPONENT_BIAS[fmt]) + 1
            )  # Account for subnorms when shifting the leading bits into a significand
            shift_into_sig = (nf + 1 - subnorm_amount) - leading_bits.bit_length()
            extra_bits = 0
            if shift_into_sig < 0:
                continue
            else:
                if addend_greater:  # We've already done the borrow chain work in this case
                    randomization_point = shift_into_sig
                else:
                    # In this case, we can only randomize beyond the first one
                    # Find the first one past leading bits
                    first_one = bin(multiplication_result)[2:].find("1", leading_bits.bit_length() + 1)
                    if first_one != -1:
                        # first_one + 1 is safe to randomize after
                        randomization_point = (nf + 1 - subnorm_amount) - (first_one + 1)
                        randomization_point = max(0, randomization_point)
                    else:
                        randomization_point = 0
                extra_bits = random.getrandbits(randomization_point)

            # Build out the addend sig, and only allow it to have nf bits
            full_addend_sig = leading_bits << shift_into_sig | extra_bits
            addend_sig = full_addend_sig & ((1 << nf) - 1)

        # Build Floating Point Inputs, given the previous information

        # 1. Signs
        multiplication_sign = random.randint(0, 1)
        addend_sign = multiplication_sign ^ (1 if opposite_signs else 0)
        multiplication_sign1 = random.randint(0, 1)
        multiplication_sign2 = multiplication_sign1 ^ (0 if multiplication_sign == 0 else 1)

        if op in [constants.OP_FMSUB, constants.OP_FNMSUB]:  # Account for FMA variants
            addend_sign ^= 1

        # 2. Exponents
        exp_low, exp_high = constants.UNBIASED_EXP[fmt]
        # Generate a valid pair of multiplication exponents
        multiplication_exp1 = random.randint(exp_low, exp_high)
        multiplication_exp2 = multiplication_exp - multiplication_exp1
        while not (exp_low <= multiplication_exp2 <= exp_high):
            multiplication_exp1 = random.randint(exp_low, exp_high)
            multiplication_exp2 = multiplication_exp - multiplication_exp1

        # The addend exponent can be subnormal
        usable_addend_exp = max(addend_exp, -constants.EXPONENT_BIAS[fmt])

        # Generate the floats and run the test
        mul_f1 = generate_float(multiplication_sign1, multiplication_exp1, sig1, fmt)
        mul_f2 = generate_float(multiplication_sign2, multiplication_exp2, sig2, fmt)
        add_f = generate_float(addend_sign, usable_addend_exp, addend_sig, fmt)

        # MINMAG is important to not get rounding errors giving an incorrect subnormal exponent
        tv = generate_test_vector(op, mul_f1, mul_f2, add_f, fmt, fmt, constants.ROUND_MINMAG)
        cv = run_test_vector(tv)

        # Check that the generated answer is correct using the cover vector
        unpacked = unpack_test_vector(cv)
        interm_sig = bin(unpacked.interm_sig)[2:].zfill(constants.INTER_SIGNIFICAND_LENGTH)

        # Calculate the effective intermediate exponent
        biased_interm_exp = unpacked.interm_exp
        if biased_interm_exp != 0:
            interm_exp = biased_interm_exp
        else:
            sig_leading_zeros = len(interm_sig) - len(interm_sig.lstrip("0"))
            interm_exp = -sig_leading_zeros
        interm_exp -= constants.EXPONENT_BIAS[fmt]

        # Information for the effective result exponent
        result_sig = unpacked.result & ((1 << nf) - 1)
        result_leading_zeros = nf - result_sig.bit_length()

        # Get the Effective Product and Addend Exponents
        actual_addend_exp = (unpacked.input3 >> nf) & ((1 << constants.EXPONENT_BITS[fmt]) - 1)
        if actual_addend_exp == 0:
            addend_sig = unpacked.input3 & ((1 << nf) - 1)
            addend_leading_zeros = nf - addend_sig.bit_length()
            actual_addend_exp = -addend_leading_zeros
        actual_addend_exp -= constants.EXPONENT_BIAS[fmt]
        actual_m1_exp = ((unpacked.input1 >> nf) & ((1 << constants.EXPONENT_BITS[fmt]) - 1)) - constants.EXPONENT_BIAS[
            fmt
        ]
        actual_m2_exp = ((unpacked.input2 >> nf) & ((1 << constants.EXPONENT_BITS[fmt]) - 1)) - constants.EXPONENT_BIAS[
            fmt
        ]
        actual_multiplication_exp = actual_m1_exp + actual_m2_exp
        actual_cancellation = interm_exp - max(actual_addend_exp, actual_multiplication_exp)

        # Check Coverage Constraints

        # 1. Is subnormal
        assert biased_interm_exp == 0, (
            f"B17 Must Generate Subnormal Intermediate Result, Actual Biased Exponent: {biased_interm_exp}"
        )

        # 2. Has the desired subnormal exponent
        assert result_leading_zeros == -subnorm_exp, (
            f"B17 Did Not Generate the Correct Subnormal Final Exponent, Expected: {subnorm_exp}, "
            f"Actual: {-result_leading_zeros}"
        )

        # 3. We have the desired cancellation amount
        assert addend_exp == actual_addend_exp, (
            f"B17 Generated Wrong addend_exp: Expected: {addend_exp}, Actual: {actual_addend_exp}"
        )
        assert multiplication_exp == actual_multiplication_exp, (
            f"B17 Generated Wrong multiplication_exp: Expected: {multiplication_exp}, "
            f"Actual: {actual_multiplication_exp}"
        )
        assert actual_cancellation == cancellation, (
            f"B17 Generated Wrong Cancellation: Expected: {cancellation}, actual: {actual_cancellation}"
        )

        store_cover_vector(cv, test_f, cover_f, config)
        return

    raise ValueError(
        f"Unable to Generate B17 Testcase: op={op}, fmt={fmt}, subnorm_exp={subnorm_exp}, cancellation={cancellation}"
    )


@register_model("B17")
def generate(config: Config, test_f: TextIO, cover_f: TextIO) -> None:
    for fmt in constants.FLOAT_FMTS:
        for op in [constants.OP_FMADD, constants.OP_FMSUB, constants.OP_FNMADD, constants.OP_FNMSUB]:
            random.seed(reproducible_hash(f"B17 {fmt} {op}"))
            with logger.progress_bar(f"{fmt} Subnorm Exp for {op}", show_m_of_n=True) as pbar:
                for subnorm_exp in pbar.track(range(-constants.MANTISSA_BITS[fmt] + 1, 1)):
                    min_cancel = -(2 * constants.MANTISSA_BITS[fmt] + 1)
                    max_cancel = 1 if subnorm_exp != -constants.MANTISSA_BITS[fmt] + 1 else 0

                    for cancellation in range(min_cancel, max_cancel + 1):
                        generate_case(op, fmt, subnorm_exp, cancellation, test_f, cover_f, config)
