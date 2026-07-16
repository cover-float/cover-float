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

# B19 - Compare: Different Input Fields Relations
# Aharoni et al.
#
# This model checks various possible differences between two inputs for
# comparison and min/max operations. Test cases are generated for each
# combination of exponent and significand relationship constraints.
#
# Total vectors: 2700 (108 per format x op, across 5 formats and 5 operations)

import random
from typing import TextIO

import cover_float.common.constants as const
from cover_float.common.config import Config
from cover_float.common.util import reproducible_hash
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model

OPS = [const.OP_FEQ, const.OP_FLT, const.OP_FLE, const.OP_MIN, const.OP_MAX]

# ---------------------------------------------------------------------------
# Format helpers
# ---------------------------------------------------------------------------


def _fmt_params(fmt: str) -> tuple[int, int, int]:
    """Return (min_norm_bexp, max_norm_bexp, frac_max) for the format."""
    max_bexp = (1 << const.EXPONENT_BITS[fmt]) - 1
    min_norm_bexp = 1
    max_norm_bexp = max_bexp - 1
    frac_max = (1 << const.MANTISSA_BITS[fmt]) - 1
    return min_norm_bexp, max_norm_bexp, frac_max


def _any_frac(fmt: str) -> int:
    """Seeded random mid-range fraction: 00..001 < any_frac < all_ones."""
    frac_max = (1 << const.MANTISSA_BITS[fmt]) - 1
    return random.randint(2, frac_max - 1)


def _any_exp(fmt: str) -> int:
    """Seeded random mid-range exponent: min_norm_bexp < any_exp < max_norm_bexp."""
    max_bexp = (1 << const.EXPONENT_BITS[fmt]) - 1
    max_norm_bexp = max_bexp - 1
    return random.randint(2, max_norm_bexp - 1)


def _build(fmt: str, sign: int, bexp: int, frac: int) -> str:
    """Pack sign/biased-exp/frac into a 128-bit (32 hex char) string."""
    bits = f"{sign:01b}{bexp:0{const.EXPONENT_BITS[fmt]}b}{frac:0{const.MANTISSA_BITS[fmt]}b}"
    return f"{int(bits, 2):032X}"


def _emit(
    fmt: str,
    op: str,
    test_f: TextIO,
    cover_f: TextIO,
    config: Config,
    s1: int,
    bexp1: int,
    frac1: int,
    s2: int,
    bexp2: int,
    frac2: int,
) -> None:
    hex1 = _build(fmt, s1, bexp1, frac1)
    hex2 = _build(fmt, s2, bexp2, frac2)
    run_and_store_test_vector(
        f"{op}_{const.ROUND_NEAR_EVEN}_{hex1}_{hex2}_{32 * '0'}_{fmt}_{32 * '0'}_{fmt}_00",
        test_f,
        cover_f,
        config,
    )


# ---------------------------------------------------------------------------
# Case functions
# ---------------------------------------------------------------------------


def _case_1_normal_x_normal(fmt: str, op: str, test_f: TextIO, cover_f: TextIO, config: Config) -> int:
    """Case 1: +/-Normal x +/-Normal.  9 cells x 4 sign combos = 36."""
    min_nb, max_nb, frac_max = _fmt_params(fmt)
    Z = 0  # all zeros
    ALL_ONES = frac_max  # all ones
    count = 0

    # Exp >: bexp1 = max_norm_bexp, bexp2 = any exp
    for frac1, frac2 in [
        (_any_frac(fmt), Z),  # sig >
        (Z, _any_frac(fmt)),  # sig <
        (Z, Z),  # sig =
    ]:
        bexp2 = _any_exp(fmt)
        for s1 in (0, 1):
            for s2 in (0, 1):
                _emit(fmt, op, test_f, cover_f, config, s1, max_nb, frac1, s2, bexp2, frac2)
                count += 1

    # Exp <: bexp1 = min_norm_bexp, bexp2 = any exp
    for frac1, frac2 in [
        (ALL_ONES, _any_frac(fmt)),  # sig >
        (_any_frac(fmt), ALL_ONES),  # sig <
        (ALL_ONES, ALL_ONES),  # sig =
    ]:
        bexp2 = _any_exp(fmt)
        for s1 in (0, 1):
            for s2 in (0, 1):
                _emit(fmt, op, test_f, cover_f, config, s1, min_nb, frac1, s2, bexp2, frac2)
                count += 1

    # Exp =: bexp1 = bexp2 = any exp (same value)
    for frac1, frac2 in [
        (ALL_ONES, Z),  # sig >
        (Z, ALL_ONES),  # sig <
        (Z, Z),  # sig =
    ]:
        bexp = _any_exp(fmt)
        for s1 in (0, 1):
            for s2 in (0, 1):
                _emit(fmt, op, test_f, cover_f, config, s1, bexp, frac1, s2, bexp, frac2)
                count += 1

    return count


