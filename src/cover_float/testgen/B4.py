# B4: Overflow and Near Overflow
#
# Implements the Aharoni et al. (2008) overflow model. Three groups per format:
#
#   Group 1A - T_k integer-ULP offsets (k in {-3..+3}), both signs, all 5 rounding
#              modes, all 8 arithmetic operations. Targets the overflow detection
#              comparator.  (560 vectors / format)
#
#   Group 1B - LGS sub-ULP bit positions (7 non-zero {L,G,S} configs), both signs,
#              all 5 rounding modes:
#                Arithmetic (ADD/SUB/FMADD/FMSUB/FNMADD/FNMSUB): 420 / format
#                MUL/DIV supplement (LGS=100 only):               20  / format
#
#   Group 2  - Clear overflow (intermediate >> MaxNorm + 3ulp), both signs, all
#              5 rounding modes, all 8 operations. (80 / format)
#
#   Group 3  - Exponent sweep [max_biased-3 .. max_biased+3], both signs, all 5
#              rounding modes, all 8 operations. (560 / format)
#
#   Total: 1640 / format * 5 formats = 8200 vectors.

import itertools
import logging
import random
from collections.abc import Generator
from typing import TYPE_CHECKING, TextIO, cast

from cover_float.common.config import Config
import cover_float.common.constants as const
import cover_float.common.log as log
from cover_float.common.util import factors_to_bit_width, reproducible_hash
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model

if TYPE_CHECKING:
    # This block is seen by Pyright but ignored at runtime
    def factorint(n: int) -> dict[int, int]: ...
else:
    from sympy import factorint

logger: log.ModelLogger = cast(log.ModelLogger, logging.getLogger("B4"))

ZERO_PAD = "0" * 32

ROUND_MODES = [
    const.ROUND_NEAR_EVEN,
    const.ROUND_MINMAG,
    const.ROUND_MIN,
    const.ROUND_MAX,
    const.ROUND_NEAR_MAXMAG,
]

# LGS configs: (use_m1ulp, gs) covering all 7 non-zero {L,G,S} values.
# gs encodes G and S directly: bit 1 → G, bit 0 → S.
# use_m1ulp selects A operand: True → A = MaxNorm-1ulp (L=0), False → A = MaxNorm (L=1).
#
#   (True,  gs=1) → LGS = 001   (True,  gs=2) → LGS = 010   (True,  gs=3) → LGS = 011
#   (False, gs=0) → LGS = 100   (False, gs=1) → LGS = 101
#   (False, gs=2) → LGS = 110   (False, gs=3) → LGS = 111
_LGS_CONFIGS = [
    (True, 1),  # LGS=001
    (True, 2),  # LGS=010
    (True, 3),  # LGS=011
    (False, 0),  # LGS=100  (exactly MaxNorm, no rounding bits)
    (False, 1),  # LGS=101
    (False, 2),  # LGS=110
    (False, 3),  # LGS=111
]

# ---------------------------------------------------------------------------
# Low-level floating-point encoding helpers
# ---------------------------------------------------------------------------


def _fp_hex(sign: int, biased_exp: int, mantissa: int, E: int, M: int) -> str:
    """Pack (sign, biased_exp, mantissa) into a 32-char left-zero-padded hex string."""
    raw = (sign << (E + M)) | (biased_exp << M) | mantissa
    return f"{raw:0{(1 + E + M + 3) // 4}x}".rjust(32, "0")


def _fmt_params(fmt: str) -> tuple[int, int, int]:
    """Return (E, M, bias) for a format."""
    return (
        const.EXPONENT_BITS[fmt],
        const.MANTISSA_BITS[fmt],
        const.BIAS[fmt],
    )


# ---------------------------------------------------------------------------
# Derived format constants
# ---------------------------------------------------------------------------


def _max_biased(E: int) -> int:
    return (1 << E) - 2


def _unbiased_max(E: int, bias: int) -> int:
    return _max_biased(E) - bias


def _ulp_exp(E: int, M: int, bias: int) -> int:
    """Base-2 exponent of 1 ULP at MaxNorm: unbiased_max - M."""
    return _unbiased_max(E, bias) - M


# ---------------------------------------------------------------------------
# Common operand constructors
# ---------------------------------------------------------------------------


def _maxnorm(sign: int, E: int, M: int) -> str:
    """±MaxNorm: biased_exp = max_biased, mantissa = all ones."""
    return _fp_hex(sign, _max_biased(E), (1 << M) - 1, E, M)


def _maxnorm_m1ulp(sign: int, E: int, M: int) -> str:
    """±(MaxNorm - 1ulp): same biased_exp, mantissa LSB cleared."""
    return _fp_hex(sign, _max_biased(E), (1 << M) - 2, E, M)


def _half_maxnorm(sign: int, E: int, M: int) -> str:
    """±MaxNorm/2: biased_exp decremented by 1, mantissa unchanged (all ones)."""
    return _fp_hex(sign, _max_biased(E) - 1, (1 << M) - 1, E, M)


