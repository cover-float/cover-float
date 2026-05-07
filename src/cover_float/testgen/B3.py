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

import logging
import random
from typing import Optional, TextIO, cast

import cover_float.common.constants as common
import cover_float.common.log as log
from cover_float.common.util import (
    extract_rounding_info,
    generate_float,
    generate_test_vector,
    get_rounding_bits,
    reproducible_hash,
    unpack_test_vector,
)
from cover_float.reference import run_test_vector, store_cover_vector
from cover_float.testgen.model import register_model

logger: log.ModelLogger = cast(log.ModelLogger, logging.getLogger("B3"))

SRC1_OPS = [common.OP_SQRT]

SRC2_OPS = [common.OP_ADD, common.OP_SUB, common.OP_MUL, common.OP_DIV]

SRC3_OPS = [
    common.OP_FMADD,
    common.OP_FMSUB,
    common.OP_FNMADD,
    common.OP_FNMSUB,
]


def generate_random_float(exponent: int, fmt: str, sign: Optional[int] = None) -> int:
    if sign is None:
        sign = random.randint(0, 1)
    # sign = 0
    mantissa = random.randint(0, (1 << common.MANTISSA_BITS[fmt]) - 1)
    # Add in the exponent bias for single-precision (127)
    float32 = generate_float(sign, exponent, mantissa, fmt)

    return float32


def get_significand_from_float(float_: int, fmt: str) -> int:
    mask = (1 << common.MANTISSA_BITS[fmt]) - 1
    return float_ & mask | (1 << common.MANTISSA_BITS[fmt])


