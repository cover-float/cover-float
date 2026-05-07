# Lamarr
# B5 Model


import random
from collections.abc import Iterator
from random import seed
from typing import TextIO

from cover_float.common.constants import (
    EXPONENT_BIAS,
    EXPONENT_BITS,
    FLOAT_FMTS,
    FMT_BF16,
    FMT_DOUBLE,
    FMT_HALF,
    FMT_QUAD,
    FMT_SINGLE,
    MANTISSA_BITS,
    OP_ADD,
    OP_CFF,
    OP_DIV,
    OP_FMADD,
    OP_FMSUB,
    OP_FNMADD,
    OP_FNMSUB,
    OP_MUL,
    OP_SUB,
    ROUND_MAX,
    ROUND_MIN,
    ROUND_MINMAG,
    ROUND_NEAR_EVEN,
    ROUND_NEAR_MAXMAG,
    UNBIASED_EXP,
)
from cover_float.common.util import reproducible_hash
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model

B5_FMTS = [FMT_QUAD, FMT_DOUBLE, FMT_SINGLE, FMT_BF16, FMT_HALF]
ROUNDING_MODES = [ROUND_NEAR_EVEN, ROUND_MINMAG, ROUND_MIN, ROUND_MAX, ROUND_NEAR_MAXMAG]
FMA_OPS = [OP_FMADD, OP_FMSUB, OP_FNMADD, OP_FNMSUB]


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
    hp: str, lp: str, g_exp: int, grs: str, sign: str, rounding_mode: str, test_f: TextIO, cover_f: TextIO
) -> None:
    hp_m_bits = MANTISSA_BITS[hp]
    hp_e_bits = EXPONENT_BITS[hp]
    hp_e_bias = EXPONENT_BIAS[hp]
    hp_min_exp = UNBIASED_EXP[hp][0]
    hp_minsn_exp = hp_min_exp - hp_m_bits

    # Determine the actual exponent, based on desired grs pattern
    grs_int = int(grs, 2)
    first_1 = grs.index("1")

    input_exp = g_exp - first_1 if grs_int != 1 else random.randint(hp_minsn_exp, g_exp - 2)

    # Generate the mantissa
    input_mant = 0
    bits_left = hp_m_bits - max(hp_min_exp - input_exp, 0)
    sn = bits_left < hp_m_bits
    # Handle the first bit

    # Like for BF_16 to Single, you're going from sn -> sn
    if sn:
        input_mant += 1 << bits_left
    bits_left -= 1
    if int(grs, 2) != 1:
        grs = grs.replace("1", "0", 1)
    if grs[1] == "0":
        bits_left -= 1
    elif grs[1] == "1":
        input_mant += 1 << bits_left

    if grs[2] == "1":
        input_mant += random.randint(1, (1 << bits_left) - 1)

    # Normalize exponent
    input_exp = max(input_exp, hp_min_exp - 1)
    # Make sure exponent has correct padding
    input_mant_bin = f"{input_mant:0{hp_m_bits}b}"

    input_fp = generate_FP(hp_e_bits, sign, input_exp, input_mant_bin, hp_e_bias)
    run_and_store_test_vector(
        f"{OP_CFF}_{rounding_mode}_{input_fp}_{32 * '0'}_{32 * '0'}_{hp}_{32 * '0'}_{lp}_00", test_f, cover_f
    )


def tests_conversion_1_2(lp: str, hp: str, rounding_mode: str, test_f: TextIO, cover_f: TextIO) -> None:
    hashval = reproducible_hash(OP_CFF + lp + "b5")
    seed(hashval)
    lp_min_exp = UNBIASED_EXP[lp][0]

    convert_grs(hp, lp, lp_min_exp + 1, "001", "0", rounding_mode, test_f, cover_f)
    convert_grs(hp, lp, lp_min_exp + 1, "001", "1", rounding_mode, test_f, cover_f)


def genPNTestVectors(
    lp: str,
    hp: str,
    rounding_mode: str,
    hp_e_bits: int,
    hp_exp: int,
    complete_binary_1: str,
    complete_binary_2: str,
    hp_e_bias: int,
    test_f: TextIO,
    cover_f: TextIO,
) -> None:

    hashval = reproducible_hash(OP_CFF + lp + "b5")
    seed(hashval)
    input_value_1 = generate_FP(hp_e_bits, "0", hp_exp, complete_binary_1, hp_e_bias)
    input_value_2 = generate_FP(hp_e_bits, "1", hp_exp, complete_binary_2, hp_e_bias)

    run_and_store_test_vector(
        f"{OP_CFF}_{rounding_mode}_{input_value_1}_{32 * '0'}_{32 * '0'}_{hp}_{32 * '0'}_{lp}_00", test_f, cover_f
    )  # Test 1
    run_and_store_test_vector(
        f"{OP_CFF}_{rounding_mode}_{input_value_2}_{32 * '0'}_{32 * '0'}_{hp}_{32 * '0'}_{lp}_00", test_f, cover_f
    )  # Test 2


def tests_conversion_3_4(lp: str, hp: str, rounding_mode: str, test_f: TextIO, cover_f: TextIO) -> None:

    hashval = reproducible_hash(OP_CFF + lp + "b5")
    seed(hashval)
    lp_sn_exp = UNBIASED_EXP[lp][0] - 1  # Account for subnorms
    lp_m_bits = MANTISSA_BITS[lp]

    lp_min_exp = lp_sn_exp - lp_m_bits

    grs = ["001", "010", "011", "100", "101", "110", "111"]
    for bits in grs:
        convert_grs(hp, lp, lp_min_exp + 1, bits, "0", rounding_mode, test_f, cover_f)
        convert_grs(hp, lp, lp_min_exp + 1, bits, "1", rounding_mode, test_f, cover_f)