def _one(E: int, M: int, bias: int) -> str:
    """+1.0"""
    return _fp_hex(0, bias, 0, E, M)


def _two(E: int, M: int, bias: int) -> str:
    """+2.0"""
    return _fp_hex(0, bias + 1, 0, E, M)


def _half_fp(E: int, M: int, bias: int) -> str:
    """+0.5"""
    return _fp_hex(0, bias - 1, 0, E, M)


def _pow2(d: int, E: int, M: int, bias: int) -> str:
    """
    +2^d as a float (mantissa = 0). Biased_exp is clamped to [1, max_biased]
    so subnormal / overflow encoding is avoided for the scale operands used in
    Groups 1A and 3.
    """
    biased = max(1, min(d + bias, _max_biased(E)))
    return _fp_hex(0, biased, 0, E, M)


def _k_ulp(k: int, E: int, M: int, bias: int) -> str:
    """
    k x ulp where ulp = 2^ulp_exp.  Returns a signed float: negative for k < 0.
    Returns ZERO_PAD for k = 0.

    For |k| in {1, 2, 3}:
      |k|=1 → exactly 2^ulp_exp (biased_exp = ulp_exp+bias, mantissa = 0)
      |k|=2 → exactly 2^(ulp_exp+1)
      |k|=3 → 1.1₂ x 2^(ulp_exp+1)  (mantissa MSB set)
    """
    if k == 0:
        return ZERO_PAD
    sign = 1 if k < 0 else 0
    abs_k = abs(k)
    ue = _ulp_exp(E, M, bias)
    # abs_k = 1.frac x 2^(b-1) in binary
    b = abs_k.bit_length()
    biased_exp = ue + (b - 1) + bias
    frac = abs_k ^ (1 << (b - 1))
    mantissa = frac << (M - (b - 1))
    return _fp_hex(sign, biased_exp, mantissa, E, M)


def _t_k_half(k: int, sign: int, E: int, M: int, bias: int) -> str:
    """
    ±(T_k / 2) = ±(MaxNorm + k*ulp) / 2 for use in OP_MUL/OP_DIV constructions.

    For k <= 0: T_k has biased_exp = max_biased, mantissa = (2^M-1)+k.
               Halving decrements biased_exp by 1 with mantissa unchanged. Exact.
    For k = 1: T_1 = 2^(unbiased_max+1), T_1/2 = 2^unbiased_max.
               biased_exp = max_biased, mantissa = 0.  Exact.
    For k = 2: T_2/2 is not exactly representable in any supported format.
               We use T_1/2 (biased_exp = max_biased, mantissa = 0) as the
               closest representable value.  The resulting intermediate equals
               T_1 rather than T_2; T_1 is still in the ±3ulp coverage window.
    For k = 3: T_3/2 = (1 + 2^{-M}) x 2^unbiased_max.
               biased_exp = max_biased, mantissa = 1 (LSB). Exact.
    """
    mb = _max_biased(E)
    if k <= 0:
        return _fp_hex(sign, mb - 1, (1 << M) - 1 + k, E, M)
    elif k == 1:
        return _fp_hex(sign, mb, 0, E, M)
    elif k == 2:
        # Not representable; use T_1/2 (still within ±3ulp window after x2)
        return _fp_hex(sign, mb, 0, E, M)
    else:  # k == 3
        return _fp_hex(sign, mb, 1, E, M)


def _gs_b(gs: int, sign: int, E: int, M: int, bias: int) -> str:
    """
    gs x 2^(sub_ulp_exp) where sub_ulp_exp = ulp_exp - 2.
    gs in {0,1,2,3}: bit 1 → G, bit 0 → S in the intermediate.
    gs = 0 returns ZERO_PAD (+0.0).
    """
    if gs == 0:
        return ZERO_PAD
    sub_exp = _ulp_exp(E, M, bias) - 2
    b = gs.bit_length()
    biased_exp = (b - 1 + sub_exp) + bias
    frac = gs ^ (1 << (b - 1))
    mantissa = frac << (M - (b - 1))
    return _fp_hex(sign, biased_exp, mantissa, E, M)


def _at_biased_exp(sign: int, biased_exp: int, E: int, M: int) -> str:
    """A normal FP number with the given biased_exp and all-ones mantissa."""
    biased_exp = max(1, min(biased_exp, _max_biased(E)))
    return _fp_hex(sign, biased_exp, (1 << M) - 1, E, M)


# ---------------------------------------------------------------------------
# Emit helper
# ---------------------------------------------------------------------------


def _emit(
    op: str,
    rm: str,
    a: str,
    b: str,
    c: str,
    fmt: str,
    test_f: TextIO,
    cover_f: TextIO,
    config: Config,
) -> None:
    tv = f"{op}_{rm}_{a}_{b}_{c}_{fmt}_{ZERO_PAD}_{fmt}_00"
    run_and_store_test_vector(tv, test_f, cover_f, config)


