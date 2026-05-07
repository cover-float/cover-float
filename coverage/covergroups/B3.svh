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

covergroup B3_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;


    F32_sign: coverpoint CFI.result[31] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F64_sign: coverpoint CFI.result[63] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F128_sign: coverpoint CFI.result[127] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F16_sign: coverpoint CFI.result[15] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    BF16_sign: coverpoint CFI.result[15] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    interm_sign: coverpoint CFI.intermS {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }


    F16_LSB:   coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS     ] {
        type_option.weight = 0;
    }
    F32_LSB:   coverpoint CFI.intermM[INTERM_M_BITS - F32_M_BITS     ] {
        type_option.weight = 0;
    }
    F64_LSB:   coverpoint CFI.intermM[INTERM_M_BITS - F64_M_BITS     ] {
        type_option.weight = 0;
    }
    F128_LSB:  coverpoint CFI.intermM[INTERM_M_BITS - F128_M_BITS    ] {
        type_option.weight = 0;
    }
    BF16_LSB:  coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS    ] {
        type_option.weight = 0;
    }
    int_LSB:   coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT + 1 ] {
        type_option.weight = 0;
    }
    uint_LSB:  coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT     ] {
        type_option.weight = 0;
    }
    long_LSB:  coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG + 1 ] {
        type_option.weight = 0;
    }
    ulong_LSB: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG     ] {
        type_option.weight = 0;
    }


    F16_guard:  coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS - 1] {
        type_option.weight = 0;
    }
    F32_guard:  coverpoint CFI.intermM[INTERM_M_BITS - F32_M_BITS - 1] {
        type_option.weight = 0;
    }
    F64_guard:  coverpoint CFI.intermM[INTERM_M_BITS - F64_M_BITS - 1] {
        type_option.weight = 0;
    }
    F128_guard: coverpoint CFI.intermM[INTERM_M_BITS - F128_M_BITS - 1] {
        type_option.weight = 0;
    }
    BF16_guard: coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 1] {
        type_option.weight = 0;
    }
    int_guard:  coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT     ] {
        type_option.weight = 0;
    }
    uint_guard: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 ] {
        type_option.weight = 0;
    }
    long_guard: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG    ] {
        type_option.weight = 0;
    }
    ulong_guard: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1] {
        type_option.weight = 0;
    }


    F16_sticky:  coverpoint |CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 : 0] {
        type_option.weight = 0;
    }
    F32_sticky:  coverpoint |CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 : 0] {
        type_option.weight = 0;
    }
    F64_sticky:  coverpoint |CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 : 0] {
        type_option.weight = 0;
    }
    F128_sticky: coverpoint |CFI.intermM[INTERM_M_BITS - F128_M_BITS - 2 : 0] {
        type_option.weight = 0;
    }
    BF16_sticky: coverpoint |CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 : 0] {
        type_option.weight = 0;
    }
    int_sticky:  coverpoint |CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 : 0] {
        type_option.weight = 0;
    }
    uint_sticky: coverpoint |CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2  : 0] {
        type_option.weight = 0;
    }
    long_sticky: coverpoint |CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 : 0] {
        type_option.weight = 0;
    }
    ulong_sticky: coverpoint |CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 : 0] {
        type_option.weight = 0;
    }

    rounding_mode_all: coverpoint CFI.rm {
        type_option.weight = 0;
        bins round_near_even   = {ROUND_NEAR_EVEN};
        bins round_minmag      = {ROUND_MINMAG};
        bins round_min         = {ROUND_MIN};
        bins round_max         = {ROUND_MAX};
        bins round_near_maxmag = {ROUND_NEAR_MAXMAG};
    }


    FP_arith_ops: coverpoint CFI.op {
        type_option.weight = 0;
        `include "bins_templates/arithmetic_op_bins.svh"
    }

    FP_convert_ops: coverpoint CFI.op {
        type_option.weight = 0;
        // checks that a convert is happening (F2X, X2F, or F2F)
        // operand and result formats infer which type

        bins convert = {OP_CFI, OP_CFF, OP_CIF};
        // bins op_cfi
        // bins op_cff
        // bins op_cif
    }

    FP_int_convert_fmt: coverpoint CFI.operandFmt {
        type_option.weight = 0;
        // all formats to convert to

        `ifdef COVER_F16
            bins fmt_half   = {FMT_HALF};
        `endif // COVER_F16

        `ifdef COVER_F32
            bins fmt_single = {FMT_SINGLE};
        `endif // COVER_F32

        `ifdef COVER_F64
            bins fmt_double = {FMT_DOUBLE};
        `endif // COVER_F64

        `ifdef COVER_F128
            bins fmt_quad   = {FMT_QUAD};
        `endif // COVER_F128

        `ifdef COVER_BF16
            bins fmt_bf16   = {FMT_BF16};
        `endif // COVER_BF16

        bins fmt_int    = {FMT_INT};
        bins fmt_uint   = {FMT_UINT};

        `ifdef COVER_LONG
            bins fmt_long  = {FMT_LONG};
            bins fmt_ulong = {FMT_ULONG};
        `endif // COVER_LONG
    }

    FP_convert_fmt: coverpoint CFI.operandFmt {
        type_option.weight = 0;
        // all formats to convert to

        `ifdef COVER_F16
            bins fmt_half   = {FMT_HALF};
        `endif // COVER_F16

        `ifdef COVER_F32
            bins fmt_single = {FMT_SINGLE};
        `endif // COVER_F32

        `ifdef COVER_F64
            bins fmt_double = {FMT_DOUBLE};
        `endif // COVER_F64

        `ifdef COVER_F128
            bins fmt_quad   = {FMT_QUAD};
        `endif // COVER_F128

        `ifdef COVER_BF16
            bins fmt_bf16   = {FMT_BF16};
        `endif // COVER_BF16
    }

    F16_result_fmt: coverpoint CFI.resultFmt == FMT_HALF {
        type_option.weight = 0;
        // half precision format for result
        bins f16 = {1};
    }

    BF16_result_fmt: coverpoint CFI.resultFmt == FMT_BF16 {
        type_option.weight = 0;
        // bfloat16 precision format for result
        bins bf16 = {1};
    }

    F32_result_fmt: coverpoint CFI.resultFmt == FMT_SINGLE {
        type_option.weight = 0;
        // single precision format for result
        bins f32 = {1};
    }

    F64_result_fmt: coverpoint CFI.resultFmt == FMT_DOUBLE {
        type_option.weight = 0;
        // half precision format for result
        bins f64 = {1};
    }

    F128_result_fmt: coverpoint CFI.resultFmt == FMT_QUAD {
        type_option.weight = 0;
        // quad precision format for result
        bins f128 = {1};
    }

    int_result_fmt : coverpoint CFI.resultFmt == FMT_INT {
        type_option.weight = 0;
        // int format for result
        bins fmt_int = {1};
    }
    uint_result_fmt : coverpoint CFI.resultFmt == FMT_UINT {
        type_option.weight = 0;
        // uint format for result
        bins fmt_uint = {1};
    }
    long_result_fmt : coverpoint CFI.resultFmt == FMT_LONG {
        type_option.weight = 0;
        // long format for result
        bins fmt_long = {1};
    }
    ulong_result_fmt : coverpoint CFI.resultFmt == FMT_ULONG {
        type_option.weight = 0;
        // ulong format for result
        bins fmt_ulong = {1};
    }

    // main coverpoints

    B3_int_convert:  cross FP_convert_ops, rounding_mode_all, interm_sign, int_LSB,  int_guard,  int_sticky, FP_convert_fmt,  int_result_fmt;
    B3_uint_convert: cross FP_convert_ops, rounding_mode_all,             uint_LSB, uint_guard, uint_sticky, FP_convert_fmt, uint_result_fmt;

    `ifdef COVER_LONG
        B3_long_convert:  cross FP_convert_ops, rounding_mode_all, interm_sign, long_LSB,  long_guard,  long_sticky, FP_convert_fmt,  long_result_fmt;
        B3_ulong_convert: cross FP_convert_ops, rounding_mode_all,             ulong_LSB, ulong_guard, ulong_sticky, FP_convert_fmt, ulong_result_fmt;
    `endif // COVER_LONG

    `ifdef COVER_F32
        B3_F32_arith:  cross FP_arith_ops, rounding_mode_all, F32_sign, F32_LSB,  F32_guard,  F32_sticky, F32_result_fmt {
            ignore_bins negative_sqrt = binsof(FP_arith_ops.op_sqrt) && binsof(F32_sign.neg);
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt) with (!F32_sticky && (F32_guard || F32_LSB));
        }
        B3_F32_convert: cross FP_convert_ops, rounding_mode_all, F32_sign, F32_LSB, F32_guard, F32_sticky, FP_int_convert_fmt, F32_result_fmt {
            ignore_bins negative_uint = binsof(F32_sign.neg) && binsof(FP_int_convert_fmt.fmt_uint);

            `ifdef COVER_LONG
                ignore_bins negative_ulong = binsof(F32_sign.neg) && binsof(FP_int_convert_fmt.fmt_ulong);
            `endif // COVER_LONG

            ignore_bins invalid_convert = binsof(FP_int_convert_fmt.fmt_single);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f32 = binsof(FP_int_convert_fmt.fmt_half);
            `endif // COVER_F64

            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f32 = binsof(FP_int_convert_fmt.fmt_bf16);
            `endif // COVER_F64
        }
    `endif // COVER_F32

    `ifdef COVER_F64
        B3_F64_arith:  cross FP_arith_ops, rounding_mode_all, F64_sign, F64_LSB,  F64_guard,  F64_sticky, F64_result_fmt {
            ignore_bins negative_sqrt = binsof(FP_arith_ops.op_sqrt) && binsof(F64_sign.neg);
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt) with (!F64_sticky && (F64_guard || F64_LSB));
        }
        B3_F64_convert: cross FP_convert_ops, rounding_mode_all, F64_sign, F64_LSB, F64_guard, F64_sticky, FP_int_convert_fmt, F64_result_fmt {
            ignore_bins widen_int_to_f64 = binsof(FP_int_convert_fmt.fmt_uint) || binsof(FP_int_convert_fmt.fmt_int);

            `ifdef COVER_LONG
                ignore_bins negative_ulong = binsof(F64_sign.neg) && binsof(FP_int_convert_fmt.fmt_ulong);
            `endif // COVER_LONG

            ignore_bins invalid_convert = binsof(FP_int_convert_fmt.fmt_double);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f64 = binsof(FP_int_convert_fmt.fmt_half);
            `endif // COVER_F64

            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f64 = binsof(FP_int_convert_fmt.fmt_bf16);
            `endif // COVER_F64

            `ifdef COVER_F32
                ignore_bins widen_f32_to_f64 = binsof(FP_int_convert_fmt.fmt_single);
            `endif // COVER_F64
        }
    `endif // COVER_F64

    `ifdef COVER_F16
        B3_F16_arith:  cross FP_arith_ops, rounding_mode_all, F16_sign, F16_LSB,  F16_guard,  F16_sticky, F16_result_fmt {
            ignore_bins negative_sqrt = binsof(FP_arith_ops.op_sqrt) && binsof(F16_sign.neg);
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt) with (!F16_sticky && (F16_guard || F16_LSB));
        }
        B3_F16_convert: cross FP_convert_ops, rounding_mode_all, F16_sign, F16_LSB, F16_guard, F16_sticky, FP_int_convert_fmt, F16_result_fmt {
            ignore_bins negative_uint = binsof(F16_sign.neg) && binsof(FP_int_convert_fmt.fmt_uint);

            `ifdef COVER_LONG
                ignore_bins negative_ulong = binsof(F16_sign.neg) && binsof(FP_int_convert_fmt.fmt_ulong);
            `endif // COVER_LONG

            ignore_bins invalid_convert = binsof(FP_int_convert_fmt.fmt_half);

            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f16 = binsof(FP_int_convert_fmt.fmt_bf16);
            `endif // COVER_F128
        }
    `endif // COVER_F16

    `ifdef COVER_BF16
        B3_BF16_arith: cross FP_arith_ops, rounding_mode_all, BF16_sign, BF16_LSB, BF16_guard, BF16_sticky, BF16_result_fmt {
            ignore_bins negative_sqrt = binsof(FP_arith_ops.op_sqrt) && binsof(BF16_sign.neg);
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt) with (!BF16_sticky && (BF16_guard || BF16_LSB));
        }
        B3_BF16_convert: cross FP_convert_ops, rounding_mode_all, BF16_sign, BF16_LSB, BF16_guard, BF16_sticky, FP_int_convert_fmt, BF16_result_fmt {
            ignore_bins negative_uint = binsof(BF16_sign.neg) && binsof(FP_int_convert_fmt.fmt_uint);

            `ifdef COVER_LONG
                ignore_bins negative_ulong = binsof(BF16_sign.neg) && binsof(FP_int_convert_fmt.fmt_ulong);
            `endif // COVER_LONG

            ignore_bins invalid_convert = binsof(FP_int_convert_fmt.fmt_bf16);

        }
    `endif // COVER_BF16

    `ifdef COVER_F128
        B3_F128_arith: cross FP_arith_ops, rounding_mode_all, F128_sign, F128_LSB, F128_guard, F128_sticky, F128_result_fmt {
            ignore_bins negative_sqrt = binsof(FP_arith_ops.op_sqrt) && binsof(F128_sign.neg);
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt) with (!F128_sticky && (F128_guard || F128_LSB));
        }
        B3_F128_convert: cross FP_convert_ops, rounding_mode_all, F128_sign, F128_LSB, F128_guard, F128_sticky, FP_int_convert_fmt, F128_result_fmt {
            ignore_bins widen_int_to_f128 = binsof(FP_int_convert_fmt.fmt_uint) || binsof(FP_int_convert_fmt.fmt_int);

            `ifdef COVER_LONG
                ignore_bins widen_long_to_f128 = binsof(FP_int_convert_fmt.fmt_ulong) || binsof(FP_int_convert_fmt.fmt_long);
            `endif // COVER_LONG

            ignore_bins invalid_convert = binsof(FP_int_convert_fmt.fmt_quad);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f128 = binsof(FP_int_convert_fmt.fmt_half);
            `endif // COVER_F16

            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f128 = binsof(FP_int_convert_fmt.fmt_bf16);
            `endif // COVER_BF16

            `ifdef COVER_F32
                ignore_bins widen_f32_to_f128 = binsof(FP_int_convert_fmt.fmt_single);
            `endif // COVER_F32

            `ifdef COVER_F64
                ignore_bins widen_f64_to_f128 = binsof(FP_int_convert_fmt.fmt_double);
            `endif // COVER_F64
        }
    `endif // COVER_F128


endgroup