def tests_conversion_5_6(lp: str, hp: str, rounding_mode: str, test_f: TextIO, cover_f: TextIO) -> None:

    hashval = reproducible_hash(OP_CFF + lp + "b5")
    seed(hashval)
    hp_m_bits = MANTISSA_BITS[hp]
    lp_sn_exp = UNBIASED_EXP[lp][0] - 1
    hp_e_bits = EXPONENT_BITS[hp]
    hp_e_bias = EXPONENT_BIAS[hp]
    lp_m_bits = MANTISSA_BITS[lp]

    if (
        hp != FMT_BF16 and lp != FMT_SINGLE
    ):  # The mantissa bits for bf_16 are smaller than that for single, so you can't do these operations
        rem_bits = hp_m_bits - lp_m_bits

        max_rem = (1 << rem_bits) - 1

        # MinNorm - 3 i_ulp:
        hp_m = "1" * (lp_m_bits - 1) + "0" + f"{random.randint(1, max_rem):0{rem_bits}b}"
        hp_exp = lp_sn_exp

        genPNTestVectors(lp, hp, rounding_mode, hp_e_bits, hp_exp, hp_m, hp_m, hp_e_bias, test_f, cover_f)

        # MinNorm - 2 i_ulp:
        hp_m = "1" * (lp_m_bits - 1) + "1" + "0" * rem_bits
        hp_exp = lp_sn_exp

        genPNTestVectors(lp, hp, rounding_mode, hp_e_bits, hp_exp, hp_m, hp_m, hp_e_bias, test_f, cover_f)

        # MinNorm - 1 i_ulp:
        hp_m_1 = "1" * (lp_m_bits - 1) + "1" + f"{random.randint(1, max_rem):0{rem_bits}b}"
        hp_m_2 = "1" * (lp_m_bits - 1) + "1" + f"{random.randint(1, max_rem):0{rem_bits}b}"
        hp_exp = lp_sn_exp

        genPNTestVectors(lp, hp, rounding_mode, hp_e_bits, hp_exp, hp_m_1, hp_m_2, hp_e_bias, test_f, cover_f)

        # # MinNorm:
        # hp_m_1 = "0" * (hp_m_bits)
        # hp_m_2 = "0" * (hp_m_bits)
        # hp_exp = lp_n_exp

        # genPNTestVectors(lp, hp, rounding_mode, hp_e_bits, hp_exp, hp_m_1, hp_m_2, hp_e_bias, test_f, cover_f)

        # # MinNorm + 1 i_ulp:
        # hp_m = "0" * (lp_m_bits - 1) + "0" + f"{random.randint(1, max_rem):0{rem_bits}b}"
        # hp_exp = lp_n_exp

        # genPNTestVectors(lp, hp, rounding_mode, hp_e_bits, hp_exp, hp_m, hp_m, hp_e_bias, test_f, cover_f)

        # # MinNorm + 2 i_ulp:
        # hp_m = "0" * lp_m_bits + "1" + "0" * (rem_bits - 1)
        # hp_exp = lp_n_exp

        # genPNTestVectors(lp, hp, rounding_mode, hp_e_bits, hp_exp, hp_m, hp_m, hp_e_bias, test_f, cover_f)

        # # MinNorm + 3 i_ulp:
        # hp_m = ("0" * lp_m_bits) + "1" + f"{random.randint(1, (1 << (rem_bits - 1)) - 1):0{(rem_bits - 1)}b}"
        # hp_exp = lp_n_exp

        # genPNTestVectors(lp, hp, rounding_mode, hp_e_bits, hp_exp, hp_m, hp_m, hp_e_bias, test_f, cover_f)


def tests_conversion_7_8(lp: str, hp: str, rounding_mode: str, test_f: TextIO, cover_f: TextIO) -> None:
    hashval = reproducible_hash(OP_CFF + lp + "b5")
    seed(hashval)

    lp_sn_exp = UNBIASED_EXP[lp][0] - 1

    convert_grs(hp, lp, lp_sn_exp + 2, "001", "0", rounding_mode, test_f, cover_f)
    convert_grs(hp, lp, lp_sn_exp + 2, "001", "0", rounding_mode, test_f, cover_f)


def tests_conversion_9(lp: str, hp: str, rounding_mode: str, test_f: TextIO, cover_f: TextIO) -> None:
    hashval = reproducible_hash(OP_CFF + lp + "b5")
    seed(hashval)
    hp_m_bits = MANTISSA_BITS[hp]
    hp_e_bits = EXPONENT_BITS[hp]
    hp_e_bias = EXPONENT_BIAS[hp]
    lp_sn_exp = UNBIASED_EXP[lp][0] - 1  # Account for subnorms
    max_m_value = int("1" * hp_m_bits, 2)

    hp_exp = lp_sn_exp

    for i in range(0, 6):
        complete_binary = f"{random.randint(0, max_m_value):0{hp_m_bits}b}"

        input_value_1 = generate_FP(hp_e_bits, f"{random.randint(0, 1)}", hp_exp, complete_binary, hp_e_bias)
        run_and_store_test_vector(
            f"{OP_CFF}_{rounding_mode}_{input_value_1}_{32 * '0'}_{32 * '0'}_{hp}_{32 * '0'}_{lp}_00", test_f, cover_f
        )  # Test 1
        hp_exp = lp_sn_exp + i + 1


def convertTests(test_f: TextIO, cover_f: TextIO) -> None:
    # All conversion tests:
    for i_hp in range(len(B5_FMTS)):
        hp = B5_FMTS[i_hp]
        for i_lp in range(i_hp + 1, len(B5_FMTS)):
            lp = B5_FMTS[i_lp]
            # hp = B5_FMTS[0]
            # lp = B5_FMTS[4]
            for rounding_mode in ROUNDING_MODES:
                tests_conversion_1_2(lp, hp, rounding_mode, test_f, cover_f)
                tests_conversion_3_4(lp, hp, rounding_mode, test_f, cover_f)
                tests_conversion_5_6(lp, hp, rounding_mode, test_f, cover_f)
                tests_conversion_7_8(lp, hp, rounding_mode, test_f, cover_f)
                tests_conversion_9(lp, hp, rounding_mode, test_f, cover_f)


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
        a_min = 1 << m_bits
        a_max = 1 << m_bits
        if grs_int == 7:
            a_min = 7 << (m_bits - 2)
            a_max = (1 << (m_bits + 1)) - 1
            a_int = random.randint(a_min, a_max)
            b_int = 1 << m_bits
        else:
            a_min = 5 << (m_bits - 2)
            a_max = (1 << m_bits) + ((1 << (m_bits - 1)) - 1)
            a_int = random.randint(a_min, a_max)
            b_int = random.randint((1 << m_bits), int((a_min / a_int) * a_min))

        a_mantissa = a_int - (1 << a_bits_left)  # Remove hidden 1
        b_mantissa = b_int - (1 << b_bits_left)

    if grs_int == 3 and operation == OP_DIV:
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


