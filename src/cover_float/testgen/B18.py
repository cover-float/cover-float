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
    SIGN_BIT,
    UNBIASED_EXP,
)
from cover_float.common.util import reproducible_hash
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.B4 import get_mul_inputs as getB4MultiplyTests
from cover_float.testgen.B5 import getMultiplyTests as getB5MultiplyTests
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
        for a, b in getB5MultiplyTests(precision, rounding_mode):
            for operation in FMA_OPS:
                c = getRandomInt(min_exp, max_exp, str(random.randint(0, 1)), precision)
                rm = random.choice(ROUNDING_MODES)
                run_and_store_test_vector(
                    f"{operation}_{rm}_{a}_{b}_{c}_{precision}_{32 * '0'}_{precision}_00",
                    test_f,
                    cover_f,
                )


def genOverflowTests(test_f: TextIO, cover_f: TextIO) -> None:
    for precision in FLOAT_FMTS:
        rounding_mode = random.choice(ROUNDING_MODES)

        for a, b in getB4MultiplyTests(precision, rounding_mode):
            for operation in FMA_OPS:
                effective_subtraction = operation in [OP_FMSUB, OP_FNMADD]
                negate_multiply = operation in [OP_FNMADD, OP_FNMSUB]

                a_sign = (int(a, 16) & (1 << SIGN_BIT[precision])) != 0
                b_sign = (int(b, 16) & (1 << SIGN_BIT[precision])) != 0

                prod_sign = a_sign ^ b_sign ^ negate_multiply
                c_sign = prod_sign ^ 1 ^ effective_subtraction

                c_exp = UNBIASED_EXP[precision][1]
                c_mant = (1 << MANTISSA_BITS[precision]) - 1

                c = generate_FP(precision, str(c_sign), c_exp, bin(c_mant)[2:])

                rm = random.choice(ROUNDING_MODES)
                run_and_store_test_vector(
                    f"{operation}_{rm}_{a}_{b}_{c}_{precision}_{32 * '0'}_{precision}_00",
                    test_f,
                    cover_f,
                )


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
        for grs_int in range(0, 8):
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

    lsb = grs_pattern[0] == "1"
    guard = grs_pattern[1] == "1"
    sticky = grs_pattern[2] == "1"

    if sticky:
        sig1, sig2 = generate_inexact_factors(lsb, guard, m_bits)
    else:
        sig1, sig2 = generate_exact_factors(lsb, guard, m_bits)

    sign1 = random.randint(0, 1)
    sign2 = sign1 ^ mul_sign

    sig_prod = sig1 * sig2

    rounding_bit_count = m_bits if sig_prod.bit_length() == 2 * m_bits + 1 else m_bits + 1
    rounding_bits = sig_prod & ((1 << rounding_bit_count) - 1)

    if sig_prod.bit_length() == 2 * m_bits + 1:
        exp_diff = -m_bits

        if addend_sign == 1:
            sig3 = rounding_bits
        else:
            target = 1 << m_bits
            sig3 = target - rounding_bits
    else:
        exp_diff = -m_bits + 1
        assert sig_prod & 1 == 0, "Generation must make sig_prod even with full 2.2nf products"

        if addend_sign == 1:
            sig3 = rounding_bits >> 1
        else:
            target = 1 << m_bits
            sig3 = target - (rounding_bits >> 1)

    sig3 &= (1 << m_bits) - 1

    mul_exp = random.randint(e_min, e_max)
    addend_exp = mul_exp + exp_diff
    while addend_exp <= e_min or addend_exp >= e_max:
        mul_exp = random.randint(e_min, e_max)
        addend_exp = mul_exp + exp_diff

    exp1 = random.randint(e_min, e_max)
    exp2 = mul_exp - exp1
    while exp2 <= e_min or exp2 >= e_max:
        exp1 = random.randint(e_min, e_max)
        exp2 = mul_exp - exp1

    sig1_str = f"{sig1 & ((1 << m_bits) - 1):0{m_bits}b}"
    sig2_str = f"{sig2 & ((1 << m_bits) - 1):0{m_bits}b}"
    sig3_str = f"{sig3 & ((1 << m_bits) - 1):0{m_bits}b}"

    f1 = generate_FP(precision, str(sign1), exp1, sig1_str)
    f2 = generate_FP(precision, str(sign2), exp2, sig2_str)
    f3 = generate_FP(precision, str(0), addend_exp, sig3_str)

    return f1, f2, f3


def generate_inexact_factors(lsb: int, guard: int, m_bits: int) -> tuple[int, int]:
    for _ in range(100):
        sig1 = 1 << m_bits | random.getrandbits(m_bits)
        sig2 = 1 << m_bits | random.getrandbits(m_bits)

        sig_prod = sig1 * sig2

        # In guard == 0 cases ensure that the last sig bit is zero so that it can be
        # cancelled later
        if (sig1 & 1 == 1) and sig_prod.bit_length() == 2 * m_bits + 2:
            sig1 ^= 1
            sig_prod = sig1 * sig2
            assert sig_prod & 1 == 0

        rounding_bit_count = m_bits if sig_prod.bit_length() == 2 * m_bits + 1 else m_bits + 1
        gen_lsb = sig_prod & (1 << rounding_bit_count) != 0
        gen_guard = sig_prod & (1 << rounding_bit_count - 1) != 0
        gen_sticky = (sig_prod & (1 << (rounding_bit_count - 2) - 1)) != 0

        if gen_sticky and gen_lsb == lsb and gen_guard == guard:
            return sig1, sig2
    else:
        raise ValueError(
            f"Failed to Generate Multiplicands giving lsb={lsb}, guard={guard} with {m_bits} mantissa bits"
        )


def generate_exact_factors(lsb: int, guard: int, m_bits: int) -> tuple[int, int]:
    trailing_zeros = m_bits - 1

    for _ in range(100):
        # Figure out how many zeros go in each
        a_zeros = -1
        b_zeros = -1
        while b_zeros < 3 or b_zeros > m_bits - 3:
            a_zeros = random.randint(3, m_bits - 3)
            b_zeros = trailing_zeros - a_zeros

        m1 = random.getrandbits(m_bits - a_zeros) << a_zeros
        m2 = random.getrandbits(m_bits - b_zeros) << b_zeros

        sig1 = 1 << m_bits | m1
        sig2 = 1 << m_bits | m2

        sig_prod = sig1 * sig2

        rounding_bit_count = m_bits if sig_prod.bit_length() == 2 * m_bits + 1 else m_bits + 1

        gen_sticky = (sig_prod & (1 << (rounding_bit_count - 1) - 1)) != 0
        gen_guard = sig_prod & (1 << rounding_bit_count - 1) != 0
        gen_lsb = sig_prod & (1 << rounding_bit_count) != 0

        if gen_sticky == 0 and gen_guard == guard and gen_lsb == lsb:
            return sig1, sig2
    else:
        raise ValueError(
            f"Failed to Generate Exact Multiplicands for lsb={lsb}, guard={guard} with {m_bits} mantissa bits"
        )


@register_model("B18")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    random.seed(reproducible_hash("B18"))
    genUnderflowTests(test_f, cover_f)
    genOverflowTests(test_f, cover_f)
    lsbGuardStickyTests(test_f, cover_f)
