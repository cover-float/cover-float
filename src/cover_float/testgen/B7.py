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

# Ryan Wolk (rwolk@hmc.edu)
# B7: Sticky Bit Calculation
# This model checks that the sticky bit is calculated correctly in each of the
# following cases (for every possible combination in the table). The Guard bit
# should be always 0, and the sign positive, so that miscalculation of the sticky bit
# will alter the final result.

# Operations: FMA, ADD, SUB, MUL
#   This excludes DIV and SQRT as targeting specific sticky values is impossible

import functools
import logging
import random
from typing import TYPE_CHECKING, Optional, TextIO, cast

import cover_float.common.constants as constants
import cover_float.common.log as log
from cover_float.common.util import (
    bezout_inverse,
    factors_to_bit_width,
    generate_float,
    generate_test_vector,
    reproducible_hash,
)
from cover_float.reference import run_test_vector, store_cover_vector
from cover_float.testgen.model import register_model

logger: log.ModelLogger = cast(log.ModelLogger, logging.getLogger("B7"))

if TYPE_CHECKING:
    # This block is seen by Pyright but ignored at runtime
    def factorint(n: int) -> dict[int, int]: ...
else:
    from sympy import factorint


def add_sub_tests(fmt: str, test_f: TextIO, cover_f: TextIO) -> None:
    hashval = reproducible_hash(fmt + "add sub" + "b7")
    random.seed(hashval)

    for op in [constants.OP_ADD, constants.OP_SUB]:
        nf = constants.MANTISSA_BITS[fmt]
        exp_min, exp_max = constants.BIASED_EXP[fmt]
        exp_min -= constants.BIAS[fmt]
        exp_min += nf
        exp_max -= constants.BIAS[fmt]

        # There are nf possible extra_bits for addition, nf + 1 for subtraction
        is_subtraction = op == constants.OP_SUB
        for extra_bit in range(1, nf + is_subtraction):
            sigA = random.getrandbits(nf) | (1 << nf)
            sigB = random.getrandbits(nf) | (1 << nf)

            exp_a = random.randint(exp_min, exp_max)
            shift_amount = random.randint(extra_bit + 1, nf + is_subtraction)

            exp_b = exp_a - shift_amount
            rounding_bits_mask = (1 << shift_amount) - 1

            sigB &= ~rounding_bits_mask
            if op == constants.OP_ADD:
                sigB |= 1 << (shift_amount - extra_bit - 1)
            else:
                # We want the operation to be effective subtraction in the subtraction cases
                subtraction_target = rounding_bits_mask ^ ((1 << (shift_amount - extra_bit - 1)) - 1)
                sigB |= subtraction_target

            if ((sigA << shift_amount) + sigB).bit_length() != (sigA << shift_amount).bit_length():
                sigA ^= 1 << nf - 1

            f1 = generate_float(0, exp_a, sigA ^ (1 << nf), fmt)
            f2 = generate_float(0, exp_b, sigB ^ (1 << nf), fmt)

            if random.random() < 0.5:
                f1, f2 = f2, f1

            tv = generate_test_vector(op, f1, f2, 0, fmt, fmt, constants.ROUND_MAX)
            result = run_test_vector(tv)

            pre_rounding_mantissa = int("1" + result.split("_")[-2], 16)
            # Mask off 0b, leading one, and significant bits
            rounding_bits = bin(pre_rounding_mantissa)[2 + 1 + nf :]
            # Only get the remaining rounding bits
            rounding_bits = rounding_bits[: nf + is_subtraction]

            if int(rounding_bits, 2) != 1 << (nf - extra_bit - 1 + is_subtraction) and rounding_bits.count("1") == 1:
                logger.exception(f"Add Sub Generation Failed: extra_bit: {extra_bit}, op: {op}")
            else:
                store_cover_vector(result, test_f, cover_f)