def factor_mul_gen(precision: str, rounding_mode: str, grs_pattern: str, sign: str) -> Iterator[tuple[str, str]]:
    m_bits = MANTISSA_BITS[precision]
    e_min = UNBIASED_EXP[precision][0] - 1
    e_bits = EXPONENT_BITS[precision]
    e_bias = EXPONENT_BIAS[precision]

    target_list = {
        # Above MinNorm
        "001": {
            FMT_BF16: (8 + 1) * (8**2 - 8 + 1),
            FMT_HALF: ((2**4) + 1) * ((2**4) ** 2 - (2**4) + 1),
            FMT_SINGLE: ((2**5) + 1) * ((2**5) ** 4 - (2**5) ** 3 + (2**5) ** 2 - (2**5) + 1),
            FMT_DOUBLE: ((2**11) + 1) * ((2**11) ** 4 - (2**11) ** 3 + (2**11) ** 2 - (2**11) + 1),
            FMT_QUAD: ((2**38) + 1) * ((2**76) - (2**38) + 1),
        },
        "010": {
            FMT_BF16: 2056,
            FMT_HALF: (2**11) + 1,
            FMT_SINGLE: ((2**8) + 1) * ((2**8) ** 2 - (2**8) + 1),
            FMT_DOUBLE: (2**53) + 1,
            FMT_QUAD: (2**113) + 1,
        },
        "011": {
            FMT_BF16: 2**9 + 2 + 1,
            FMT_HALF: 2**13 + 4 + 3,
            FMT_SINGLE: (2**26) + 7,
            FMT_DOUBLE: 2**55 + 7,
            FMT_QUAD: 2**120 + 125,
        },
        # Below MinNorm
        "111": {
            FMT_BF16: (2**14) - 1,
            FMT_HALF: (2**20) - 1,
            FMT_SINGLE: (2**46) - 1,
            FMT_DOUBLE: (2**104) - 1,
            FMT_QUAD: (2**224) - 1,
        },  # - 1 ulp
        "110": {
            FMT_BF16: (2 ** (m_bits + 1)) - 1,
            FMT_HALF: (2 ** (m_bits + 1)) - 1,
            FMT_SINGLE: (2 ** (m_bits + 1)) - 1,
            FMT_DOUBLE: (2 ** (m_bits + 1)) - 1,
            FMT_QUAD: (2 ** (m_bits + 1)) - 1,
        },  # - 2ulp
        "101": {
            FMT_BF16: 19 * 107,
            FMT_HALF: 233 * 281,
            FMT_SINGLE: 479 * 70051,
            FMT_DOUBLE: 497401731493 * 36217,
            FMT_QUAD: 613 * 33881219305284356466756909162937,
        },  # - 3 ulp
    }

    factor_list = {
        # Above MinNorm
        "001": {
            FMT_BF16: (8 + 1),
            FMT_HALF: ((2**4) + 1),
            FMT_SINGLE: ((2**5) + 1),
            FMT_DOUBLE: ((2**11) + 1),
            FMT_QUAD: ((2**38) + 1),
        },
        "010": {FMT_BF16: 257, FMT_HALF: 683, FMT_SINGLE: ((2**8) + 1), FMT_DOUBLE: 321, FMT_QUAD: 491003369344660409},
        "011": {FMT_BF16: 103, FMT_HALF: 9, FMT_SINGLE: 23 * 29, FMT_DOUBLE: 9 * 25, FMT_QUAD: 1099511627781},
        # Below MinNorm
        "111": {
            FMT_BF16: (2**7) - 1,
            FMT_HALF: (2**10) - 1,
            FMT_SINGLE: (2**23) - 1,
            FMT_DOUBLE: (2**52) - 1,
            FMT_QUAD: (2**112) - 1,
        },
        "110": {
            FMT_BF16: (4**2) - 1,
            FMT_HALF: 23,
            FMT_SINGLE: (2**12) - 1,
            FMT_DOUBLE: 6361,
            FMT_QUAD: 1066818132868207,
        },
        "101": {
            FMT_BF16: 19,
            FMT_HALF: 233,
            FMT_SINGLE: 479,
            FMT_DOUBLE: 36217,
            FMT_QUAD: 33881219305284356466756909162937,
        },
    }
    # Randomize the sign bit
    if sign == "0":
        a_sign = random.randint(0, 1)
        b_sign = a_sign
    else:
        a_sign = random.randint(0, 1)
        b_sign = (a_sign + 1) % 2

    target_int = target_list[grs_pattern][precision]
    factor_1 = factor_list[grs_pattern][precision]
    factor_2 = target_int // factor_1  # Integers have unlimited precision, must use integer division

    if target_int == 1 and factor_1 == 1:
        yield ("0", "0")

    a_int = int(max(factor_1, factor_2))  # Ensure a is the largest value
    b_int = int(min(factor_1, factor_2))

    a_bin = format(a_int, "b")
    b_bin = format(b_int, "b")

    a_bits = len(a_bin)
    b_bits = len(b_bin)

    exp_offset = a_bits - b_bits

    # Subtract Hidden 1
    a_int -= 1 << (a_bits - 1)
    b_int -= 1 << (b_bits - 1)

    a_trailing_zeros = m_bits - a_bits + 1
    b_trailing_zeros = m_bits - b_bits + 1

    a_int *= 2 ** max(a_trailing_zeros, 0)
    b_int *= 2 ** max(b_trailing_zeros, 0)

    a_bin = f"{a_int:0{m_bits}b}"
    b_bin = f"{b_int:0{m_bits}b}"

    a_exp = int((e_min + exp_offset) / 2)
    b_exp = int(a_exp - exp_offset) - 1
    if e_min - (a_exp + b_exp) == -1:
        b_exp -= 1
    elif e_min - (a_exp + b_exp) == 1:
        b_exp += 1

    a_fp = generate_FP(e_bits, str(a_sign), a_exp, a_bin, e_bias)
    b_fp = generate_FP(e_bits, str(b_sign), b_exp, b_bin, e_bias)

    yield (a_fp, b_fp)


