// Copyright (C) 2025-26 Harvey Mudd College, Ryan Wolk (rwolk@hmc.edu)
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

covergroup B6_cg (virtual coverfloat_interface CFI);
    option.per_instance = 0;

    // Source Format Helpers

    F16_result_fmt: coverpoint (CFI.resultFmt == FMT_HALF) {
        type_option.weight = 0;
        bins f16 = {1};
    }

    BF16_result_fmt: coverpoint (CFI.resultFmt == FMT_BF16) {
        type_option.weight = 0;
        bins bf16 = {1};
    }

    F32_result_fmt: coverpoint (CFI.resultFmt == FMT_SINGLE) {
        type_option.weight = 0;
        bins f32 = {1};
    }

    F64_result_fmt: coverpoint (CFI.resultFmt == FMT_DOUBLE) {
        type_option.weight = 0;
        bins f64 = {1};
    }

    F128_result_fmt: coverpoint (CFI.resultFmt == FMT_QUAD) {
        type_option.weight = 0;
        bins f128 = {1};
    }

    // rounding mode
    rounding_mode_all: coverpoint (CFI.rm) {
        type_option.weight = 0;
        bins round_near_even   = {ROUND_NEAR_EVEN};
        bins round_minmag      = {ROUND_MINMAG};
        bins round_min         = {ROUND_MIN};
        bins round_max         = {ROUND_MAX};
        bins round_near_maxmag = {ROUND_NEAR_MAXMAG};
    }

    // Operands
    B6_arith_ops: coverpoint (CFI.op) {
        type_option.weight = 0;
        bins fmadd = { OP_FMADD };
        bins fmsub = { OP_FMSUB };
        bins fnmadd = { OP_FNMADD };
        bins fnmsub = { OP_FNMSUB };

        bins mul = { OP_MUL };
        bins div = { OP_DIV };
    }

    B6_convert_ops: coverpoint (CFI.op) {
        type_option.weight = 0;
        bins cff = { OP_CFF };
    }

    // Narrowing Sources for Each Precision
    BF16_convert_narrowing_sources: coverpoint (CFI.operandFmt) {
        type_option.weight = 0;
        `ifdef COVER_F32
            bins f32 = { FMT_SINGLE };
        `endif

        `ifdef COVER_F64
            bins f64 = { FMT_DOUBLE };
        `endif

        `ifdef COVER_F128
            bins f128 = { FMT_QUAD };
        `endif
    }
    F16_convert_narrowing_sources: coverpoint (CFI.operandFmt) {
        type_option.weight = 0;
        // This is narrowing because half precision and represent fewer possible exponents than BF16
        // so these cases only apply in this direction.
        `ifdef COVER_BF16
            bins bf16 = { FMT_BF16 };
        `endif

        `ifdef COVER_F32
            bins f32 = { FMT_SINGLE };
        `endif

        `ifdef COVER_F64
            bins f64 = { FMT_DOUBLE };
        `endif

        `ifdef COVER_F128
            bins f128 = { FMT_QUAD };
        `endif
    }
    F32_convert_narrowing_sources: coverpoint (CFI.operandFmt) {
        type_option.weight = 0;
        `ifdef COVER_F64
            bins f64 = { FMT_DOUBLE };
        `endif

        `ifdef COVER_F128
            bins f128 = { FMT_QUAD };
        `endif
    }
    F64_convert_narrowing_sources: coverpoint (CFI.operandFmt) {
        type_option.weight = 0;
        `ifdef COVER_F128
            bins f128 = { FMT_QUAD };
        `endif
    }

    // Rounding bit information coverpoints
    F32_minsubnorm_m1_bit: coverpoint (CFI.intermM[INTERM_M_BITS-F32_M_BITS-1]) {
        type_option.weight = 0;
    }
    F32_minsubnorm_m2_bit: coverpoint (CFI.intermM[INTERM_M_BITS-F32_M_BITS-2]) {
        type_option.weight = 0;
    }
    F32_minsubnorm_m3_bit: coverpoint (CFI.intermM[INTERM_M_BITS-F32_M_BITS-3]) {
        type_option.weight = 0;
    }
    F32_minsubnorm_m3_sticky: coverpoint (|CFI.intermM[INTERM_M_BITS-F32_M_BITS-3:0]) {
        type_option.weight = 0;
    }
    F32_minsubnorm_m4_sticky: coverpoint (|CFI.intermM[INTERM_M_BITS-F32_M_BITS-4:0]) {
        type_option.weight = 0;
    }
    F32_sign: coverpoint (CFI.result[F32_SIGN_BIT]) {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F64_minsubnorm_m1_bit: coverpoint (CFI.intermM[INTERM_M_BITS-F64_M_BITS-1]) {
        type_option.weight = 0;
    }
    F64_minsubnorm_m2_bit: coverpoint (CFI.intermM[INTERM_M_BITS-F64_M_BITS-2]) {
        type_option.weight = 0;
    }
    F64_minsubnorm_m3_bit: coverpoint (CFI.intermM[INTERM_M_BITS-F64_M_BITS-3]) {
        type_option.weight = 0;
    }
    F64_minsubnorm_m3_sticky: coverpoint (|CFI.intermM[INTERM_M_BITS-F64_M_BITS-3:0]) {
        type_option.weight = 0;
    }
    F64_minsubnorm_m4_sticky: coverpoint (|CFI.intermM[INTERM_M_BITS-F64_M_BITS-4:0]) {
        type_option.weight = 0;
    }
    F64_sign: coverpoint (CFI.result[F64_SIGN_BIT]) {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F128_minsubnorm_m1_bit: coverpoint (CFI.intermM[INTERM_M_BITS-F128_M_BITS-1]) {
        type_option.weight = 0;
    }
    F128_minsubnorm_m2_bit: coverpoint (CFI.intermM[INTERM_M_BITS-F128_M_BITS-2]) {
        type_option.weight = 0;
    }
    F128_minsubnorm_m3_bit: coverpoint (CFI.intermM[INTERM_M_BITS-F128_M_BITS-3]) {
        type_option.weight = 0;
    }
    F128_minsubnorm_m3_sticky: coverpoint (|CFI.intermM[INTERM_M_BITS-F128_M_BITS-3:0]) {
        type_option.weight = 0;
    }
    F128_minsubnorm_m4_sticky: coverpoint (|CFI.intermM[INTERM_M_BITS-F128_M_BITS-4:0]) {
        type_option.weight = 0;
    }
    F128_sign: coverpoint (CFI.result[F128_SIGN_BIT]) {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F16_minsubnorm_m1_bit: coverpoint (CFI.intermM[INTERM_M_BITS-F16_M_BITS-1]) {
        type_option.weight = 0;
    }
    F16_minsubnorm_m2_bit: coverpoint (CFI.intermM[INTERM_M_BITS-F16_M_BITS-2]) {
        type_option.weight = 0;
    }
    F16_minsubnorm_m3_bit: coverpoint (CFI.intermM[INTERM_M_BITS-F16_M_BITS-3]) {
        type_option.weight = 0;
    }
    F16_minsubnorm_m3_sticky: coverpoint (|CFI.intermM[INTERM_M_BITS-F16_M_BITS-3:0]) {
        type_option.weight = 0;
    }
    F16_minsubnorm_m4_sticky: coverpoint (|CFI.intermM[INTERM_M_BITS-F16_M_BITS-4:0]) {
        type_option.weight = 0;
    }
    F16_sign: coverpoint (CFI.result[F16_SIGN_BIT]) {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    BF16_minsubnorm_m1_bit: coverpoint (CFI.intermM[INTERM_M_BITS-BF16_M_BITS-1]) {
        type_option.weight = 0;
    }
    BF16_minsubnorm_m2_bit: coverpoint (CFI.intermM[INTERM_M_BITS-BF16_M_BITS-2]) {
        type_option.weight = 0;
    }
    BF16_minsubnorm_m3_bit: coverpoint (CFI.intermM[INTERM_M_BITS-BF16_M_BITS-3]) {
        type_option.weight = 0;
    }
    BF16_minsubnorm_m3_sticky: coverpoint (|CFI.intermM[INTERM_M_BITS-BF16_M_BITS-3:0]) {
        type_option.weight = 0;
    }
    BF16_minsubnorm_m4_sticky: coverpoint (|CFI.intermM[INTERM_M_BITS-BF16_M_BITS-4:0]) {
        type_option.weight = 0;
    }
    BF16_sign: coverpoint (CFI.result[BF16_SIGN_BIT]) {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }


    // Main crosses
    `ifdef COVER_F32
        F32_arith_case_i_iv: cross F32_result_fmt, F32_sign, F32_minsubnorm_m1_bit, F32_minsubnorm_m2_bit, F32_minsubnorm_m3_sticky, rounding_mode_all, B6_arith_ops {
            ignore_bins zero = binsof(F32_minsubnorm_m1_bit) intersect {0};
        }
        F32_arith_case_ii_iii: cross F32_result_fmt, F32_sign, F32_minsubnorm_m2_bit, F32_minsubnorm_m3_bit, F32_minsubnorm_m4_sticky, rounding_mode_all, B6_arith_ops {
            ignore_bins zero = binsof(F32_minsubnorm_m2_bit) intersect {0} && binsof(F32_minsubnorm_m3_bit) intersect {0} && binsof(F32_minsubnorm_m4_sticky) intersect {0};
        }

        F32_convert_case_i_iv: cross F32_result_fmt, F32_sign, F32_minsubnorm_m1_bit, F32_minsubnorm_m2_bit, F32_minsubnorm_m3_sticky, rounding_mode_all, B6_convert_ops, F32_convert_narrowing_sources {
            ignore_bins zero = binsof(F32_minsubnorm_m1_bit) intersect {0};
        }
        F32_convert_case_ii_iii: cross F32_result_fmt, F32_sign, F32_minsubnorm_m2_bit, F32_minsubnorm_m3_bit, F32_minsubnorm_m4_sticky, rounding_mode_all, B6_convert_ops, F32_convert_narrowing_sources {
            ignore_bins zero = binsof(F32_minsubnorm_m2_bit) intersect {0} && binsof(F32_minsubnorm_m3_bit) intersect {0} && binsof(F32_minsubnorm_m4_sticky) intersect {0};
        }
    `endif

    `ifdef COVER_F64
        F64_arith_case_i_iv: cross F64_result_fmt, F64_sign, F64_minsubnorm_m1_bit, F64_minsubnorm_m2_bit, F64_minsubnorm_m3_sticky, rounding_mode_all, B6_arith_ops {
            ignore_bins zero = binsof(F64_minsubnorm_m1_bit) intersect {0};
        }
        F64_arith_case_ii_iii: cross F64_result_fmt, F64_sign, F64_minsubnorm_m2_bit, F64_minsubnorm_m3_bit, F64_minsubnorm_m4_sticky, rounding_mode_all, B6_arith_ops {
            ignore_bins zero = binsof(F64_minsubnorm_m2_bit) intersect {0} && binsof(F64_minsubnorm_m3_bit) intersect {0} && binsof(F64_minsubnorm_m4_sticky) intersect {0};
        }

        F64_convert_case_i_iv: cross F64_result_fmt, F64_sign, F64_minsubnorm_m1_bit, F64_minsubnorm_m2_bit, F64_minsubnorm_m3_sticky, rounding_mode_all, B6_convert_ops, F64_convert_narrowing_sources {
            ignore_bins zero = binsof(F64_minsubnorm_m1_bit) intersect {0};
        }
        F64_convert_case_ii_iii: cross F64_result_fmt, F64_sign, F64_minsubnorm_m2_bit, F64_minsubnorm_m3_bit, F64_minsubnorm_m4_sticky, rounding_mode_all, B6_convert_ops, F64_convert_narrowing_sources {
            ignore_bins zero = binsof(F64_minsubnorm_m2_bit) intersect {0} && binsof(F64_minsubnorm_m3_bit) intersect {0} && binsof(F64_minsubnorm_m4_sticky) intersect {0};
        }
    `endif

    `ifdef COVER_F128
        F128_arith_case_i_iv: cross F128_result_fmt, F128_sign, F128_minsubnorm_m1_bit, F128_minsubnorm_m2_bit, F128_minsubnorm_m3_sticky, rounding_mode_all, B6_arith_ops {
            ignore_bins zero = binsof(F128_minsubnorm_m1_bit) intersect {0};
        }
        F128_arith_case_ii_iii: cross F128_result_fmt, F128_sign, F128_minsubnorm_m2_bit, F128_minsubnorm_m3_bit, F128_minsubnorm_m4_sticky, rounding_mode_all, B6_arith_ops {
            ignore_bins zero = binsof(F128_minsubnorm_m2_bit) intersect {0} && binsof(F128_minsubnorm_m3_bit) intersect {0} && binsof(F128_minsubnorm_m4_sticky) intersect {0};
        }

        // no F128 narrowing converts
    `endif

    `ifdef COVER_F16
        F16_arith_case_i_iv: cross F16_result_fmt, F16_sign, F16_minsubnorm_m1_bit, F16_minsubnorm_m2_bit, F16_minsubnorm_m3_sticky, rounding_mode_all, B6_arith_ops {
            ignore_bins zero = binsof(F16_minsubnorm_m1_bit) intersect {0};
        }
        F16_arith_case_ii_iii: cross F16_result_fmt, F16_sign, F16_minsubnorm_m2_bit, F16_minsubnorm_m3_bit, F16_minsubnorm_m4_sticky, rounding_mode_all, B6_arith_ops {
            ignore_bins zero = binsof(F16_minsubnorm_m2_bit) intersect {0} && binsof(F16_minsubnorm_m3_bit) intersect {0} && binsof(F16_minsubnorm_m4_sticky) intersect {0};
        }

        F16_convert_case_i_iv: cross F16_result_fmt, F16_sign, F16_minsubnorm_m1_bit, F16_minsubnorm_m2_bit, F16_minsubnorm_m3_sticky, rounding_mode_all, B6_convert_ops, F16_convert_narrowing_sources {
            ignore_bins zero = binsof(F16_minsubnorm_m1_bit) intersect {0};
        }
        F16_convert_case_ii_iii: cross F16_result_fmt, F16_sign, F16_minsubnorm_m2_bit, F16_minsubnorm_m3_bit, F16_minsubnorm_m4_sticky, rounding_mode_all, B6_convert_ops, F16_convert_narrowing_sources {
            ignore_bins zero = binsof(F16_minsubnorm_m2_bit) intersect {0} && binsof(F16_minsubnorm_m3_bit) intersect {0} && binsof(F16_minsubnorm_m4_sticky) intersect {0};
        }
    `endif

    `ifdef COVER_BF16
        BF16_arith_case_i_iv: cross BF16_result_fmt, BF16_sign, BF16_minsubnorm_m1_bit, BF16_minsubnorm_m2_bit, BF16_minsubnorm_m3_sticky, rounding_mode_all, B6_arith_ops {
            ignore_bins zero = binsof(BF16_minsubnorm_m1_bit) intersect {0};
        }
        BF16_arith_case_ii_iii: cross BF16_result_fmt, BF16_sign, BF16_minsubnorm_m2_bit, BF16_minsubnorm_m3_bit, BF16_minsubnorm_m4_sticky, rounding_mode_all, B6_arith_ops {
            ignore_bins zero = binsof(BF16_minsubnorm_m2_bit) intersect {0} && binsof(BF16_minsubnorm_m3_bit) intersect {0} && binsof(BF16_minsubnorm_m4_sticky) intersect {0};
        }

        BF16_convert_case_i_iv: cross BF16_result_fmt, BF16_sign, BF16_minsubnorm_m1_bit, BF16_minsubnorm_m2_bit, BF16_minsubnorm_m3_sticky, rounding_mode_all, B6_convert_ops, BF16_convert_narrowing_sources {
            ignore_bins zero = binsof(BF16_minsubnorm_m1_bit) intersect {0};
        }
        BF16_convert_case_ii_iii: cross BF16_result_fmt, BF16_sign, BF16_minsubnorm_m2_bit, BF16_minsubnorm_m3_bit, BF16_minsubnorm_m4_sticky, rounding_mode_all, B6_convert_ops, BF16_convert_narrowing_sources {
            ignore_bins zero = binsof(BF16_minsubnorm_m2_bit) intersect {0} && binsof(BF16_minsubnorm_m3_bit) intersect {0} && binsof(BF16_minsubnorm_m4_sticky) intersect {0};
        }
    `endif

endgroup