def mul_sigs_with_trailing(target: int, bit_length: int, fmt: str) -> tuple[int, int]:
    nf = constants.MANTISSA_BITS[fmt]

    for _ in range(100):
        sig_a = 1 << nf | random.getrandbits(nf) | 1  # A must be odd, this is a place for randomization in the future
        sig_a_inv = bezout_inverse(sig_a, 2 ** (bit_length))

        sig_b = (sig_a_inv * target) % (2 ** (bit_length))

        if sig_b.bit_length() != nf + 1:
            continue

        return (sig_a, sig_b)

    return (0, 0)


def mul_tests(fmt: str, test_f: TextIO, cover_f: TextIO) -> None:
    hashval = reproducible_hash(fmt + "mul" + "b7")
    random.seed(hashval)

    # Mul generates U2.2Nf, this means that rounding bits are either going to have
    # length Nf or Nf + 1 depending on whether or not the first bit is zero.

    # The model is about the correct calculation of each sticky bit, so I believe that the
    # correct test plan is hitting each of these cases for all Nf + 1 possible sticky bits

    # A number theory approach works well here: We are searching for a pair of significands
    # a and b such that a, b = (target_bit) (mod 2^(nf + 1)). Finding significands that fit our
    # criteria should be very easy with a random search (quick math says 16 iterations on average
    # to find working significands for both mul behaviors)

    exp_min, exp_max = constants.BIASED_EXP[fmt]
    exp_min -= constants.BIAS[fmt]
    exp_max -= constants.BIAS[fmt]
    exp_min += 1
    exp_max -= 1

    nf = constants.MANTISSA_BITS[fmt]
    for extra_bit in range(nf):  # The first bit of sticky being active in a shifted case is impossible
        target = 1 << extra_bit

        hit_with_shift = False
        # We cannot hit this case without a shift
        hit_without_shift = extra_bit == nf - 1

        for _ in range(100):
            sig_a, sig_b = mul_sigs_with_trailing(target, nf + 1, fmt)
            if sig_a == 0:
                continue

            sign = random.randint(0, 1)
            expA = random.randint(exp_min, exp_max)
            expB = random.randint(exp_min, exp_max)
            while not exp_min <= expA + expB <= exp_max:
                expA = random.randint(exp_min, exp_max)
                expB = random.randint(exp_min, exp_max)

            f1 = generate_float(sign, expA, sig_a ^ (1 << nf), fmt)  # Sign is the same so that the output is positive
            f2 = generate_float(sign, expB, sig_b ^ (1 << nf), fmt)

            tv = generate_test_vector(constants.OP_MUL, f1, f2, 0, fmt, fmt, constants.ROUND_MAX)
            result = run_test_vector(tv)

            pre_rounding_mantissa = int("1" + result.split("_")[-2], 16)
            expected_shift_left = len(bin(sig_a * sig_b)[2:]) == (2 * nf + 2)
            # Mask off 0b, leading one, and significant bits
            rounding_bits = bin(pre_rounding_mantissa)[2 + 1 + nf :]
            # Only get the remaining rounding bits
            rounding_bits = rounding_bits[: nf + expected_shift_left]

            if int(rounding_bits, 2) != target:
                continue

            if rounding_bits.startswith("1"):
                continue  # This means guard is 1

            if expected_shift_left and not hit_with_shift:
                store_cover_vector(result, test_f, cover_f)
                hit_with_shift = True
            elif not expected_shift_left and not hit_without_shift:
                store_cover_vector(result, test_f, cover_f)
                hit_without_shift = True

            if hit_with_shift and hit_without_shift:
                break
        else:
            logger.exception(
                f"Failure to generate mul tests, fmt={fmt}, extra_bit={extra_bit}, hit_with_shift={hit_with_shift}, "
                f"hit_without_shift={hit_without_shift}"
            )


