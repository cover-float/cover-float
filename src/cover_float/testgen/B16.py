"""
Angela Zheng (angela20061015@gmail.com)

Created: 4/28/2026
Last Modified: 4/28/2026
"""

import logging
import random
from dataclasses import dataclass
from pathlib import Path
from random import seed
from typing import TextIO, cast

import cover_float.common.log as log
from cover_float.common.constants import (
    BIAS,
    EXPONENT_BITS,
    FLOAT_FMTS,
    MANTISSA_BITS,
    OP_FMADD,
    OP_FMSUB,
    OP_FNMADD,
    OP_FNMSUB,
    OP_MUL,
    UNBIASED_EXP,
)
from cover_float.common.util import (
    decimal_components_to_hex,
    generate_test_vector,
    get_result_from_ref,
    reproducible_hash,
)
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model

logger: log.ModelLogger = cast(log.ModelLogger, logging.getLogger("B16"))

OPS = [OP_FMADD, OP_FMSUB, OP_FNMADD, OP_FNMSUB]
SOLVER_OPS = {
    OP_FMADD: OP_FNMSUB,
    OP_FMSUB: OP_FMSUB,
    OP_FNMADD: OP_FNMADD,
    OP_FNMSUB: OP_FMADD,
}


@dataclass(frozen=True)
class FloatFormat:
    name: str
    m_bits: int
    e_bits: int
    bias: int
    min_exp: int
    max_exp: int

    @property
    def p(self) -> int:
        return self.m_bits + 1

    @classmethod
    def from_name(cls, name: str) -> "FloatFormat":
        min_e, max_e = UNBIASED_EXP[name]
        return cls(name, MANTISSA_BITS[name], EXPONENT_BITS[name], BIAS[name], min_e, max_e)

    def to_hex(self, sign: int, exp: int, mant: int) -> str:
        return decimal_components_to_hex(self.name, sign, exp + self.bias, mant)

    def get_exp(self, fp_hex: str) -> int:
        bits = int(fp_hex, 16)
        return ((bits >> self.m_bits) & ((1 << self.e_bits) - 1)) - self.bias


