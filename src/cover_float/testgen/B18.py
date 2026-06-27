# B18
# Lamarr

import random
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
    OP_FMADD,
    OP_FMSUB,
    OP_FNMADD,
    OP_FNMSUB,
    ROUND_MAX,
    ROUND_MIN,
    ROUND_MINMAG,
    ROUND_NEAR_EVEN,
    ROUND_NEAR_MAXMAG,
    UNBIASED_EXP,
)
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.B5 import getMultiplyTests
from cover_float.testgen.model import register_model

B5_FMTS = [FMT_QUAD, FMT_DOUBLE, FMT_SINGLE, FMT_BF16, FMT_HALF]
ROUNDING_MODES = [ROUND_NEAR_EVEN, ROUND_MINMAG, ROUND_MIN, ROUND_MAX, ROUND_NEAR_MAXMAG]
FMA_OPS = [OP_FMADD, OP_FMSUB, OP_FNMADD, OP_FNMSUB]

fma_op_key = {
    OP_FMADD: {"mul_sign": 0, "add_sign": 0},
    OP_FMSUB: {"mul_sign": 0, "add_sign": 1},
    OP_FNMADD: {"mul_sign": 1, "add_sign": 1},
    OP_FNMSUB: {"mul_sign": 1, "add_sign": 0},
}


def generate_FP(precision: str, input_sign: str, input_exponent: int, input_mantissa: str) -> str:
    input_e_bitwidth = EXPONENT_BITS[precision]
    input_bias = EXPONENT_BIAS[precision]

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


def getRandomInt(min_exp: int, max_exp: int, sign: str, precision: str) -> str:
    mantissa_bits = MANTISSA_BITS[precision]

    exp = random.randint(min_exp, max_exp + 1)
    mantissa = random.randint(1, (1 << mantissa_bits) - 1)
    mantissa_str = f"{mantissa:0{mantissa_bits}b}"
    return generate_FP(precision, sign, exp, mantissa_str)


def genUnderflowTests(test_f: TextIO, cover_f: TextIO) -> None:

    for precision in FLOAT_FMTS:
        min_exp = UNBIASED_EXP[precision][0] + 1
        max_exp = UNBIASED_EXP[precision][1] - 1
        rounding_mode = random.choice(ROUNDING_MODES)
        for a, b in getMultiplyTests(precision, rounding_mode):
            for operation in FMA_OPS:
                c = getRandomInt(min_exp, max_exp, str(random.randint(0, 1)), precision)
                run_and_store_test_vector(
                    f"{operation}_{rounding_mode}_{a}_{b}_{c}_{precision}_{32 * '0'}_{precision}_00",
                    test_f,
                    cover_f,
                )


# def genOverflowTests(test_f: TextIO, cover_f: TextIO) -> None:


def get_fma_signs(operation: str) -> tuple[int, int]:
    fma_op_key = {
        OP_FMADD: {"mul_sign": 0, "add_sign": 0},
        OP_FMSUB: {"mul_sign": 0, "add_sign": 1},
        OP_FNMADD: {"mul_sign": 1, "add_sign": 1},
        OP_FNMSUB: {"mul_sign": 1, "add_sign": 0},
    }

    op_mul_sign = fma_op_key[operation]["mul_sign"]
    op_add_sign = fma_op_key[operation]["add_sign"]

    return op_mul_sign, op_add_sign


def lsbGuardStickyTests(test_f: TextIO, cover_f: TextIO) -> None:
    rounding_mode = random.choice(ROUNDING_MODES)
    for precision in FLOAT_FMTS:
        for grs_int in range(1, 8):
            for operation in FMA_OPS:
                mul_sign, add_sign = get_fma_signs(operation)
                a, b, c = get_fp_values(precision, f"{grs_int:03b}", mul_sign, add_sign)
                run_and_store_test_vector(
                    f"{operation}_{rounding_mode}_{a}_{b}_{c}_{precision}_{32 * '0'}_{precision}_00", test_f, cover_f
                )