def two_ones_multiplicands(fmt: str) -> dict[int, tuple[int, int]]:
    answer: dict[int, tuple[int, int]] = {}
    nf = constants.MANTISSA_BITS[fmt]
    low_one = 0

    while low_one <= nf:
        # B15-like logic
        target = 1 << (2 * nf + 1)
        target |= 1 << low_one

        factors = factorint(target)
        f1, f2 = factors_to_bit_width(factors, target, nf + 1)

        if f1 * f2 == target:
            one_location = bin(f1 * f2)[3:].rfind("1")
            answer[one_location] = (f1, f2)
            break

        low_one += 1

    mid_one = nf
    while mid_one >= 0:
        # B15-like logic
        target = 1 << (2 * nf + 1)
        target |= 1 << mid_one

        factors = factorint(target)
        f1, f2 = factors_to_bit_width(factors, target, nf + 1)

        if f1 * f2 == target:
            one_location = bin(f1 * f2)[3:].rfind("1")
            answer[one_location] = (f1, f2)
            break

        mid_one -= 1

    return answer


STICKY_LIMITS = {
    constants.FMT_DOUBLE: 72,
    constants.FMT_QUAD: 127,
}


@functools.cache
def multiplicand_generator(
    target_location: int, shift_amount: int, effective_subtraction: bool, nf: int
) -> Optional[tuple[int, int]]:
    total_multiplicand_rounding_bits = nf + shift_amount + 2
    target = 1 << (nf - target_location - 1)
    if effective_subtraction:
        # We want 1s until the target location, then zeros
        # target = 1 << (nf - target_location)
        # target = (~target & ((1 << total_multiplicand_rounding_bits) - 1)) + 1
        target = (1 << total_multiplicand_rounding_bits) - target

    iterations = 10000
    if effective_subtraction and nf >= 52:
        iterations *= 10

    for _ in range(iterations):
        # Bezout's identity does not quite hold here, as we have trailing zeros, by construction we
        # have (nf - target_location) extraneous zeros

        # extraneous_zeros = nf - target_location - 1 if not effective_subtraction else 0
        extraneous_zeros = len(bin(target)) - len(bin(target).rstrip("0"))
        bezout_base = total_multiplicand_rounding_bits - extraneous_zeros
        bezout_target = target >> extraneous_zeros

        # a_zeros = random.randint(max(0, extraneous_zeros - nf), min(nf, extraneous_zeros))
        b_zeros = max(0, extraneous_zeros - nf)
        a_zeros = extraneous_zeros - b_zeros

        a_guess = random.getrandbits(nf - a_zeros) | (1 << (nf - a_zeros)) | 1
        a_guess_inv = bezout_inverse(a_guess, 2**bezout_base)
        b = (a_guess_inv * bezout_target) % (2**bezout_base)

        if bezout_base <= nf - b_zeros:
            b += ((1 << nf - b_zeros) // (2**bezout_base)) * (2**bezout_base)

        a_guess <<= a_zeros
        b <<= b_zeros

        if b.bit_length() == nf + 1:
            return a_guess, b

    if (nf <= 52 and effective_subtraction) or (not effective_subtraction and nf < 23):
        leading_bit_count = 2 * nf + 1 - total_multiplicand_rounding_bits

        # This ensures that we check every possible case at the lower precisions
        if leading_bit_count == -1:
            leaders = [0]
        elif 2**leading_bit_count < 100:
            leaders = list(range(2**leading_bit_count))
        else:
            leaders = [random.getrandbits(leading_bit_count) for _ in range(100)]

        for leading_bits in leaders:
            factor_target = target | (leading_bits << total_multiplicand_rounding_bits) | (1 << 2 * nf + 1)
            factors = factorint(factor_target)
            f1, f2 = factors_to_bit_width(factors, factor_target, nf + 1)

            if f1 * f2 == factor_target:
                return (f1, f2)

    return None


@functools.cache
def cached_factorint(target: int) -> dict[int, int]:
    return factorint(target)


def fma_tests(fmt: str, test_f: TextIO, cover_f: TextIO) -> None:
    hashval = reproducible_hash(fmt + "fma" + "b7")
    random.seed(hashval)

    # For FMA, the output is U(Nf + 4).(2Nf + 2)
    # So, (Nf + 4) refers to adding a full significand (Nf + 1) bits then a U2.2nf where the top bit hits the sticky
    # (thus, it is 1 Nf (0 -- guard) 2.2Nf) for a total of Nf + 4 . 2Nf bits
    # Then we get 2Nf + 2 in the other end because the Z addend is squashed into the last sticky bit

    # For the purposes of our tests, we want to set all of the possible Nf + 1 extra_bits with the Z shifted
    # into the sticky, Then we want to test sticky calculation with the multiplication result shifted into the
    # right place

    min_exp, max_exp = constants.BIASED_EXP[fmt]
    min_exp -= constants.BIAS[fmt]
    max_exp -= constants.BIAS[fmt]

    for op in [constants.OP_FMADD, constants.OP_FMSUB, constants.OP_FNMADD, constants.OP_FNMSUB]:
        effective_subtraction = op == constants.OP_FMSUB or op == constants.OP_FNMADD

        for extra_bit in range(1, constants.MANTISSA_BITS[fmt] + 1):
            for _ in range(100):
                # Logic taken from B3.py
                signA = random.randint(0, 1)
                signB = random.randint(0, 1)

                sigA_initial = random.randint(0, (1 << constants.MANTISSA_BITS[fmt]) - 1)
                sigB_initial = random.randint(0, (1 << constants.MANTISSA_BITS[fmt]) - 1)
                expA = random.randint(-10, 10) + constants.BIAS[fmt]
                expB = random.randint(-10, 10) + constants.BIAS[fmt]

                if fmt == constants.FMT_HALF:
                    # Just be careful that we don't generate things that need
                    # to add a number that we don't have the exponents to add
                    expA = random.randint(-1, 6) + constants.BIAS[fmt]
                    expB = random.randint(-1, 6) + constants.BIAS[fmt]

                # Put in the leading one
                sigA = sigA_initial | (1 << constants.MANTISSA_BITS[fmt])
                sigB = sigB_initial | (1 << constants.MANTISSA_BITS[fmt])

                # Actually Multiply
                sigProd = sigA * sigB
                signProd = signA ^ signB  # zero iff both are the same
                expProd = expA + expB - constants.BIAS[fmt] + 1

                # Correct for the actual operation
                if op == constants.OP_FNMADD or op == constants.OP_FNMSUB:
                    signProd ^= 1  # These ops induce a sign flip

                # Now we ensure that our leading one is in the correct bit, and the
                # product exponent is correct
                if sigProd < (1 << (constants.MANTISSA_BITS[fmt] * 2 + 1)):
                    sigProd <<= 1
                    expProd -= 1

                # The leading one should be in bit MANTISSA_BIT * 2 + 2, so
                # bits MANTISSA_BIT * 2 + 1 --> MANTISSA_BIT + 2 (inclusive) are mantissa
                # Thus, G = MANTISSA_BIT + 1, STICKY = MANTISSA_BIT --> 1
                mask = 2 ** (constants.MANTISSA_BITS[fmt] + 1) - 1
                rounding_bits = sigProd & mask
                sticky_bits = rounding_bits & (mask >> 1)
                _not_sticky = sigProd & (~mask)

                # Sticky bits should be aligned to already, so
                signC = signProd
                target = 1 << (constants.MANTISSA_BITS[fmt] - extra_bit)
                if op == constants.OP_FMADD or op == constants.OP_FNMSUB:
                    # These are effective addition
                    if sticky_bits < target:
                        sigC_initial = target - sticky_bits
                    else:
                        sigC_initial = (target | (1 << constants.MANTISSA_BITS[fmt])) - sticky_bits

                    sigC = sigC_initial | (1 << constants.MANTISSA_BITS[fmt])
                else:
                    # Then its effective subtraction
                    if sticky_bits > target:
                        sigC_initial = sticky_bits - target
                    else:
                        sigC_initial = sticky_bits - target + (1 << constants.MANTISSA_BITS[fmt])

                    sigC = sigC_initial | (1 << constants.MANTISSA_BITS[fmt])

                # Figure out alignment
                expC = expProd - constants.MANTISSA_BITS[fmt] - 1
                expDiff = expProd - expC

                # Align sigC to correct bits of sigProd, the shifts are a no-op but
                # they are there for correctness
                if op == constants.OP_FMADD or op == constants.OP_FNMSUB:
                    sigZ64 = sigProd + ((sigC << (constants.MANTISSA_BITS[fmt] + 1)) >> expDiff)
                else:
                    sigZ64 = sigProd - ((sigC << constants.MANTISSA_BITS[fmt] + 1) >> expDiff)

                # In some cases, especially in lower precision formats (i.e. bf16 and half),
                # we get an "overflow" here (i.e. we move up or down an exponent and have to shift)
                # This means we can accidentally cause a shift of guard into the sticky bit
                # which we do not guarantee to be zero, so we check that here
                if len(bin(sigZ64)) != len(bin(sigProd)):
                    continue

                # Get new rounding info, if we want to log it
                new_rounding = sigZ64 & mask
                _new_sticky = new_rounding & (mask >> 1)

                # Generate the FMA result
                in1 = generate_float(signA, expA - constants.BIAS[fmt], sigA_initial, fmt)
                in2 = generate_float(signB, expB - constants.BIAS[fmt], sigB_initial, fmt)
                in3 = generate_float(signC, expC - constants.BIAS[fmt], sigC_initial, fmt)

                tv = generate_test_vector(op, in1, in2, in3, fmt, fmt, constants.ROUND_MAX)
                result = run_test_vector(tv)

                interm_mantissa = bin(int("1" + result.split("_")[-2], 16))[3:]
                actual_extra_bits = interm_mantissa[constants.MANTISSA_BITS[fmt] :]
                expected_extra_bits = bin(target)[2:].zfill(constants.MANTISSA_BITS[fmt] + 1)

                actual_extra_bits = actual_extra_bits.strip("0")
                expected_extra_bits = expected_extra_bits.strip("0")

                if actual_extra_bits == expected_extra_bits:
                    store_cover_vector(result, test_f, cover_f)
                    break
                if actual_extra_bits[1:] == expected_extra_bits[1:]:
                    logger.exception("Failure in FMA Test Generation, failed to create the expected bits")
            else:
                logger.exception("Failure to generate a Guard=0 Case in FMA Testgen")

        # Now do the addend hanging off of the end of the mantissa
        # This will be the (2nf + 1)th extra bit
        for overhang_extra in range(constants.MANTISSA_BITS[fmt] + 1, 2 * constants.MANTISSA_BITS[fmt] + 1):
            for _ in range(100):
                if not effective_subtraction:
                    sigC = 1 << (2 * constants.MANTISSA_BITS[fmt] - overhang_extra) | (
                        1 << constants.MANTISSA_BITS[fmt]
                    )
                    sigA, sigB = mul_sigs_with_trailing(
                        (1 << constants.MANTISSA_BITS[fmt] + 1) - 1, constants.MANTISSA_BITS[fmt] + 1, fmt
                    )
                else:
                    sigC = 1 << (2 * constants.MANTISSA_BITS[fmt] - overhang_extra)
                    sigC = (1 << constants.MANTISSA_BITS[fmt]) - sigC
                    sigC |= 1 << constants.MANTISSA_BITS[fmt]
                    sigA, sigB = mul_sigs_with_trailing(2, constants.MANTISSA_BITS[fmt] + 1, fmt)

                if sigA == 0:
                    continue

                # Place the leading one in bit 2nf
                exp_diff = -2 * constants.MANTISSA_BITS[fmt]

                # Randomized Exponents so that we get the desired exponent difference
                prod_exp = random.randint(max(min_exp, min_exp - exp_diff), min(max_exp, max_exp - exp_diff))
                add_exp = prod_exp + exp_diff

                # Find two exponents that add to prod_exp
                mul_exp1 = random.randint(max(min_exp, prod_exp - max_exp), min(max_exp, prod_exp - min_exp))
                mul_exp2 = prod_exp - mul_exp1

                mul_sign = random.randint(0, 1)
                overall_negate = op in [constants.OP_FNMADD, constants.OP_FNMSUB]

                floatA = generate_float(mul_sign, mul_exp1, sigA ^ (1 << constants.MANTISSA_BITS[fmt]), fmt)
                floatB = generate_float(
                    mul_sign ^ overall_negate, mul_exp2, sigB ^ (1 << constants.MANTISSA_BITS[fmt]), fmt
                )
                floatC = generate_float(0, add_exp, sigC ^ (1 << constants.MANTISSA_BITS[fmt]), fmt)

                tv = generate_test_vector(op, floatA, floatB, floatC, fmt, fmt, constants.ROUND_MAX)
                result = run_test_vector(tv)

                interm_mantissa = bin(int("1" + result.split("_")[-2], 16))[3:]
                actual_extra_bits = interm_mantissa[constants.MANTISSA_BITS[fmt] :]
                placement = actual_extra_bits.rfind("1")

                if (
                    ((sigA * sigB).bit_length() != 2 * constants.MANTISSA_BITS[fmt] + 2 and not effective_subtraction)
                    or (placement != overhang_extra)  # and overhang_extra <= STICKY_LIMITS.get(fmt, 1000))
                    or actual_extra_bits.count("1") != 1
                ):
                    continue
                else:
                    store_cover_vector(result, test_f, cover_f)
                    break
            else:
                logger.exception(
                    f"Failure to generate big multiplication, small, far addend for fma with sticky = {overhang_extra}"
                    f" in fmt: {fmt}"
                )

        # Now consider the cases where the multiplicand is responsible for sticky bit generation,
        # That is, cases where the addend has an exponent that does not let it cancel the remaining
        # Sticky Bits.
        one_placements = two_ones_multiplicands(fmt)

        lowest_one = max(one_placements.keys())
        middle_one = min(one_placements.keys())

        # Idea is that the last one starts just barely hanging off of the addend, and then we go until
        # the leading one from the multiplication mantissa is in the lsb
        placements: list[int] = []

        with logger.progress_bar(status=f"{fmt} FMA Target Placements", show_m_of_n=True) as pbar:
            for target_placement in pbar.track(range(1, 2 * constants.MANTISSA_BITS[fmt])):
                # We want the lowest possible exponent difference
                shift_amount = max(3, target_placement - constants.MANTISSA_BITS[fmt] + 1)
                target_location = target_placement - shift_amount

                if target_placement < STICKY_LIMITS.get(fmt, 2 * constants.MANTISSA_BITS[fmt]):
                    attempted_sigs = multiplicand_generator(
                        target_location, shift_amount, effective_subtraction, constants.MANTISSA_BITS[fmt]
                    )
                else:
                    attempted_sigs = None

                if attempted_sigs is None:
                    if not effective_subtraction:
                        sigA, sigB = one_placements[middle_one]
                        exp_diff = target_placement - middle_one + constants.MANTISSA_BITS[fmt] + 1
                        if exp_diff > constants.MANTISSA_BITS[fmt]:
                            sigA, sigB = one_placements[lowest_one]
                            exp_diff = target_placement - lowest_one + constants.MANTISSA_BITS[fmt] + 1

                            if exp_diff > constants.MANTISSA_BITS[fmt]:
                                continue
                    else:
                        # 1st attempt all ones in the significand
                        target = (1 << 2 * constants.MANTISSA_BITS[fmt] + 1) - 1
                        factors = cached_factorint(target)
                        f1, f2 = factors_to_bit_width(factors, target, constants.MANTISSA_BITS[fmt] + 1)

                        if f1 * f2 == target:
                            sigA, sigB = f1, f2
                            one_location = 2 * constants.MANTISSA_BITS[fmt]  # After the decimal point
                        else:
                            sigA = (1 << constants.MANTISSA_BITS[fmt] + 1) - 2
                            sigB = (1 << constants.MANTISSA_BITS[fmt]) + 1
                            # These are the second best thing we can do
                            one_location = 2 * constants.MANTISSA_BITS[fmt] - 1

                        exp_diff = target_placement - one_location + constants.MANTISSA_BITS[fmt] + 1

                        if exp_diff > constants.MANTISSA_BITS[fmt] + 1:
                            continue
                else:
                    sigA, sigB = attempted_sigs
                    exp_diff = shift_amount

                # Randomized Exponents so that we get the desired exponent difference
                prod_exp = random.randint(max(min_exp, min_exp - exp_diff), min(max_exp, max_exp - exp_diff))
                add_exp = prod_exp + exp_diff

                # Find two exponents that add to prod_exp
                mul_exp1 = random.randint(max(min_exp, prod_exp - max_exp), min(max_exp, prod_exp - min_exp))
                mul_exp2 = prod_exp - mul_exp1

                # Order doesn't matter so randomly swap them
                if random.random() < 0.5:
                    mul_exp1, mul_exp2 = mul_exp2, mul_exp1

                if random.random() < 0.5:
                    sigA, sigB = sigB, sigA

                sigC = random.getrandbits(constants.MANTISSA_BITS[fmt] - 1)  # -1 to stop all carry chains
                if effective_subtraction:
                    sigC |= 1 << (constants.MANTISSA_BITS[fmt] - 1)
                    sigC |= 1 << (constants.MANTISSA_BITS[fmt] - 2)  # Stop all borrow chains

                if exp_diff == 0:
                    add_exp -= 2
                    sigC &= ~0b11
                elif (sigA * sigB).bit_length() == (2 * constants.MANTISSA_BITS[fmt] + 2):
                    pass

                signA = random.randint(0, 1)
                signB = signA
                if op == constants.OP_FNMADD or op == constants.OP_FNMSUB:
                    signB ^= 1

                signC = 0

                floatA = generate_float(signA, mul_exp1, sigA ^ (1 << constants.MANTISSA_BITS[fmt]), fmt)
                floatB = generate_float(signB, mul_exp2, sigB ^ (1 << constants.MANTISSA_BITS[fmt]), fmt)
                floatC = generate_float(signC, add_exp, sigC, fmt)

                tv = generate_test_vector(op, floatA, floatB, floatC, fmt, fmt, constants.ROUND_MAX)
                result = run_test_vector(tv)

                interm_mantissa = bin(int("1" + result.split("_")[-2], 16))[3:]
                actual_extra_bits = interm_mantissa[constants.MANTISSA_BITS[fmt] :]
                placement = actual_extra_bits.rfind("1")

                if (placement != target_placement) or actual_extra_bits.count("1") != 1:
                    logger.exception(f"Failed To Generate C +- Prod Cases for FMA, op={op}, target={target_placement}")
                    continue
                elif placement not in placements:
                    placements.append(placement)
                    store_cover_vector(result, test_f, cover_f)


def convert_tests(fmt: str, test_f: TextIO, cover_f: TextIO) -> None:
    # CFF
    nf = constants.MANTISSA_BITS[fmt]
    for from_fmt in constants.FLOAT_FMTS:
        hashval = reproducible_hash(f"B7 {from_fmt} convert to {fmt}")
        random.seed(hashval)

        from_nf = constants.MANTISSA_BITS[from_fmt]

        if from_nf <= nf:
            # We only want narrowing conversions
            continue

        for extra_bit in range(1, from_nf - nf):
            upper_bits = random.getrandbits(nf)
            extra_bits = 1 << ((from_nf - nf) - extra_bit - 1)

            sig = (upper_bits << (from_nf - nf)) | extra_bits
            f = generate_float(0, random.randint(-10, 10), sig, from_fmt)

            tv = generate_test_vector(constants.OP_CFF, f, 0, 0, from_fmt, fmt, constants.ROUND_MAX)
            result = run_test_vector(tv)
            interm_mantissa = bin(int("1" + result.split("_")[-2], 16))[3:][:from_nf]
            rounding_bits = interm_mantissa[nf:]

            if rounding_bits == bin(extra_bits)[2:].zfill(from_nf - nf):
                store_cover_vector(result, test_f, cover_f)
            elif fmt == "04" and constants.MANTISSA_BITS[fmt] + extra_bit >= 23:
                store_cover_vector(result, test_f, cover_f)  # This is just a quirk of how bf16 converts work
            else:
                logger.exception(f"CFF Generation Failure From: {from_fmt}, To: {fmt}, Extra-Bits: {extra_bits:b}")

    # CFI
    for to_fmt in constants.INT_FMTS:
        to_bits = constants.INT_MAX_EXPS[to_fmt]

        for extra_bit in range(1, nf):
            # Min_int_bits is 0 as we can do 1.frac with the leading one
            min_int_bits = 0
            # Max_int_bits places the target extra_bit last
            max_int_bits = min(nf - extra_bit - 1, to_bits - 1)

            int_bits = random.randint(min_int_bits, max_int_bits)
            frac_bits = nf - int_bits

            int_part = random.getrandbits(int_bits)
            frac_part = 1 << (frac_bits - extra_bit - 1)

            sig = int_part << frac_bits | frac_part

            f = generate_float(0, int_bits, sig, fmt)

            tv = generate_test_vector(constants.OP_CFI, f, 0, 0, fmt, to_fmt, constants.ROUND_MAX)
            result = run_test_vector(tv)
            interm_mantissa = bin(int("1" + result.split("_")[-2], 16))[3:]
            rounding_bits = interm_mantissa[to_bits : to_bits + frac_bits]

            if rounding_bits == bin(frac_part)[2:].zfill(frac_bits):
                store_cover_vector(result, test_f, cover_f)
            else:
                logger.exception(f"CFI Generation Failure From: {fmt}, To: {to_fmt}, Extra-Bits: {frac_part:b}")

    # CIF
    for from_fmt in constants.INT_FMTS:
        from_bits = constants.INT_MAX_EXPS[from_fmt]

        if from_bits <= nf:
            # Not a narrowing conversion
            continue

        for extra_bit in range(1, from_bits - nf - 1):  # - nf - 1 because one extra bit from the leading one
            upper_bits = random.getrandbits(nf) | (1 << nf)

            sig = upper_bits << (extra_bit + 1)
            sig |= 1  # Places the extra bit in the right place

            remaining_shift_dist = from_bits - sig.bit_length()
            additional_zeros = random.randint(0, remaining_shift_dist)
            sig <<= additional_zeros

            tv = generate_test_vector(constants.OP_CIF, sig, 0, 0, from_fmt, fmt, constants.ROUND_MAX)
            result = run_test_vector(tv)
            interm_mantissa = bin(int("1" + result.split("_")[-2], 16))[3:]
            rounding_bits = interm_mantissa[nf:]

            if rounding_bits.count("1") == 1 and rounding_bits.find("1") == extra_bit:
                store_cover_vector(result, test_f, cover_f)
            elif (
                from_fmt in [constants.FMT_INT, constants.FMT_UINT]
                and fmt == constants.FMT_BF16
                and extra_bit + constants.MANTISSA_BITS[fmt] >= constants.MANTISSA_BITS[constants.FMT_SINGLE]
            ) or (
                from_fmt in [constants.FMT_LONG, constants.FMT_ULONG]
                and fmt == constants.FMT_BF16
                and extra_bit + constants.MANTISSA_BITS[fmt] >= constants.MANTISSA_BITS[constants.FMT_DOUBLE]
            ):
                store_cover_vector(result, test_f, cover_f)  # Softfloat quirk makes it not track correctly here
            else:
                logger.exception(f"CIF Generation Failure From: {from_fmt}, To: {fmt}, Extra-Bit: {extra_bit}")


@register_model("B7")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    for fmt in constants.FLOAT_FMTS:
        add_sub_tests(fmt, test_f, cover_f)
        mul_tests(fmt, test_f, cover_f)
        fma_tests(fmt, test_f, cover_f)
        convert_tests(fmt, test_f, cover_f)
