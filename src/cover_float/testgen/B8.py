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

# B8 (rwolk@hmc.edu)

import itertools
import logging
import random
from typing import Optional, TextIO, cast

import cover_float.common.constants as constants
import cover_float.common.log as log
from cover_float.common.util import (
    bezout_inverse,
    extract_rounding_info,
    generate_float,
    generate_test_vector,
    reproducible_hash,
    unpack_test_vector,
)
from cover_float.reference import run_and_store_test_vector, run_test_vector, store_cover_vector
from cover_float.testgen.model import register_model

logger: log.ModelLogger = cast(log.ModelLogger, logging.getLogger("B8"))


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


def divideSetRounding(
    lsb: int, guard: int, target: int, extra_bits: int, fmt: str, should_shift: Optional[bool] = None
) -> Optional[tuple[int, int]]:
    nf = constants.MANTISSA_BITS[fmt]

    # There is a potential shift when sigA < sigB, so make it random
    if not should_shift:
        should_shift = bool(random.randint(0, 1))

    for _ in range(100):
        sigB = random.getrandbits(nf) | 1 << nf | 1  # B must be odd in this approach ...

        bottom = sigB * target // (2**extra_bits)
        if bottom * (2**extra_bits) != sigB * target:
            bottom += 1  # Ceil division (through floating point) breaks for quads

        top = sigB * (target + 1) // (2**extra_bits)

        for c in range(bottom, top):
            sigA = (c * pow(2 ** (nf + 1 + should_shift), -1, sigB)) % sigB

            if sigA.bit_length() != nf + 1:
                sigA += sigB
                if sigA.bit_length() != nf + 1:
                    continue

            if (should_shift and sigA > sigB) or (not should_shift and sigA < sigB):
                continue

            # The shift is + 1 for the guard, and then another if we should shift

            divide_result = (sigA << (nf + extra_bits + 1 + should_shift)) // sigB
            binary_result = bin(divide_result)[2:]

            generated_lsb = int(binary_result[nf])
            generated_guard = int(binary_result[nf + 1])
            generated_sticky = int(binary_result[nf + 2 :], 2)

            if generated_lsb == lsb and generated_guard == guard and generated_sticky == target:
                return (sigA, sigB)

    return None


def check_div_result(result: str, target: int, sticky_length: int) -> bool:
    fields = unpack_test_vector(result)
    interm_mantissa = f"{fields.interm_sig:0{constants.INTER_SIGNIFICAND_LENGTH}b}"
    fmt = fields.output_format
    nf = constants.MANTISSA_BITS[fmt]

    sticky = interm_mantissa[nf + 1 :]
    relevant_bits = sticky[:sticky_length]

    return int(relevant_bits, 2) == target


def generate_extra_bits_patterns(length: int) -> list[int]:
    # These avoid duplicated tests and silly negative numbers
    if length == 1:
        return [0, 1]
    elif length == 2:
        return list(range(1, 4))

    target_extra_bits = list(range(1, 4))
    for target_offset in range(4, 0, -1):
        target_extra_bits.append((1 << length) - target_offset)
    return target_extra_bits


def sign_lsb_guard() -> list[tuple[int, int, int]]:
    return list(itertools.product([0, 1], [0, 1], [0, 1]))


def generate_exponents(fmt: str, *, subtract: bool = False) -> tuple[int, int]:
    exp_min, exp_max = constants.BIASED_EXP[fmt]

    exp_min -= constants.BIAS[fmt]
    exp_max -= constants.BIAS[fmt]

    exp1 = random.randint(exp_min, exp_max)
    exp2 = random.randint(exp_min, exp_max)
    score = exp1 + exp2 if not subtract else exp1 - exp2

    while not exp_min < score < exp_max:
        exp1 = random.randint(exp_min, exp_max)
        exp2 = random.randint(exp_min, exp_max)
        score = exp1 + exp2 if not subtract else exp1 - exp2

    return exp1, exp2