def mul_div_grs_gen(
    operation: str,
    precision: str,
    rounding_mode: str,
    grs: str,
    g_exp: int,
    sign: str,
    hashEnding: str,
) -> Iterator[tuple[str, str]]:
    hashString = "b5" + OP_MUL + precision + rounding_mode + hashEnding
    seed(hashString)

    # g_exp is needed for going below normal, getting specific subnorm results
    e_bits = EXPONENT_BITS[precision]
    m_bits = MANTISSA_BITS[precision]
    e_bias = EXPONENT_BIAS[precision]
    min_exp = UNBIASED_EXP[precision][0]
    sn_exp = min_exp - 1

    first_bit = g_exp - grs.index("1")

    if sign == "0":
        a_sign = random.randint(0, 1)
        b_sign = a_sign
    else:
        a_sign = random.randint(0, 1)
        b_sign = (a_sign + 1) % 2

    grs_int = int(grs, 2)

    target_exp = first_bit
    if grs_int == 1:
        smallest_res_exp = min_exp - (2 * m_bits)
        target_exp = random.randint(smallest_res_exp, target_exp)

    if operation == OP_MUL:
        a_exp, b_exp = genSpecExp_mul(precision, target_exp, hashString + grs + sign)
    else:  # operation == OP_DIV
        a_exp, b_exp = genSpecExp_div(precision, target_exp, hashString, grs_int)

    a_mant, b_mant = get_grs_mant(operation, precision, a_exp, b_exp, hashString + grs + sign, grs)

    # Normalize exponents
    a_exp = max(a_exp, sn_exp)
    b_exp = max(b_exp, sn_exp)

    a = generate_FP(e_bits, str(a_sign), a_exp, a_mant, e_bias)
    b = generate_FP(e_bits, str(b_sign), b_exp, b_mant, e_bias)
    yield (a, b)


def tests_multiply_1_2(precision: str, rounding_mode: str) -> Iterator[tuple[str, str]]:
    hashString = "b5" + OP_MUL + precision + rounding_mode
    seed(hashString)

    min_exp = UNBIASED_EXP[precision][0]
    sn_exp = min_exp - 1

    yield from mul_div_grs_gen(OP_MUL, precision, rounding_mode, "001", sn_exp, "0", "1/2")
    yield from mul_div_grs_gen(OP_MUL, precision, rounding_mode, "001", sn_exp, "1", "1/2")


def tests_multiply_3_4(precision: str, rounding_mode: str) -> Iterator[tuple[str, str]]:
    hashString = "b5" + OP_MUL + precision + rounding_mode
    seed(hashString)

    m_bits = MANTISSA_BITS[precision]
    min_exp = UNBIASED_EXP[precision][0]

    minSNPos = min_exp - m_bits  # Treating the minSN as normalized

    for grs_int in range(1, 8):
        # grs_int = 2
        yield from mul_div_grs_gen(
            OP_MUL, precision, rounding_mode, f"{grs_int:03b}", minSNPos, "0", f"{grs_int:03b}"
        )  # Positive Test
        yield from mul_div_grs_gen(
            OP_MUL, precision, rounding_mode, f"{grs_int:03b}", minSNPos, "1", f"{grs_int:03b}"
        )  # Negative Test


def tests_multiply_5_6(precision: str, rounding_mode: str) -> Iterator[tuple[str, str]]:
    min_exp = UNBIASED_EXP[precision][0]

    # MinNorm - 3 ulp
    yield from factor_mul_gen(precision, rounding_mode, "101", "0")  # Positive Test
    yield from factor_mul_gen(precision, rounding_mode, "101", "1")  # Negative Test

    # MinNorm - 2 ulp
    yield from factor_mul_gen(precision, rounding_mode, "110", "0")  # Positive Test
    yield from factor_mul_gen(precision, rounding_mode, "110", "1")  # Negative Test

    # MinNorm - 1 ulp
    yield from factor_mul_gen(precision, rounding_mode, "111", "0")  # Positive Test
    yield from factor_mul_gen(precision, rounding_mode, "111", "1")  # Negative Test

    # MinNorm
    yield from mul_div_grs_gen(OP_MUL, precision, rounding_mode, "100", min_exp, "0", "minExp")  # Positive Test
    yield from mul_div_grs_gen(OP_MUL, precision, rounding_mode, "100", min_exp, "1", "minExp")  # Negative Test

    # MinNorm + 1 ulp
    yield from factor_mul_gen(precision, rounding_mode, "001", "0")  # Positive Test
    yield from factor_mul_gen(precision, rounding_mode, "001", "1")  # Negative Test

    # MinNorm + 2 ulp
    yield from factor_mul_gen(precision, rounding_mode, "010", "0")  # Positive Test
    yield from factor_mul_gen(precision, rounding_mode, "010", "1")  # Negative Test #BF_16 is producing an error

    # MinNorm + 3 ulp
    yield from factor_mul_gen(precision, rounding_mode, "011", "0")  # Positive Test
    yield from factor_mul_gen(precision, rounding_mode, "011", "1")  # Negative Test #FP_128 is producing an error


def tests_multiply_7_8(precision: str, rounding_mode: str) -> Iterator[tuple[str, str]]:
    m_bits = MANTISSA_BITS[precision]
    min_exp = UNBIASED_EXP[precision][0]

    target_exp = min_exp - m_bits

    yield from mul_div_grs_gen(OP_MUL, precision, rounding_mode, "011", target_exp, "0", "1/2 pos")
    yield from mul_div_grs_gen(OP_MUL, precision, rounding_mode, "011", target_exp, "1", "1/2 neg")


def tests_multiply_9(precision: str, rounding_mode: str) -> Iterator[tuple[str, str]]:
    min_exp = UNBIASED_EXP[precision][0]

    # all values from minNorm.exp to minNorm.exp + 5
    min_exp_range = min_exp + 1  # minNorm.exp + 1, we want it randomized, so add 1 and lsb = 0, r = 1, s = 1
    max_exp_range = min_exp_range + 5

    for target_exp in range(min_exp_range, max_exp_range + 1):  # Because end is exclusive
        seed("b5" + OP_MUL + precision + rounding_mode + str(target_exp))
        sign = str(random.randint(0, 1))

        yield from mul_div_grs_gen(OP_MUL, precision, rounding_mode, "011", target_exp, sign, str(target_exp))


