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

"""
Angela Zheng (angela20061015@gmail.com)

Created:        March 30, 2026
Last Edited:    March 30, 2026
"""

import random
from random import seed
from typing import TextIO

from cover_float.common.constants import (
    EXPONENT_BITS,
    FLOAT_FMTS,
    MANTISSA_BITS,
    OP_ADD,
    OP_SUB,
    ROUND_NEAR_EVEN,
)
from cover_float.common.util import reproducible_hash
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model


# TODO: Investigate d = -1 case.
def decimalComponentsToHex(fmt: str, sign: int, biased_exp: int, mantissa: int) -> str:
    b_sign = f"{sign:01b}"
    b_exp = f"{biased_exp:0{EXPONENT_BITS[fmt]}b}"
    b_man = f"{mantissa:0{MANTISSA_BITS[fmt]}b}"
    bits = b_sign + b_exp + b_man
    return f"{int(bits, 2):032X}"


def writeAdd(fmt: str, a_hex: str, b_hex: str, test_f: TextIO, cover_f: TextIO) -> None:
    run_and_store_test_vector(
        f"{OP_ADD}_{ROUND_NEAR_EVEN}_{a_hex}_{b_hex}_{32 * '0'}_{fmt}_{32 * '0'}_{fmt}_00",
        test_f,
        cover_f,
    )


def writeSub(fmt: str, a_hex: str, b_hex: str, test_f: TextIO, cover_f: TextIO) -> None:
    run_and_store_test_vector(
        f"{OP_SUB}_{ROUND_NEAR_EVEN}_{a_hex}_{b_hex}_{32 * '0'}_{fmt}_{32 * '0'}_{fmt}_00",
        test_f,
        cover_f,
    )


def makeNegPMantissas(fmt: str, m_shifts: int) -> tuple[int, int]:
    """Create mantissas for the most extreme cancellation (d = -p)"""
    m = MANTISSA_BITS[fmt]

    a_m = 0  # A = 1.00...0 (Mantissa 0)
    b_m = ((1 << m) - 1) >> m_shifts  # B = 0.01...1 (Mantissa all 1s)

    return a_m, b_m


def makeCancellationMantissas(fmt: str, d: int, m_shifts: int) -> tuple[int, int]:
    """Generate identical -d bits for both mantissas such that exactly -d bits cancel."""
    m = MANTISSA_BITS[fmt]
    k = -d

    # generate identical prefixes for both operands
    if k > 1:
        a_prefix = 1 << (m - 1 - m_shifts) | random.getrandbits(k - 1) << (m - k - m_shifts)
        b_prefix = a_prefix
    else:
        a_prefix = 0
        b_prefix = 0

    diff_bit = 1 << (m - k - m_shifts - 1)  # differing bit

    # randomly generate tails for both operands
    if k < (m - 1 - m_shifts):
        a_tail = 1 << (m - k - m_shifts - 2) | random.getrandbits(m - k - m_shifts - 2)
        b_tail = random.getrandbits(m - k - m_shifts - 2)
    else:
        a_tail = 0
        b_tail = 0

    a_m = a_prefix | diff_bit | a_tail
    b_m = b_prefix | b_tail

    return a_m, b_m


def makeNoCancelMantissas(fmt: str, m_shifts: int) -> tuple[int, int]:
    """Generate mantissas that result in no bit cancellation (d = 0)"""
    m = MANTISSA_BITS[fmt]

    a_m = ((1 << m) - 1) >> m_shifts
    b_m = (((1 << (m - 1)) - 1) << 1) >> m_shifts

    return a_m, b_m


def makeCarryMantissas(fmt: str, m_shifts: int) -> tuple[int, int]:
    """Generate mantissas that will cause a carry (d = +1)"""
    m = MANTISSA_BITS[fmt]

    a_m = ((1 << m) - 1) >> m_shifts  # 0.011...111
    b_m = a_m  # 0.011...111

    return a_m, b_m


def makeTestVectors(fmt: str, d: int, leading_zeros: int, operation: str, test_f: TextIO, cover_f: TextIO) -> None:
    m = MANTISSA_BITS[fmt]
    p = m + 1

    is_carry = False
    is_add = operation == "add"
    write_fn = writeAdd if is_add else writeSub
    m_shifts = 0

    a_exp = (
        -1
    ) * d - leading_zeros  # if a_exp is less than zero, clips to zero and shifts mantissa to the right by m_shift bits
    if a_exp < 0:
        m_shifts = (-1) * a_exp
        a_exp = 0
    b_exp = a_exp

    # Generate mantissas based on d
    if d == 1:
        is_carry = True
        a_m, b_m = makeCarryMantissas(fmt, m_shifts)
    elif d == 0:
        a_m, b_m = makeNoCancelMantissas(fmt, m_shifts)
        b_m >>= 1  # absorb the exponent shift into mantissa shift
    elif d == -p:
        a_m, b_m = makeNegPMantissas(fmt, m_shifts)
        if a_exp == 0:
            a_exp = 1  # minimum normal, so b_exp = 0 (subnormal) is valid
        b_exp = a_exp - 1  # impossible case is when a_exp = 0
    else:
        a_m, b_m = makeCancellationMantissas(fmt, d, m_shifts)

    # Sign assignments based on whether d is 1
    if is_add:
        if is_carry:
            a_sign = 0
            b_sign = 0
        else:
            a_sign = 0
            b_sign = 1
    else:
        if is_carry:
            a_sign = 0
            b_sign = 1
        else:
            a_sign = 0
            b_sign = 0

    a_hex = decimalComponentsToHex(fmt, a_sign, a_exp, a_m)
    b_hex = decimalComponentsToHex(fmt, b_sign, b_exp, b_m)

    write_fn(fmt, a_hex, b_hex, test_f, cover_f)


def SubnormCancellationTests(test_f: TextIO, cover_f: TextIO, fmt: str) -> None:
    m = MANTISSA_BITS[fmt]
    p = m + 1

    for leading_zeros in range(m):
        for d in range(-p, 2):
            if d == -1 or d == 0 or d == 1:
                if leading_zeros != (m - 1):
                    seed(reproducible_hash(f"{fmt}_b13_add_{d}_{leading_zeros}"))
                    makeTestVectors(fmt, d, leading_zeros, "add", test_f, cover_f)

                    seed(reproducible_hash(f"{fmt}_b13_sub_{d}_{leading_zeros}"))
                    makeTestVectors(fmt, d, leading_zeros, "sub", test_f, cover_f)
            else:
                seed(reproducible_hash(f"{fmt}_b13_add_{d}_{leading_zeros}"))
                makeTestVectors(fmt, d, leading_zeros, "add", test_f, cover_f)

                seed(reproducible_hash(f"{fmt}_b13_sub_{d}_{leading_zeros}"))
                makeTestVectors(fmt, d, leading_zeros, "sub", test_f, cover_f)


@register_model("B13")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    test_f.write("// B13 Cancellation + Subnormal Tests\n")
    test_f.write("// ADD, SUB\n")

    for fmt in FLOAT_FMTS:
        SubnormCancellationTests(test_f, cover_f, fmt)