def _emit_convert(
    op: str,
    rm: str,
    a: str,
    fmt: str,
    target_fmt: str,
    test_f: TextIO,
    cover_f: TextIO,
    config: Config,
) -> None:
    tv = f"{op}_{rm}_{a}_{ZERO_PAD}_{ZERO_PAD}_{fmt}_{ZERO_PAD}_{target_fmt}_00"
    run_and_store_test_vector(tv, test_f, cover_f, config)


# ---------------------------------------------------------------------------
# Group 1A: T_k integer-ULP offsets
# ---------------------------------------------------------------------------


def _group1a_tk(fmt: str, E: int, M: int, bias: int, test_f: TextIO, cover_f: TextIO, config: Config) -> None:
    """
    7 k values x 8 operations x 2 signs x 5 rounding modes = 560 vectors.

    For each (k, sign, rm), emit one vector per operation using the exact
    construction that drives the infinite-precision intermediate to ±T_k.

    Positive intermediate (+T_k), sign=0:
      ADD:    A = +MaxNorm,    B = +k*ulp
      SUB:    A = +MaxNorm,    B = -k*ulp          (A - (-k*ulp) = T_k)
      MUL:    A = +(T_k/2),   B = 2.0
      DIV:    A = +(T_k/2),   B = 0.5
      FMADD:  A = +MaxNorm/2, B = 2.0, C = +k*ulp
      FMSUB:  A = +MaxNorm/2, B = 2.0, C = -k*ulp  (A*B - C = MaxNorm + k*ulp)
      FNMADD: A = -MaxNorm/2, B = 2.0, C = -k*ulp  (-(A*B) - C = MaxNorm + k*ulp)
      FNMSUB: A = -MaxNorm/2, B = 2.0, C = +k*ulp  (-(A*B) + C = MaxNorm + k*ulp)

    Negative intermediate (-T_k), sign=1: negate all dominant operands.
    """
    two = _two(E, M, bias)
    half = _half_fp(E, M, bias)

    for k in range(-3, 4):
        k_ulp = _k_ulp(k, E, M, bias)
        neg_k_ulp = _k_ulp(-k, E, M, bias)

        for sign in (0, 1):
            # Signed MaxNorm and MaxNorm/2
            mn = _maxnorm(sign, E, M)
            hmn = _half_maxnorm(sign, E, M)
            hmn_op = _half_maxnorm(1 - sign, E, M)  # opposite-sign MaxNorm/2

            # T_k/2 operand for MUL/DIV
            tk2 = _t_k_half(k, sign, E, M, bias)

            # For sign=0 the B operand of ADD/SUB uses the raw k_ulp/neg_k_ulp.
            # For sign=1 we need to produce -T_k = -MaxNorm - k*ulp:
            #   ADD(-MaxNorm, -(+k*ulp)) = -MaxNorm - k*ulp = -T_k  (k>0 case)
            #   i.e. sign=1 ADD uses B = neg_k_ulp, SUB uses B = k_ulp.
            if sign == 0:
                add_b = k_ulp
                sub_b = neg_k_ulp
                fmadd_c = k_ulp
                fmsub_c = neg_k_ulp
                fnmadd_c = neg_k_ulp
                fnmsub_c = k_ulp
            else:
                add_b = neg_k_ulp
                sub_b = k_ulp
                fmadd_c = neg_k_ulp
                fmsub_c = k_ulp
                fnmadd_c = k_ulp
                fnmsub_c = neg_k_ulp

            for rm in ROUND_MODES:
                _emit(const.OP_ADD, rm, mn, add_b, ZERO_PAD, fmt, test_f, cover_f, config)
                _emit(const.OP_SUB, rm, mn, sub_b, ZERO_PAD, fmt, test_f, cover_f, config)
                _emit(const.OP_MUL, rm, tk2, two, ZERO_PAD, fmt, test_f, cover_f, config)
                _emit(const.OP_DIV, rm, tk2, half, ZERO_PAD, fmt, test_f, cover_f, config)
                _emit(const.OP_FMADD, rm, hmn, two, fmadd_c, fmt, test_f, cover_f, config)
                _emit(const.OP_FMSUB, rm, hmn, two, fmsub_c, fmt, test_f, cover_f, config)
                _emit(const.OP_FNMADD, rm, hmn_op, two, fnmadd_c, fmt, test_f, cover_f, config)
                _emit(const.OP_FNMSUB, rm, hmn_op, two, fnmsub_c, fmt, test_f, cover_f, config)


# ---------------------------------------------------------------------------
# Group 1B: LGS sub-ULP bit positions — arithmetic (6 ops)
# ---------------------------------------------------------------------------