def generate_div_tests(fmt: str, rm: str, test_f: TextIO, cover_f: TextIO, target_bits: Optional[int] = None) -> None:
    seed = reproducible_hash(f"B8 DIV {fmt} {rm}")
    random.seed(seed)

    nf = constants.MANTISSA_BITS[fmt]
    if not target_bits:
        target_bits = nf - 2

    for target in range(1, 4):
        for sign, lsb, guard in sign_lsb_guard():
            maybe_result = divideSetRounding(lsb, guard, target, target_bits, fmt)
            if not maybe_result:
                logger.exception(f"Div Failure for lsb={lsb}, guard={guard}, sticky={target:b}, fmt={fmt}")
                continue

            s1, s2 = maybe_result

            sign1 = random.randint(0, 1)
            sign2 = sign1 ^ sign

            exp1, exp2 = generate_exponents(fmt, subtract=True)

            f1 = generate_float(sign1, exp1, s1 & ((1 << nf) - 1), fmt)
            f2 = generate_float(sign2, exp2, s2 & ((1 << nf) - 1), fmt)

            tv = generate_test_vector(constants.OP_DIV, f1, f2, 0, fmt, fmt)
            result = run_test_vector(tv)
            info = extract_rounding_info(result)
            if check_div_result(result, target, target_bits) and info["Guard"] == guard and info["LSB"] == lsb:
                store_cover_vector(result, test_f, cover_f)
            else:
                logger.exception(f"Div Result Failure, lsb={lsb}, guard={guard}, sticky={target:b}, fmt={fmt}")

    for target_offset in range(4, 0, -1):
        target = (1 << target_bits) - target_offset
        for sign, lsb, guard in sign_lsb_guard():
            maybe_result = divideSetRounding(lsb, guard, target, target_bits, fmt)
            if not maybe_result:
                logger.exception(f"Div Failure for lsb={lsb}, guard={guard}, sticky={target:b}, fmt={fmt}")
                continue

            s1, s2 = maybe_result

            sign1 = random.randint(0, 1)
            sign2 = sign1 ^ sign

            exp1, exp2 = generate_exponents(fmt, subtract=True)

            f1 = generate_float(sign1, exp1, s1 & ((1 << nf) - 1), fmt)
            f2 = generate_float(sign2, exp2, s2 & ((1 << nf) - 1), fmt)

            tv = generate_test_vector(constants.OP_DIV, f1, f2, 0, fmt, fmt, rm)
            result = run_test_vector(tv)
            info = extract_rounding_info(result)
            if check_div_result(result, target, target_bits) and info["Guard"] == guard and info["LSB"] == lsb:
                store_cover_vector(result, test_f, cover_f)
            else:
                logger.exception(f"Div Result Failure, lsb={lsb}, guard={guard}, sticky={target:b}, fmt={fmt}")


def generate_mul_tests(fmt: str, rm: str, test_f: TextIO, cover_f: TextIO) -> None:
    seed = reproducible_hash(f"B8 MUL {fmt} {rm}")
    random.seed(seed)

    # To maximize extra bits, we take a 2.2nf result with a leading one
    # That is, 1.(2nf + 1) is the real result, so we have nf bits contributing to sticky

    nf = constants.MANTISSA_BITS[fmt]
    target_extra_bits = generate_extra_bits_patterns(nf)

    for sign, lsb, guard in sign_lsb_guard():
        for target_sticky in target_extra_bits:
            target = (lsb << 1 | guard) << nf | target_sticky

            for _ in range(100):
                s1, s2 = mul_sigs_with_trailing(target, nf + 2, fmt)

                if (s1 * s2).bit_length() != 2 * nf + 2:
                    continue

                sign1 = random.randint(0, 1)
                sign2 = sign1 ^ sign

                exp1, exp2 = generate_exponents(fmt)

                f1 = generate_float(sign1, exp1, s1 & ((1 << nf) - 1), fmt)
                f2 = generate_float(sign2, exp2, s2 & ((1 << nf) - 1), fmt)

                tv = generate_test_vector(constants.OP_MUL, f1, f2, 0, fmt, fmt, rm)
                run_and_store_test_vector(tv, test_f, cover_f)
                break
            else:
                logger.exception(
                    f"Mul Generation Failed: fmt={fmt}, lsb={lsb}, guard={guard}, extra_bits={target_sticky}"
                )


