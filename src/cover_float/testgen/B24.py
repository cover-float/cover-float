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
# B24: CvtFP2Int - Underflow


from typing import Optional, TextIO

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

# Each magnitude is (unbiased_exp, top_fraction_value, num_top_bits). The stored
# fraction is (top << (nf - num_top_bits)), i.e. top-justified, so construction
# is format-general. None is a sentinel for +-0 (biased exponent 0, fraction 0).
MAGNITUDES: list[Optional[tuple[int, int, int]]] = [
    None,  # 0
    (-2, 0, 0),  # 1/4  = 1.0  x 2^-2
    (-1, 0, 0),  # 1/2  = 1.0  x 2^-1
    (-1, 0b1, 1),  # 3/4  = 1.1  x 2^-1
    (0, 0, 0),  # 1    = 1.0  x 2^0
    (0, 0b01, 2),  # 1.25 = 1.01 x 2^0
    (0, 0b10, 2),  # 1.5  = 1.10 x 2^0
    (0, 0b11, 2),  # 1.75 = 1.11 x 2^0
]


def generate_B24(test_f: TextIO, cover_f: TextIO) -> None:
    for src_fmt in constants.FLOAT_FMTS:
        nf = constants.MANTISSA_BITS[src_fmt]
        bias = constants.EXPONENT_BIAS[src_fmt]

        for dest_fmt in DEST_FMTS:
            for rm in ROUNDING_MODES:
                for mag in MAGNITUDES:
                    if mag is None:
                        unbiased_exp, fraction = -bias, 0  # -> biased exp 0 -> +-0
                    else:
                        e, top, bits = mag
                        unbiased_exp = e
                        fraction = (top << (nf - bits)) if bits else 0

                    # Both signs: the input sign drives the directed-rounding
                    # asymmetry (RDN/RUP) and the negative-to-unsigned deviation.
                    for sign in (0, 1):
                        f = generate_float(sign, unbiased_exp, fraction, src_fmt)
                        tv = generate_test_vector(constants.OP_CFI, f, 0, 0, src_fmt, dest_fmt, rm)
                        run_and_store_test_vector(tv, test_f, cover_f)


@register_model("B24")
def main(test_f: TextIO, cover_f: TextIO) -> None:
    generate_B24(test_f, cover_f)