def _group1b_arithmetic(fmt: str, E: int, M: int, bias: int, test_f: TextIO, cover_f: TextIO, config: Config) -> None:
    """
    7 LGS configs x 6 operations x 2 signs x 5 rounding modes = 420 vectors.

    For each config (use_m1ulp, gs):
      A_lgs = MaxNorm-1ulp if use_m1ulp else MaxNorm
      B_lgs = gs x 2^(sub_ulp_exp)

    Positive intermediate +(A_lgs + B_lgs):
      ADD:    A = +A_lgs,  B = +B_lgs
      SUB:    A = +A_lgs,  B = -B_lgs      (A - (-B) = A + B)
      FMADD:  A = +A_lgs,  B = 1.0, C = +B_lgs
      FMSUB:  A = +A_lgs,  B = 1.0, C = -B_lgs
      FNMADD: A = -A_lgs,  B = 1.0, C = -B_lgs  (-(-A*1) - (-B) = A + B)
      FNMSUB: A = -A_lgs,  B = 1.0, C = +B_lgs  (-(-A*1) + B = A + B)

    Negative intermediate -(A_lgs + B_lgs): negate all operands.
    """
    one = _one(E, M, bias)

    for use_m1ulp, gs in _LGS_CONFIGS:
        for sign in (0, 1):
            # A_lgs with the desired sign
            if use_m1ulp:
                a_lgs_pos = _maxnorm_m1ulp(0, E, M)
                a_lgs_neg = _maxnorm_m1ulp(1, E, M)
            else:
                a_lgs_pos = _maxnorm(0, E, M)
                a_lgs_neg = _maxnorm(1, E, M)

            b_lgs_pos = _gs_b(gs, 0, E, M, bias)
            b_lgs_neg = _gs_b(gs, 1, E, M, bias)

            if sign == 0:
                # Positive intermediate: A = +A_lgs, B/C = +B_lgs (or -B_lgs for SUB/FMSUB)
                a_add = a_lgs_pos
                b_add = b_lgs_pos
                a_sub = a_lgs_pos
                b_sub = b_lgs_neg  # A - (-B) = A+B
                a_fmadd = a_lgs_pos
                c_fmadd = b_lgs_pos
                a_fmsub = a_lgs_pos
                c_fmsub = b_lgs_neg
                a_fnmadd = a_lgs_neg
                c_fnmadd = b_lgs_neg
                a_fnmsub = a_lgs_neg
                c_fnmsub = b_lgs_pos
            else:
                # Negative intermediate: negate all
                a_add = a_lgs_neg
                b_add = b_lgs_neg
                a_sub = a_lgs_neg
                b_sub = b_lgs_pos  # -A - B = -(A+B)
                a_fmadd = a_lgs_neg
                c_fmadd = b_lgs_neg
                a_fmsub = a_lgs_neg
                c_fmsub = b_lgs_pos
                a_fnmadd = a_lgs_pos
                c_fnmadd = b_lgs_pos
                a_fnmsub = a_lgs_pos
                c_fnmsub = b_lgs_neg

            for rm in ROUND_MODES:
                _emit(const.OP_ADD, rm, a_add, b_add, ZERO_PAD, fmt, test_f, cover_f, config)
                _emit(const.OP_SUB, rm, a_sub, b_sub, ZERO_PAD, fmt, test_f, cover_f, config)
                _emit(const.OP_FMADD, rm, a_fmadd, one, c_fmadd, fmt, test_f, cover_f, config)
                _emit(const.OP_FMSUB, rm, a_fmsub, one, c_fmsub, fmt, test_f, cover_f, config)
                _emit(const.OP_FNMADD, rm, a_fnmadd, one, c_fnmadd, fmt, test_f, cover_f, config)
                _emit(const.OP_FNMSUB, rm, a_fnmsub, one, c_fnmsub, fmt, test_f, cover_f, config)


# ---------------------------------------------------------------------------
# Group 1B: LGS=100 supplement for OP_MUL and OP_DIV
# ---------------------------------------------------------------------------


def _generate_group1b_mul_factors(
    fmt: str, E: int, M: int, _bias: int, rm: str
) -> Generator[tuple[str, str], None, None]:
    random.seed(reproducible_hash(f"B4{fmt}{rm}"))

    for (lsb_zero, bits), sign in itertools.product(_LGS_CONFIGS, (0, 1)):
        if bits == 2 and lsb_zero and fmt in [const.FMT_HALF, const.FMT_BF16]:
            # Impossible cases to get the correct factors with
            continue

        # Find two factors
        if bits & 1 == 0:
            f1, f2 = generate_exact_mul_group1b(fmt, lsb_zero, bits, M)
        else:
            f1, f2 = generate_inexact_mul_group1b(fmt, lsb_zero, bits, M)

        # Find Exponents
        min_exp, max_exp = const.UNBIASED_EXP[fmt]
        target_exp = max_exp

        exp1 = random.randint(min_exp + 1, max_exp)  # Don't include min norm so we can subtract it later
        exp2 = target_exp - exp1
        while exp2 < min_exp or exp2 > max_exp:
            exp1 = random.randint(min_exp + 1, max_exp)  # Don't include min norm so we can subtract it later
            exp2 = target_exp - exp1

        if (f1 * f2).bit_length() == 2 * M + 2:
            exp1 -= 1

        sign1 = random.randint(0, 1)
        sign2 = sign1 ^ sign

        a = _fp_hex(sign1, exp1 + const.EXPONENT_BIAS[fmt], f1 & ((1 << M) - 1), E, M)
        b = _fp_hex(sign2, exp2 + const.EXPONENT_BIAS[fmt], f2 & ((1 << M) - 1), E, M)

        yield (a, b)