def generate_add_sub_tests(fmt: str, rm: str, test_f: TextIO, cover_f: TextIO) -> None:
    seed = reproducible_hash(f"B8 ADD SUB {fmt} {rm}")
    random.seed(seed)
    # To maximize the extra bits lengths, we know that we need to align one of the addends
    # in the others guard bit (for guard=1) and in the lsb (for guard = 0)
    # This gives nf extra bits for guard = 1 and and nf - 1 for guard = 0

    nf = constants.MANTISSA_BITS[fmt]

    for op in [constants.OP_ADD, constants.OP_SUB]:
        for sign, lsb, guard in sign_lsb_guard():
            if guard == 1:  # noqa: SIM108
                sticky_length = nf + (op == constants.OP_SUB)
            else:  # guard == 0
                sticky_length = nf - 1 + (op == constants.OP_SUB)

            extra_bits_patterns = generate_extra_bits_patterns(sticky_length)
            if op == constants.OP_SUB and guard == 1:
                # We need to lower the sticky length when we have a high extra bits pattern
                shorter_sticky_length = generate_extra_bits_patterns(sticky_length - 2)
                patterns: list[int] = []
                for long_target, short_target in zip(extra_bits_patterns, shorter_sticky_length):
                    if long_target < 4:
                        patterns.append(long_target)
                    else:
                        patterns.append(short_target)
                extra_bits_patterns = patterns

            for target_sticky in extra_bits_patterns:
                if op == constants.OP_ADD:
                    s1 = random.getrandbits(nf - 1) << 1 | lsb
                    s2 = target_sticky
                else:
                    s1 = random.getrandbits(nf - 1) << 1 | (lsb ^ 1)
                    s2 = (1 << nf + 1) - target_sticky
                    s2 &= (1 << nf) - 1

                if guard == 0 and op != constants.OP_SUB:
                    s1 ^= 1

                # Edge case handling (overflowing into another exponent)
                if ((1 << nf) + s1 + 1).bit_length() > ((1 << nf) + s1).bit_length():
                    s1 -= 4
                if ((1 << nf) + s1 - 1).bit_length() < ((1 << nf) + s1).bit_length():
                    s1 += 4

                expDiff = nf + (guard == 1) + (op == constants.OP_SUB)
                exp1 = 0
                exp2 = exp1 - expDiff

                f1 = generate_float(sign, exp1, s1, fmt)
                f2 = generate_float(sign, exp2, s2, fmt)

                if random.random() < 1 and op == constants.OP_ADD:
                    f1, f2 = f2, f1

                tv = generate_test_vector(op, f1, f2, 0, fmt, fmt, rm)
                result = run_test_vector(tv)

                fields = unpack_test_vector(result)
                interm_mantissa = f"{fields.interm_sig:0{constants.INTER_SIGNIFICAND_LENGTH}b}"
                rounding_bits = interm_mantissa[nf - 1 :]
                total_rounding_bits = sticky_length + 2
                target_bits = bin((lsb << 1 | guard) << sticky_length | target_sticky)[2:].zfill(total_rounding_bits)

                if (
                    rounding_bits[:total_rounding_bits] == target_bits
                    and rounding_bits[total_rounding_bits:].count("1") == 0
                ):
                    store_cover_vector(result, test_f, cover_f)
                else:
                    logger.exception(
                        f"Add/Sub Generation Failed, fmt={fmt}, op={op}, guard={guard}, lsb={lsb}, "
                        f"extra_bits:{target_sticky}"
                    )