def write_fma_tests(test_f: TextIO, cover_f: TextIO, fmt: str) -> None:
    FMA_OPS = [
        common.OP_FMADD,
        common.OP_FMSUB,
        common.OP_FNMADD,
        common.OP_FNMSUB,
    ]

    targets = [
        {
            "Sign": (x & 1),
            "LSB": (x & 2) >> 1,
            "Guard": (x & 4) >> 2,
            "Sticky": 0,
        }
        for x in range(8)
    ]

    for op in FMA_OPS:
        for mode in common.ROUNDING_MODES:
            random.seed(reproducible_hash(op + fmt + mode + "B3"))

            to_cover = targets[:]

            for _ in range(100):
                """
                    How does FMA actually work on softfloat? (and why we are not using the reference
                    model to do our math)

                    Softfloat is going to crush extra bits into one with the shiftJam logic, and in
                    the f32 case, softfloat's rounding function takes a uint_fast32_t as input for
                    the significand. This means that it rounds based off of ~9 extra bits instead
                    of all of the generated sticky bits (so we cannot get pre-addition results
                    with an OP_FMADD x, y, 0 call).

                    The following is a calculation from s_mulAddF32.c:

                        sigC = (sigC | 0x00800000)<<6;

                        ...

                        sig64Z =
                            sigProd
                                + softfloat_shiftRightJam64(
                                    (uint_fast64_t) sigC<<32, expDiff );
                        sigZ = softfloat_shortShiftRightJam64( sig64Z, 32 );

                    sig64Z is a uint_fast64_t, while sigZ is a uint_fast32_t. SigZ is the final answer
                    but what we want is sig64Z. The meaning of Jam is that bits shifted out of the integer
                    are "jammed" into a 1. Thus, we just need a faithful calculation of sigProd.

                    So, how is sigProd calculated?

                        sigA = (sigA | 0x00800000)<<7;
                        sigB = (sigB | 0x00800000)<<7;
                        sigProd = (uint_fast64_t) sigA * sigB;
                        if ( sigProd < UINT64_C( 0x2000000000000000 ) ) {
                            --expProd;
                            sigProd <<= 1;
                        }

                    And expProd? (This is off by one because softfloat rounding is weird)

                        expProd = expA + expB - 0x7E // 0x7e = 126
                """

                signA = random.randint(0, 1)
                signB = random.randint(0, 1)

                sigA_initial = random.randint(0, (1 << common.MANTISSA_BITS[fmt]) - 1)
                sigB_initial = random.randint(0, (1 << common.MANTISSA_BITS[fmt]) - 1)
                expA = random.randint(-10, 10) + common.BIAS[fmt]
                expB = random.randint(-10, 10) + common.BIAS[fmt]

                if fmt == common.FMT_HALF:
                    # Just be careful that we don't generate things that need
                    # to add a number that we don't have the exponents to add
                    expA = random.randint(-1, 6) + common.BIAS[fmt]
                    expB = random.randint(-1, 6) + common.BIAS[fmt]

                # Put in the leading one
                sigA = sigA_initial | (1 << common.MANTISSA_BITS[fmt])
                sigB = sigB_initial | (1 << common.MANTISSA_BITS[fmt])

                # Actually Multiply
                sigProd = sigA * sigB
                signProd = signA ^ signB  # zero iff both are the same
                expProd = expA + expB - common.BIAS[fmt] + 1

                # Correct for the actual operation
                if op == common.OP_FNMADD or op == common.OP_FNMSUB:
                    signProd ^= 1  # These ops induce a sign flip

                # Now we ensure that our leading one is in the correct bit, and the
                # product exponent is correct
                if sigProd < (1 << (common.MANTISSA_BITS[fmt] * 2 + 1)):
                    sigProd <<= 1
                    expProd -= 1

                # The leading one should be in bit MANTISSA_BIT * 2 + 2, so
                # bits MANTISSA_BIT * 2 + 1 --> MANTISSA_BIT + 2 (inclusive) are mantissa
                # Thus, G = MANTISSA_BIT + 1, STICKY = MANTISSA_BIT --> 1
                mask = 2 ** (common.MANTISSA_BITS[fmt] + 1) - 1
                rounding_bits = sigProd & mask
                sticky_bits = rounding_bits & (mask >> 1)
                _not_sticky = sigProd & (~mask)

                # Sticky bits should be aligned to already, so
                signC = signProd
                if op in [common.OP_FMADD, common.OP_FNMSUB]:
                    # For effective addition, add something to make them go away
                    sigC_initial = 2 ** common.MANTISSA_BITS[fmt] - sticky_bits
                else:
                    # In effective subtraction subtract them off
                    sigC_initial = sticky_bits

                sigC = sigC_initial | (1 << common.MANTISSA_BITS[fmt])

                # Figure out alignment
                expC = expProd - common.MANTISSA_BITS[fmt] - 1
                expDiff = expProd - expC

                # Align sigC to correct bits of sigProd, the shifts are a no-op but
                # they are there for correctness
                if op in [common.OP_FMADD, common.OP_FNMSUB]:
                    sigZ64 = sigProd + ((sigC << (common.MANTISSA_BITS[fmt] + 1)) >> expDiff)
                else:
                    sigZ64 = sigProd - ((sigC << (common.MANTISSA_BITS[fmt] + 1)) >> expDiff)

                # In some cases, especially in lower precision formats (i.e. bf16 and half),
                # we get an "overflow" here (i.e. we move up an exponent and have to shift)
                # This means we can accidentally cause a shift of guard into the stickt bit
                # which we do not guarentee to be zero, so we check that here
                if len(bin(sigZ64)) != len(bin(sigProd)):
                    continue

                # Get new rounding info, if we want to log it
                new_rounding = sigZ64 & mask
                _new_sticky = new_rounding & (mask >> 1)

                # Generate the FMA result
                in1 = generate_float(signA, expA - common.BIAS[fmt], sigA_initial, fmt)
                in2 = generate_float(signB, expB - common.BIAS[fmt], sigB_initial, fmt)
                in3 = generate_float(signC, expC - common.BIAS[fmt], sigC_initial, fmt)

                tv = generate_test_vector(op, in1, in2, in3, fmt, fmt, mode)
                result = run_test_vector(tv)

                fields = unpack_test_vector(result)
                if (sigA * sigB) != fields.fma_pre_addition:
                    logger.exception(
                        "FMA PreAddition is being Incorrectly Calculated, Please Investigate"
                        f" {in1:x} * {in2:x} + {in3:x}"
                    )

                rounding = extract_rounding_info(result)

                if rounding["Sticky"] != 0:
                    logger.exception(
                        "FMA Sticky Bit Generation Failed! This should not happen, please investigate "
                        f"Inputs: signA={signA}, sigA={sigA:#x}, expA={expA}, signB={signB}, sigB={sigB:#x}, "
                        f"expB={expB}, fmt={fmt}, op={op}"
                    )

                if rounding in to_cover:
                    to_cover.remove(rounding)
                    store_cover_vector(result, test_f, cover_f)

                    # This means we're done
                    if len(to_cover) == 0:
                        break
            else:
                # This catches a for loop that does not break, i.e. we don't hit every goal
                logger.exception(
                    f"FMA Generation Failed for fmt={fmt}, mode={mode}, with to_cover={to_cover} goals remaining"
                )