# def multiplyTests(test_f: TextIO, cover_f: TextIO, genTests: bool) -> None:
#     if genTests:
#         for precision in FLOAT_FMTS:
#             for rounding_mode in ROUNDING_MODES:
#                 tests_multiply_1_2(precision, rounding_mode, test_f, cover_f)
#                 tests_multiply_3_4(precision, rounding_mode, test_f, cover_f)
#                 tests_multiply_5_6(precision, rounding_mode, test_f, cover_f)
#                 tests_multiply_7_8(precision, rounding_mode, test_f, cover_f)
#                 tests_multiply_9(precision, rounding_mode, test_f, cover_f)


def getMultiplyTests(precision: str, rounding_mode: str) -> Iterator[tuple[str, str]]:
    yield from tests_multiply_1_2(precision, rounding_mode)
    yield from tests_multiply_3_4(precision, rounding_mode)
    yield from tests_multiply_5_6(precision, rounding_mode)
    yield from tests_multiply_7_8(precision, rounding_mode)
    yield from tests_multiply_9(precision, rounding_mode)


def multiplyTests(test_f: TextIO, cover_f: TextIO) -> None:
    for precision in FLOAT_FMTS:
        for rounding_mode in ROUNDING_MODES:
            for a, b in getMultiplyTests(precision, rounding_mode):
                run_and_store_test_vector(
                    f"{OP_MUL}_{rounding_mode}_{a}_{b}_{32 * '0'}_{precision}_{32 * '0'}_{precision}_00",
                    test_f,
                    cover_f,
                )


def fma_gen(
    operation: str,
    precision: str,
    rounding_mode: str,
    product_sign: int,
    product_grs: str,
    product_exponent: int,
    addend_sign: int,
    addend_pattern: str,
    test_f: TextIO,
    cover_f: TextIO,
    hashEnding: str,
) -> None:
    m_bits = MANTISSA_BITS[precision]
    e_bits = EXPONENT_BITS[precision]
    e_bias = EXPONENT_BIAS[precision]
    min_exp = UNBIASED_EXP[precision][0]

    fma_op_key = {
        OP_FMADD: {"mul_sign": 0, "add_sign": 0},
        OP_FMSUB: {"mul_sign": 0, "add_sign": 1},
        OP_FNMADD: {"mul_sign": 1, "add_sign": 1},
        OP_FNMSUB: {"mul_sign": 1, "add_sign": 0},
    }

    # Determine the desired output signs for multiplication and addition
    op_mul_sign = fma_op_key[operation]["mul_sign"]
    op_add_sign = fma_op_key[operation]["add_sign"]

    mul_sign = (op_mul_sign + product_sign) % 2
    c_sign = (op_add_sign + addend_sign) % 2

    # Generate the multiplication testvectors
    for a, b in mul_div_grs_gen(
        OP_MUL, precision, rounding_mode, product_grs, product_exponent, str(mul_sign), hashEnding
    ):
        # Generate the addition testvector
        c_exp = -1
        c_mant = -1
        if addend_pattern == "1*m-1_0":
            c_exp = min_exp - 1
            c_mant = (1 << m_bits) - 2  # all ones throughout the mantissa
        elif addend_pattern == "min_n":
            c_exp = min_exp
            c_mant = 0
        elif addend_pattern == "2*min_sn":
            c_exp = min_exp - 1
            c_mant = 2
        elif addend_pattern == "min_sn":
            c_exp = min_exp - 1
            c_mant = 1
        elif addend_pattern == "1_0*m-1_1":
            c_exp = min_exp
            c_mant = 1
        elif addend_pattern == "rand_sn":
            c_exp = min_exp - random.randint(1, m_bits)  # Upper: Just SN, Lower: Leave 1 spot open on the end
            max_mant = (1 << (min_exp - c_exp)) - 1
            c_mant = random.randint(1, max_mant)
            c_mant = max_mant
            # Normalize c_exp
            c_exp = max(min_exp - 1, c_exp)
        elif addend_pattern == "rand_n":
            c_exp = min_exp
            max_mant = 1 << m_bits
            c_mant = random.randint(1, max_mant)
        elif addend_pattern[0 : addend_pattern.index("_")] == "randexp":
            exp_string = addend_pattern[addend_pattern.index("_") + 1 : len(addend_pattern)]
            c_exp = 0 - int(exp_string)
            max_mant = (1 << m_bits) - 1
            c_mant = random.randint(1, max_mant)

        c_bin_mant = f"{c_mant:0{m_bits}b}"
        c = generate_FP(e_bits, str(c_sign), c_exp, c_bin_mant, e_bias)
        run_and_store_test_vector(
            f"{operation}_{rounding_mode}_{a}_{b}_{c}_{precision}_{32 * '0'}_{precision}_00", test_f, cover_f
        )


def tests_fma_1_2(operation: str, precision: str, rounding_mode: str, test_f: TextIO, cover_f: TextIO) -> None:
    m_bits = MANTISSA_BITS[precision]
    min_exp = UNBIASED_EXP[precision][0]

    minSNPos = min_exp - m_bits

    fma_gen(
        operation, precision, rounding_mode, 0, "001", minSNPos, 1, "rand_sn", test_f, cover_f, "pos_1"
    )  # adds decreased magnitude, can't be normal
    fma_gen(
        operation, precision, rounding_mode, 1, "001", minSNPos, 0, "rand_sn", test_f, cover_f, "neg_2"
    )  # add decreases magnitude, can't be normal


