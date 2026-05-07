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

Created:         April 8, 2026
Last Edited:     April 10, 2026
"""

import logging
import random
from random import seed
from typing import Callable, TextIO, cast

import cover_float.common.log as log
from cover_float.common.constants import (
    BIAS,
    BIASED_EXP,
    EXPONENT_BITS,
    FLOAT_FMTS,
    MANTISSA_BITS,
    OP_ADD,
    OP_DIV,
    OP_FMADD,
    OP_FMSUB,
    OP_FNMADD,
    OP_FNMSUB,
    OP_MUL,
    OP_SQRT,
    OP_SUB,
)
from cover_float.common.util import (
    decimal_components_to_hex,
    generate_test_vector,
    get_result_from_ref,
    reproducible_hash,
)
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model

logger: log.ModelLogger = cast(log.ModelLogger, logging.getLogger("B2"))

ZERO = "0" * 32


class Generator:
    MAX_TRIES = 20

    def __init__(self, fmt: str) -> None:
        self.fmt = fmt
        self.m_bits = MANTISSA_BITS[fmt]
        self.bias = BIAS[fmt]
        self.max_exp = BIASED_EXP[fmt][1]

    def random_fp(self, exp_range: tuple[int, int]) -> str:
        return decimal_components_to_hex(
            self.fmt,
            random.randint(0, 1),
            random.randint(*exp_range),
            random.getrandbits(self.m_bits),
        )

    def random_fp_with_sign_and_exp(self, exp: int, sign: int) -> str:
        return decimal_components_to_hex(
            self.fmt,
            sign,
            exp,
            random.getrandbits(self.m_bits),
        )

    def solve_exact(
        self,
        op: str,
        desired: str,
        builder: Callable[[], tuple[str, str, str]],
    ) -> tuple[str, str, str]:

        a, b, c = builder()
        last = (a, b, c)

        for _ in range(self.MAX_TRIES):
            a, b, c = builder()
            result = get_result_from_ref(op, a, b, c, self.fmt)
            if result == desired.lower():
                return a, b, c
            last = (a, b, c)

        a, _, _ = last
        b = get_result_from_ref(OP_SUB, desired, a, ZERO, self.fmt)
        return a, b, ZERO

    def gen_add(self, desired: str, base_e: int, maxnorm: bool, sign: int) -> tuple[str, str, str]:
        neg_zero = decimal_components_to_hex(self.fmt, 1, 0, 0)

        def builder() -> tuple[str, str, str]:
            if desired == neg_zero:
                return neg_zero, neg_zero, ZERO

            a_sign = sign if maxnorm else random.randint(0, 1)

            a = self.random_fp_with_sign_and_exp(base_e, a_sign)
            b = get_result_from_ref(OP_SUB, desired, a, ZERO, self.fmt)
            return a, b, ZERO

        return self.solve_exact(OP_ADD, desired, builder)

    def gen_sub(self, desired: str, base_e: int, maxnorm: bool, sign: int) -> tuple[str, str, str]:
        neg_zero = decimal_components_to_hex(self.fmt, 1, 0, 0)
        pos_zero = decimal_components_to_hex(self.fmt, 0, 0, 0)

        def builder() -> tuple[str, str, str]:
            if desired == neg_zero:
                return neg_zero, pos_zero, ZERO

            a_sign = sign if maxnorm else random.randint(0, 1)

            a = self.random_fp_with_sign_and_exp(base_e, a_sign)
            b = get_result_from_ref(OP_SUB, a, desired, ZERO, self.fmt)
            return a, b, ZERO

        return self.solve_exact(OP_SUB, desired, builder)

    def gen_mul(self, desired: str, maxnorm: bool, sign: int) -> tuple[str, str, str]:
        exp_range = (self.bias, self.max_exp) if maxnorm else (1, self.bias)

        def builder() -> tuple[str, str, str]:
            a = self.random_fp(exp_range)
            b = get_result_from_ref(OP_DIV, desired, a, ZERO, self.fmt)
            return a, b, ZERO

        return self.solve_exact(OP_MUL, desired, builder)

    def gen_div(self, desired: str, maxnorm: bool, sign: int) -> tuple[str, str, str]:
        exp_range = (self.bias, self.max_exp) if maxnorm else (1, self.bias)

        def builder() -> tuple[str, str, str]:
            a = self.random_fp(exp_range)
            b = get_result_from_ref(OP_DIV, a, desired, ZERO, self.fmt)
            return a, b, ZERO

        return self.solve_exact(OP_DIV, desired, builder)

    def gen_sqrt(self, desired: str) -> tuple[str, str, str]:
        def builder() -> tuple[str, str, str]:
            a = get_result_from_ref(OP_MUL, desired, desired, ZERO, self.fmt)
            return a, ZERO, ZERO

        return self.solve_exact(OP_SQRT, desired, builder)

    def gen_fma(self, op: str, desired: str, base_e: int, maxnorm: bool) -> tuple[str, str, str]:

        def builder() -> tuple[str, str, str]:
            a_exp = random.randint(self.bias, self.max_exp) if maxnorm else random.randint(1, self.bias)
            b_exp = base_e - a_exp + self.bias

            a = decimal_components_to_hex(self.fmt, random.randint(0, 1), a_exp, random.getrandbits(self.m_bits))
            b = decimal_components_to_hex(self.fmt, random.randint(0, 1), b_exp, random.getrandbits(self.m_bits))

            if op == OP_FMADD:
                c = get_result_from_ref(OP_FNMSUB, a, b, desired, self.fmt)
            elif op == OP_FMSUB:
                c = get_result_from_ref(OP_FMSUB, a, b, desired, self.fmt)
            elif op == OP_FNMADD:
                c = get_result_from_ref(OP_FNMADD, a, b, desired, self.fmt)
            else:
                c = get_result_from_ref(OP_FMADD, a, b, desired, self.fmt)

            return a, b, c

        return self.solve_exact(op, desired, builder)


@register_model("B2")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    for fmt in FLOAT_FMTS:
        gen = Generator(fmt)

        bases = {
            "Zero": (0, 0),
            "One": (0, (1 << (EXPONENT_BITS[fmt] - 1)) - 1),
            "MinSub": (1, 0),
            "MaxSub": ((1 << gen.m_bits) - 1, 0),
            "MinNorm": (0, 1),
            "MaxNorm": ((1 << gen.m_bits) - 1, (1 << EXPONENT_BITS[fmt]) - 2),
        }

        for base, (base_m, base_e) in bases.items():
            maxnorm = base == "MaxNorm"

            for i in range(gen.m_bits):
                for sign in [0, 1]:
                    desired = decimal_components_to_hex(fmt, sign, base_e, base_m ^ (1 << i))
                    seed(reproducible_hash(f"{fmt}_{base}_{i}_{sign}"))

                    a, b, c = gen.gen_add(desired, base_e, maxnorm, sign)
                    vec = generate_test_vector(OP_ADD, int(a, 16), int(b, 16), int(c, 16), fmt, fmt)
                    run_and_store_test_vector(vec, test_f, cover_f)

                    a, b, c = gen.gen_sub(desired, base_e, maxnorm, sign)
                    vec = generate_test_vector(OP_SUB, int(a, 16), int(b, 16), int(c, 16), fmt, fmt)
                    run_and_store_test_vector(vec, test_f, cover_f)

                    a, b, c = gen.gen_mul(desired, maxnorm, sign)
                    vec = generate_test_vector(OP_MUL, int(a, 16), int(b, 16), int(c, 16), fmt, fmt)
                    run_and_store_test_vector(vec, test_f, cover_f)

                    a, b, c = gen.gen_div(desired, maxnorm, sign)
                    vec = generate_test_vector(OP_DIV, int(a, 16), int(b, 16), int(c, 16), fmt, fmt)
                    run_and_store_test_vector(vec, test_f, cover_f)

                    if sign == 0 and base == "One":
                        a, b, c = gen.gen_sqrt(desired)
                        vec = generate_test_vector(OP_SQRT, int(a, 16), int(b, 16), int(c, 16), fmt, fmt)
                        run_and_store_test_vector(vec, test_f, cover_f)

                    for op in [OP_FMADD, OP_FMSUB, OP_FNMADD, OP_FNMSUB]:
                        a, b, c = gen.gen_fma(op, desired, base_e, maxnorm)
                        vec = generate_test_vector(op, int(a, 16), int(b, 16), int(c, 16), fmt, fmt)
                        run_and_store_test_vector(vec, test_f, cover_f)

            # for -0 cases
            if base == "Zero":
                desired = decimal_components_to_hex(fmt, 1, 0, 0)

                seed(reproducible_hash(f"{fmt}_zero_add_1"))
                a, b, c = gen.gen_add(desired, 0, False, 1)
                vec = generate_test_vector(OP_ADD, int(a, 16), int(b, 16), int(c, 16), fmt, fmt)
                run_and_store_test_vector(vec, test_f, cover_f)

                seed(reproducible_hash(f"{fmt}_zero_sub_1"))
                a, b, c = gen.gen_sub(desired, 0, False, 1)
                vec = generate_test_vector(OP_SUB, int(a, 16), int(b, 16), int(c, 16), fmt, fmt)
                run_and_store_test_vector(vec, test_f, cover_f)
