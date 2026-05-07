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

# B15

from __future__ import annotations

import itertools
import logging
import pickle
import random
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING, BinaryIO, TextIO, cast

import cover_float.common.constants as constants
import cover_float.common.log as log
from cover_float.common.util import (
    bezout_inverse,
    factors_to_bit_width,
    generate_float,
    generate_test_vector,
    reproducible_hash,
)
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.B9 import B9SignificandGenerator
from cover_float.testgen.model import register_model

logger: log.ModelLogger = cast(log.ModelLogger, logging.getLogger("B15"))

if TYPE_CHECKING:
    # This block is seen by Pyright but ignored at runtime
    def factorint(n: int) -> dict[int, int]: ...
else:
    from sympy import factorint

B15_OPS = [
    constants.OP_FMADD,
    constants.OP_FMSUB,
    constants.OP_FNMADD,
    constants.OP_FNMSUB,
]


@dataclass
class B15Significand:
    sig1: str
    sig2: str
    result: int


class B15SignificandGenerator:
    def __init__(self, nf: int, fmt: str, seed: str) -> None:
        self.sigs: list[B15Significand] = []
        self.nf = nf
        self.fmt = fmt
        self.seed = seed

    def checkerboards(self, patterns: list[tuple[int, int]] | None = None) -> None:
        random.seed(reproducible_hash(self.seed + " Checkers"))

        if patterns is None:
            patterns = [(1, 0), (2, 0)]

        for run_len, offset in patterns:
            # This should generate a reasonably good checkerboard
            sig1 = "1" + "0" * (self.nf - 1) + "1"

            cell = "0" * run_len + "1" * run_len
            sig2 = ("1" + (cell * self.nf)[offset:])[: self.nf + 1]
            sig2 = sig2[:-1] + "0"  # This ensures that the checkerboard hits both sides

            res = int(sig1, 2) * int(sig2, 2)

            self.sigs.append(B15Significand(sig1[1:], sig2[1:], res))

    def trailing_zeros(self, counts: list[int] | None = None) -> None:
        random.seed(reproducible_hash(self.seed + " Trailing Zeros"))

        if counts is None:
            counts = [2 * self.nf - 1, 2 * self.nf - 2, 2 * self.nf - 3, self.nf, 3, 2, 1]

        for zero_count in counts:
            a_zeros = random.randint(max(zero_count - self.nf, 0), min(self.nf, zero_count))
            b_zeros = zero_count - a_zeros

            sig1 = random.getrandbits(self.nf - a_zeros) << a_zeros
            sig1 |= 1 << self.nf
            sig2 = random.getrandbits(self.nf - b_zeros) << b_zeros
            sig2 |= 1 << self.nf

            res = sig1 * sig2

            self.sigs.append(B15Significand(bin(sig1)[3:], bin(sig2)[3:], res))

    def leading_zeros(self, counts: list[int] | None = None) -> None:
        random.seed(reproducible_hash(self.seed + " Leading Zeros"))

        if counts is None:
            counts = [2 * self.nf - 1, 2 * self.nf - 2, 2 * self.nf - 3, self.nf, 3, 2, 1]

        for count in counts:
            if count - self.nf < 20:
                score, f1, f2 = self._leading_digit_stochastic(self.nf, count, "0")

                if f1 == 0:
                    continue
                if score != 0:
                    continue

                sig1 = bin(f1)[3:]
                sig2 = bin(f2)[3:]
                res = f1 * f2
                self.sigs.append(B15Significand(sig1, sig2, res))
            elif count == 2 * self.nf - 1:
                target = int("1" + "0" * (self.nf * 2) + "1", 2)
                factors = factorint(target)  # Possible up to quad, by sheer luck
                f1, f2 = factors_to_bit_width(factors, target, self.nf)
                if f1 == 0:
                    continue

                sig1 = bin(f1)[3:]
                sig2 = bin(f2)[3:]
                res = f1 * f2
                self.sigs.append(B15Significand(sig1, sig2, res))
            elif self.nf != 112:
                # We can get away with a factoring approach in a small sample space
                f1, f2 = self._leading_digit_factoring(self.nf, count, "0")
                if f1 == 0:
                    continue

                sig1 = bin(f1)[3:]
                sig2 = bin(f2)[3:]
                res = f1 * f2
                self.sigs.append(B15Significand(sig1, sig2, res))

    @staticmethod
    def _trailing_ones_factoring(nf: int, ones: int) -> tuple[int, int]:
        # We want a significand with so many trailing ones
        if (1 << (2 * nf - ones)) <= (1 << 20):  # Around 1 Million
            leaders = list(range(0, 1 << (2 * nf - ones)))
            random.shuffle(leaders)
        else:
            leaders = (random.randint(0, (1 << (2 * nf - ones)) - 1) for _ in range(1 << 20))
        pattern = int("1" * ones, 2)

        for lead in leaders:
            # Get something of the form 1(random)01111.1111
            num = (1 << (2 * nf)) | (lead << (ones + 1)) | pattern
            factors: dict[int, int] = factorint(num)
            f1, f2 = factors_to_bit_width(factors, num, nf + 1)
            if f1 * f2 == num:
                return f1, f2

        return 0, 0

    @staticmethod
    # This works up to a difference around 20
    def _trailing_ones_number_theory(nf: int, ones: int) -> tuple[int, int]:
        # The basic idea here uses modular arithmetic, we want to find a, b, in N such that
        # ab = 2^k - 1 (mod 2^k), this is simply, a statement in Z/(2^k)Z, that
        # a = -b^{-1}, we can find inverses very easily (they exist for odd a) using Bezout's identity
        # Then, we just need to verify that the bit width is correct

        if ones <= nf:
            a = int("1" + "0" * (nf - 1) + "1", 2)
            b = int("1" + "0" * (nf - ones) + "1" * ones, 2)

            if (a * b + 1) % (2**ones) == 0:
                return a, b

            # The above if statement is a sanity check and must happen by construction
            raise AssertionError("Unreachable Code")

        for _ in range(10000000):
            sig1 = (1 << nf) + random.getrandbits(16) | 1  # Must be odd
            sig2 = bezout_inverse(sig1, 2**ones)
            sig2 = 2**ones - sig2

            if sig1.bit_length() != (nf + 1) or sig2.bit_length() != (nf + 1):
                continue

            if (sig1 * sig2 + 1) % (2**ones) == 0:
                return sig1, sig2

            # The above if statement is a sanity check and must happen by construction
            raise AssertionError("Unreachable Code")

        return 0, 0

    @staticmethod
    def _leading_digit_stochastic(nf: int, count: int, digit: str, limit: int = 1000000) -> tuple[int, int, int]:
        opposite_digit = "01"[digit == "0"]
        target_str = "1" + digit * count + opposite_digit + digit + "0" * (2 * nf)

        if digit == "0" and count >= nf:
            target_str += "0"

        target = int(target_str[: 2 * nf + 1], 2)
        if target < (1 << nf | 1) ** 2:
            target <<= 1
        best = 2 * nf, 0, 0

        for _ in range(limit):
            if best[0] == 0:
                return best

            sig1 = (1 << nf) + random.getrandbits(nf)
            sig2 = target // sig1

            if sig2.bit_length() != (nf + 1):
                continue

            prod = bin(sig1 * sig2)[3:]
            score = abs(abs(len(prod) - len(prod.lstrip(digit))) - count)
            if score < best[0]:
                best = score, sig1, sig2

            sig2 += 1
            if sig2.bit_length() != (nf + 1):
                continue

            prod = bin(sig1 * sig2)[3:]
            score = abs(abs(len(prod) - len(prod.lstrip(digit))) - count)
            if score < best[0]:
                best = score, sig1, sig2

        return best

    @staticmethod
    def _leading_digit_factoring(nf: int, count: int, digit: str) -> tuple[int, int]:
        # We want a significand with so many trailing ones
        if (1 << (2 * nf - count)) <= (1 << 10):  # Around 1 Thousand
            finals = list(range(0, 1 << (2 * nf - count)))
            random.shuffle(finals)
        else:
            finals = (random.randint(0, (1 << (2 * nf - count)) - 1) for _ in range(1 << 10))

        pattern = int(digit * count, 2) << (2 * nf - count)

        for final in finals:
            # Get something of the form 1111...111(random)
            num = (1 << (2 * nf)) | pattern | final
            factors: dict[int, int] = factorint(num)
            f1, f2 = factors_to_bit_width(factors, num, nf + 1)
            if f1 * f2 == num:
                return f1, f2

        return 0, 0

    def trailing_ones(self, counts: list[int] | None = None) -> None:
        random.seed(reproducible_hash(self.seed + " Trailing Ones"))

        if counts is None:
            counts = [
                2 * self.nf,
                2 * self.nf - 4,
                3 * self.nf // 2,
                self.nf + 1,
                self.nf,
                self.nf - 1,
                3,
                2,
                1,
            ]  # Very high concentration of impossible cases around 2nf

        for count in counts:
            # Decide on a method to use, as a limit we will keep search spaces at 64 or below for analytic trailing
            # ones with doubles
            if self.nf == 112 and self.nf + 15 < count < 2 * self.nf:
                continue  # Not possible cases for quads

            # Exclude Quads and Cases that won't work well for the number theory method
            if (self.nf == 112 and count == 2 * self.nf) or (
                self.nf <= 52 and (count - self.nf > 15 or (self.nf * 2 - count < 4))
            ):
                f1, f2 = self._trailing_ones_factoring(self.nf, count)
            else:
                f1, f2 = self._trailing_ones_number_theory(self.nf, count)

            sig1 = bin(f1)[3:]
            sig2 = bin(f2)[3:]

            if f1 == 0:
                continue

            res = f1 * f2
            self.sigs.append(B15Significand(sig1, sig2, res))

    def leading_ones(self, counts: list[int] | None = None) -> None:
        random.seed(reproducible_hash(self.seed + "Leading Ones"))

        if counts is None:
            counts = [
                2 * self.nf - 1,
                min(self.nf + 20, self.nf * 3 // 2),
                2 * self.nf - 2,
                self.nf - 3,
                self.nf,
                3,
                2,
                1,
            ]  # Very high concentration of impossible cases around 2nf

        for count in counts:
            # If we do not have a crazy high number of ones to get, targeting a number then dividing to get to
            # it could work well
            if count - self.nf < 20:
                score, f1, f2 = self._leading_digit_stochastic(self.nf, count, "1")

                if score != 0:
                    continue

                sig1 = bin(f1)[3:]
                sig2 = bin(f2)[3:]
                res = f1 * f2
                self.sigs.append(B15Significand(sig1, sig2, res))
            elif count == 2 * self.nf - 1:
                # This one we can easily get by construction
                sig1 = "1" + "0" * (self.nf - 1) + "1"
                sig2 = "1" + "1" * (self.nf - 1) + "0"

                res = int(sig1, 2) * int(sig2, 2)
                if not bin(res)[3:].startswith("1" * (2 * self.nf - 1)):
                    continue

                self.sigs.append(B15Significand(sig1[1:], sig2[1:], res))
            elif self.nf != 112:
                # We can get away with a factoring approach in a small sample space
                f1, f2 = self._leading_digit_factoring(self.nf, count, "1")
                if f1 == 0:
                    continue

                sig1 = bin(f1)[3:]
                sig2 = bin(f2)[3:]
                res = f1 * f2
                self.sigs.append(B15Significand(sig1, sig2, res))

    def sparse_ones(self, positions: list[int] | None = None) -> None:
        random.seed(reproducible_hash(self.seed + "Sparse Ones"))

        if positions is None:
            # Specific Values Known to work well, and are close to the ideal
            if self.nf == constants.MANTISSA_BITS["00"]:
                positions = [3, 6, 7, 9, 16, 18]
            elif self.nf == constants.MANTISSA_BITS["01"]:
                positions = [1, 5, 9, 15, 22, 23, 32, 44]
            elif self.nf == constants.MANTISSA_BITS["02"]:
                positions = [0, 3, 5, 7, 15, 31, 51, 52, 64, 102]
            elif self.nf == constants.MANTISSA_BITS["03"]:
                # For reference, these are the positions that would factor in under 10 sections
                # [0, 3, 5, 9, 11, 12, 14, 15, 16, 17, 19, 21, 22, 23, 24, 25, 27, 29, 30, 31, 32, 35, 36, 37, 39, 40,
                #  41, 43, 45, 47, 48, 50, 51, 52, 54, 55, 56, 57, 59, 60, 62, 63, 65, 66, 68, 69, 70, 71, 72, 73, 74,
                #  75, 76, 78, 79, 80, 81, 82, 83, 84, 85, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 99, 100, 101,
                #  102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121,
                #  122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141,
                #  142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161,
                #  162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181,
                #  182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201,
                #  202, 203, 204, 205, 206, 207, 208, 210, 211, 212, 213, 214, 215, 216, 218, 219, 220, 222]
                positions = [0, 3, 16, 32, 63, 112, 113, 128, 168, 200, 222]
            elif self.nf == constants.MANTISSA_BITS["04"]:
                positions = [1, 3, 5, 6, 8, 9, 10, 12]  # Turns out to be all possible values
            else:
                positions = [0, 2 * self.nf, self.nf, self.nf - 1]
                position = 1
                while position < 2 * self.nf and len(positions) < 10:
                    positions.append(position)
                    position *= 2
                while len(positions) < min(2 * self.nf, 10):
                    val = random.randint(0, 2 * self.nf - 1)
                    if val not in positions:
                        positions.append(val)

        for position in positions:
            target = 1 << (2 * self.nf + 1)
            target |= 1 << position

            factors: dict[int, int] = factorint(target)
            f1, f2 = factors_to_bit_width(factors, target, self.nf + 1)

            sig1 = bin(f1)[3:]
            sig2 = bin(f2)[3:]
            res = f1 * f2
            if res == target:
                self.sigs.append(B15Significand(sig1, sig2, res))

    def sparse_zeros(self) -> None:
        # These numbers are so rare and so not worth it to attempt to generate for quads
        if self.nf == 112:
            return

        hits = 0
        for attempt in range(10000):
            logger.status(f"Generating {self.fmt} Sparse Zeros: Generated: {hits}/10, Attempts: {attempt}")
            target = (1 << (2 * self.nf + 2)) - 1
            for _ in range(min(8, self.nf // 2)):
                p2 = random.randint(1, 2 * self.nf)
                target &= ~(1 << p2)

            factors: dict[int, int] = factorint(target)
            f1, f2 = factors_to_bit_width(factors, target, self.nf + 1)

            sig1 = bin(f1)[3:]
            sig2 = bin(f2)[3:]
            res = f1 * f2
            if res == target:
                self.sigs.append(B15Significand(sig1, sig2, res))
                hits += 1
                if hits == 10:
                    break

    @staticmethod
    def evenly_spaced_numbers(start: int, end: int, count: int) -> list[int]:
        answer: list[int] = []
        for i in range(count):
            answer.append(int(start + (end - start) * (i / (count - 1))))
        return answer

    def long_run_ones(self, run_lengths_and_offsets: list[tuple[int, int]] | None = None) -> None:
        random.seed(reproducible_hash(self.seed + "Long Run Ones"))

        # Right now, what we are going to cover is runs in the middle of nf
        if run_lengths_and_offsets is None:
            run_lengths_and_offsets = []

            # The generated sig1 has size (offset * 2) + (run_length - offset) // 2 = (run_length + 3 * offset) // 2
            # Thus, nf + 1 >= (run_length + offset) // 2 ==> offset <= (2 * (nf + 1) - run_length) // 3
            # Which means that we need to keep offsets contained between 0, (2 * (nf + 1) - run_length) // 3
            for run_length in [3 * self.nf // 2, self.nf]:
                for offset in self.evenly_spaced_numbers(0, ((2 * (self.nf + 1) - run_length) // 3), 6):
                    if offset != 0:
                        run_lengths_and_offsets.append((run_length, offset))

        # Our significand generation works like the following example:
        # >>> sig1 = int('101011111111111111110101', 2)
        # >>> sig2 = (1 << 23) | (1 << 3)
        # >>> bin(sig1 * sig2)
        # '0b10101111111111111111111111111111111111110101000'

        # Notice that the pattern creates a number that looks like:
        # (10){2}(1){16}(01){2}
        # And as a result, we get a pattern of length 16 * 2 + 2 * 2 = 36

        # Then, the second one in sig2 comes from having the ones end at
        # position 16 + 4 = 20, so or in a bit at (1 << (23 - 20))

        for run_length, offset in run_lengths_and_offsets:
            run_length &= ~1
            offset &= ~1  # This must be even, and rounding down is safe

            teeth_length = offset // 2
            internal_ones_count = (run_length - (teeth_length * 2)) // 2

            sig1_pattern = "10" * (teeth_length) + "1" * internal_ones_count + "01" * teeth_length
            if len(sig1_pattern) > self.nf + 1:
                logger.exception(
                    f"Invalid Arrangement for Long Run of Ones, offset={offset}, run_length={run_length} "
                    f"Generated Sig1: {sig1_pattern}, length={len(sig1_pattern)}"
                )
                continue

            sig1_pattern += "0" * (self.nf + 1 - len(sig1_pattern))
            sig1 = int(sig1_pattern, 2)

            sig2 = 1 << self.nf
            second_bit_position = self.nf - (teeth_length * 2) - internal_ones_count
            sig2 |= 1 << second_bit_position

            res = sig1 * sig2
            self.sigs.append(B15Significand(bin(sig1)[3:], bin(sig2)[3:], res))

    def long_run_zeros(self, run_lengths_and_offsets: list[tuple[int, int]] | None = None) -> None:
        random.seed(reproducible_hash(self.seed + "Long Run Zeros"))

        if run_lengths_and_offsets is None:
            run_lengths_and_offsets = []

            # The generated sig1 has size (offset * 2) + (run_length - offset) // 2 = (run_length + 3 * offset) // 2
            # Thus, nf + 1 >= (run_length + offset) // 2 ==> offset <= (2 * (nf + 1) - run_length) // 3
            # Which means that we need to keep offsets contained between 0, (2 * (nf + 1) - run_length) // 3
            for run_length in [3 * self.nf // 2, self.nf]:
                for offset in self.evenly_spaced_numbers(0, 2 * self.nf + 1 - run_length, 7):
                    if offset != 0 and offset + run_length != 2 * self.nf + 1:
                        run_lengths_and_offsets.append((run_length, offset))

        for run_length, offset in run_lengths_and_offsets:
            # Unlike long runs of ones, there doesn't seem to be a great way to generate these
            # Like the leading zeros cases, we'll break it down into a stochastic search for good
            # factors and a search via factoring

            if self.nf != 112 and (run_length + offset - self.nf > 20 or 2 * self.nf - run_length - offset < 5):
                # In these cases, factoring should work reasonably well

                for _ in range(1024):
                    # Give us some number of attempts to get it right
                    final_length = 2 * self.nf - offset - run_length + 1
                    final_digits = bin(random.getrandbits(final_length))[2:].zfill(final_length)
                    if offset != 1:
                        lead_digits = bin(random.getrandbits(offset - 2))[2:].zfill(offset - 2)
                        if offset == 2:
                            lead_digits = ""

                        target_str = "1" + lead_digits + "1" + "0" * run_length + final_digits
                    else:
                        target_str = "1" + "0" * run_length + final_digits

                    if len(target_str) != 2 * self.nf + 1:
                        raise ValueError(
                            f"Sanity Check Failed in Long_Run_Zeros, \n\ttarget_str={target_str}, len={len(target_str)}"
                        )

                    target = int(target_str, 2)
                    if target < (1 << self.nf | 1) ** 2:
                        target <<= 1

                    factors: dict[int, int] = factorint(target)
                    f1, f2 = factors_to_bit_width(factors, target, self.nf + 1)
                    if f1 * f2 == target:
                        sig1 = bin(f1)[3:]
                        sig2 = bin(f2)[3:]
                        self.sigs.append(B15Significand(sig1, sig2, target))
                        break
                else:
                    logger.exception("Long Run Zeros Failed (factoring)")
            elif run_length + offset - self.nf < 20:
                # We can generally get away with the stochastic search here (limitation still exists for nf=112)
                best = 2 * self.nf, 0, 0

                for _ in range(10000000):
                    if best[0] == 0:
                        break

                    if offset != 1:
                        lead_digits = bin(random.getrandbits(offset - 2))[2:].zfill(offset - 2)
                        target_str = "1" + lead_digits + "1" + "0" * run_length + "1" + "0" * (2 * self.nf)
                    else:
                        target_str = "1" + "0" * run_length + "1" + "0" * (2 * self.nf)

                    target = int(target_str[: 2 * self.nf + 1], 2)
                    if target < (1 << 2 * self.nf | 1) ** 2:
                        target <<= 1

                    sig1 = (1 << self.nf) + random.getrandbits(self.nf)
                    sig2 = target // sig1
                    if sig2.bit_length() != (self.nf + 1):
                        continue

                    run = bin(sig1 * sig2)[3 + offset :]
                    zero_run_length = len(run) - len(run.lstrip("0"))
                    score = abs(run_length - zero_run_length)
                    if score < best[0]:
                        best = score, sig1, sig2

                    sig2 += 1
                    run = bin(sig1 * sig2)[3 + offset :]
                    zero_run_length = len(run) - len(run.lstrip("0"))
                    score = abs(run_length - zero_run_length)
                    if score < best[0]:
                        best = score, sig1, sig2

                if best[0] != 0:
                    logger.exception(f"Long Run Zeros Failed for {self.fmt}")

                sig1 = bin(best[1])[3:]
                sig2 = bin(best[2])[3:]
                res = best[1] * best[2]
                self.sigs.append(B15Significand(sig1, sig2, res))

    def generate(self, file: TextIO, *, cache_file_path: Path | None = None) -> list[tuple[str, str]]:
        if cache_file_path and cache_file_path.exists():
            logger.info(f"Retrieving Cached Significands from {cache_file_path}")
            with cache_file_path.open("rb") as cache:
                self.retrieve_cached_sigs(cache)
            return [(sig.sig1, sig.sig2) for sig in self.sigs]

        logger.status(f"Generating {self.fmt} Checker Boards")
        self.checkerboards()
        logger.status(f"Generating {self.fmt} Trailing Zeros")
        self.trailing_zeros()
        logger.status(f"Generating {self.fmt} Trailing Ones")
        self.trailing_ones()
        logger.status(f"Generating {self.fmt} Leading Zeros")
        self.leading_zeros()
        logger.status(f"Generating {self.fmt} Leading Ones")
        self.leading_ones()
        logger.status(f"Generating {self.fmt} Sparse Ones")
        self.sparse_ones()
        logger.status(f"Generating {self.fmt} Sparse Zeros")
        self.sparse_zeros()
        logger.status(f"Generating {self.fmt} Long Runs of Ones")
        self.long_run_ones()
        logger.status(f"Generating {self.fmt} Long Runs of Zeros")
        self.long_run_zeros()

        self.store_sigs(file)

        if cache_file_path is not None:
            cache_file_path.parent.mkdir(parents=True, exist_ok=True)
            with cache_file_path.open("wb") as cache:
                self.cache_sigs(cache)

        return [(sig.sig1, sig.sig2) for sig in self.sigs]

    def store_sigs(self, file: TextIO) -> None:
        for i, sig in enumerate(self.sigs):
            file.write(f"bins bin_{i} = {{ 'b{sig.result:0{2 * self.nf + 2}b} }}; \n")

    def cache_sigs(self, file: BinaryIO) -> None:
        pickle.dump(self.sigs, file)

    def retrieve_cached_sigs(self, file: BinaryIO) -> None:
        self.sigs = pickle.load(file)


def interesting_tests(
    b15_sigs: list[tuple[int, int]],
    b9_sigs: list[int],
    interesting_shifts: list[int],
    fmt: str,
    test_f: TextIO,
    cover_f: TextIO,
) -> None:
    random.seed(reproducible_hash(f"b15 {fmt} interesting"))

    exp_min, exp_max = constants.BIASED_EXP[fmt]
    exp_min -= constants.BIAS[fmt]
    exp_max -= constants.BIAS[fmt]

    for op in B15_OPS:
        for shift in interesting_shifts:
            for mul_sigs, add_sig in itertools.product(b15_sigs, b9_sigs):
                mul_sigs = list(mul_sigs)
                random.shuffle(mul_sigs)

                # Randomized Exponents so that we get the desired shift
                prod_exp = random.randint(max(exp_min, exp_min + shift), min(exp_max, exp_max + shift))
                add_exp = prod_exp - shift

                # Find two exponents that add to prod_exp
                mul_exp1 = random.randint(max(exp_min, prod_exp - exp_max), min(exp_max, prod_exp - exp_min))
                mul_exp2 = prod_exp - mul_exp1

                # Order doesn't matter so randomly swap them
                if random.random() < 0.5:
                    mul_exp1, mul_exp2 = mul_exp2, mul_exp1

                # Keep All Signs The Same To Facilitate All effective Operations
                sign = random.randint(0, 1)

                # This ensures that we get two signs that match in the output
                sign2 = 0

                mul_float1 = generate_float(sign, mul_exp1, mul_sigs[0], fmt)
                mul_float2 = generate_float(sign2, mul_exp2, mul_sigs[1], fmt)
                add_float = generate_float(sign, add_exp, add_sig, fmt)

                tv = generate_test_vector(
                    op, mul_float1, mul_float2, add_float, fmt, fmt, random.choice(constants.ROUNDING_MODES)
                )
                run_and_store_test_vector(tv, test_f, cover_f)


def uninteresting_tests(
    b15_sigs: list[tuple[int, int]],
    b9_sigs: list[int],
    interesting_shifts: list[int],
    fmt: str,
    test_f: TextIO,
    cover_f: TextIO,
) -> None:
    random.seed(reproducible_hash(f"b15 {fmt} uninteresting"))

    nf = constants.MANTISSA_BITS[fmt]
    possible_shifts = [shift for shift in range(-2 * nf - 3, nf + 2 + 1) if shift not in interesting_shifts]
    shift_generator = itertools.cycle(possible_shifts)

    exp_min, exp_max = constants.BIASED_EXP[fmt]
    exp_min -= constants.BIAS[fmt]
    exp_max -= constants.BIAS[fmt]

    for op in B15_OPS:
        for mul_sigs, add_sig in itertools.product(b15_sigs, b9_sigs):
            mul_sigs = list(mul_sigs)
            random.shuffle(mul_sigs)

            # Just cycle through any uninteresting shift, perhaps there could be more weighting here
            # in the future, i.e. pass a generator?
            shift = next(shift_generator)

            if shift == -2 * nf - 3:
                # We reserve this shift size for an arbitrary shift outside the normal range
                shift = random.randint(nf + 2, exp_max - 2)
                if random.random() < 0.5:
                    shift = -shift

            # Randomized Exponents so that we get the desired shift
            prod_exp = random.randint(max(exp_min, exp_min + shift), min(exp_max, exp_max + shift))
            add_exp = prod_exp - shift

            # Find two exponents that add to prod_exp
            mul_exp1 = random.randint(max(exp_min, prod_exp - exp_max), min(exp_max, prod_exp - exp_min))
            mul_exp2 = prod_exp - mul_exp1

            # Order doesn't matter so randomly swap them
            if random.random() < 0.5:
                mul_exp1, mul_exp2 = mul_exp2, mul_exp1

            # Keep All Signs The Same To Facilitate All effective Operations
            sign = random.randint(0, 1)

            # This ensures that we get two signs that match in the output
            sign2 = 0

            mul_float1 = generate_float(sign, mul_exp1, mul_sigs[0], fmt)
            mul_float2 = generate_float(sign2, mul_exp2, mul_sigs[1], fmt)
            add_float = generate_float(sign, add_exp, add_sig, fmt)

            tv = generate_test_vector(
                op, mul_float1, mul_float2, add_float, fmt, fmt, random.choice(constants.ROUNDING_MODES)
            )
            run_and_store_test_vector(tv, test_f, cover_f)


def interesting_shift_ranges(low_shifts: int, shifts_from_edge: int, fmt: str) -> list[int]:
    nf = constants.MANTISSA_BITS[fmt]

    shifts: list[int] = []
    shifts.extend(range(-low_shifts, low_shifts + 1))
    shifts.extend(range(-2 * nf - 1, -2 * nf - 1 + shifts_from_edge + 1))
    shifts.extend(range(nf - shifts_from_edge, nf + 1))

    return shifts


@register_model("B15")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    cache_dir = Path(constants.config.CACHE_DIR)

    for fmt in constants.FLOAT_FMTS:
        hashval = reproducible_hash(fmt + "b15")
        random.seed(hashval)

        bins_path = Path("coverage", "covergroups", "bins_templates", "generated")
        bins_path.mkdir(parents=True, exist_ok=True)

        add_sigs_path = bins_path / f"B15_{constants.FMT_TO_STRING[fmt]}_special_sigs.svh"
        mul_sigs_path = bins_path / f"B15_{constants.FMT_TO_STRING[fmt]}_prod_special_sigs.svh"
        with add_sigs_path.open("w") as add_sigs_file, mul_sigs_path.open("w") as mul_sigs_file:
            cache_file = cache_dir / f"b15-{fmt}-cache.pkl"

            logger.status(f"Generating {fmt} Sigs & Shifts")
            b9_sig_gen = B9SignificandGenerator(constants.MANTISSA_BITS[fmt], fmt + "b15")
            b9_sigs = [int(sig, 2) for sig in b9_sig_gen.generate(add_sigs_file)]

            b15_sig_gen = B15SignificandGenerator(constants.MANTISSA_BITS[fmt], fmt, fmt + "b15")
            b15_sigs = [
                (int(sig1, 2), int(sig2, 2))
                for sig1, sig2 in b15_sig_gen.generate(mul_sigs_file, cache_file_path=cache_file)
            ]

            if constants.config.FULL_COVERAGE_TESTGEN:
                interesting_shifts = interesting_shift_ranges(2, 2, fmt)
            else:
                interesting_shifts = interesting_shift_ranges(0, 0, fmt)

            logger.status(f"Generating {fmt} Tests")
            interesting_tests(b15_sigs, b9_sigs, interesting_shifts, fmt, test_f, cover_f)
            uninteresting_tests(b15_sigs, b9_sigs, interesting_shifts, fmt, test_f, cover_f)