def tests_fma_3_4(operation: str, precision: str, rounding_mode: str, test_f: TextIO, cover_f: TextIO) -> None:
    m_bits = MANTISSA_BITS[precision]
    min_exp = UNBIASED_EXP[precision][0]

    minSNPos = min_exp - m_bits

    # MinSN - 3 ulp; G = 1, R = 0, S = 1
    fma_gen(
        operation, precision, rounding_mode, 0, "101", minSNPos, 1, "min_sn", test_f, cover_f, "pos_-3_ulp_3"
    )  # Get rid of G Bit and some more from sticky, result is negative
    fma_gen(operation, precision, rounding_mode, 1, "101", minSNPos, 0, "min_sn", test_f, cover_f, "neg_-3_ulp_4")

    # MinSN - 2 ulp; G = 1, R = 1, S = 0
    fma_gen(
        operation, precision, rounding_mode, 1, "010", minSNPos, 0, "min_sn", test_f, cover_f, "pos_-2_ulp_3"
    )  # Subtract minSN from 1 bit 2*minSN
    fma_gen(operation, precision, rounding_mode, 0, "010", minSNPos, 1, "min_sn", test_f, cover_f, "neg_-2_ulp_4")

    # MinSN - 1 ulp; G = 0, R = 1, S = 1
    fma_gen(operation, precision, rounding_mode, 0, "111", minSNPos, 1, "min_sn", test_f, cover_f, "pos_-1_ulp_3")
    fma_gen(operation, precision, rounding_mode, 1, "111", minSNPos, 0, "min_sn", test_f, cover_f, "neg_-1_ulp_4")

    # #MinSN; G = 1, R = 0, S = 0
    fma_gen(operation, precision, rounding_mode, 0, "100", minSNPos, 1, "2*min_sn", test_f, cover_f, "pos_minSN_3")
    fma_gen(operation, precision, rounding_mode, 1, "100", minSNPos, 0, "2*min_sn", test_f, cover_f, "neg_minSN_4")

    # MinSN + 1 ulp; G = 1, R = 0, S = 1
    fma_gen(operation, precision, rounding_mode, 0, "001", minSNPos, 0, "min_sn", test_f, cover_f, "pos_+1_ulp_3")
    fma_gen(operation, precision, rounding_mode, 1, "001", minSNPos, 1, "min_sn", test_f, cover_f, "neg_+1_ulp_4")

    # MinSN + 2 ulp; G = 1, R = 1, S = 0
    fma_gen(operation, precision, rounding_mode, 0, "010", minSNPos, 0, "min_sn", test_f, cover_f, "pos_+2_ulp_3")
    fma_gen(operation, precision, rounding_mode, 1, "010", minSNPos, 1, "min_sn", test_f, cover_f, "neg_+2_ulp_4")

    # MinSN + 3 ulp; G = 1, R = 1, S = 1
    fma_gen(operation, precision, rounding_mode, 0, "011", minSNPos, 0, "min_sn", test_f, cover_f, "pos_+3_ulp_3")
    fma_gen(operation, precision, rounding_mode, 1, "011", minSNPos, 1, "min_sn", test_f, cover_f, "neg_+3_ulp_4")


def tests_fma_5_6(operation: str, precision: str, rounding_mode: str, test_f: TextIO, cover_f: TextIO) -> None:
    m_bits = MANTISSA_BITS[precision]
    min_exp = UNBIASED_EXP[precision][0]

    minSNPos = min_exp - m_bits

    # MinN - 3 ulp; G = 1, R = 0, S = 1
    fma_gen(
        operation, precision, rounding_mode, 0, "101", minSNPos, 0, "1*m-1_0", test_f, cover_f, "pos_-3_ulp_5"
    )  # Get rid of G Bit and some more from sticky, result is negative
    fma_gen(operation, precision, rounding_mode, 1, "101", minSNPos, 1, "1*m-1_0", test_f, cover_f, "neg_-3_ulp_6")

    # MinN - 2 ulp; G = 1, R = 1, S = 0
    fma_gen(
        operation, precision, rounding_mode, 0, "110", minSNPos, 0, "1*m-1_0", test_f, cover_f, "pos_-2_ulp_5"
    )  # Get rid of G Bit and some more from sticky, result is negative
    fma_gen(operation, precision, rounding_mode, 1, "110", minSNPos, 1, "1*m-1_0", test_f, cover_f, "neg_-2_ulp_6")

    # MinN - 1 ulp; G = 1, R = 1, S = 1
    fma_gen(
        operation, precision, rounding_mode, 0, "111", minSNPos, 0, "1*m-1_0", test_f, cover_f, "pos_-2_ulp_5"
    )  # Get rid of G Bit and some more from sticky, result is negative
    fma_gen(operation, precision, rounding_mode, 1, "111", minSNPos, 1, "1*m-1_0", test_f, cover_f, "neg_-2_ulp_6")

    # MinN
    fma_gen(operation, precision, rounding_mode, 1, "100", minSNPos, 0, "1_0*m-1_1", test_f, cover_f, "pos_norm_5")
    fma_gen(operation, precision, rounding_mode, 0, "100", minSNPos, 1, "1_0*m-1_1", test_f, cover_f, "neg_norm_6")

    # MinN + 1 ulp
    fma_gen(operation, precision, rounding_mode, 0, "001", minSNPos, 0, "min_n", test_f, cover_f, "pos_+1_ulp_5")
    fma_gen(operation, precision, rounding_mode, 1, "001", minSNPos, 1, "min_n", test_f, cover_f, "neg_+1_ulp_6")

    # MinN + 2 ulp
    fma_gen(operation, precision, rounding_mode, 0, "010", minSNPos, 0, "min_n", test_f, cover_f, "pos_+2_ulp_5")
    fma_gen(operation, precision, rounding_mode, 1, "010", minSNPos, 1, "min_n", test_f, cover_f, "neg_+2_ulp_6")

    # MinN + 3 ulp
    fma_gen(operation, precision, rounding_mode, 0, "011", minSNPos, 0, "min_n", test_f, cover_f, "pos_+3_ulp_5")
    fma_gen(operation, precision, rounding_mode, 1, "011", minSNPos, 1, "min_n", test_f, cover_f, "neg_+3_ulp_6")


def tests_fma_7_8(operation: str, precision: str, rounding_mode: str, test_f: TextIO, cover_f: TextIO) -> None:
    m_bits = MANTISSA_BITS[precision]
    min_exp = UNBIASED_EXP[precision][0]

    minSNPos = min_exp - m_bits

    fma_gen(
        operation, precision, rounding_mode, 0, "011", minSNPos + 1, 1, "min_sn", test_f, cover_f, "pos_-3_ulp_3"
    )  # Get rid of G Bit and some more from sticky, result is negative
    fma_gen(operation, precision, rounding_mode, 1, "011", minSNPos + 1, 0, "min_sn", test_f, cover_f, "neg_-3_ulp_4")


