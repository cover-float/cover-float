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

# Lamarr
# B6 Model


import random
from random import seed
from typing import TextIO

from cover_float.common.constants import (
    EXPONENT_BIAS,
    EXPONENT_BITS,
    FMT_BF16,
    FMT_DOUBLE,
    FMT_HALF,
    FMT_QUAD,
    FMT_SINGLE,
    MANTISSA_BITS,
    OP_CFF,
    OP_DIV,
    OP_FMADD,
    OP_FMSUB,
    OP_FNMADD,
    OP_FNMSUB,
    OP_MUL,
    UNBIASED_EXP,
)
from cover_float.common.util import reproducible_hash
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model

B6_FMTS = [FMT_QUAD, FMT_DOUBLE, FMT_SINGLE, FMT_BF16, FMT_HALF]
ROUNDING_MODES = ["00", "01", "02", "03", "04", "05"]
FMA_OPS = [OP_FMADD, OP_FMSUB, OP_FNMADD, OP_FNMSUB]


# def generate_FP(
#     input_e_bitwidth: int, input_sign: str, input_exponent: int, input_mantissa: str, input_bias: int
# ) -> str:
#     exponent = f"{input_exponent + input_bias:0{input_e_bitwidth}b}"
#     complete = input_sign + exponent + input_mantissa
#     fp_complete = format(int(complete, 2), "X")


#     return fp_complete


def generate_FP(
    input_e_bitwidth: int, input_sign: str, input_exponent: int, input_mantissa: str, input_bias: int
) -> str:
    # 1. Calculate and format the exponent
    exp_val = input_exponent + input_bias
    exponent = f"{exp_val:0{input_e_bitwidth}b}"

    # 2. Check for Exponent Overflow/Underflow
    if len(exponent) != input_e_bitwidth:
        raise ValueError(
            f"Alignment Error: Exponent binary '{exponent}' is {len(exponent)} bits long. "
            f"Expected exactly {input_e_bitwidth} bits. (Calculated value was {exp_val})"
        )

    # 3. Validate Sign Bit
    if len(input_sign) != 1 or input_sign not in ("0", "1"):
        raise ValueError(f"Alignment Error: Sign bit must be exactly '0' or '1'. Got: '{input_sign}'")

    # 4. Construct the full binary string
    complete = input_sign + exponent + input_mantissa
    total_bits = len(complete)

    # 5. Validate total bit length is a clean multiple of 4 (for hex conversion)
    if total_bits % 4 != 0:
        raise ValueError(
            f"Alignment Error: Total bit length ({total_bits}) is not a multiple of 4. "
            f"Sign: 1, Exp: {input_e_bitwidth}, Mantissa: {len(input_mantissa)}"
        )

    # 6. Convert to Hex AND explicitly pad to the correct number of characters
    hex_chars_needed = total_bits // 4
    fp_complete = format(int(complete, 2), "X").zfill(hex_chars_needed)

    return fp_complete


def convert_grs(
    hp: str,
    lp: str,
    g_exp: int,
    grs: str,
    sign: str,
    rounding_mode: str,
    test_f: TextIO,
    cover_f: TextIO,
    hashString: str,
) -> None:
    hashval = reproducible_hash(hashString)
    seed(hashval)

    hp_m_bits = MANTISSA_BITS[hp]
    hp_e_bits = EXPONENT_BITS[hp]
    hp_e_bias = EXPONENT_BIAS[hp]
    hp_min_exp = UNBIASED_EXP[hp][0]
    hp_minsn_exp = hp_min_exp - hp_m_bits

    # Determine the actual exponent, based on desired grs pattern
    grs_int = int(grs, 2)
    first_1 = grs.index("1")

    input_exp = g_exp - first_1 if grs_int != 1 else random.randint(hp_minsn_exp + 3, g_exp - 2)

    # Generate the mantissa
    input_mant = 0
    bits_left = hp_m_bits - max(hp_min_exp - input_exp, 0)
    sn = bits_left < hp_m_bits
    # Handle the first bit

    # Like for BF_16 to Single, you're going from sn -> sn
    if sn:
        input_mant += 1 << bits_left
    bits_left -= 1
    if int(grs, 2) != 1:  # TODO: Maybe contain in one statement, so line 121's if doesn't get triggered
        grs = grs.replace("1", "0", 1)
    if grs[1] == "0":
        bits_left -= 1
    elif grs[1] == "1":
        input_mant += 1 << bits_left

    if grs[2] == "1":
        if bits_left == 1:
            input_mant += 1
        else:
            input_mant += random.randint(1, (1 << bits_left) - 1)

    # Normalize exponent
    input_exp = max(input_exp, hp_min_exp - 1)
    # Make sure exponent has correct padding
    input_mant_bin = f"{input_mant:0{hp_m_bits}b}"

    input_fp = generate_FP(hp_e_bits, sign, input_exp, input_mant_bin, hp_e_bias)
    run_and_store_test_vector(
        f"{OP_CFF}_{rounding_mode}_{input_fp}_{32 * '0'}_{32 * '0'}_{hp}_{32 * '0'}_{lp}_00", test_f, cover_f
    )


