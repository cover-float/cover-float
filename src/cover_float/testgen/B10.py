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
# B10 Model
# This model tests every possible value for a shift between the input operands

import random
from random import seed
from typing import TextIO

from cover_float.common.constants import (
    BIASED_EXP,
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


def decimalComponentsToHex(fmt: str, biased_exp: int) -> str:
    b_sign = f"{random.randint(0, 1)}"
    b_exponent = f"{biased_exp:0{EXPONENT_BITS[fmt]}b}"
    b_mantissa = f"{random.getrandbits(MANTISSA_BITS[fmt]):0{MANTISSA_BITS[fmt]}b}"
    b_complete = b_sign + b_exponent + b_mantissa
    h_complete = f"{int(b_complete, 2):032X}"
    return h_complete


def innerTest(test_f: TextIO, cover_f: TextIO, op: str) -> None:
    for fmt in FLOAT_FMTS:
        p = MANTISSA_BITS[fmt] + 1
        min_exp = BIASED_EXP[fmt][0]
        max_exp = BIASED_EXP[fmt][1]

        hashval = reproducible_hash(op + fmt + "b10")
        seed(hashval)
        # Incrementing b_exp

        a_exp = random.randint(min_exp, max_exp - (p + 4))
        b_exp = a_exp

        for _ in range(0, p + 5):
            complete_a = decimalComponentsToHex(fmt, a_exp)
            complete_b = decimalComponentsToHex(fmt, b_exp)

            run_and_store_test_vector(
                f"{op}_{ROUND_NEAR_EVEN}_{complete_a}_{complete_b}_{32 * '0'}_{fmt}_{32 * '0'}_{fmt}_00",
                test_f,
                cover_f,
            )

            b_exp += 1  # Final statement, increments 1 over

        # Decrementing b_exp

        a_exp = random.randint(min_exp + (p + 4), max_exp)
        b_exp = a_exp - 1

        for _ in range(0, p + 4):
            complete_a = decimalComponentsToHex(fmt, a_exp)
            complete_b = decimalComponentsToHex(fmt, b_exp)
            run_and_store_test_vector(
                f"{op}_{ROUND_NEAR_EVEN}_{complete_a}_{complete_b}_{32 * '0'}_{fmt}_{32 * '0'}_{fmt}_00",
                test_f,
                cover_f,
            )

            b_exp -= 1  # Final statement, decrements 1 under


def outerTest(isTestOne: bool, test_f: TextIO, cover_f: TextIO, op: str) -> None:
    for fmt in FLOAT_FMTS:
        p = MANTISSA_BITS[fmt] + 1
        min_exp = BIASED_EXP[fmt][0]
        max_exp = BIASED_EXP[fmt][1]
        max_a_exp = max_exp - (p + 5)

        hashval = reproducible_hash(op + fmt + "b10")
        seed(hashval)

        a_exp = random.randint(min_exp, max_a_exp)
        b_exp_nums = max_a_exp - a_exp
        min_b_exp = max_exp - b_exp_nums
        b_exp = random.randint(min_b_exp, max_exp)

        complete_a = decimalComponentsToHex(fmt, a_exp)
        complete_b = decimalComponentsToHex(fmt, b_exp)

        if isTestOne:
            run_and_store_test_vector(
                f"{op}_{ROUND_NEAR_EVEN}_{complete_a}_{complete_b}_{32 * '0'}_{fmt}_{32 * '0'}_{fmt}_00",
                test_f,
                cover_f,
            )
        else:
            run_and_store_test_vector(
                f"{op}_{ROUND_NEAR_EVEN}_{complete_b}_{complete_a}_{32 * '0'}_{fmt}_{32 * '0'}_{fmt}_00",
                test_f,
                cover_f,
            )


@register_model("B10")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    for op in [OP_ADD, OP_SUB]:
        outerTest(True, test_f, cover_f, op)  # Test #1
        innerTest(test_f, cover_f, op)  # Test #2
        outerTest(False, test_f, cover_f, op)  # Test #3