def tests_fma_9(operation: str, precision: str, rounding_mode: str, test_f: TextIO, cover_f: TextIO) -> None:
    m_bits = MANTISSA_BITS[precision]
    min_exp = UNBIASED_EXP[precision][0]

    minSNPos = min_exp - m_bits
    for exp in range(min_exp - 1, min_exp + 6):
        fma_gen(
            operation,
            precision,
            rounding_mode,
            0,
            "001",
            minSNPos + 2,
            1,
            f"randexp_{abs(exp)}",
            test_f,
            cover_f,
            f"pos_-3_ulp_{exp}",
        )
        fma_gen(
            operation,
            precision,
            rounding_mode,
            1,
            "001",
            minSNPos + 2,
            0,
            f"randexp_{abs(exp)}",
            test_f,
            cover_f,
            f"pos_-3_ulp_{exp}",
        )


def fmaTests(test_f: TextIO, cover_f: TextIO) -> None:
    for operation in FMA_OPS:
        for precision in FLOAT_FMTS:
            for rounding_mode in ROUNDING_MODES:
                tests_fma_1_2(operation, precision, rounding_mode, test_f, cover_f)
                tests_fma_3_4(operation, precision, rounding_mode, test_f, cover_f)
                tests_fma_5_6(operation, precision, rounding_mode, test_f, cover_f)
                tests_fma_7_8(operation, precision, rounding_mode, test_f, cover_f)
                tests_fma_9(operation, precision, rounding_mode, test_f, cover_f)


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


def tests_div_1_2(precision: str, rounding_mode: str) -> Iterator[tuple[str, str]]:
    min_exp = UNBIASED_EXP[precision][0]

    # Random SN: G = 0, R = 0, S = 1
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "001", min_exp + 1, "0", "positive")
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "001", min_exp + 1, "1", "positive")


def tests_div_3_4(precision: str, rounding_mode: str) -> Iterator[tuple[str, str]]:
    m_bits = MANTISSA_BITS[precision]
    min_exp = UNBIASED_EXP[precision][0]

    minSNPos = min_exp - m_bits  # Treating the minSN as normalized

    # minSN - 3 ulp G = 0, R = 0, S = 1
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "001", minSNPos, "0", "minSN-3ulppos")
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "001", minSNPos, "1", "minSN-3ulppos")

    # minSN - 2 ulp G = 0, R = 1, S = 0
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "010", minSNPos, "0", "minSN-2ulppos")
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "010", minSNPos, "1", "minSN-2ulppos")

    # minSN - 1 ulp G = 0, R = 1, S = 1
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "011", minSNPos, "0", "minSN-1ulppos")
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "011", minSNPos, "1", "minSN-1ulppos")

    # minSN G = 1, R = 0, S = 0
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "100", minSNPos, "0", "minSNppos")
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "100", minSNPos, "1", "minSNpos")

    # minSN + 1 ulp G = 1, R = 0, S = 1 grs_int = 5
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "101", minSNPos, "0", "minSN")
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "101", minSNPos, "1", "minSN")

    # minSN + 2 ulp G = 1, R = 1, S = 0
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "110", minSNPos, "0", "minSN+2ulppos")
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "110", minSNPos, "1", "minSN+2ulppos")

    # minSN + 3 ulp G = 1, R = 1, S = 1
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "111", minSNPos, "0", "minSN+3ulppos")
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "111", minSNPos, "1", "minSN+3ulppos")


def tests_div_7_8(precision: str, rounding_mode: str) -> Iterator[tuple[str, str]]:
    m_bits = MANTISSA_BITS[precision]
    min_exp = UNBIASED_EXP[precision][0]

    minSNPos = min_exp - m_bits  # Treating the minSN as normalized

    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "001", minSNPos, "0", "minSN")
    yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "001", minSNPos, "1", "minSN")


def tests_div_9(precision: str, rounding_mode: str) -> Iterator[tuple[str, str]]:
    min_exp = UNBIASED_EXP[precision][0]

    for target_exp in range(min_exp, min_exp + 6):  # Because end is exclusive
        seed("b5" + OP_DIV + precision + rounding_mode + str(target_exp))
        sign = str(random.randint(0, 1))

        yield from mul_div_grs_gen(OP_DIV, precision, rounding_mode, "011", target_exp + 1, sign, "min")


def getDivTests(precision: str, rounding_mode: str) -> Iterator[tuple[str, str]]:
    yield from tests_div_1_2(precision, rounding_mode)
    yield from tests_div_3_4(precision, rounding_mode)
    yield from tests_div_7_8(precision, rounding_mode)
    # yield from tests_div_9(precision, rounding_mode)


def divTests(test_f: TextIO, cover_f: TextIO) -> None:
    for precision in FLOAT_FMTS:
        for rounding_mode in ROUNDING_MODES:
            for a, b in getDivTests(precision, rounding_mode):
                run_and_store_test_vector(
                    f"{OP_DIV}_{rounding_mode}_{a}_{b}_{32 * '0'}_{precision}_{32 * '0'}_{precision}_00",
                    test_f,
                    cover_f,
                )