def genSpecExp_mul(precision: str, target: int, hashString: str) -> tuple[int, int]:
    hashval = reproducible_hash(hashString)
    seed(hashval)
    m_bits = MANTISSA_BITS[precision]
    min_exp = UNBIASED_EXP[precision][0]

    min_sn = min_exp - m_bits

    a_exp = random.randint(min_sn, target - min_sn)
    b_exp = target - a_exp
    return (a_exp, b_exp)


def genSpecExp_div(precision: str, target: int, hashString: str, grs_int: int) -> tuple[int, int]:
    hashval = reproducible_hash(hashString)
    seed(hashval)
    m_bits = MANTISSA_BITS[precision]
    min_exp = UNBIASED_EXP[precision][0]
    max_exp = UNBIASED_EXP[precision][1]

    # Absolute lowest effective exponent (subnormal floor)
    min_sn = min_exp - m_bits + 1

    # Mathematical rule for Division: target = a_exp - b_exp
    # Therefore: b_exp = a_exp - target

    lower_bound = max(min_sn, min_sn + target)

    if grs_int == 7 or grs_int == 5:
        lower_bound = max(min_exp, min_sn + target)  # No Subnormal Values, so mantissa has same # of bits

    upper_bound = min(max_exp, max_exp + target)

    if lower_bound > upper_bound:
        lower_bound = upper_bound

    a_exp = random.randint(lower_bound, upper_bound)
    b_exp = a_exp - target

    large_exp = max(a_exp, b_exp)
    small_exp = min(b_exp, a_exp)
    return (small_exp, large_exp)


