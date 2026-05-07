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

# Created By: Ryan Wolk (rwolk@hmc.edu) on 2/26/2026

import math
import random
from pathlib import Path
from typing import TextIO

import cover_float.common.constants as constants
from cover_float.common.util import generate_float, generate_test_vector, reproducible_hash
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model

B9_1SRC = [constants.OP_SQRT]
B9_2SRC = [
    constants.OP_MUL,
    constants.OP_DIV,
    constants.OP_REM,
]


class B9SignificandGenerator:
    def __init__(self, nf: int, seed: str) -> None:
        """Initialize B9 Significand Generation With the Default Generators"""
        self.nf = nf
        self.lead_trail_lengths = [
            nf - 1,
            nf - 2,
            nf - 3,
            math.ceil(3 * nf / 4),
            math.ceil(nf / 2),
            math.ceil(nf / 2 - 1),
            math.floor(nf / 4),
            3,
            2,
            1,
        ]
        self.seed = seed
        random.seed(reproducible_hash(seed))

        # 0, nf - 1, nf/2, nf/2 - 2, powers of 2, random to fill 10
        one_sparse_positions = [[0], [nf - 1], [math.ceil(nf / 2)], [math.ceil(nf / 2 - 1)]]
        position = 1
        while position < nf and len(one_sparse_positions) < 10:
            one_sparse_positions.append([position])
            position *= 2
        while len(one_sparse_positions) < min(nf, 10):
            val = [random.randint(0, nf - 1)]
            if val not in one_sparse_positions:
                one_sparse_positions.append(val)

        two_sparse_positions: list[list[int]] = []
        while len(two_sparse_positions) < 3:
            k1 = random.randint(0, nf - 1)
            k2 = random.randint(0, nf - 1)

            if abs(k1 - k2) > nf / 2 and [k1, k2] not in two_sparse_positions:
                two_sparse_positions.append([k1, k2])

        self.sparse_positions = [*one_sparse_positions, *two_sparse_positions]

        # Checkerboards: List of (run_length, offset)
        self.checkerboards = [(run_length, offset) for run_length in range(1, 3) for offset in range(0, run_length * 2)]

        # Long Runs: List of (length, positions)
        self.long_runs: list[tuple[int, int]] = []
        self.long_runs.extend(self.evenly_generated_runs(math.floor(3 * nf / 4), nf, 6))
        self.long_runs.extend(self.evenly_generated_runs(math.floor(nf / 2), nf, 7))

    @staticmethod
    def swap_ones_and_zeros(s: str) -> str:
        swap_map = str.maketrans({"1": "0", "0": "1"})
        return s.translate(swap_map)

    @staticmethod
    def evenly_generated_runs(run_length: int, total_size: int, max_n: int) -> list[tuple[int, int]]:
        ans: list[tuple[int, int]] = []
        start = 1
        end = total_size - run_length

        for i in range(max_n):
            interpolated = start + (end - start) * (i / max_n)
            ans.append((run_length, math.floor(interpolated)))

        return sorted(list(set(ans)))

    def generate_leading_and_trailing(self) -> list[str]:
        random.seed(reproducible_hash(self.seed + "leading/trailing"))

        def with_n_leading_zeros(n: int) -> str:
            mantissa = "0" * n + "1" + bin(random.getrandbits(self.nf))[2:]
            return mantissa[: self.nf]

        ans = ["1" * self.nf, "0" * self.nf]
        for length in self.lead_trail_lengths:
            leading_zeros = with_n_leading_zeros(length)
            leading_ones = self.swap_ones_and_zeros(with_n_leading_zeros(length))
            trailing_zeros = with_n_leading_zeros(length)[::-1]
            trailing_ones = self.swap_ones_and_zeros(with_n_leading_zeros(length))[::-1]

            ans.append(leading_zeros)
            ans.append(leading_ones)
            ans.append(trailing_zeros)
            ans.append(trailing_ones)

        return ans

    def generate_sparse(self) -> list[str]:
        random.seed(reproducible_hash(self.seed + "sparse"))

        answer: list[str] = []

        for positions in self.sparse_positions:
            as_list = ["0" for _ in range(self.nf)]
            for i in positions:
                as_list[i] = "1"

            answer.append("".join(as_list))
            answer.append(self.swap_ones_and_zeros("".join(as_list)))

        return answer

    def generate_checkerboards(self) -> list[str]:
        random.seed(reproducible_hash(self.seed + "checkerboard"))

        answer: list[str] = []

        for run_length, offset in self.checkerboards:
            pattern = ("1" * run_length + "0" * run_length) * (self.nf + 2)
            answer.append(pattern[offset : offset + self.nf])

        return answer

    def generate_long_runs(self) -> list[str]:
        random.seed(reproducible_hash(self.seed + "long runs"))

        answer: list[str] = []

        for run_length, start in self.long_runs:
            one_run_list = list(bin(random.getrandbits(self.nf))[2:].zfill(self.nf))

            # We want the run to be exact so we pad it
            one_run_list[start - 1] = "0"
            one_run_list[start + run_length] = "0"
            for i in range(start, start + run_length):
                one_run_list[i] = "1"
            answer.append("".join(one_run_list))

            zero_run_list = list(bin(random.getrandbits(self.nf))[2:].zfill(self.nf))

            # We want the run to be exact so we pad it
            zero_run_list[start - 1] = "1"
            zero_run_list[start + run_length] = "1"
            for i in range(start, start + run_length):
                zero_run_list[i] = "0"
            answer.append("".join(zero_run_list))

        return answer

    def generate(self, file: TextIO) -> list[str]:
        leading_trailing = self.generate_leading_and_trailing()
        sparse = self.generate_sparse()
        checkers = self.generate_checkerboards()
        long_runs = self.generate_long_runs()

        file.write("// Leading and Trailing Ones and Zeros\n")
        self.write_significand_coverage_template(leading_trailing, 0, file)
        file.write("// Sparse Ones and Zeros\n")
        self.write_significand_coverage_template(sparse, len(leading_trailing), file)
        file.write("// Checkerboard Patterns\n")
        self.write_significand_coverage_template(checkers, len(leading_trailing) + len(sparse), file)
        file.write("// Long Runs of Zeros and Ones\n")
        self.write_significand_coverage_template(long_runs, len(leading_trailing) + len(sparse) + len(checkers), file)

        return leading_trailing + sparse + checkers + long_runs

    def write_significand_coverage_template(self, significands: list[str], initial: int, file: TextIO) -> None:
        for i, sig in enumerate(significands, initial):
            file.write(f"bins bin_{i:02d} = {{ 'b{sig.zfill(self.nf)} }}; \n")


