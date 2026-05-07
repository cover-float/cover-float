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

# B11

# We need slightly modified rules to cover this completely,
# Many cases I don't see what we gain from running this with so many different
# special significands in these places (esp. the tests for shifts that just result in
# the sticky being set). Similarly, running all of the middling shifts seem like important,
# though relatively uninteresting test cases. The majority of the coverage effort needs to be on
# the interesting shift ranges, so short and long shifts: [-3, 3], [nf, nf-3], and [-nf, -nf+3]

import itertools
import logging
import random
from pathlib import Path
from typing import TextIO, cast

import cover_float.common.constants as constants
import cover_float.common.log as log
from cover_float.common.util import generate_float, generate_test_vector, reproducible_hash
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.B9 import B9SignificandGenerator
from cover_float.testgen.model import register_model

logger: log.ModelLogger = cast(log.ModelLogger, logging.getLogger("B11"))

B11_OPS = [constants.OP_ADD, constants.OP_SUB]


def interesting_shift_ranges(low_shifts: int, shifts_from_edge: int, fmt: str) -> list[int]:
    nf = constants.MANTISSA_BITS[fmt]

    shifts: list[int] = []
    shifts.extend(range(-low_shifts, low_shifts + 1))
    shifts.extend(range(-nf, -nf + shifts_from_edge + 1))
    shifts.extend(range(nf - shifts_from_edge, nf + 1))

    return shifts


def interesting_tests(
    sigs: list[int], interesting_shifts: list[int], fmt: str, test_f: TextIO, cover_f: TextIO
) -> None:
    random.seed(reproducible_hash("b11 interesting " + fmt))
    exp_min, exp_max = constants.BIASED_EXP[fmt]
    exp_min -= constants.BIAS[fmt]
    exp_max -= constants.BIAS[fmt]

    for op in B11_OPS:
        for shift in interesting_shifts:
            for sig1, sig2 in itertools.product(sigs, sigs):
                # Randomized Exponents so that we get the desired shift
                exp1 = random.randint(max(exp_min, exp_min + shift), min(exp_max, exp_max + shift))
                exp2 = exp1 - shift
                sign = random.randint(0, 1)

                # If we keep the sign the same, we get the same number of effective addition and subtraction cases
                float1 = generate_float(sign, exp1, sig1, fmt)
                float2 = generate_float(sign, exp2, sig2, fmt)

                tv = generate_test_vector(op, float1, float2, 0, fmt, fmt, random.choice(constants.ROUNDING_MODES))
                run_and_store_test_vector(tv, test_f, cover_f)


def uninteresting_tests(
    sigs: list[int], interesting_shifts: list[int], fmt: str, test_f: TextIO, cover_f: TextIO
) -> None:
    random.seed(reproducible_hash("b11 uninteresting " + fmt))

    nf = constants.MANTISSA_BITS[fmt]
    possible_shifts = [shift for shift in range(-nf - 5, nf + 4 + 1) if shift not in interesting_shifts]
    shift_generator = itertools.cycle(possible_shifts)

    exp_min, exp_max = constants.BIASED_EXP[fmt]
    exp_min -= constants.BIAS[fmt]
    exp_max -= constants.BIAS[fmt]

    for op in B11_OPS:
        for sig1, sig2 in itertools.product(sigs, sigs):
            # Just cycle through any uninteresting shift, perhaps there could be more weighting here
            # in the future, i.e. pass a generator?
            shift = next(shift_generator)

            if shift == -nf - 5:
                # We reserve this shift size for an arbitrary shift outside the normal range
                shift = random.randint(nf + 5, max(exp_max - 2, nf + 5))
                if random.random() < 0.5:
                    shift = -shift

            # Randomized Exponents so that we get the desired shift
            exp1 = random.randint(max(exp_min, exp_min + shift), min(exp_max, exp_max + shift))
            exp2 = exp1 - shift
            sign = random.randint(0, 1)

            # If we keep the sign the same, we get the same number of effective addition and subtraction cases
            float1 = generate_float(sign, exp1, sig1, fmt)
            float2 = generate_float(sign, exp2, sig2, fmt)

            tv = generate_test_vector(op, float1, float2, 0, fmt, fmt, random.choice(constants.ROUNDING_MODES))
            run_and_store_test_vector(tv, test_f, cover_f)


@register_model("B11")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    for fmt in constants.FLOAT_FMTS:
        seed = reproducible_hash(fmt + "b11")
        random.seed(seed)

        logger.status(f"Generating {fmt} Sigs & Shifts")
        bins_path = Path(
            "coverage",
            "covergroups",
            "bins_templates",
            "generated",
            f"B11_{constants.FMT_TO_STRING[fmt]}_special_sigs.svh",
        )
        bins_path.parent.mkdir(parents=True, exist_ok=True)

        with bins_path.open("w") as generated_coverage:
            sig_gen = B9SignificandGenerator(constants.MANTISSA_BITS[fmt], "b11" + fmt)
            sigs = [int(sig, 2) for sig in sig_gen.generate(generated_coverage)]

            if constants.config.FULL_COVERAGE_TESTGEN:
                interesting_shifts = interesting_shift_ranges(2, 2, fmt)
            else:
                interesting_shifts = interesting_shift_ranges(0, 0, fmt)

            logger.status(f"Generating {fmt} Tests")
            interesting_tests(sigs, interesting_shifts, fmt, test_f, cover_f)
            uninteresting_tests(sigs, interesting_shifts, fmt, test_f, cover_f)