def get_grs_mant(operation: str, precision: str, a_exp: int, b_exp: int, hashString: str, grs: str) -> tuple[str, str]:
    m_bits = MANTISSA_BITS[precision]
    e_min = UNBIASED_EXP[precision][0]
    min_sn = e_min - m_bits

    # Since we're unbiased, if a_exp > e_min, result < 0, meaning it's normal and bits_left = m_bits
    a_bits_left = m_bits - max(e_min - a_exp, 0)
    b_bits_left = m_bits - max(e_min - b_exp, 0)

    grs_int = int(grs, 2)

    # Loop until we get desired results:
    met_conditions = False

    cycles_attempted = 0

    a_mantissa = 0
    b_mantissa = 0

    # Set up a_mantissa and b_mantissa, they are different based on the grs pattern:
    a_rBit = False
    b_rBit = False
    if grs_int == 6:
        if a_exp == min_sn or b_exp == min_sn:  # If exp = min_sn, then you can't have the rBit
            if operation == OP_MUL:
                if a_exp == min_sn and b_exp == min_sn:
                    raise ValueError("a_exp and b_exp can't both be min_sn")
                elif a_exp == min_sn:
                    b_rBit = True
                elif b_exp == min_sn:
                    a_rBit = True
            else:
                a_rBit = True
        else:  # Random selection otherwise
            if operation == OP_MUL:
                a_rBit = random.randint(0, 1) == 1  # If 1 is randomly selected, then a_rBit = True
                b_rBit = not a_rBit
            else:
                a_rBit = True
        if a_rBit:
            a_mantissa += 1 << (a_bits_left - 1)
        elif b_rBit:
            b_mantissa += 1 << (b_bits_left - 1)

    elif (grs_int == 7 and operation == OP_DIV) or (grs_int == 5 and operation == OP_DIV):
        a_max = (1 << (a_bits_left + 1)) - 1
        # a_min = 1 << a_bits_left  # With hidden 1

        b_min = 1 << b_bits_left
        b_max = (1 << (b_bits_left + 1)) - 1

        a_int = 0
        b_int = 0

        if grs_int == 7 or grs_int == 5:
            # b and a mantissas have the same range
            b_min_range = b_min
            b_max_range = (2 * b_max) // 3

            small_int = random.randint(b_min_range, b_max_range)

            a_min_range = (3 * small_int) // 2
            a_max_range = a_max

            large_int = random.randint(a_min_range, a_max_range)

            if grs_int == 7:
                a_int = large_int
                b_int = small_int
            else:
                a_int = small_int
                b_int = large_int

        a_mantissa = a_int - (1 << a_bits_left)  # Remove hidden 1
        b_mantissa = b_int - (1 << b_bits_left)

    if grs_int == 3 and operation == OP_DIV:
        a_mantissa = random.randint(1, (1 << a_bits_left) - 1)
        b_mantissa = random.randint(1, (1 << b_bits_left) - 1)

    if grs_int == 1 and operation == OP_DIV:
        a_mantissa = random.randint(1, (1 << a_bits_left) - 1)
        b_mantissa = random.randint(1, a_mantissa)

    if grs_int != 2 and grs_int != 6 and grs_int != 4 and operation == OP_MUL:
        while not met_conditions:
            seed(cycles_attempted)  # Make deterministic

            # Scales down values for test 5 to get a r_bit = 0
            mantissa_scalar = 1
            if grs_int == 5:
                mantissa_scalar = (cycles_attempted % 3) + 1

            a_mantissa = random.randint(0, (1 << a_bits_left) - 1) // mantissa_scalar
            b_mantissa = random.randint(0, (1 << b_bits_left) - 1) // mantissa_scalar

            # Add hidden 1
            a_mantissa += 1 << a_bits_left
            b_mantissa += 1 << b_bits_left

            product_a_b = a_mantissa * b_mantissa

            # To avoid normalization, the product must be < 2
            product_bits = a_bits_left + b_bits_left + 2
            decimal_bit = a_bits_left + b_bits_left  # The first bit where there will be a decimal
            maxNorm = 1 << (product_bits - 1)  # Really the smallest nonNorm

            if product_a_b < maxNorm:
                if grs_int == 5 or grs_int == 7:
                    subtract_g_bit = product_a_b - (1 << decimal_bit)
                    subtract_r_bit = subtract_g_bit - (1 << (decimal_bit - 1))
                    if grs_int == 5:
                        met_conditions = subtract_r_bit < 0
                    elif grs_int == 7:
                        met_conditions = subtract_r_bit > 0
                else:
                    met_conditions = True

                if met_conditions:
                    # Once a_mantissa and b_mantissa are generated, I can remove the hidden 1 if normal
                    a_mantissa -= 1 << a_bits_left
                    b_mantissa -= 1 << b_bits_left

            cycles_attempted += 1

    # Add leading 1 if SN
    if a_bits_left < m_bits:
        a_mantissa += 1 << a_bits_left
    if b_bits_left < m_bits:
        b_mantissa += 1 << b_bits_left

    bin_a_mantissa = f"{a_mantissa:0{m_bits}b}"
    bin_b_mantissa = f"{b_mantissa:0{m_bits}b}"

    return (bin_a_mantissa, bin_b_mantissa)


