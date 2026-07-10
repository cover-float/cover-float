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

covergroup B22_cg (virtual coverfloat_interface CFI);
    option.per_instance = 0;

    // Input Precision coverpoints
    F16_input_fmt: coverpoint (CFI.operandFmt == FMT_HALF) {
        type_option.weight = 0;
        bins f16 = {1};
    }

    BF16_input_fmt: coverpoint (CFI.operandFmt == FMT_BF16) {
        type_option.weight = 0;
        bins bf16 = {1};
    }

    F32_input_fmt: coverpoint (CFI.operandFmt == FMT_SINGLE) {
        type_option.weight = 0;
        bins f32 = {1};
    }

    F64_input_fmt: coverpoint (CFI.operandFmt == FMT_DOUBLE) {
        type_option.weight = 0;
        bins f64 = {1};
    }

    F128_input_fmt: coverpoint (CFI.operandFmt == FMT_QUAD) {
        type_option.weight = 0;
        bins f128 = {1};
    }

    // Sign coverpoints
    F16_sign: coverpoint CFI.a[F16_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    BF16_sign: coverpoint CFI.a[BF16_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F32_sign: coverpoint CFI.a[F32_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F64_sign: coverpoint CFI.a[F64_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F128_sign: coverpoint CFI.a[F128_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    // Operation coverpoint
    FP2INT_op: coverpoint (CFI.op == OP_CFI) {
        type_option.weight = 0;
        bins convert_float_int = {1};
    }

    //Result format coverpoints
    result_int32_fmt: coverpoint CFI.resultFmt {
        type_option.weight = 0;

        bins int32 = {FMT_INT};
    }

    result_uint32_fmt: coverpoint CFI.resultFmt {
        type_option.weight = 0;

        bins uint32 = {FMT_UINT};
    }

    result_long64_fmt: coverpoint CFI.resultFmt {
        type_option.weight = 0;

        bins int64 = {FMT_LONG};
    }

    result_ulong64_fmt: coverpoint CFI.resultFmt {
        type_option.weight = 0;

        bins uint64 = {FMT_ULONG};
    }

    //F16's max unbiased exponent is 15, below the limit for both int and long bit width
    //This will be able to satisfy both the int and long possible cases for half precision
    f16_exponent_dif: coverpoint $signed(get_unbiased_exponent(CFI.a, CFI.operandFmt)){
        type_option.weight = 0;

        bins less_than_neg_3 = {[$:-4]};
        bins between_neg_3_and_15[] = {[-3:15]};
    }

    //Input Exponent Coverpoint, only need 2 because unsigned/signed ints/longs have same width
    exponent_dif_int32: coverpoint $signed(get_unbiased_exponent(CFI.a, CFI.operandFmt)){
        type_option.weight = 0;

        bins less_than_neg_3 = {[$:-4]};
        bins between_neg_3_and_int_width_plus_3[] = {[-3:SIZEOF_INT + 3]};
        bins greater_than_int_width_plus_3 = {[SIZEOF_INT + 4:$]};
    }

    exponent_dif_long64: coverpoint $signed(get_unbiased_exponent(CFI.a, CFI.operandFmt)){
        type_option.weight = 0;

        bins less_than_neg_3 = {[$:-4]};
        bins between_neg_3_and_int_width_plus_3[] = {[-3:SIZEOF_LONG + 3]};
        bins greater_than_int_width_plus_3 = {[SIZEOF_LONG + 4:$]};
    }

    //Crosses
    //FMT_HALF
    `ifdef COVER_F16
        B22_F16_INT: cross F16_input_fmt, F16_sign, FP2INT_op, result_int32_fmt, f16_exponent_dif;
        B22_F16_UINT: cross F16_input_fmt, FP2INT_op, result_uint32_fmt, f16_exponent_dif;

        `ifdef COVER_LONG
            B22_F16_LONG: cross F16_input_fmt, F16_sign, FP2INT_op, result_long64_fmt, f16_exponent_dif;
            B22_F16_ULONG: cross F16_input_fmt, FP2INT_op, result_ulong64_fmt, f16_exponent_dif;
        `endif
    `endif

    // FMT_BF16
    `ifdef COVER_BF16
        B22_BF16_INT: cross BF16_input_fmt, BF16_sign, FP2INT_op, result_int32_fmt, exponent_dif_int32;
        B22_BF16_UINT: cross BF16_input_fmt, FP2INT_op, result_uint32_fmt, exponent_dif_int32;

        `ifdef COVER_LONG
            B22_BF16_LONG: cross BF16_input_fmt, BF16_sign, FP2INT_op, result_long64_fmt, exponent_dif_long64;
            B22_BF16_ULONG: cross BF16_input_fmt, FP2INT_op, result_ulong64_fmt, exponent_dif_long64;
        `endif
    `endif

    // FMT_SINGLE
    `ifdef COVER_F32
        B22_F32_INT: cross F32_input_fmt, F32_sign, FP2INT_op, result_int32_fmt, exponent_dif_int32;
        B22_F32_UINT: cross F32_input_fmt, FP2INT_op, result_uint32_fmt, exponent_dif_int32;

        `ifdef COVER_LONG
            B22_F32_LONG: cross F32_input_fmt, F32_sign, FP2INT_op, result_long64_fmt, exponent_dif_long64;
            B22_F32_ULONG: cross F32_input_fmt, FP2INT_op, result_ulong64_fmt, exponent_dif_long64;
        `endif
    `endif

    // FMT_DOUBLE
    `ifdef COVER_F64
        B22_F64_INT: cross F64_input_fmt, F64_sign, FP2INT_op, result_int32_fmt, exponent_dif_int32;
        B22_F64_UINT: cross F64_input_fmt, FP2INT_op, result_uint32_fmt, exponent_dif_int32;

        `ifdef COVER_LONG
            B22_F64_LONG: cross F64_input_fmt, F64_sign, FP2INT_op, result_long64_fmt, exponent_dif_long64;
            B22_F64_ULONG: cross F64_input_fmt, FP2INT_op, result_ulong64_fmt, exponent_dif_long64;
        `endif
    `endif

    // FMT_QUAD
    `ifdef COVER_F128
        B22_F128_INT: cross F128_input_fmt, F128_sign, FP2INT_op, result_int32_fmt, exponent_dif_int32;
        B22_F128_UINT: cross F128_input_fmt, FP2INT_op, result_uint32_fmt, exponent_dif_int32;

        `ifdef COVER_LONG
            B22_F128_LONG: cross F128_input_fmt, F128_sign, FP2INT_op, result_long64_fmt, exponent_dif_long64;
            B22_F128_ULONG: cross F128_input_fmt, FP2INT_op, result_ulong64_fmt, exponent_dif_long64;
        `endif
    `endif

endgroup