def _group1b_mul_div(fmt: str, E: int, M: int, bias: int, test_f: TextIO, cover_f: TextIO, config: Config) -> None:
    """
    1 LGS config x 2 operations x 2 signs x 5 rounding modes = 20 vectors.

    MUL and DIV cannot independently set G and S bits; multiplying or dividing
    MaxNorm by 1.0 always gives LGS=100 (exact MaxNorm, no rounding bits).
    This supplement satisfies the op_mul and op_div bins in the covergroup cross.

      OP_MUL(±MaxNorm, 1.0) → ±MaxNorm  (LGS=100)
      OP_DIV(±MaxNorm, 1.0) → ±MaxNorm  (LGS=100)
    """
    one = _one(E, M, bias)

    for sign in (0, 1):
        mn = _maxnorm(sign, E, M)
        for rm in ROUND_MODES:
            _emit(const.OP_DIV, rm, mn, one, ZERO_PAD, fmt, test_f, cover_f, config)

    for rm in ROUND_MODES:
        for a, b in _generate_group1b_mul_factors(fmt, E, M, bias, rm):
            _emit(const.OP_MUL, rm, a, b, ZERO_PAD, fmt, test_f, cover_f, config)


def generate_exact_mul_group1b(fmt: str, lsb_zero: bool, bits: int, nf: int) -> tuple[int, int]:
    lsb_one = not lsb_zero
    target = (((1 << nf) - 1) << 1 | lsb_one) << nf | bits << nf - 2

    factors = factorint(target)
    f1, f2 = factors_to_bit_width(factors, target, nf + 1)

    if f1 == 0 or f2 == 0:
        # Try the target as 2.2nf (rounding bits are still relative to the leading one)
        target *= 2

        factors = factorint(target)
        f1, f2 = factors_to_bit_width(factors, target, nf + 1)

        if f1 == 0 or f2 == 0:
            raise ValueError(
                f"Could Not Find Factors for LGS Config: {(lsb_zero, bits)}, fmt: {fmt}, factors: {factors}, "
                f"target: {target:b}"
            )

    return f1, f2


def generate_inexact_mul_group1b(fmt: str, lsb_zero: bool, bits: int, nf: int) -> tuple[int, int]:
    assert bits & 1, "Sticky Must Be Set to Generate Inexact Mul Results"

    lsb_one = not lsb_zero
    target = (((1 << nf) - 1) << 1 | lsb_one) << nf | bits << nf - 2

    # Find the two mantissas
    f1, f2 = 0, 0
    for _ in range(100000):
        # Try to get somewhere close to halfway to between the two numbers
        f1 = 1 << nf | random.getrandbits(nf)
        f2 = target // f1 + random.randint(0, 1)  # Randomly Choose Between Floor and Ceiling Division

        if f2.bit_length() == nf:
            f2 *= 2

        if f2.bit_length() != nf + 1:
            continue

        # 1.(nf+1) bits
        product_bin = f"{f1 * f2:b}"
        mantissa_and_guard = product_bin[: nf + 2]
        sticky = "1" in product_bin[nf + 2 :]  # All inexact cases have a sticky bit

        if bin(target)[2:].startswith(mantissa_and_guard) and sticky:
            break
    else:
        raise ValueError(f"Unable to find Inexact Factors to Hit LGS={(lsb_zero, bits)}, fmt={fmt}")

    return f1, f2


# ---------------------------------------------------------------------------
# Group 2: Clear overflow (intermediate >> MaxNorm + 3ulp)
# ---------------------------------------------------------------------------