def mul_div_grs_gen(
    operation: str,
    precision: str,
    rounding_mode: str,
    grs: str,
    g_exp: int,
    sign: int,
    test_f: TextIO,
    cover_f: TextIO,
    hashEnding: str,
    genTests: bool,
) -> tuple[str, str]:
    hashString = "b5" + OP_MUL + precision + rounding_mode + hashEnding
    seed(hashString)

    # g_exp is needed for going below normal, getting specific subnorm results
    e_bits = EXPONENT_BITS[precision]
    m_bits = MANTISSA_BITS[precision]
    e_bias = EXPONENT_BIAS[precision]
    min_exp = UNBIASED_EXP[precision][0]
    sn_exp = min_exp - 1

    first_bit = g_exp - grs.index("1")

    if sign == 0:
        a_sign = random.randint(0, 1)
        b_sign = a_sign
    else:
        a_sign = random.randint(0, 1)
        b_sign = (a_sign + 1) % 2

    grs_int = int(grs, 2)

    target_exp = first_bit
    if grs_int == 1:
        smallest_res_exp = min_exp - (2 * m_bits)
        target_exp = random.randint(smallest_res_exp, first_bit)

    if operation == OP_MUL:
        a_exp, b_exp = genSpecExp_mul(precision, target_exp, str(hashString) + str(grs) + str(sign))
    else:  # operation == OP_DIV
        a_exp, b_exp = genSpecExp_div(precision, target_exp, hashString, grs_int)

    a_mant, b_mant = get_grs_mant(operation, precision, a_exp, b_exp, hashString + str(grs) + str(sign), str(grs))

    # Normalize exponents
    a_exp = max(a_exp, sn_exp)
    b_exp = max(b_exp, sn_exp)

    a = generate_FP(e_bits, str(a_sign), a_exp, a_mant, e_bias)
    b = generate_FP(e_bits, str(b_sign), b_exp, b_mant, e_bias)

    if genTests:
        run_and_store_test_vector(
            f"{operation}_{rounding_mode}_{a}_{b}_{32 * '0'}_{precision}_{32 * '0'}_{precision}_00", test_f, cover_f
        )

    return (a, b)


def fma_gen(
    operation: str,
    precision: str,
    rounding_mode: str,
    result_sign: int,
    product_grs: str,
    product_exponent: int,
    addend_pattern: str,
    test_f: TextIO,
    cover_f: TextIO,
    hashEnding: str,
) -> None:
    m_bits = MANTISSA_BITS[precision]
    e_bits = EXPONENT_BITS[precision]
    e_bias = EXPONENT_BIAS[precision]
    min_exp = UNBIASED_EXP[precision][0]

    min_sn_exp = min_exp - m_bits

    hashval = reproducible_hash(hashEnding)
    seed(hashval)

    fma_grs_int = 8
    target_grs_int = int(product_grs, 2)

    mul_grs = fma_grs_int - target_grs_int
    mul_grs_bin = f"{mul_grs:0{3}b}"

    fma_mant_shifter = product_exponent - (min_sn_exp - 2)
    fma_op_key = {
        OP_FMADD: {"mul_sign": 0, "add_sign": 0},
        OP_FMSUB: {"mul_sign": 0, "add_sign": 1},
        OP_FNMADD: {"mul_sign": 1, "add_sign": 1},
        OP_FNMSUB: {"mul_sign": 1, "add_sign": 0},
    }

    # Determine the desired output signs for multiplication and addition

    addend_sign = result_sign
    product_sign = (addend_sign + 1) % 2

    op_mul_sign = fma_op_key[operation]["mul_sign"]
    op_add_sign = fma_op_key[operation]["add_sign"]

    mul_sign = (op_mul_sign + product_sign) % 2
    c_sign = (op_add_sign + addend_sign) % 2

    # Generate the multiplication testvectors

    a, b = mul_div_grs_gen(
        OP_MUL,
        precision,
        rounding_mode,
        mul_grs_bin,
        product_exponent,
        mul_sign,
        test_f,
        cover_f,
        hashEnding,
        False,
    )

    # Generate the addition testvector
    c_exp = -1
    c_mant = -1
    if addend_pattern == "min_sn":
        c_exp = min_exp - 1  # Subnormal
        # Normalization
        c_mant = fma_mant_shifter

    c_bin_mant = f"{c_mant:0{m_bits}b}"
    c = generate_FP(e_bits, str(c_sign), c_exp, c_bin_mant, e_bias)
    run_and_store_test_vector(
        f"{operation}_{rounding_mode}_{a}_{b}_{c}_{precision}_{32 * '0'}_{precision}_00", test_f, cover_f
    )