def generate_fma_tests(fmt: str, rm: str, test_f: TextIO, cover_f: TextIO) -> None:
    seed = reproducible_hash(f"B8 FMA {fmt} {rm}")
    random.seed(seed)

    # The logic here is the same as add/sub, just with s1 coming from a multiplication result
    nf = constants.MANTISSA_BITS[fmt]

    for op in [constants.OP_FMADD, constants.OP_FMSUB, constants.OP_FNMADD, constants.OP_FNMSUB]:
        for sign, lsb, guard in sign_lsb_guard():
            # We will be placing the msb of the input 3 into the lsb of the multiplication result
            sticky_length = 2 * nf

            for sticky_target in generate_extra_bits_patterns(sticky_length):
                # The idea here is that we can compute what we want the addition and subtraction sigs to be beforehand
                # Using a version of the overall target of what we want in the end. Then, we know how to find
                # relevant multiplication significands and addition significands will come easily
                overall_target = ((lsb << 1 | guard) << sticky_length | sticky_target) | (1 << (sticky_length + 2))
                mul_target = 0
                if op == constants.OP_FMADD or op == constants.OP_FNMSUB:
                    # Effective Addition
                    add_target = overall_target & ((1 << nf) - 1)
                    add_target |= 1 << nf

                    mul_target = overall_target - add_target
                else:
                    # Effective Subtraction
                    add_target = overall_target & ((1 << nf) - 1)
                    add_target = (1 << nf) - add_target
                    add_target |= 1 << nf

                    mul_target = overall_target + add_target

                mul_target ^= 1 << (sticky_length + 2)

                for _ in range(100):
                    s1, s2 = mul_sigs_with_trailing(mul_target >> nf, nf + 2, fmt)
                    if (s1 * s2).bit_length() != 2 * nf + 2:
                        continue

                    expDiff = -2 * nf

                    prodSign = sign
                    addSign = sign

                    signA = random.randint(0, 1)
                    signB = signA ^ prodSign

                    negated_operation = op == constants.OP_FNMADD or op == constants.OP_FNMSUB
                    signA ^= negated_operation

                    exp_min, exp_max = constants.BIASED_EXP[fmt]
                    exp_min -= constants.BIAS[fmt]
                    exp_max -= constants.BIAS[fmt]

                    exp1, exp2 = generate_exponents(fmt)
                    addExp = exp1 + exp2 + expDiff

                    while not exp_min <= addExp <= exp_max:
                        exp1, exp2 = generate_exponents(fmt)
                        addExp = exp1 + exp2 + expDiff

                    f1 = generate_float(signA, exp1, s1 & ((1 << nf) - 1), fmt)
                    f2 = generate_float(signB, exp2, s2 & ((1 << nf) - 1), fmt)
                    f3 = generate_float(addSign, addExp, add_target & ((1 << nf) - 1), fmt)

                    tv = generate_test_vector(op, f1, f2, f3, fmt, fmt, rm)
                    result = run_test_vector(tv)

                    fields = unpack_test_vector(result)
                    interm_mantissa = f"{fields.interm_sig:0{constants.INTER_SIGNIFICAND_LENGTH}b}"
                    rounding_bits = interm_mantissa[nf - 1 :]
                    total_rounding_bits = sticky_length + 2
                    target_bits = bin((lsb << 1 | guard) << sticky_length | sticky_target)[2:].zfill(
                        total_rounding_bits
                    )

                    if (
                        rounding_bits[:total_rounding_bits] == target_bits
                        and rounding_bits[total_rounding_bits:].count("1") == 0
                    ):
                        store_cover_vector(result, test_f, cover_f)
                        break
                    else:
                        logger.exception(
                            f"FMA Generation Failed, fmt={fmt}, op={op}, guard={guard}, lsb={lsb},"
                            f" extra_bits:{sticky_target}"
                        )