def write_add_sub_tests(test_f: TextIO, cover_f: TextIO, fmt: str) -> None:
    ops = [
        common.OP_ADD,
        common.OP_SUB,
    ]

    targets = [
        {
            "Sign": (x & 1),
            "LSB": (x & 2) >> 1,
            "Guard": (x & 4) >> 2,
            "Sticky": 0,
        }
        for x in range(8)
    ]

    for op in ops:
        for mode in common.ROUNDING_MODES:
            random.seed(reproducible_hash(op + fmt + mode + "B3"))
            for target in targets:
                # Generate a random float for A
                signA = target["Sign"]

                # If the MSB of sigA_initial is 0, it prevents rounding up to another exponent in addition
                sigA_initial = random.randint(0, (1 << (common.MANTISSA_BITS[fmt] - 1)) - 1)
                if op == common.OP_SUB:
                    # But we want it to be one in subtractions
                    sigA_initial |= 1 << (common.MANTISSA_BITS[fmt] - 1)

                _sigA = sigA_initial | (1 << common.MANTISSA_BITS[fmt])
                expA = random.randint(-10, 14)  # + common.BIAS[fmt]

                # How can we get rounding bits to be what we want?
                # For add and sub, unfortunately, there is no way to get a lot of manipulation, like we could with fma

                # We will misalign them by 2 bits
                expB = expA - 2

                last_digits = ((target["LSB"] ^ (sigA_initial & 1)) << 2) | (target["Guard"] << 1) | (target["Sticky"])

                if op == common.OP_ADD:
                    sigB_initial = (random.randint(1, (1 << common.MANTISSA_BITS[fmt]) - 1) & (~0b111)) + last_digits
                    _sigB = sigB_initial | (1 << common.MANTISSA_BITS[fmt])
                else:
                    # For effective subtraction, we need to do a little bit of work
                    subtraction_target = target["LSB"] << 2 | target["Guard"] << 1 | target["Sticky"]
                    subtraction_last_digits = (1 << 3 | (sigA_initial & 1) << 2) - subtraction_target
                    sigB_initial = random.getrandbits(common.MANTISSA_BITS[fmt] - 3) << 3 | subtraction_last_digits
                    _sigB = sigB_initial | (1 << common.MANTISSA_BITS[fmt])

                signB = signA

                A = generate_float(signA, expA, sigA_initial, fmt)
                B = generate_float(signB, expB, sigB_initial, fmt)

                tv = generate_test_vector(op, A, B, 0, fmt, fmt, mode)
                result = run_test_vector(tv)

                info = extract_rounding_info(result)
                if info == target:
                    store_cover_vector(result, test_f, cover_f)
                else:
                    logger.exception(
                        f"AddSub test generation failed: op={op}, target={target}, last_digits={last_digits}, "
                        f"A={A}, B={B}"
                    )