def div_grs_mant(
    test_f: TextIO,
    cover_f: TextIO,
    grs: str,
    g_bit_pos: int,
    precision: str,
    rounding_mode: str,
    target_exp: int,
    sign: str,
    hashString: str,
) -> tuple[str, str]:
    m_bits = MANTISSA_BITS[precision]
    e_bits = EXPONENT_BITS[precision]
    e_bias = EXPONENT_BIAS[precision]
    min_exp = UNBIASED_EXP[precision][0]

    # Determine exponents, subtract to target_exp
    possible_exponents = genSpecExp_div(precision, target_exp, hashString, int(grs, 2))

    a_exp = max(possible_exponents)
    b_exp = min(possible_exponents)

    a_bits_left = m_bits - max(min_exp - a_exp, 0)
    b_bits_left = m_bits - max(min_exp - b_exp, 0)

    b_max_mant = (1 << b_bits_left) - 1
    a_max_mant = (1 << a_bits_left) - 1

    b_mantissa = random.randint(1, b_max_mant - 1)
    a_mantissa = random.randint(b_mantissa // 2, a_max_mant)

    if sign == "0":
        a_sign = random.randint(0, 1)
        b_sign = a_sign
    else:
        a_sign = random.randint(0, 1)
        b_sign = (a_sign + 1) % 2

    a_exp_norm = max(a_exp, min_exp - 1)
    b_exp_norm = max(b_exp, min_exp - 1)

    if a_bits_left < m_bits:
        a_mantissa += 1 << a_bits_left
    if b_bits_left < m_bits:
        b_mantissa += 1 << b_bits_left

    a = f"{a_mantissa:0{m_bits}b}"
    b = f"{b_mantissa:0{m_bits}b}"

    a_fp = generate_FP(e_bits, str(a_sign), a_exp_norm, a, e_bias)
    b_fp = generate_FP(e_bits, str(b_sign), b_exp_norm, b, e_bias)

    run_and_store_test_vector(
        f"{OP_DIV}_{rounding_mode}_{b_fp}_{a_fp}_{32 * '0'}_{precision}_{32 * '0'}_{precision}_00", test_f, cover_f
    )
    return a_fp, b_fp


def convertTests(test_f: TextIO, cover_f: TextIO) -> None:
    # All conversion tests:
    for i_hp in range(len(B6_FMTS)):
        hp = B6_FMTS[i_hp]
        for i_lp in range(i_hp + 1, len(B6_FMTS)):
            lp = B6_FMTS[i_lp]
            # hp = FMT_SINGLE
            # lp = FMT_HALF
            for rounding_mode in ROUNDING_MODES:
                lp_min_exp = UNBIASED_EXP[lp][0]
                lp_m_bits = MANTISSA_BITS[lp]

                lp_min_sn_exp = lp_min_exp - lp_m_bits
                tlp_min_sn_exp = lp_min_sn_exp - 1

                grs = ["001", "010", "011", "100", "101", "110", "111"]
                for bits in grs:
                    for exp in [lp_min_sn_exp, tlp_min_sn_exp]:
                        hashString = str(hp) + str(lp) + str(rounding_mode) + str(grs) + str(exp)
                        convert_grs(hp, lp, exp, bits, "0", rounding_mode, test_f, cover_f, hashString + "0")
                        convert_grs(hp, lp, exp, bits, "1", rounding_mode, test_f, cover_f, hashString + "1")


def createTests(test_f: TextIO, cover_f: TextIO) -> None:
    for rounding_mode in ROUNDING_MODES:
        for precision in B6_FMTS:
            # precision = FMT_HALF
            m_bits = MANTISSA_BITS[precision]
            min_exp = UNBIASED_EXP[precision][0]

            min_sn_exp = min_exp - m_bits
            t_min_sn_exp = min_sn_exp - 1  # MinSN/2
            for exp in [min_sn_exp, t_min_sn_exp]:
                for sign in [0, 1]:
                    grs = ["001", "010", "011", "100", "101", "110", "111"]

                    for grs_bin in grs:
                        mul_div_grs_gen(
                            OP_MUL, precision, rounding_mode, grs_bin, exp, sign, test_f, cover_f, "1/2", True
                        )
                        mul_div_grs_gen(
                            OP_DIV, precision, rounding_mode, grs_bin, exp, sign, test_f, cover_f, "1/2", True
                        )
                        for operation in FMA_OPS:
                            fma_gen(
                                operation,
                                precision,
                                rounding_mode,
                                sign,
                                grs_bin,
                                exp,
                                "min_sn",
                                test_f,
                                cover_f,
                                "pos_1",
                            )


@register_model("B6")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    convertTests(test_f, cover_f)
    createTests(test_f, cover_f)