def generate_convert_tests(fmt: str, rm: str, test_f: TextIO, cover_f: TextIO) -> None:
    # These are pretty simple, we just want the maximum possible overhang for each type of conversion
    nf = constants.MANTISSA_BITS[fmt]
    exp_min, exp_max = constants.BIASED_EXP[fmt]
    exp_min -= constants.BIAS[fmt]
    exp_max -= constants.BIAS[fmt]

    # CFF / CFI
    for target_fmt in constants.FLOAT_FMTS + constants.INT_FMTS:
        if target_fmt in constants.FLOAT_FMTS:
            target_nf = constants.MANTISSA_BITS[target_fmt]
        else:
            target_nf = constants.INT_MAX_EXPS[target_fmt]

        if nf - target_nf <= 0 and target_fmt not in constants.INT_FMTS:
            # Not an interesting conversion to round
            continue

        if target_fmt in constants.FLOAT_FMTS:
            target_exp_min, target_exp_max = constants.BIASED_EXP[target_fmt]
            target_exp_min -= constants.BIAS[target_fmt]
            target_exp_max -= constants.BIAS[target_fmt]
        else:
            target_exp_min = 1
            target_exp_max = 1

        maximal_overhang = nf - target_nf if target_fmt in constants.FLOAT_FMTS else nf - 1
        op = constants.OP_CFF if target_fmt in constants.FLOAT_FMTS else constants.OP_CFI

        for sign, lsb, guard in sign_lsb_guard():
            if target_fmt in constants.INT_FMTS and not constants.INT_SIGNED[target_fmt] and sign:
                continue

            for extra_bits in generate_extra_bits_patterns(maximal_overhang - 2):
                target = ((lsb << 1) | guard) << (maximal_overhang - 2) | extra_bits

                sig = random.getrandbits(nf - maximal_overhang - 1) << (maximal_overhang + 1) | target
                exp = random.randint(max(exp_min, target_exp_min), min(exp_max, target_exp_max))

                f = generate_float(sign, exp, sig, fmt)
                tv = generate_test_vector(op, f, 0, 0, fmt, target_fmt, rm)
                result = run_test_vector(tv)

                fields = unpack_test_vector(result)
                interm_sig = f"{fields.interm_sig:0{constants.INTER_SIGNIFICAND_LENGTH}b}"

                rounding_bits = interm_sig[target_nf - 1 :][: maximal_overhang + 1]

                if (
                    int(rounding_bits, 2) == target and rounding_bits[target_nf + maximal_overhang :].count("1") == 0
                ) or (fmt == constants.FMT_QUAD and target_fmt == constants.FMT_BF16):
                    store_cover_vector(result, test_f, cover_f)
                else:
                    logger.exception(
                        f"CFF/CFI Generation Failed, fmt={fmt}, target_fmt={target_fmt}, lsb={lsb}, guard={guard}, "
                        f"extra_bits={extra_bits:b}"
                    )

    # CIF
    for from_fmt in constants.INT_FMTS:
        from_bits = constants.INT_MAX_EXPS[from_fmt]

        maximal_overhang = from_bits - (nf + 1)  # Account for leading one in floats
        if maximal_overhang <= 0:
            # Uninteresting case
            continue

        for sign, lsb, guard in sign_lsb_guard():
            if sign and not constants.INT_SIGNED[from_fmt]:
                continue

            for extra_bits in generate_extra_bits_patterns(maximal_overhang - 2):
                target = ((lsb << 1) | guard) << (maximal_overhang - 2) | extra_bits
                integer = random.getrandbits(from_bits - maximal_overhang - 1) << (maximal_overhang + 1) | target
                integer |= 1 << (from_bits - 1)

                if sign:
                    integer *= 1
                    integer &= (1 << constants.INT_SIZES[from_fmt]) - 1  # Bring it to 2s complement representation

                tv = generate_test_vector(constants.OP_CIF, integer, 0, 0, from_fmt, fmt, rm)
                result = run_test_vector(tv)

                fields = unpack_test_vector(result)
                interm_sig = f"{fields.interm_sig:0{constants.INTER_SIGNIFICAND_LENGTH}b}"

                rounding_bits = interm_sig[nf - 1 :][: maximal_overhang + 1]

                if (
                    int(rounding_bits, 2) == target and rounding_bits[from_bits:].count("1") == 0
                ) or fmt == constants.FMT_BF16:
                    store_cover_vector(result, test_f, cover_f)
                else:
                    logger.exception(
                        f"CIF Generation Failed, from_fmt={from_fmt}, fmt={fmt}, lsb={lsb}, guard={guard}, "
                        f"extra_bits={extra_bits:b}"
                    )


@register_model("B8")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    for fmt in constants.FLOAT_FMTS:
        for rm in constants.ROUNDING_MODES:
            generate_div_tests(fmt, rm, test_f, cover_f)
            generate_mul_tests(fmt, rm, test_f, cover_f)
            generate_add_sub_tests(fmt, rm, test_f, cover_f)
            generate_fma_tests(fmt, rm, test_f, cover_f)
            generate_convert_tests(fmt, rm, test_f, cover_f)