def get_fp_values(precision: str, grs_pattern: str, mul_sign: int, addend_sign: int) -> tuple[str, str, str]:
    m_bits = MANTISSA_BITS[precision]
    e_min = UNBIASED_EXP[precision][0]
    e_max = UNBIASED_EXP[precision][1]

    # Determine the input mantissas for each desired value
    target_list = {
        # Above MinNorm
        "001": {  # Same as B5, FIX
            FMT_BF16: (8 + 1) * (8**2 - 8 + 1),
            FMT_HALF: ((2**4) + 1) * ((2**4) ** 2 - (2**4) + 1),
            FMT_SINGLE: ((2**5) + 1) * ((2**5) ** 4 - (2**5) ** 3 + (2**5) ** 2 - (2**5) + 1),
            FMT_DOUBLE: ((2**11) + 1) * ((2**11) ** 4 - (2**11) ** 3 + (2**11) ** 2 - (2**11) + 1),
            FMT_QUAD: ((2**38) + 1) * ((2**76) - (2**38) + 1),
        },
        "010": {  # Same as B5, FIX
            FMT_BF16: 2056,
            FMT_HALF: (2**11) + 1,
            FMT_SINGLE: ((2**8) + 1) * ((2**8) ** 2 - (2**8) + 1),
            FMT_DOUBLE: (2**53) + 1,
            FMT_QUAD: (2**113) + 1,
        },
        "011": {  # Same as B5, FIX
            FMT_BF16: 2**9 + 2 + 1,
            FMT_HALF: 2**13 + 4 + 3,
            FMT_SINGLE: (2**26) + 7,
            FMT_DOUBLE: 2**55 + 7,
            FMT_QUAD: 2**120 + 125,
        },
        "100": {  # grs_int = 4
            FMT_BF16: (2**8) - 1,
            FMT_HALF: (2**11) - 1,
            FMT_SINGLE: (2**24) - 1,
            FMT_DOUBLE: (2**53) - 1,
            FMT_QUAD: (2**113) - 1,
        },
        # Below MinNorm
        "111": {  # grs_int = 7
            FMT_BF16: (2**10) - 1,
            FMT_HALF: (2**14) - 1,
            FMT_SINGLE: (2**26) - 1,
            FMT_DOUBLE: (2**56) - 1,
            FMT_QUAD: (2**116) - 1,
        },  # - 1 ulp
        "110": {  # grs_int = 6
            FMT_BF16: (2**9) - 1,
            FMT_HALF: (2**12) - 1,
            FMT_SINGLE: (2**25) - 1,
            FMT_DOUBLE: (2**54) - 1,
            FMT_QUAD: (2**114) - 1,
        },
        "101": {  # grs_int = 5
            FMT_BF16: 517,
            FMT_HALF: (2**12) + 5,
            FMT_SINGLE: (2**26) - 3,
            FMT_DOUBLE: (2**55) - 3,
            FMT_QUAD: 613 * 33881219305284356466756909162937,  # FIX
        },
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
        "100": {
            FMT_BF16: (2**4) - 1,
            FMT_HALF: 23,
            FMT_SINGLE: (2**12) - 1,
            FMT_DOUBLE: 6361 * 69431,
            FMT_QUAD: 3391 * 23279 * 65993,
        },
        # Below MinNorm
        "111": {  # grs_int = 7
            FMT_BF16: (2**5) - 1,
            FMT_HALF: (2**7) - 1,
            FMT_SINGLE: (2**13) - 1,
            FMT_DOUBLE: (2**28) - 1,
            FMT_QUAD: (2**58) - 1,
        },
        "110": {  # grs_int = 6
            FMT_BF16: 73,
            FMT_HALF: (2**4) - 1,
            FMT_SINGLE: (2**5) - 1,
            FMT_DOUBLE: (2**27) - 1,
            FMT_QUAD: (2**57) - 1,
        },
        "101": {  # grs_int = 5
            FMT_BF16: 11,
            FMT_HALF: 1367,
            FMT_SINGLE: 37 * 349,
            FMT_DOUBLE: 181 * 313 * 431,
            FMT_QUAD: 33881219305284356466756909162937,  # FIX
        },
    }
    # Randomize the sign bit
    if mul_sign == 0:
        a_sign = random.randint(0, 1)
        b_sign = a_sign
    else:
        a_sign = random.randint(0, 1)
        b_sign = (a_sign + 1) % 2

    target_int = target_list[grs_pattern][precision]
    factor_1 = factor_list[grs_pattern][precision]
    factor_2 = target_int // factor_1  # Integers have unlimited precision, must use integer division

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

    e_mul_target = random.randint(e_min + m_bits + 2, e_max)

    a_exp = int((e_mul_target + exp_offset) / 2)
    b_exp = int(a_exp - exp_offset) - 1
    if e_min - (a_exp + b_exp) == -1:
        b_exp -= 1
    elif e_min - (a_exp + b_exp) == 1:
        b_exp += 1
    target_binary = f"{target_int:b}"
    target_len = len(target_binary) - 1  # subtract hidden 1
    additional_bits = max(0, target_len - m_bits)
    if additional_bits > 0:  # If we have bits to remove
        c_len = random.randint(additional_bits, m_bits + 1)

        additional_bits_bin = target_binary[m_bits + 1 :]
        additional_bits_len = len(additional_bits_bin)
        c_prefix_len = c_len - additional_bits_len
        c_mantissa_prefix = ""
        if c_prefix_len > 0:
            c_mantissa_prefix = f"{random.randint(1 << (c_prefix_len - 1), (1 << c_prefix_len) - 1):0{c_prefix_len}b}"
        c_mantissa_bin = c_mantissa_prefix + additional_bits_bin

        c_mantissa_bin = c_mantissa_bin.lstrip("0")
        if not c_mantissa_bin:
            c_mantissa_bin = "1"  # Failsafe if the slice was entirely zeros

        # Update c_len to the TRUE length after removing leading zeros
        c_len = len(c_mantissa_bin)

        # Calculate precise exponent offset using the corrected c_len
        c_exp_offset = a_bits + b_bits - c_len - 1
    else:  # If there are no bits to remove
        c_len = random.randint(1, m_bits + 1)
        c_mantissa = random.randint(1 << (c_len - 1), (1 << c_len) - 1)
        c_mantissa_bin = f"{c_mantissa:0{c_len}b}"
        c_exp_offset = random.randint(0, m_bits - c_len) if m_bits - c_len > 0 else 0

    mantissa_len = len(c_mantissa_bin)
    c_mantissa_int = int(c_mantissa_bin, 2)

    # handle normal vs subnormals:
    c_exp = (a_exp + b_exp) - c_exp_offset
    if c_exp < e_min:
        c_exp = e_min - 1
    else:  # subtract hidden 1
        c_mantissa_int -= 1 << (mantissa_len - 1)

    # Shift the mantissa left to align it to the MSB of the IEEE fraction field
    c_trailing_zeros = m_bits - c_len + 1
    c_mantissa_int *= 2 ** max(c_trailing_zeros, 0)

    c_bin = f"{c_mantissa_int:0{m_bits}b}"

    a_fp = generate_FP(precision, str(a_sign), a_exp, a_bin)
    b_fp = generate_FP(precision, str(b_sign), b_exp, b_bin)
    c_fp = generate_FP(precision, str((addend_sign + 1) % 2), c_exp, c_bin)

    return a_fp, b_fp, c_fp


@register_model("B18")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    genUnderflowTests(test_f, cover_f)
    # overFlowTests(test_f, cover_f)
    # lsbGuardStickyTests(test_f, cover_f)
