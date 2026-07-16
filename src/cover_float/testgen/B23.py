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
# License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific language governing permissions
# and limitations under the License.

# By: Sisi Wang
# B23: CvtFP2Int - Overflow

from typing import TextIO

import cover_float.common.constants as constants
from cover_float.common.util import generate_float, generate_test_vector
from cover_float.reference import run_and_store_test_vector
from cover_float.testgen.model import register_model

ROUNDING_MODES = [
    constants.ROUND_NEAR_EVEN,
    constants.ROUND_MINMAG,
    constants.ROUND_MIN,
    constants.ROUND_MAX,
    constants.ROUND_NEAR_MAXMAG,
]

DEST_FMTS = [
    constants.FMT_INT,
    constants.FMT_UINT,
    constants.FMT_LONG,
    constants.FMT_ULONG,
]


def fine_neighborhood(nf: int, e: int) -> list[tuple[int, int]]:
    """Full Aharoni offset set, for sources that can represent quarter steps.

    Precondition: nf - e >= 2 (source ULP at the MaxInt scale is <= 1/4).

    MaxInt = 1.11..1 x 2^e  (e ones after the point) = 2^(e+1) - 1.
    Its stored mantissa is e ones followed by (nf - e) zeros. At exponent e the
    integer ULP (value 1) sits at mantissa bit index frac_width = nf - e, so one
    quarter is two bits below that.

    Returns nine (unbiased_exp, mantissa) magnitudes:
        MaxInt, MaxInt +- {1/4, 1/2, 3/4, 1}.
    """
    frac_width = nf - e  # fractional mantissa bits at exponent e
    m = ((1 << e) - 1) << frac_width  # MaxIntFP mantissa: e ones, then zeros
    q = 1 << (frac_width - 2)  # value 1/4 in mantissa LSBs
    one = 1 << frac_width  # value 1
    return [
        (e, m),  # MaxInt
        (e, m + q),  # MaxInt + 1/4
        (e, m + 2 * q),  # MaxInt + 1/2
        (e, m + 3 * q),  # MaxInt + 3/4
        (e + 1, 0),  # MaxInt + 1   (m + one overflows the field -> carry to 2^(e+1))
        (e, m - q),  # MaxInt - 1/4
        (e, m - 2 * q),  # MaxInt - 1/2
        (e, m - 3 * q),  # MaxInt - 3/4
        (e, m - one),  # MaxInt - 1
    ]


def coarse_neighborhood(nf: int, e: int) -> list[tuple[int, int]]:
    """Two distinct magnitudes bracketing the boundary, for coarse sources.

    Used when nf - e < 2: the source ULP at the MaxInt scale already exceeds
    1/4, so the quarter offsets collapse and are not representable. We emit:
        - MaxInt + 1 = 2^(e+1): exactly representable power of two -> overflows.
        - the largest source value below it (1.11..1 x 2^e) -> in range.
    """
    return [
        (e + 1, 0),  # MaxInt + 1  -> overflow
        (e, (1 << nf) - 1),  # largest representable < MaxInt + 1  -> in range
    ]


def f16_neighborhood(nf: int) -> list[tuple[int, int]]:
    """F16 cannot reach the MaxInt of any RISC-V integer destination.

    Its largest finite value (65,504) converts IN RANGE to every destination, so
    the only F16 overflow is +-inf. MaxNorm is emitted as an in-range contrast
    case; it raises no NV. (See B23.adoc, "F16 cannot reach the MaxInt boundary".)
    """
    return [
        (16, 0),  # +-inf    -> overflow, NV
        (15, (1 << nf) - 1),  # +-MaxNorm_F16 (65,504) -> in range, no NV
    ]


def generate_B23(test_f: TextIO, cover_f: TextIO) -> None:
    for src_fmt in constants.FLOAT_FMTS:
        nf = constants.MANTISSA_BITS[src_fmt]

        for dest_fmt in DEST_FMTS:
            e = constants.INT_MAX_EXPS[dest_fmt] - 1  # unbiased exponent of MaxInt

            if src_fmt == constants.FMT_HALF:
                magnitudes = f16_neighborhood(nf)
            elif nf - e >= 2:
                magnitudes = fine_neighborhood(nf, e)
            else:
                magnitudes = coarse_neighborhood(nf, e)

            for rm in ROUNDING_MODES:
                for unbiased_exp, mantissa in magnitudes:
                    # +sign exercises positive overflow / saturation to MaxInt.
                    # -sign exercises negative-to-unsigned -> 0 (deviation 2) and,
                    # for signed destinations, the MinInt path (note: true negative
                    # signed overflow is out of spec scope - see B23.adoc).
                    for sign in (0, 1):
                        f = generate_float(sign, unbiased_exp, mantissa, src_fmt)
                        tv = generate_test_vector(constants.OP_CFI, f, 0, 0, src_fmt, dest_fmt, rm)
                        run_and_store_test_vector(tv, test_f, cover_f)


@register_model("B23")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    generate_B23(test_f, cover_f)