def _case_2_normal_x_subnormal(fmt: str, op: str, test_f: TextIO, cover_f: TextIO, config: Config) -> int:
    """Case 2: +/-Normal x +/-SubNormal.  3 cells x 4 sign combos = 12."""
    af = _any_frac(fmt)
    bexp1 = _any_exp(fmt)
    lsb = 1  # 00..001
    count = 0
    msb = 1 << (const.MANTISSA_BITS[fmt] - 1)  # 10000..000

    for frac1, frac2 in [
        (af, lsb),  # sig >
        (lsb, af),  # sig <  (all zeros vs 00..001)
        (0, msb),  # sig =  (same any_frac for both fields)
    ]:
        for s1 in (0, 1):
            for s2 in (0, 1):
                _emit(fmt, op, test_f, cover_f, config, s1, bexp1, frac1, s2, 0, frac2)
                count += 1

    return count


def _case_3_subnormal_x_normal(fmt: str, op: str, test_f: TextIO, cover_f: TextIO, config: Config) -> int:
    """Case 3: +/-SubNormal x +/-Normal.  3 cells x 4 sign combos = 12."""
    _, _, frac_max = _fmt_params(fmt)
    af = _any_frac(fmt)
    bexp2 = _any_exp(fmt)
    ALL_ONES = frac_max  # all ones
    msb = 1 << (const.MANTISSA_BITS[fmt] - 1)  # 10000..000
    count = 0

    for frac1, frac2 in [
        (ALL_ONES, 0),  # sig >  (all ones vs all zeros)
        (af, ALL_ONES),  # sig <
        (msb, 0),  # sig =  (same any_frac for both fields)
    ]:
        for s1 in (0, 1):
            for s2 in (0, 1):
                _emit(fmt, op, test_f, cover_f, config, s1, 0, frac1, s2, bexp2, frac2)
                count += 1

    return count


def _case_4_subnormal_x_subnormal(fmt: str, op: str, test_f: TextIO, cover_f: TextIO, config: Config) -> int:
    """Case 4: +/-SubNormal x +/-SubNormal.  5 cells x 4 sign combos = 20."""
    _, _, frac_max = _fmt_params(fmt)
    af = _any_frac(fmt)
    lsb = 1  # 00..001
    msb = 1 << (const.MANTISSA_BITS[fmt] - 1)  # 10000..000
    ALL_ONES = frac_max  # all ones
    count = 0

    for frac1, frac2 in [
        (af, lsb),  # exp >, sig >
        (msb, af >> 1),  # exp >, sig <
        (msb, lsb),  # exp >, sig =
        (lsb, af),  # exp <, sig <
        (af >> 1, msb),  # exp <, sig >
        (lsb, msb),  # exp <, sig =
        (ALL_ONES, msb),  # exp =, sig >
        (msb, ALL_ONES),  # exp =, sig <
        (af, af),  # exp =, sig =  (same any_frac)
    ]:
        for s1 in (0, 1):
            for s2 in (0, 1):
                _emit(fmt, op, test_f, cover_f, config, s1, 0, frac1, s2, 0, frac2)
                count += 1

    return count


def _case_5_zero_x_normal(fmt: str, op: str, test_f: TextIO, cover_f: TextIO, config: Config) -> int:
    """Case 5: +/-Zero x +/-Normal.  2 cells x 4 sign combos = 8."""
    af = _any_frac(fmt)
    bexp2 = _any_exp(fmt)
    count = 0

    for frac2 in [
        af,  # sig <  (zero frac=0 < any_frac)
        0,  # sig =  (zero frac=0 == all zeros)
    ]:
        for s1 in (0, 1):
            for s2 in (0, 1):
                _emit(fmt, op, test_f, cover_f, config, s1, 0, 0, s2, bexp2, frac2)
                count += 1

    return count