def _group2_clear_overflow(
    fmt: str, E: int, M: int, bias: int, test_f: TextIO, cover_f: TextIO, config: Config
) -> None:
    """
    8 operations x 2 signs x 5 rounding modes = 80 vectors.

    All constructions target 2*MaxNorm as the intermediate, which lies well
    above MaxNorm + 3ulp for all supported formats.  The result is always ±Inf
    and the overflow flag is always raised, regardless of rounding mode.

    Positive intermediate (+2*MaxNorm), sign=0:
      ADD:    A = +MaxNorm,    B = +MaxNorm
      SUB:    A = +MaxNorm,    B = -MaxNorm       (A - (-B) = 2*MaxNorm)
      MUL:    A = +MaxNorm,    B = 2.0
      DIV:    A = +MaxNorm,    B = 0.5
      FMADD:  A = +MaxNorm/2,  B = 2.0, C = +MaxNorm
      FMSUB:  A = +MaxNorm/2,  B = 2.0, C = -MaxNorm
      FNMADD: A = -MaxNorm/2,  B = 2.0, C = -MaxNorm  (-(-Mn/2*2) - (-Mn) = 2Mn)
      FNMSUB: A = -MaxNorm/2,  B = 2.0, C = +MaxNorm  (-(-Mn/2*2) + Mn = 2Mn)

    Negative intermediate (-2*MaxNorm), sign=1: negate dominant operands.
    """
    two = _two(E, M, bias)

    for sign in (0, 1):
        mn = _maxnorm(sign, E, M)
        hmn = _half_maxnorm(sign, E, M)
        hmn_op = _half_maxnorm(1 - sign, E, M)

        mn_op = _maxnorm(1 - sign, E, M)  # opposite-sign MaxNorm, used only for SUB
        for rm in ROUND_MODES:
            # ADD: ±MaxNorm + ±MaxNorm = ±2*MaxNorm
            _emit(const.OP_ADD, rm, mn, mn, ZERO_PAD, fmt, test_f, cover_f, config)
            # SUB: ±MaxNorm - (∓MaxNorm) = ±2*MaxNorm
            _emit(const.OP_SUB, rm, mn, mn_op, ZERO_PAD, fmt, test_f, cover_f, config)
            # MUL: ±MaxNorm x 2.0 = ±2*MaxNorm
            _emit(const.OP_MUL, rm, mn, two, ZERO_PAD, fmt, test_f, cover_f, config)
            # DIV: ±MaxNorm / 0.5 = ±2*MaxNorm
            _emit(const.OP_DIV, rm, mn, _half_fp(E, M, bias), ZERO_PAD, fmt, test_f, cover_f, config)
            # FMADD: (±Mn/2 x 2) + ±Mn = ±2*Mn
            _emit(const.OP_FMADD, rm, hmn, two, mn, fmt, test_f, cover_f, config)
            # FMSUB: (±Mn/2 x 2) - (∓Mn) = ±2*Mn
            _emit(const.OP_FMSUB, rm, hmn, two, mn_op, fmt, test_f, cover_f, config)
            # FNMADD: -(∓Mn/2 x 2) - (∓Mn) = ±Mn + ±Mn = ±2*Mn
            _emit(const.OP_FNMADD, rm, hmn_op, two, mn_op, fmt, test_f, cover_f, config)
            # FNMSUB: -(∓Mn/2 x 2) + (±Mn) = ±Mn + ±Mn = ±2*Mn
            _emit(const.OP_FNMSUB, rm, hmn_op, two, mn, fmt, test_f, cover_f, config)


def _generate_group2_mul_factors(
    _fmt: str, E: int, M: int, bias: int, _rm: str
) -> Generator[tuple[str, str], None, None]:
    """Generator for the values used for group 2 multiplication tests"""
    two = _two(E, M, bias)

    for sign in (0, 1):
        # MUL: ±MaxNorm x 2.0 = ±2*MaxNorm
        mn = _maxnorm(sign, E, M)
        yield (mn, two)


# ---------------------------------------------------------------------------
# Group 3: Exponent sweep [max_biased-3 .. max_biased+3]
# ---------------------------------------------------------------------------


