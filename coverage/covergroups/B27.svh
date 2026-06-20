// Copyright (C) 2025-26 Harvey Mudd College
//
// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, any work distributed under the
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific language governing permissions
// and limitations under the License.

// B27. CvtFP2FP: NaNs (wide to narrow conversion)
//
// Per the spec, each narrowing conversion crosses three dimensions:
//   1. the qNaN/sNaN bit (MSB of the source fraction),
//   2. the (N_dest - 1) MSB fraction bits below it (the destination's surviving payload),
//   3. "the rest of the bits", interpreted as the sign bit.
// sNaN with an all-zero surviving payload is +-Inf, not a NaN, so it is ignored.
//
// The generator produces every narrowing pair (source mantissa wider than dest):
//   F16 -> BF16
//   F32 -> F16, BF16
//   F64 -> F32, F16, BF16
//   F128 -> F64, F32, F16, BF16
// for 10 conversions total.

covergroup B27_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;

    // CFF Operation Helper Coverpoint
    CFF_op: coverpoint CFI.op {
        type_option.weight = 0;
        bins cff = {OP_CFF};
    }

    // ---------------------------------------------------------------
    // Per-source NaN-class and sign coverpoints
    // ---------------------------------------------------------------

    // F16 source
    F16_nan_class: coverpoint CFI.a[F16_M_UPPER]
        iff (CFI.operandFmt == FMT_HALF
             && CFI.a[F16_E_UPPER:F16_E_LOWER] == '1 && CFI.a[F16_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins qnan = {1};
            bins snan = {0};
        }
    F16_sign: coverpoint CFI.a[F16_SIGN_BIT]
        iff (CFI.operandFmt == FMT_HALF
             && CFI.a[F16_E_UPPER:F16_E_LOWER] == '1 && CFI.a[F16_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins pos = {0};
            bins neg = {1};
        }

    // F32 source
    F32_nan_class: coverpoint CFI.a[F32_M_UPPER]
        iff (CFI.operandFmt == FMT_SINGLE
             && CFI.a[F32_E_UPPER:F32_E_LOWER] == '1 && CFI.a[F32_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins qnan = {1};
            bins snan = {0};
        }
    F32_sign: coverpoint CFI.a[F32_SIGN_BIT]
        iff (CFI.operandFmt == FMT_SINGLE
             && CFI.a[F32_E_UPPER:F32_E_LOWER] == '1 && CFI.a[F32_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins pos = {0};
            bins neg = {1};
        }

    // F64 source
    F64_nan_class: coverpoint CFI.a[F64_M_UPPER]
        iff (CFI.operandFmt == FMT_DOUBLE
             && CFI.a[F64_E_UPPER:F64_E_LOWER] == '1 && CFI.a[F64_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins qnan = {1};
            bins snan = {0};
        }
    F64_sign: coverpoint CFI.a[F64_SIGN_BIT]
        iff (CFI.operandFmt == FMT_DOUBLE
             && CFI.a[F64_E_UPPER:F64_E_LOWER] == '1 && CFI.a[F64_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins pos = {0};
            bins neg = {1};
        }

    // F128 source
    F128_nan_class: coverpoint CFI.a[F128_M_UPPER]
        iff (CFI.operandFmt == FMT_QUAD
             && CFI.a[F128_E_UPPER:F128_E_LOWER] == '1 && CFI.a[F128_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins qnan = {1};
            bins snan = {0};
        }
    F128_sign: coverpoint CFI.a[F128_SIGN_BIT]
        iff (CFI.operandFmt == FMT_QUAD
             && CFI.a[F128_E_UPPER:F128_E_LOWER] == '1 && CFI.a[F128_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins pos = {0};
            bins neg = {1};
        }

    // ---------------------------------------------------------------
    // Per-conversion surviving-payload coverpoints
    // surviving = the (N_dest - 1) MSB fraction bits below the source's qNaN bit
    // ---------------------------------------------------------------

    // F16 -> BF16
    F16_to_BF16_surviving: coverpoint (CFI.a[F16_M_UPPER-1 -: (BF16_M_BITS-1)] == '0)
        iff (CFI.operandFmt == FMT_HALF && CFI.resultFmt == FMT_BF16
             && CFI.a[F16_E_UPPER:F16_E_LOWER] == '1 && CFI.a[F16_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins all_zero = {1};
            bins not_zero = {0};
        }

    // F32 -> F16 / BF16
    F32_to_F16_surviving: coverpoint (CFI.a[F32_M_UPPER-1 -: (F16_M_BITS-1)] == '0)
        iff (CFI.operandFmt == FMT_SINGLE && CFI.resultFmt == FMT_HALF
             && CFI.a[F32_E_UPPER:F32_E_LOWER] == '1 && CFI.a[F32_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins all_zero = {1};
            bins not_zero = {0};
        }
    F32_to_BF16_surviving: coverpoint (CFI.a[F32_M_UPPER-1 -: (BF16_M_BITS-1)] == '0)
        iff (CFI.operandFmt == FMT_SINGLE && CFI.resultFmt == FMT_BF16
             && CFI.a[F32_E_UPPER:F32_E_LOWER] == '1 && CFI.a[F32_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins all_zero = {1};
            bins not_zero = {0};
        }

    // F64 -> F32 / F16 / BF16
    F64_to_F32_surviving: coverpoint (CFI.a[F64_M_UPPER-1 -: (F32_M_BITS-1)] == '0)
        iff (CFI.operandFmt == FMT_DOUBLE && CFI.resultFmt == FMT_SINGLE
             && CFI.a[F64_E_UPPER:F64_E_LOWER] == '1 && CFI.a[F64_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins all_zero = {1};
            bins not_zero = {0};
        }
    F64_to_F16_surviving: coverpoint (CFI.a[F64_M_UPPER-1 -: (F16_M_BITS-1)] == '0)
        iff (CFI.operandFmt == FMT_DOUBLE && CFI.resultFmt == FMT_HALF
             && CFI.a[F64_E_UPPER:F64_E_LOWER] == '1 && CFI.a[F64_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins all_zero = {1};
            bins not_zero = {0};
        }
    F64_to_BF16_surviving: coverpoint (CFI.a[F64_M_UPPER-1 -: (BF16_M_BITS-1)] == '0)
        iff (CFI.operandFmt == FMT_DOUBLE && CFI.resultFmt == FMT_BF16
             && CFI.a[F64_E_UPPER:F64_E_LOWER] == '1 && CFI.a[F64_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins all_zero = {1};
            bins not_zero = {0};
        }

    // F128 -> F64 / F32 / F16 / BF16
    F128_to_F64_surviving: coverpoint (CFI.a[F128_M_UPPER-1 -: (F64_M_BITS-1)] == '0)
        iff (CFI.operandFmt == FMT_QUAD && CFI.resultFmt == FMT_DOUBLE
             && CFI.a[F128_E_UPPER:F128_E_LOWER] == '1 && CFI.a[F128_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins all_zero = {1};
            bins not_zero = {0};
        }
    F128_to_F32_surviving: coverpoint (CFI.a[F128_M_UPPER-1 -: (F32_M_BITS-1)] == '0)
        iff (CFI.operandFmt == FMT_QUAD && CFI.resultFmt == FMT_SINGLE
             && CFI.a[F128_E_UPPER:F128_E_LOWER] == '1 && CFI.a[F128_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins all_zero = {1};
            bins not_zero = {0};
        }
    F128_to_F16_surviving: coverpoint (CFI.a[F128_M_UPPER-1 -: (F16_M_BITS-1)] == '0)
        iff (CFI.operandFmt == FMT_QUAD && CFI.resultFmt == FMT_HALF
             && CFI.a[F128_E_UPPER:F128_E_LOWER] == '1 && CFI.a[F128_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins all_zero = {1};
            bins not_zero = {0};
        }
    F128_to_BF16_surviving: coverpoint (CFI.a[F128_M_UPPER-1 -: (BF16_M_BITS-1)] == '0)
        iff (CFI.operandFmt == FMT_QUAD && CFI.resultFmt == FMT_BF16
             && CFI.a[F128_E_UPPER:F128_E_LOWER] == '1 && CFI.a[F128_M_UPPER:0] != 0) {
            type_option.weight = 0;
            bins all_zero = {1};
            bins not_zero = {0};
        }

    // ---------------------------------------------------------------
    // Crosses (one per narrowing conversion)
    // sNaN + all-zero surviving payload == +-Inf, so it is ignored.
    // ---------------------------------------------------------------

    `ifdef COVER_F16
        `ifdef COVER_BF16
            B27_F16_to_BF16: cross CFF_op, F16_nan_class, F16_to_BF16_surviving, F16_sign {
                ignore_bins inf = binsof(F16_nan_class.snan) && binsof(F16_to_BF16_surviving.all_zero);
            }
        `endif
    `endif

    `ifdef COVER_F32
        `ifdef COVER_F16
            B27_F32_to_F16: cross CFF_op, F32_nan_class, F32_to_F16_surviving, F32_sign {
                ignore_bins inf = binsof(F32_nan_class.snan) && binsof(F32_to_F16_surviving.all_zero);
            }
        `endif
        `ifdef COVER_BF16
            B27_F32_to_BF16: cross CFF_op, F32_nan_class, F32_to_BF16_surviving, F32_sign {
                ignore_bins inf = binsof(F32_nan_class.snan) && binsof(F32_to_BF16_surviving.all_zero);
            }
        `endif
    `endif

    `ifdef COVER_F64
        `ifdef COVER_F32
            B27_F64_to_F32: cross CFF_op, F64_nan_class, F64_to_F32_surviving, F64_sign {
                ignore_bins inf = binsof(F64_nan_class.snan) && binsof(F64_to_F32_surviving.all_zero);
            }
        `endif
        `ifdef COVER_F16
            B27_F64_to_F16: cross CFF_op, F64_nan_class, F64_to_F16_surviving, F64_sign {
                ignore_bins inf = binsof(F64_nan_class.snan) && binsof(F64_to_F16_surviving.all_zero);
            }
        `endif
        `ifdef COVER_BF16
            B27_F64_to_BF16: cross CFF_op, F64_nan_class, F64_to_BF16_surviving, F64_sign {
                ignore_bins inf = binsof(F64_nan_class.snan) && binsof(F64_to_BF16_surviving.all_zero);
            }
        `endif
    `endif

    `ifdef COVER_F128
        `ifdef COVER_F64
            B27_F128_to_F64: cross CFF_op, F128_nan_class, F128_to_F64_surviving, F128_sign {
                ignore_bins inf = binsof(F128_nan_class.snan) && binsof(F128_to_F64_surviving.all_zero);
            }
        `endif
        `ifdef COVER_F32
            B27_F128_to_F32: cross CFF_op, F128_nan_class, F128_to_F32_surviving, F128_sign {
                ignore_bins inf = binsof(F128_nan_class.snan) && binsof(F128_to_F32_surviving.all_zero);
            }
        `endif
        `ifdef COVER_F16
            B27_F128_to_F16: cross CFF_op, F128_nan_class, F128_to_F16_surviving, F128_sign {
                ignore_bins inf = binsof(F128_nan_class.snan) && binsof(F128_to_F16_surviving.all_zero);
            }
        `endif
        `ifdef COVER_BF16
            B27_F128_to_BF16: cross CFF_op, F128_nan_class, F128_to_BF16_surviving, F128_sign {
                ignore_bins inf = binsof(F128_nan_class.snan) && binsof(F128_to_BF16_surviving.all_zero);
            }
        `endif
    `endif

endgroup