def write_mul_tests(test_f: TextIO, cover_f: TextIO, fmt: str) -> None:
    targets = [
        {
            "Sign": (x & 1),
            "LSB": (x & 2) >> 1,
            "Guard": (x & 4) >> 2,
            "Sticky": 0,
        }
        for x in range(8)
    ]

    for mode in common.ROUNDING_MODES:
        random.seed(reproducible_hash("MUL" + fmt + mode + "B3"))

        """
        We care about setting the last two bits as a result of our multiplication. Perhaps the simplest way
        is to use random chance. That is, we generate things that in theory multiply to the product
        length that we want, and just use random mantissas.
        """

        goals = targets[:]

        for _ in range(200):
            # a_exp_length + b_exp_length = mantissa_length + 1
            # The idea here is that we multiply and get a product significand
            # with length mantissa_length + 1
            a_exp_length = random.randint(3, common.MANTISSA_BITS[fmt] - 2)
            b_exp_length = common.MANTISSA_BITS[fmt] + 1 - a_exp_length

            # Generate significands
            sig_a_initial = random.randint(1, (1 << a_exp_length) - 1)
            sig_b_initial = random.randint(1, (1 << b_exp_length) - 1)

            # Align them
            sig_a_initial <<= common.MANTISSA_BITS[fmt] - a_exp_length
            sig_b_initial <<= common.MANTISSA_BITS[fmt] - b_exp_length

            # Randomize the rest, and don't overflow
            a_sign = random.randint(0, 1)
            b_sign = random.randint(0, 1)
            a_exp = random.randint(-common.BIAS[fmt] // 2 + 1, common.BIAS[fmt] // 2 - 1)
            b_exp = random.randint(-common.BIAS[fmt] // 2 + 1, common.BIAS[fmt] // 2 - 1)

            # Run everything
            a = generate_float(a_sign, a_exp, sig_a_initial, fmt)
            b = generate_float(b_sign, b_exp, sig_b_initial, fmt)

            tv = generate_test_vector(common.OP_MUL, a, b, 0, fmt, fmt, mode)
            result = run_test_vector(tv)
            info = extract_rounding_info(result)

            if info in goals:
                goals.remove(info)
                store_cover_vector(result, test_f, cover_f)

                if len(goals) == 0:
                    break
        else:
            logger.exception(
                f"Failed to generate mul cover_vectors for fmt={fmt}, mode={mode}. Remaining cases {goals}"
            )


def write_sqrt_tests(test_f: TextIO, cover_f: TextIO, fmt: str) -> None:
    """
    SQRT is fun. LSB  = 1 and Guard = 1 is impossible. We know this because
    consider squaring a number with guard = 1 and an m bit mantissa
    then we have (1.(mantissa)1)**2 = (1 + (mantissa) + 2**(-p-1)) ** 2
    The mantissa has least power 2**(-p), so in the resulting expression there must be
    a power of 2 ** (-2p - 2), and unfortunately, we cannot represent this. Similar logic
    means that LSB = 1, is also impossible.

    This means that the possible cases are LSB = 0, Guard = 0, Sticky = 0 :(

    Sign is, of course, always zero in these.

    Note that there are no subnormal tricks here because sqrt halves the exponent and we
    would be at expmin in a subnorm.
    """

    targets = [
        {
            "Sign": 0,
            "LSB": 0,
            "Guard": 0,
            "Sticky": 0,
        }
    ]

    for mode in common.ROUNDING_MODES:
        random.seed(reproducible_hash("SQRT" + fmt + mode + "B3"))
        # Our life is very easy, we just need a random number filled half way with bits
        usable_bits = common.MANTISSA_BITS[fmt] // 2 - 1
        mantissa = random.randint(1, (1 << (usable_bits)) - 1)
        mantissa = mantissa << (common.MANTISSA_BITS[fmt] - usable_bits)
        mantissa |= 1 << common.MANTISSA_BITS[fmt]

        # Just something that can be doubled
        exp = random.randint(3, common.BIAS[fmt] - 3) - (common.BIAS[fmt] // 2)

        # Square the mantissa
        squared_mantissa = mantissa * mantissa
        squared_exp = exp * 2 + 1

        # Align bits correctly (see fma)
        if squared_mantissa < (1 << (common.MANTISSA_BITS[fmt] * 2 + 1)):
            squared_mantissa <<= 1
            squared_exp -= 1

        # Put bits where they are supposed to be
        squared_mantissa >>= common.MANTISSA_BITS[fmt] + 1

        mask = (1 << common.MANTISSA_BITS[fmt]) - 1
        float_ = generate_float(0, squared_exp, squared_mantissa & mask, fmt)
        tv = generate_test_vector(common.OP_SQRT, float_, 0, 0, fmt, fmt, mode)

        result = run_test_vector(tv)
        info = extract_rounding_info(result)

        if info not in targets:
            logger.exception(
                f"sqrt generation sticky bit generation failed, please investigate: mantissa={mantissa:x}, exp={exp}"
            )

            float_2 = generate_float(0, exp, mantissa & mask, fmt)
            tv_mul = generate_test_vector(common.OP_MUL, float_2, float_2, 0, fmt, fmt)
            result_mul = run_test_vector(tv_mul)
            gen_square = int(result_mul.split("_")[-6], 16)

            if float_ != gen_square:
                logger.exception(f"sqrt float should have been: {gen_square:x}, was {float_:x}")
                return
        else:
            store_cover_vector(result, test_f, cover_f)


def write_div_tests(test_f: TextIO, cover_f: TextIO, fmt: str) -> None:
    """
    We can generate guard = 1, sticky = 0, unlike square root, but the machinery is going to be
    very specific. When sticky = 0, we have an exact result. This means that the given quotient
    has a terminating binary expansion. This happens if the given denominator only has a factor
    of two when it is in lowest terms. Let S1 be the first significand, S2 be the second significand,
    p1 and p2 be the powers of their respective floats, and m be the number of mantissa bits. Then
    our quotient is
            S1 * 2**(p1 + m)
            ________________
            S2 * 2**(p1 + m)
    The powers of two cancel, so what must happen for S1 and S2 is that the non-2 factors of each
    cancel. When S1 and S2 go into lowest terms, we have K / 2^p where K is any odd prime factors
    not canceled out and p is an integer. We canceled factors so K < S1. Thus, the binary representation
    of K must have as many or fewer digits than S1. The meaning of this is that guard = 1 is impossible
    for a normalized generated significand. Thus, guard = 1, sticky = 0 can only be accomplished
    with a subnorm result. Similarly, K and S1 are only the same length when S1 = K (as we can only
    cancel factors of two or greater), so for lsb = 1 cases, either we need to use trivial significands
    or also use subnorms.
    """

    targets = [
        {
            "Sign": (x & 1),
            "LSB": (x & 2) >> 1,
            "Guard": (x & 4) >> 2,
            "Sticky": 0,
        }
        for x in range(8)
    ]

    for mode in common.ROUNDING_MODES:
        random.seed(reproducible_hash("DIV" + fmt + mode + "B3"))

        # for target in targets:
        # For now while we have spontaneous failures here, this is better
        goals = targets[:]
        for _ in range(100):
            target = random.choice(goals)
            # Generate the subnormal significand that we want to get
            target_subnorm = (
                (random.randint(1, (1 << (common.MANTISSA_BITS[fmt] // 2)) - 1) << 2)
                | (target["LSB"] << 1)
                | target["Guard"]
            )
            K = target_subnorm
            odd_factors = random.randint(1, (1 << (common.MANTISSA_BITS[fmt] // 3)) - 1)

            sig1_mant = target_subnorm * odd_factors
            sig2_mant = odd_factors

            # Align each of them to have a leading one in bit common.MANTISSA_BITS[fmt]
            sig1_msb = len(bin(sig1_mant)[2:])
            sig1_shift = common.MANTISSA_BITS[fmt] - sig1_msb + 1
            sig1 = sig1_mant << sig1_shift
            sign1 = random.randint(0, 1)

            sig2_msb = len(bin(sig2_mant)[2:])
            sig2_shift = common.MANTISSA_BITS[fmt] - sig2_msb + 1
            sig2 = sig2_mant << sig2_shift
            sign2 = sign1 ^ target["Sign"]

            exp1 = random.randint(-common.BIAS[fmt] + 1, -common.MANTISSA_BITS[fmt] + 1)

            # Mirroring soft_float calculation
            sig1_64 = sig1 << (common.MANTISSA_BITS[fmt] + 1 if sig1 < sig2 else common.MANTISSA_BITS[fmt])
            sig_quotient = (sig1_64) // sig2

            if sig_quotient * sig2 != sig1_64:
                logger.exception(
                    f"Failed to generate exact division result, please investigate: target={target} K={K}, "
                    f"odd_factors={odd_factors}, sig1={sig1:x}, sig2={sig2:x}"
                )
                continue

            # We want an additional shift to get the lsb into guard
            # So, lsb --> mantissa + 1
            trailing_zeros = len(bin(target_subnorm)) - len(bin(target_subnorm).rstrip("0"))
            lsb_location = bin(sig_quotient)[2:].rfind("1") + trailing_zeros
            required_shift = (common.MANTISSA_BITS[fmt] + 1) - lsb_location

            # We want exp1 - exp2 + exponent_bias = -required_shift
            # so, exp2 = exp1 + exponent_bias + required_shift
            # -1 because softfloat
            exp2 = exp1 + common.BIAS[fmt] + required_shift - 1

            if sig1 < sig2:
                exp2 -= 1

            in1 = generate_float(sign1, exp1, sig1 & ((1 << common.MANTISSA_BITS[fmt]) - 1), fmt)
            in2 = generate_float(sign2, exp2, sig2 & ((1 << common.MANTISSA_BITS[fmt]) - 1), fmt)

            tv = generate_test_vector(common.OP_DIV, in1, in2, 0, fmt, fmt, mode)
            result = run_test_vector(tv)

            info = extract_rounding_info(result)

            """
            TODO: LOOK INTO DIV FAILURE: {'Sign': 1, 'LSB': 1, 'Guard': 0, 'Sticky': 0}
                                         {'Sign': 1, 'LSB': 1, 'Guard': 1, 'Sticky': 0}
            Failed to generate exact division result, please investigate:
              target={'Sign': 1, 'LSB': 1, 'Guard': 1, 'Sticky': 0}, K=457750356368579, odd_factors=64835023161,
                sig1=188c9d6ccd1041a1c9fa6b0000000, sig2=1e30efe2720000000000000000000
            """

            if info != target:
                logger.exception(
                    f"Failed to generate exact division result, please investigate: target={target}, K={K}, "
                    f"odd_factors={odd_factors}, sig1={sig1:x}, sig2={sig2:x}"
                )
            else:
                goals.remove(info)
                store_cover_vector(result, test_f, cover_f)

                if len(goals) == 0:
                    break


def write_cvt_tests(test_f: TextIO, cover_f: TextIO, fmt: str) -> None:
    cvt_ops_targets = {
        common.OP_CFI: common.INT_FMTS,
        common.OP_CIF: common.INT_FMTS,
        common.OP_CFF: common.FLOAT_FMTS,
    }

    targets = [
        {
            "Sign": (x & 1),
            "LSB": (x & 2) >> 1,
            "Guard": (x & 4) >> 2,
            "Sticky": (x & 8) >> 3,
        }
        for x in range(16)
    ]

    # CFI Test Gen
    for mode in common.ROUNDING_MODES:
        random.seed(reproducible_hash("CFI" + fmt + mode + "B3"))
        for target_fmt in cvt_ops_targets[common.OP_CFI]:
            goals = targets[:]

            if not common.INT_SIGNED[target_fmt]:
                goals = [goal for goal in goals if not goal["Sign"]]

            for _ in range(10000):
                sig_override = 0
                if random.random() < 0.5:
                    # Generate a case where we can hit sticky = 0
                    if common.MANTISSA_BITS[fmt] < common.INT_MAX_EXPS[target_fmt]:
                        # Something that it is reasonable we could hit sticky = 0 with
                        exp = random.randint(common.MANTISSA_BITS[fmt] - 6, common.MANTISSA_BITS[fmt] - 4)
                    else:
                        # We need to generate our own significand
                        exp = random.randint(10, common.INT_MAX_EXPS[target_fmt] - 3)

                        # We can have a guard in these cases, leading one lets us get to this
                        # so our significand only needs exp bits to overflow by 1
                        upper_bits = random.getrandbits(exp + 1)

                        sig_override = upper_bits << (common.MANTISSA_BITS[fmt] - exp - 1)
                else:
                    # Something a little more expansive, but don't overflow or make things so that
                    # softfloat takes shortcuts (VERY trivial rounding)
                    exp = random.randint(1, min(common.MANTISSA_BITS[fmt] - 1, common.INT_MAX_EXPS[target_fmt] - 1))

                sign = random.randint(0, 1)
                if not sig_override:
                    cvt_from = generate_random_float(exp, fmt, sign)
                else:
                    cvt_from = generate_float(sign, exp, sig_override, fmt)
                tv = generate_test_vector(common.OP_CFI, cvt_from, 0, 0, fmt, target_fmt, mode)
                results = run_test_vector(tv)
                info = extract_rounding_info(results)

                # Extract rounding bits
                sig = get_rounding_bits(results)
                _rounding_bits = sig[common.INT_MAX_EXPS[target_fmt] :]

                # Calculate rounding bits
                real_significand = get_significand_from_float(cvt_from, fmt)
                if exp >= 0:
                    non_rounding_bit_count = exp
                    rounding_bit_count = common.MANTISSA_BITS[fmt] - non_rounding_bit_count
                    real_rounding_bits = real_significand & ((1 << rounding_bit_count) - 1)
                    real_rounding_bits = bin(real_rounding_bits)[2:].zfill(rounding_bit_count)

                    lsb = int((real_significand & (1 << rounding_bit_count)) != 0)
                else:
                    real_rounding_bits = "0" * (-exp - 1) + bin(real_significand)[2:]
                    lsb = 0

                expected_result = {
                    "Sign": sign,
                    "LSB": lsb,
                    "Guard": int(real_rounding_bits[0] == "1"),
                    "Sticky": int(any(x == "1" for x in real_rounding_bits[1:])),
                }

                if expected_result != info:
                    logger.exception(
                        f"CFI Generation Unexpected Value, fmt={fmt}, target={target_fmt}, mode={mode},"
                        f"cvt_from={cvt_from:x}"
                    )
                elif info in goals:
                    goals.remove(info)
                    store_cover_vector(results, test_f, cover_f)

                    if len(goals) == 0:
                        break
            else:
                logger.exception(
                    f"CFI Generation Failed: fmt={fmt}, target={target_fmt}, mode={mode}, remaining_goals={goals}"
                )

    # CFF Test Gen: We choose fmt to be the target
    for mode in common.ROUNDING_MODES:
        random.seed(reproducible_hash("CFF" + fmt + mode + "B3"))
        for target_fmt in cvt_ops_targets[common.OP_CFF]:
            mantissa_diff = common.MANTISSA_BITS[target_fmt] - common.MANTISSA_BITS[fmt]

            if target_fmt == fmt:
                continue
            elif mantissa_diff <= 0:
                # If fmt (target) has more precision than the other format, then this is not a narrowing conversion, so
                # no rounding happens
                continue

            goals = targets[:]
            for _ in range(1000):
                if random.random() < 0.5:
                    # Generate a test where is going to be likely to be zero
                    mantissa = random.getrandbits(common.MANTISSA_BITS[fmt] + 1) << (mantissa_diff - 1)
                    exp = random.randint(-10, 10)

                    cvt_from = generate_float(random.randint(0, 1), exp, mantissa, target_fmt)
                else:
                    exp = random.randint(-10, 10)
                    cvt_from = generate_random_float(exp, target_fmt)

                tv = generate_test_vector(common.OP_CFF, cvt_from, 0, 0, target_fmt, fmt, mode)
                results = run_test_vector(tv)
                info = extract_rounding_info(results)

                if info in goals:
                    goals.remove(info)
                    store_cover_vector(results, test_f, cover_f)

                    if len(goals) == 0:
                        break
            else:
                logger.exception(
                    f"CFF Generation Failed: fmt={fmt}, target_fmt={target_fmt}, mode={mode}, remaining_goals={goals}"
                )

    # CIF Test Gen:
    for mode in common.ROUNDING_MODES:
        random.seed(reproducible_hash("CIF" + fmt + mode + "B3"))
        for target_fmt in cvt_ops_targets[common.OP_CIF]:
            # -1 for the leading 1!
            mantissa_diff = common.INT_MAX_EXPS[target_fmt] - common.MANTISSA_BITS[fmt] - 1
            if mantissa_diff <= 0:
                # Not a narrowing conversion (e.g. int to double)
                continue

            goals = targets[:]
            if not common.INT_SIGNED[target_fmt]:
                goals = [goal for goal in goals if goal["Sign"] == 0]

            for _ in range(2000):
                if random.random() < 0.5:
                    # Generate a test for sticky = 0
                    integer = (1 << common.INT_MAX_EXPS[target_fmt] - 1) | (
                        random.getrandbits(common.MANTISSA_BITS[fmt] + 1) << (mantissa_diff - 1)
                    )
                else:
                    integer = random.getrandbits(common.INT_MAX_EXPS[target_fmt])

                if common.INT_SIGNED[target_fmt]:
                    integer *= (-1) ** (random.randint(0, 1))

                tv = generate_test_vector(
                    common.OP_CIF, integer & ((1 << common.INT_SIZES[target_fmt]) - 1), 0, 0, target_fmt, fmt, mode
                )
                results = run_test_vector(tv)
                info = extract_rounding_info(results)

                if info in goals:
                    goals.remove(info)
                    store_cover_vector(results, test_f, cover_f)

                    if len(goals) == 0:
                        break
            else:
                logger.exception(
                    f"CIF Test Gen Failed: fmt={fmt}, from={target_fmt}, mode={mode}, remaining_goals={goals}"
                )


@register_model("B3")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    random.seed(reproducible_hash("B3"))

    # These are going to be for sticky = 0
    for fmt in common.FLOAT_FMTS:
        write_add_sub_tests(test_f, cover_f, fmt)
        write_mul_tests(test_f, cover_f, fmt)
        write_div_tests(test_f, cover_f, fmt)
        write_sqrt_tests(test_f, cover_f, fmt)
        write_fma_tests(test_f, cover_f, fmt)
        write_cvt_tests(test_f, cover_f, fmt)

    targets = [
        {
            "Sign": (x & 1),
            "LSB": (x & 2) >> 1,
            "Guard": (x & 4) >> 2,
            "Sticky": (x & 8) >> 3,  # Sticky is one for all of these
        }
        for x in range(8, 16)
    ]

    for op in [*SRC1_OPS, *SRC2_OPS, *SRC3_OPS]:
        for fmt in common.FLOAT_FMTS:
            for mode in common.ROUNDING_MODES:
                cover_goals = targets[:]
                if op == common.OP_SQRT or op == common.OP_REM:
                    cover_goals = [x for x in cover_goals if x["Sign"] == 0]

                for _ in range(200):
                    in1 = generate_random_float(random.randint(0, 5), fmt)
                    in2 = generate_random_float(random.randint(0, 5), fmt) if op in SRC2_OPS or op in SRC3_OPS else 0
                    in3 = generate_random_float(random.randint(0, 5), fmt) if op in SRC3_OPS else 0

                    tv = generate_test_vector(op, in1, in2, in3, fmt, fmt, mode)
                    cv = run_test_vector(tv)

                    rounding_results = extract_rounding_info(cv)

                    if rounding_results in cover_goals:
                        cover_goals.remove(rounding_results)
                        store_cover_vector(cv, test_f, cover_f)

                    if len(cover_goals) == 0:
                        break
                else:
                    logger.exception(
                        f"Sticky=1 Random Generation Miss: op={op}, fmt={fmt}, goals_remaining={cover_goals}"
                    )