def tests_add_sub_1_2(precision: str, rounding_mode: str, test_f: TextIO, cover_f: TextIO) -> None:
    m_bits = MANTISSA_BITS[precision]
    e_bits = EXPONENT_BITS[precision]
    e_bias = EXPONENT_BIAS[precision]
    sn_exp = UNBIASED_EXP[precision][0] - 1

    maxMant = (1 << m_bits) - 1
    # List for each subNormal:
    # operation, sign
    # add posSN, add negSN, sub posSN, sub negSN
    testList = [["add", 0], ["add", 1], ["sub", 0], ["sub", 1]]
    for test in testList:
        sign = str(test[1])
        if test[0] == "add":
            op = OP_ADD
            seed("b5" + op + precision + rounding_mode + "a" + str(test[1]))
            a = random.randint(1, maxMant // 2)
            seed("b5" + op + precision + rounding_mode + "b" + str(test[1]))
            b = random.randint(1, maxMant // 2)
        else:
            op = OP_SUB
            seed("b5" + op + precision + rounding_mode + "b" + str(test[1]))
            b = random.randint(1, maxMant // 2)
            seed("b5" + op + precision + rounding_mode + "a" + str(test[1]))
            a = random.randint(b, maxMant)
        a = f"{a:0{m_bits}b}"
        b = f"{b:0{m_bits}b}"
        a_fp = generate_FP(e_bits, sign, sn_exp, a, e_bias)
        b_fp = generate_FP(e_bits, sign, sn_exp, b, e_bias)
        run_and_store_test_vector(
            f"{op}_{rounding_mode}_{a_fp}_{b_fp}_{32 * '0'}_{precision}_{32 * '0'}_{precision}_00", test_f, cover_f
        )


def tests_add_sub_3_4(precision: str, rounding_mode: str, test_f: TextIO, cover_f: TextIO) -> None:
    m_bits = MANTISSA_BITS[precision]
    e_bits = EXPONENT_BITS[precision]
    e_bias = EXPONENT_BIAS[precision]
    sn_exp = UNBIASED_EXP[precision][0] - 1

    maxMant = (1 << m_bits) - 1

    # The IBM paper only has +minSN for 3 and -minSN for 4
    testList = [["add", 0], ["add", 1], ["sub", 0], ["sub", 1]]
    for test in testList:
        seed("b5" + str(test[0]) + precision + rounding_mode + "a" + str(test[1]))
        a = random.randint(2, maxMant)
        seed("b5" + str(test[0]) + precision + rounding_mode + "b" + str(test[1]))
        b = a - 1
        if test[0] == "add":
            op = OP_ADD
            a_sign = test[1]
            b_sign = (int(test[1]) + 1) % 2
        else:
            op = OP_SUB
            a_sign = test[1]
            b_sign = a_sign

        a = f"{a:0{m_bits}b}"
        b = f"{b:0{m_bits}b}"

        a_fp = generate_FP(e_bits, str(a_sign), sn_exp, a, e_bias)
        b_fp = generate_FP(e_bits, str(b_sign), sn_exp, b, e_bias)

        run_and_store_test_vector(
            f"{op}_{rounding_mode}_{a_fp}_{b_fp}_{32 * '0'}_{precision}_{32 * '0'}_{precision}_00", test_f, cover_f
        )


def tests_add_sub_5_6(precision: str, rounding_mode: str, test_f: TextIO, cover_f: TextIO) -> None:
    m_bits = MANTISSA_BITS[precision]
    e_bits = EXPONENT_BITS[precision]
    e_bias = EXPONENT_BIAS[precision]
    sn_exp = UNBIASED_EXP[precision][0] - 1

    maxMant = (1 << m_bits) - 1

    # Add operations:
    normDist = -3
    while normDist <= 3:
        for sign in [0, 1]:
            seed("b5" + "OP_ADD" + precision + rounding_mode + "a" + str(normDist) + str(sign))
            a = random.randint(3, maxMant)
            b = maxMant - a + 1 + normDist
            a_fp = generate_FP(e_bits, str(sign), sn_exp, f"{a:0{m_bits}b}", e_bias)
            b_fp = generate_FP(e_bits, str(sign), sn_exp, f"{b:0{m_bits}b}", e_bias)
            run_and_store_test_vector(
                f"{OP_ADD}_{rounding_mode}_{a_fp}_{b_fp}_{32 * '0'}_{precision}_{32 * '0'}_{precision}_00",
                test_f,
                cover_f,
            )
        normDist += 1

    # Subtraction operations
    normDist = -3
    while normDist <= 3:
        for sign in [0, 1]:
            seed("b5" + "OP_SUB" + precision + rounding_mode + "a" + str(normDist) + str(sign))
            a = random.randint(3, maxMant - 3)
            b = a + normDist
            b_exp = sign + sn_exp
            a_exp = sn_exp + ((sign + 1) % 2)
            a_fp = generate_FP(e_bits, str(0), a_exp, f"{a:0{m_bits}b}", e_bias)
            b_fp = generate_FP(e_bits, str(0), b_exp, f"{b:0{m_bits}b}", e_bias)
            run_and_store_test_vector(
                f"{OP_SUB}_{rounding_mode}_{a_fp}_{b_fp}_{32 * '0'}_{precision}_{32 * '0'}_{precision}_00",
                test_f,
                cover_f,
            )
        normDist += 1


def tests_add_sub_9(precision: str, rounding_mode: str, test_f: TextIO, cover_f: TextIO) -> None:
    m_bits = MANTISSA_BITS[precision]
    e_bits = EXPONENT_BITS[precision]
    e_bias = EXPONENT_BIAS[precision]
    sn_exp = UNBIASED_EXP[precision][0] - 1

    maxMant = (1 << m_bits) - 1
    for i in range(1, 7):
        for op in [OP_ADD, OP_SUB]:
            a_exp = sn_exp
            b_exp = sn_exp + i
            seed("b5" + str(op) + precision + rounding_mode + "a" + str(i))
            a_mant = random.randint(0, maxMant)
            a_sign = str(random.randint(0, 1))
            seed("b5" + str(op) + precision + rounding_mode + "b" + str(i))
            b_mant = random.randint(a_mant, maxMant)
            b_sign = str(random.randint(0, 1))
            a_fp = generate_FP(e_bits, a_sign, a_exp, f"{a_mant:0{m_bits}b}", e_bias)
            b_fp = generate_FP(e_bits, b_sign, b_exp, f"{b_mant:0{m_bits}b}", e_bias)
            run_and_store_test_vector(
                f"{op}_{rounding_mode}_{a_fp}_{b_fp}_{32 * '0'}_{precision}_{32 * '0'}_{precision}_00", test_f, cover_f
            )


def addSubTests(test_f: TextIO, cover_f: TextIO) -> None:
    for precision in FLOAT_FMTS:
        for rounding_mode in ROUNDING_MODES:
            tests_add_sub_1_2(precision, rounding_mode, test_f, cover_f)
            tests_add_sub_3_4(precision, rounding_mode, test_f, cover_f)
            tests_add_sub_5_6(precision, rounding_mode, test_f, cover_f)
            tests_add_sub_9(precision, rounding_mode, test_f, cover_f)


@register_model("B5")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    convertTests(test_f, cover_f)
    multiplyTests(test_f, cover_f)
    addSubTests(test_f, cover_f)
    fmaTests(test_f, cover_f)
    divTests(test_f, cover_f)