class B16Generator:
    def __init__(self, fmt: str, test_f: TextIO, cover_f: TextIO) -> None:
        self.f = FloatFormat.from_name(fmt)
        self.test_f, self.cover_f = test_f, cover_f

    def get_op_details(self, op: str, a: str, b: str, c: str) -> tuple[int, int]:
        """Helper to get actual product exp and final result exp."""
        p_hex = get_result_from_ref(OP_MUL, a, b, "0", self.f.name)
        r_hex = get_result_from_ref(op, a, b, c, self.f.name)
        return self.f.get_exp(p_hex), self.f.get_exp(r_hex)

    def store(self, op: str, a: str, b: str, c: str) -> None:
        v = generate_test_vector(op, int(a, 16), int(b, 16), int(c, 16), self.f.name, self.f.name)
        run_and_store_test_vector(v, self.test_f, self.cover_f)

    def get_random_split(self, target_exp: int) -> tuple[int, int]:
        """Splits a target product exponent into two valid operand exponents."""
        lo, hi = self.f.min_exp, self.f.max_exp
        a_min, a_max = max(lo, target_exp - hi), min(hi, target_exp - lo)
        a = random.randint(a_min, a_max)
        return a, target_exp - a

    def generate_same_exp(self, d: int, op: str) -> bool:
        f, m = self.f, self.f.m_bits
        a_s, b_s = random.randint(0, 1), random.randint(0, 1)
        c_s = (a_s ^ b_s) if op in [OP_FMADD, OP_FNMADD] else (a_s ^ b_s) ^ 1
        target_p_exp = random.randint(0, f.max_exp)
        a_r = random.randint(0, target_p_exp)
        b_r = target_p_exp - a_r
        c_r = a_r + b_r + 3
        a_m, b_m, c_m = random.getrandbits(m), random.getrandbits(m), random.getrandbits(m)
        a_h = f.to_hex(a_s, a_r, a_m)
        b_h = f.to_hex(b_s, b_r, b_m)
        c_h = f.to_hex(c_s, c_r, c_m)
        r_hex = get_result_from_ref(op, a_h, b_h, c_h, f.name)
        r_exp = f.get_exp(r_hex)
        if r_exp != c_r:
            return False
        self.store(op, a_h, b_h, c_h)
        return True

    def generate_shallow_cancel(self, d: int, op: str) -> bool:
        f, m = self.f, self.f.m_bits
        a_s, b_s = random.randint(0, 1), random.randint(0, 1)

        # pick a safe product exponent away from underflow/overflow
        target_p_exp = random.randint(f.min_exp + 10, f.max_exp - 10)
        a_min = max(f.min_exp + 5, target_p_exp - (f.max_exp - 5))
        a_max = min(f.max_exp - 5, target_p_exp - (f.min_exp + 5))
        a_r = random.randint(a_min, a_max)
        b_r = target_p_exp - a_r

        # use non-extreme mantissas to avoid accidental exponent carry in a*b
        a_m = random.randint(1 << (m - 2), (1 << m) - 1)
        b_m = random.randint(1 << (m - 2), (1 << m) - 1)
        a_h = f.to_hex(a_s, a_r, a_m)
        b_h = f.to_hex(b_s, b_r, b_m)
        p_exp = self.f.get_exp(get_result_from_ref(OP_MUL, a_h, b_h, "0", f.name))
        res_raw = p_exp + d

        # pick a mid-range result mantissa so rounding is less likely to change exponent
        r_s = random.randint(0, 1)
        res_m = random.randint(1 << (m - 2), (1 << (m - 1)) - 1)
        res_h = f.to_hex(r_s, res_raw, res_m)
        c_h = get_result_from_ref(SOLVER_OPS[op], a_h, b_h, res_h, f.name)
        c_exp = f.get_exp(c_h)

        # for shallow cancellation, c should be aligned with the product
        if c_exp != p_exp:
            return False
        # Final validation
        p_exp2, r_exp = self.get_op_details(op, a_h, b_h, c_h)
        if (r_exp - max(p_exp2, c_exp)) == d:
            self.store(op, a_h, b_h, c_h)
            return True
        return False

    def generate_deep_cancel(self, d: int, op: str) -> bool:
        f = self.f
        a_s, b_s, r_s = random.randint(0, 1), random.randint(0, 1), random.randint(0, 1)
        res_raw, res_m, a_m, b_m = f.min_exp - 1, 0, 0, 0
        target_p_exp = res_raw - d
        split = self.get_random_split(target_p_exp)
        a_r, b_r = split
        a_h, b_h = f.to_hex(a_s, a_r, a_m), f.to_hex(b_s, b_r, b_m)
        p_exp = self.f.get_exp(get_result_from_ref(OP_MUL, a_h, b_h, "0", f.name))
        res_h = f.to_hex(r_s, p_exp + d, res_m)
        c_h = get_result_from_ref(SOLVER_OPS[op], a_h, b_h, res_h, f.name)
        p_exp, r_exp = self.get_op_details(op, a_h, b_h, c_h)
        c_exp = f.get_exp(c_h)
        if (r_exp - max(p_exp, c_exp)) == d:
            self.store(op, a_h, b_h, c_h)
            return True
        return False

    def generate(self, d: int, op: str) -> bool:
        f, m = self.f, self.f.m_bits
        a_s, b_s, r_s = random.randint(0, 1), random.randint(0, 1), random.randint(0, 1)

        if d <= -(2 * f.p - 1):
            return self.generate_deep_cancel(d, op)
        elif d in [-6, -5, -4, -3, -2, -1]:
            return self.generate_shallow_cancel(d, op)
        elif d == 0:
            return self.generate_same_exp(d, op)
        elif d == 1:  # need result > operands
            a_raw, b_raw = random.randint(0, f.max_exp // 2), random.randint(0, f.max_exp // 2)
            c_s = 0 if op in [OP_FMADD, OP_FNMADD] else 1
            a_h = f.to_hex(a_s, a_raw, random.getrandbits(m))
            b_h = f.to_hex(a_s, b_raw, random.getrandbits(m))
            c_h = f.to_hex(c_s, a_raw + b_raw + 1, (1 << m) - 1)
            self.store(op, a_h, b_h, c_h)
            return True
        else:
            valid_lo = max(f.min_exp, (f.min_exp - 1) - d)
            valid_hi = min(f.max_exp, f.max_exp - d)
            target_p_exp = random.randint(valid_lo, valid_hi)

        # generate a and b
        split = self.get_random_split(target_p_exp)
        a_r, b_r = split

        # special mantissas for deep cancellation
        if d < -m:
            target_depth = abs(d)
            k = max(0, 2 * m - target_depth) // 2
            a_m, b_m, res_m = 1 << k, 1 << (max(0, 2 * m - target_depth) - k), 0
        else:
            a_m, b_m, res_m = [random.getrandbits(m) for _ in range(3)]

        a_h, b_h = f.to_hex(a_s, a_r, a_m), f.to_hex(b_s, b_r, b_m)

        # solve for c
        p_exp = self.f.get_exp(get_result_from_ref(OP_MUL, a_h, b_h, "0", f.name))
        res_h = f.to_hex(r_s, p_exp + d, res_m)
        c_h = get_result_from_ref(SOLVER_OPS[op], a_h, b_h, res_h, f.name)

        p_exp, r_exp = self.get_op_details(op, a_h, b_h, c_h)
        c_exp = f.get_exp(c_h)

        if (r_exp - max(p_exp, c_exp)) == d:
            self.store(op, a_h, b_h, c_h)
            return True
        return False


@register_model("B16")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    with (
        Path("./tests/testvectors/B16_tv.txt").open("w") as tf,
        Path("./tests/covervectors/B16_cv.txt").open("w") as cf,
    ):
        for fmt_name in FLOAT_FMTS:
            gen = B16Generator(fmt_name, tf, cf)
            for d in range(-(2 * gen.f.p + 1), 2):
                retries = 15
                for op in OPS:
                    seed(reproducible_hash(f"{fmt_name}_b16_{d}_{op}"))
                    for _ in range(retries):
                        if gen.generate(d, op):
                            break