def _group3_exp_sweep(fmt: str, E: int, M: int, bias: int, test_f: TextIO, cover_f: TextIO, config: Config) -> None:
    """
    7 exponents x 8 operations x 2 signs x 5 rounding modes = 560 vectors.

    d = target_biased_exp - max_biased, d in {-3..+3}.

    d <= 0: A = representable number with biased_exp = max_biased+d (all-ones
           mantissa). Neutral second operand preserves the exponent.

      ADD/SUB:             A ± 0
      MUL/DIV:             A x 1.0 / A / 1.0
      FMADD/FMSUB:         (A x 1.0) ± 0
      FNMADD/FNMSUB:       (-A x 1.0) ∓ 0  →  +(-(-A)) = A for positive sign

    d > 0: No representable finite number has biased_exp > max_biased, so the
           intermediate must be produced via overflow arithmetic.

      MUL:    MaxNorm x 2^d
      DIV:    MaxNorm / 2^(-d)
      FMADD/FMSUB/FNMADD/FNMSUB: MaxNorm x 2^d ± 0
      ADD:    MaxNorm + MaxNorm  (achieves d=1; structural impossibility for d>1)
      SUB:    MaxNorm - (-MaxNorm) = 2*MaxNorm (same limitation for d>1)

    For sign=1 the dominant operand is negated in each construction.

    Note on structural impossibilities: OP_ADD and OP_SUB cannot produce an
    intermediate with biased_exp > max_biased+1 using representable inputs, so
    those (OP_ADD/SUB) x (d=2, d=3) cross bins are excluded from the covergroup.
    The test vectors are still emitted (they hit d=1 instead).
    """
    mb = _max_biased(E)
    one = _one(E, M, bias)

    for d in range(-3, 4):
        for sign in (0, 1):
            for rm in ROUND_MODES:
                if d <= 0:
                    a_pos = _at_biased_exp(0, mb + d, E, M)
                    a_neg = _at_biased_exp(1, mb + d, E, M)
                    a = a_neg if sign == 1 else a_pos  # dominant operand
                    an = a_pos if sign == 1 else a_neg  # negated dominant (for FN* ops)

                    _emit(const.OP_ADD, rm, a, ZERO_PAD, ZERO_PAD, fmt, test_f, cover_f, config)
                    _emit(const.OP_SUB, rm, a, ZERO_PAD, ZERO_PAD, fmt, test_f, cover_f, config)
                    _emit(const.OP_MUL, rm, a, one, ZERO_PAD, fmt, test_f, cover_f, config)
                    _emit(const.OP_DIV, rm, a, one, ZERO_PAD, fmt, test_f, cover_f, config)
                    _emit(const.OP_FMADD, rm, a, one, ZERO_PAD, fmt, test_f, cover_f, config)
                    _emit(const.OP_FMSUB, rm, a, one, ZERO_PAD, fmt, test_f, cover_f, config)
                    # FNMADD: -(an x 1) - 0 = -an.  For sign=0: an=a_neg, so -an = +a_pos ✓
                    #                                 For sign=1: an=a_pos, so -an = -a_pos ✓
                    _emit(const.OP_FNMADD, rm, an, one, ZERO_PAD, fmt, test_f, cover_f, config)
                    _emit(const.OP_FNMSUB, rm, an, one, ZERO_PAD, fmt, test_f, cover_f, config)

                else:  # d > 0
                    scale = _pow2(d, E, M, bias)  # +2^d
                    scale_inv = _pow2(-d, E, M, bias)  # +2^(-d)

                    mn = _maxnorm(0, E, M)  # +MaxNorm
                    mn_neg = _maxnorm(1, E, M)  # -MaxNorm

                    # Dominant: +MaxNorm for sign=0, -MaxNorm for sign=1
                    a = mn_neg if sign == 1 else mn
                    # For FNMADD/FNMSUB: need the opposite sign to produce correct sign
                    # -(a x 2^d) should equal ±MaxNormx2^d with the desired sign
                    an = mn if sign == 1 else mn_neg

                    # ADD: MaxNorm + MaxNorm (reaches d=1 intermediate; structural
                    #      impossibility for d>1, covergroup excludes those bins)
                    mn_for_add = mn_neg if sign == 1 else mn
                    _emit(const.OP_ADD, rm, mn_for_add, mn_for_add, ZERO_PAD, fmt, test_f, cover_f, config)
                    # SUB: MaxNorm - (-MaxNorm) = 2*MaxNorm
                    mn_for_sub_b = mn if sign == 1 else mn_neg
                    _emit(const.OP_SUB, rm, mn_for_add, mn_for_sub_b, ZERO_PAD, fmt, test_f, cover_f, config)

                    _emit(const.OP_MUL, rm, a, scale, ZERO_PAD, fmt, test_f, cover_f, config)
                    _emit(const.OP_DIV, rm, a, scale_inv, ZERO_PAD, fmt, test_f, cover_f, config)
                    _emit(const.OP_FMADD, rm, a, scale, ZERO_PAD, fmt, test_f, cover_f, config)
                    _emit(const.OP_FMSUB, rm, a, scale, ZERO_PAD, fmt, test_f, cover_f, config)
                    # FNMADD: -(an x 2^d) - 0.  For sign=0: an=mn_neg, -(-Mnx2^d)=+Mnx2^d ✓
                    #                             For sign=1: an=mn,    -(+Mnx2^d)=-Mnx2^d ✓
                    _emit(const.OP_FNMADD, rm, an, scale, ZERO_PAD, fmt, test_f, cover_f, config)
                    _emit(const.OP_FNMSUB, rm, an, scale, ZERO_PAD, fmt, test_f, cover_f, config)


def _generate_group3_mul_factors(
    _fmt: str, E: int, M: int, bias: int, _rm: str
) -> Generator[tuple[str, str], None, None]:
    """Generator for the factors used in the group 3 multiplication test"""

    mb = _max_biased(E)
    one = _one(E, M, bias)

    for d in range(-3, 4):
        for sign in (0, 1):
            if d <= 0:
                a_pos = _at_biased_exp(0, mb + d, E, M)
                a_neg = _at_biased_exp(1, mb + d, E, M)
                a = a_neg if sign == 1 else a_pos  # dominant operand

                yield (a, one)
            else:  # d > 0
                scale = _pow2(d, E, M, bias)  # +2^d

                mn = _maxnorm(0, E, M)  # +MaxNorm
                mn_neg = _maxnorm(1, E, M)  # -MaxNorm

                # Dominant: +MaxNorm for sign=0, -MaxNorm for sign=1
                a = mn_neg if sign == 1 else mn
                yield (a, scale)


# ---------------------------------------------------------------------------
# B18 helper: raw MUL operands
# ---------------------------------------------------------------------------