def B9_generator(sigs: list[str], fmt: str, test_f: TextIO, cover_f: TextIO) -> None:
    exp_min, exp_max = constants.BIASED_EXP[fmt]
    exp_max -= constants.BIAS[fmt]
    exp_min -= constants.BIAS[fmt]

    # Make it impossible to overflow or underflow with multiplication or division
    exp_max //= 2
    exp_min //= 2

    for op in [*B9_1SRC, *B9_2SRC]:
        for sig1 in sigs:
            for sig2 in sigs:
                # TODO: Be more careful here so as to not accidentally create subnorms/underflows/overflows
                exp1 = random.randint(exp_min, exp_max)
                sign1 = random.randint(0, 1)
                exp2 = random.randint(exp_min, exp_max)
                sign2 = random.randint(0, 1)

                float1 = generate_float(sign1, exp1, int(sig1, 2), fmt)
                float2 = generate_float(sign2, exp2, int(sig2, 2), fmt) if op not in B9_1SRC else 0

                tv = generate_test_vector(op, float1, float2, 0, fmt, fmt, random.choice(constants.ROUNDING_MODES))
                run_and_store_test_vector(tv, test_f, cover_f)

                if op in B9_1SRC:
                    break  # Don't over generate tests


@register_model("B9")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    for fmt in constants.FLOAT_FMTS:
        generator = B9SignificandGenerator(constants.MANTISSA_BITS[fmt], fmt + "b9")

        bins_path = Path(
            "coverage",
            "covergroups",
            "bins_templates",
            "generated",
            f"B9_{constants.FMT_TO_STRING[fmt]}_special_sigs.svh",
        )
        bins_path.parent.mkdir(parents=True, exist_ok=True)

        with bins_path.open("w") as generated_coverage:
            sigs = generator.generate(generated_coverage)
            B9_generator(sigs, fmt, test_f, cover_f)