def _case_6_normal_x_zero(fmt: str, op: str, test_f: TextIO, cover_f: TextIO, config: Config) -> int:
    """Case 6: +/-Normal x +/-Zero.  2 cells x 4 sign combos = 8."""
    af = _any_frac(fmt)
    bexp1 = _any_exp(fmt)
    count = 0

    for frac1 in [
        af,  # sig >  (any_frac > zero frac=0)
        0,  # sig =  (all zeros == zero frac=0)
    ]:
        for s1 in (0, 1):
            for s2 in (0, 1):
                _emit(fmt, op, test_f, cover_f, config, s1, bexp1, frac1, s2, 0, 0)
                count += 1

    return count


def _case_7_zero_x_subnormal(fmt: str, op: str, test_f: TextIO, cover_f: TextIO, config: Config) -> int:
    """Case 7: +/-Zero x +/-Subnormal.  1 cell x 4 sign combos = 4."""
    af = _any_frac(fmt)
    count = 0
    msb = 1 << (const.MANTISSA_BITS[fmt] - 1)  # 10000..000

    for frac2 in [
        af,  # sig <  (zero frac=0 < any_frac)
        msb,
    ]:
        for s1 in (0, 1):
            for s2 in (0, 1):
                _emit(fmt, op, test_f, cover_f, config, s1, 0, 0, s2, 0, frac2)
                count += 1

    return count


def _case_8_subnormal_x_zero(fmt: str, op: str, test_f: TextIO, cover_f: TextIO, config: Config) -> int:
    """Case 8: +/-Subnormal x +/-Zero.  1 cell x 4 sign combos = 4."""
    af = _any_frac(fmt)
    count = 0
    msb = 1 << (const.MANTISSA_BITS[fmt] - 1)  # 10000..000

    for frac1 in [
        af,  # sig >  (any_frac > zero frac=0)
        msb,
    ]:
        for s1 in (0, 1):
            for s2 in (0, 1):
                _emit(fmt, op, test_f, cover_f, config, s1, 0, frac1, s2, 0, 0)
                count += 1

    return count


def _case_9_zero_x_zero(fmt: str, op: str, test_f: TextIO, cover_f: TextIO, config: Config) -> int:
    """Case 9: +/-Zero x +/-Zero.  1 cell x 4 sign combos = 4."""
    count = 0
    for s1 in (0, 1):
        for s2 in (0, 1):
            _emit(fmt, op, test_f, cover_f, config, s1, 0, 0, s2, 0, 0)
            count += 1
    return count


# ---------------------------------------------------------------------------
# Top-level entry points
# ---------------------------------------------------------------------------


def generate_b19_tests(test_f: TextIO, cover_f: TextIO, config: Config, fmt: str) -> None:
    """Generate all B19 test vectors for a given format."""
    for op in OPS:
        random.seed(reproducible_hash(f"B19 {fmt} {op}"))
        _c1 = _case_1_normal_x_normal(fmt, op, test_f, cover_f, config)
        _c2 = _case_2_normal_x_subnormal(fmt, op, test_f, cover_f, config)
        _c3 = _case_3_subnormal_x_normal(fmt, op, test_f, cover_f, config)
        _c4 = _case_4_subnormal_x_subnormal(fmt, op, test_f, cover_f, config)
        _c5 = _case_5_zero_x_normal(fmt, op, test_f, cover_f, config)
        _c6 = _case_6_normal_x_zero(fmt, op, test_f, cover_f, config)
        _c7 = _case_7_zero_x_subnormal(fmt, op, test_f, cover_f, config)
        _c8 = _case_8_subnormal_x_zero(fmt, op, test_f, cover_f, config)
        _c9 = _case_9_zero_x_zero(fmt, op, test_f, cover_f, config)


@register_model("B19")
def main(config: Config, test_f: TextIO, cover_f: TextIO) -> None:
    for fmt in const.FLOAT_FMTS:
        generate_b19_tests(test_f, cover_f, config, fmt)