def get_mul_inputs(fmt: str, rm: str) -> Generator[tuple[str, str], None, None]:
    E, M, bias = _fmt_params(fmt)
    random.seed(reproducible_hash("B4{fmt}{rm}"))
    yield from _generate_group1b_mul_factors(fmt, E, M, bias, rm)
    yield from _generate_group2_mul_factors(fmt, E, M, bias, rm)
    yield from _generate_group3_mul_factors(fmt, E, M, bias, rm)


def _group1_converts(fmt: str, E: int, M: int, bias: int, test_f: TextIO, cover_f: TextIO, config: Config) -> None:
    # Generate CFF Tests between MaxNorm - 3ulp and MaxNorm + 3ulp

    for target in const.FLOAT_FMTS:
        target_E, target_M, target_bias = _fmt_params(target)

        if target_E > E or (target in [const.FMT_HALF, const.FMT_SINGLE] and fmt == const.FMT_BF16) or (fmt == target):
            # Then the conversion is widening
            continue

        for sign, (lsb_zero, gs), rm in itertools.product((0, 1), _LGS_CONFIGS, ROUND_MODES):
            target_max_norm_exp = _unbiased_max(target_E, target_bias)
            exp = target_max_norm_exp
            mantissa_diff = M - target_M

            lsb_one = not lsb_zero
            mantissa = ((((1 << target_M - 1) - 1) << 1 | lsb_one) << mantissa_diff) | gs << (mantissa_diff - 2)

            a = _fp_hex(sign, exp + bias, mantissa, E, M)

            _emit_convert(const.OP_CFF, rm, a, fmt, target, test_f, cover_f, config)


def _group2_converts(fmt: str, E: int, M: int, bias: int, test_f: TextIO, cover_f: TextIO, config: Config) -> None:
    # A Random Number Larger than MaxNorm + 3 ulp

    for target in const.FLOAT_FMTS:
        target_E, target_M, target_bias = _fmt_params(target)

        if target_E > E or (fmt == target) or (fmt == const.FMT_BF16 and target == const.FMT_SINGLE):
            # Then the conversion is widening
            continue

        for sign, rm in itertools.product((0, 1), ROUND_MODES):
            target_max_norm_exp = _unbiased_max(target_E, target_bias)
            exp = target_max_norm_exp + 1
            mantissa_diff = max(M - target_M, 0)

            mantissa = random.randint(4 << mantissa_diff, (1 << M) - 1)

            a = _fp_hex(sign, exp + bias, mantissa, E, M)

            _emit_convert(const.OP_CFF, rm, a, fmt, target, test_f, cover_f, config)


def _group3_converts(fmt: str, E: int, M: int, bias: int, test_f: TextIO, cover_f: TextIO, config: Config) -> None:
    # Numbers with exponent in the range MaxNorm.Exp +- 3

    for target in const.FLOAT_FMTS:
        target_E, _target_M, target_bias = _fmt_params(target)

        if target_E > E or (fmt == target) or (fmt == const.FMT_BF16 and target == const.FMT_SINGLE):
            # Then the conversion is widening
            continue

        for offset, sign, rm in itertools.product(range(-3, 4), (0, 1), ROUND_MODES):
            target_max_norm_exp = _unbiased_max(target_E, target_bias)
            exp = target_max_norm_exp + offset

            mantissa = random.getrandbits(M)

            a = _fp_hex(sign, exp + bias, mantissa, E, M)

            _emit_convert(const.OP_CFF, rm, a, fmt, target, test_f, cover_f, config)


# ---------------------------------------------------------------------------
# Top-level
# ---------------------------------------------------------------------------


def generate_b4_tests_arithmetic(test_f: TextIO, cover_f: TextIO, config: Config, fmt: str) -> None:
    E, M, bias = _fmt_params(fmt)
    _group1a_tk(fmt, E, M, bias, test_f, cover_f, config)
    _group1b_arithmetic(fmt, E, M, bias, test_f, cover_f, config)
    _group1b_mul_div(fmt, E, M, bias, test_f, cover_f, config)
    _group2_clear_overflow(fmt, E, M, bias, test_f, cover_f, config)
    _group3_exp_sweep(fmt, E, M, bias, test_f, cover_f, config)


def generate_b4_tests_converts(test_f: TextIO, cover_f: TextIO, config: Config, fmt: str) -> None:
    E, M, bias = _fmt_params(fmt)
    _group1_converts(fmt, E, M, bias, test_f, cover_f, config)
    _group2_converts(fmt, E, M, bias, test_f, cover_f, config)
    _group3_converts(fmt, E, M, bias, test_f, cover_f, config)


@register_model("B4")
def main(config: Config, test_f: TextIO, cover_f: TextIO) -> None:
    for fmt in const.FLOAT_FMTS:
        random.seed(reproducible_hash(f"B4 {fmt}"))
        generate_b4_tests_arithmetic(test_f, cover_f, config, fmt)
        generate_b4_tests_converts(test_f, cover_f, config, fmt)
