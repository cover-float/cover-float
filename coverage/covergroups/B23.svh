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

covergroup B23_cg (virtual coverfloat_interface CFI);
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

    // Operation coverpoint
    FP2INT_op: coverpoint (CFI.op == OP_CFI) {
        type_option.weight = 0;
        bins convert_float_int = {1};
    }

    //Proximity To Max Int Coverpoints
    proximity_to_max_uint32: coverpoint $signed(get_proximity_to_max_int(CFI.a, CFI.operandFmt, FMT_UINT)){
        type_option.weight = 0;

        bins max_int = {1};
        bins max_int_plus_one_quarter = {2};
        bins max_int_plus_one_half = {3};
        bins max_int_plus_three_quarters = {4};
        bins max_int_plus_one = {5};
    }

    proximity_to_max_int32: coverpoint $signed(get_proximity_to_max_int(CFI.a, CFI.operandFmt, FMT_INT)){
        type_option.weight = 0;

        bins max_int = {1};
        bins max_int_plus_one_quarter = {2};
        bins max_int_plus_one_half = {3};
        bins max_int_plus_three_quarters = {4};
        bins max_int_plus_one = {5};
    }

    proximity_to_max_ulong64: coverpoint $signed(get_proximity_to_max_int(CFI.a, CFI.operandFmt, FMT_ULONG)){
        type_option.weight = 0;

        bins max_int = {1};
        bins max_int_plus_one_quarter = {2};
        bins max_int_plus_one_half = {3};
        bins max_int_plus_three_quarters = {4};
        bins max_int_plus_one = {5};
    }

    proximity_to_max_long64: coverpoint $signed(get_proximity_to_max_int(CFI.a, CFI.operandFmt, FMT_LONG)){
        type_option.weight = 0;

        bins max_int = {1};
        bins max_int_plus_one_quarter = {2};
        bins max_int_plus_one_half = {3};
        bins max_int_plus_three_quarters = {4};
        bins max_int_plus_one = {5};
    }

    //Special cases for fp_16, bf_16, and fmt_single
    //FP_16: No Cases
    //max_exp = 15; 2^15 < all possible values of maxInt

    //BF_16 Cases:
    //Each exponent must match the maxInt condition and each mantissa = 0
    BF16_proximity_to_max_uint32: coverpoint($signed(get_unbiased_exponent(CFI.a, CFI.operandFmt)) == 32 && CFI.a[BF16_M_UPPER: 0] == '0){
        type_option.weight = 0;

        bins BF16_max_int_plus_one_uint32 = {1};
    }

    BF16_proximity_to_max_int32: coverpoint($signed(get_unbiased_exponent(CFI.a, CFI.operandFmt)) == 31 && CFI.a[BF16_M_UPPER: 0] == '0){
        type_option.weight = 0;

        bins BF16_max_int_plus_one_int32 = {1};
    }

    BF16_proximity_to_max_ulong64: coverpoint($signed(get_unbiased_exponent(CFI.a, CFI.operandFmt)) == 64 && CFI.a[BF16_M_UPPER: 0] == '0){
        type_option.weight = 0;

        bins BF16_max_int_plus_one_ulong64 = {1};
    }

    BF16_proximity_to_max_long64: coverpoint($signed(get_unbiased_exponent(CFI.a, CFI.operandFmt)) == 63 && CFI.a[BF16_M_UPPER: 0] == '0){
        type_option.weight = 0;

        bins BF16_max_int_plus_one_long64 = {1};
    }

    //F32 special coverpoints
    F32_proximity_to_max_uint32: coverpoint($signed(get_unbiased_exponent(CFI.a, CFI.operandFmt)) == 32 && CFI.a[F32_M_UPPER: 0] == '0){
        type_option.weight = 0;

        bins F32_max_int_plus_one_uint32 = {1};
    }

    F32_proximity_to_max_int32: coverpoint($signed(get_unbiased_exponent(CFI.a, CFI.operandFmt)) == 31 && CFI.a[F32_M_UPPER: 0] == '0){
        type_option.weight = 0;

        bins F32_max_int_plus_one_int32 = {1};
    }

    F32_proximity_to_max_ulong64: coverpoint($signed(get_unbiased_exponent(CFI.a, CFI.operandFmt)) == 64 && CFI.a[F32_M_UPPER: 0] == '0){
        type_option.weight = 0;

        bins F32_max_int_plus_one_ulong64 = {1};
    }

    F32_proximity_to_max_long64: coverpoint($signed(get_unbiased_exponent(CFI.a, CFI.operandFmt)) == 63 && CFI.a[F32_M_UPPER: 0] == '0){
        type_option.weight = 0;

        bins F32_max_int_plus_one_long64 = {1};
    }

    //Result format coverpoints
    result_int32_fmt: coverpoint (CFI.resultFmt == FMT_INT) {
        type_option.weight = 0;

        bins int32 = {1};
    }

    result_uint32_fmt: coverpoint(CFI.result == FMT_UINT) {
        type_option.weight = 0;

        bins uint32 = {1};
    }

    result_long64_fmt: coverpoint (CFI.resultFmt == FMT_LONG) {
        type_option.weight = 0;

        bins long64 = {1};
    }

    result_ulong64_fmt: coverpoint (CFI.resultFmt == FMT_ULONG){
        type_option.weight = 0;

        bins ulong64 = {1};
    }

    //Crosses
    //Not all precisions have the exponent or mantissa range to reach maxInt. The values of MaxInt:
    //max_int32: 2^32 - 1
    //max_uint32: 2^33 - 1
    //max_long64: 2^64 - 1
    //max_ulong64: 2^65 - 1
    //FMT_HALF
    //Half precision only has the exponent range to satisfy maxInt + 1
    //exp_bits = 5; bias = 15;
    //The largest unbiased HP EXP = 2^5 - 17 = 15

    //FMT_BF16
    //BF_16 only has the exponent range to satisfy maxInt + 1
    //The largest unbiased BF_16 EXP = 2^8 - (127 + 2) = 127
    `ifdef COVER_BF16
        B23_BF16_INT: cross BF16_input_fmt, FP2INT_op, BF16_proximity_to_max_int32, result_int32_fmt;
        B23_BF16_UINT: cross BF16_input_fmt, FP2INT_op, BF16_proximity_to_max_uint32, result_uint32_fmt;
        `ifdef COVER_LONG
            B23_BF16_LONG: cross BF16_input_fmt, FP2INT_op, BF16_proximity_to_max_long64, result_long64_fmt;
            B23_BF16_ULONG: cross BF16_input_fmt, FP2INT_op, BF16_proximity_to_max_ulong64, result_ulong64_fmt;
        `endif
    `endif

    //FMT_SINGLE
    //F32 only has the exponent range to satisfy maxInt + 1, mantissa range lacks enough precision
    //The largest exponent is 2^8 - (127 + 2) = 127
    `ifdef COVER_F32
        B23_F32_INT: cross F32_input_fmt, FP2INT_op, F32_proximity_to_max_int32, result_int32_fmt;
        B23_F32_UINT: cross F32_input_fmt, FP2INT_op, F32_proximity_to_max_uint32, result_uint32_fmt;
        `ifdef COVER_LONG
            B23_F32_LONG: cross F32_input_fmt, FP2INT_op, F32_proximity_to_max_long64, result_long64_fmt;
            B23_F32_ULONG: cross F32_input_fmt, FP2INT_op, F32_proximity_to_max_ulong64, result_ulong64_fmt;
        `endif
    `endif

    //FMT_DOUBLE
    //sufficient exponent and mantissa range to reach all values
    `ifdef COVER_F64
        B64_F64_INT: cross F64_input_fmt, FP2INT_op, proximity_to_max_int32, result_int32_fmt;
        B23_F64_UINT: cross F64_input_fmt, FP2INT_op, proximity_to_max_uint32, result_uint32_fmt;
        `ifdef COVER_LONG
            B23_F64_LONG: cross F64_input_fmt, FP2INT_op, proximity_to_max_long64, result_long64_fmt;
            B23_F64_ULONG: cross F64_input_fmt, FP2INT_op, proximity_to_max_ulong64, result_ulong64_fmt;
        `endif
    `endif

    //FMT_QUAD
    //sufficient exponent and mantissa range to reach all values
    `ifdef COVER_F128
        B23_F128_INT: cross F128_input_fmt, FP2INT_op, proximity_to_max_int32, result_int32_fmt;
        B23_F128_UINT: cross F128_input_fmt, FP2INT_op, proximity_to_max_uint32, result_uint32_fmt;
        `ifdef COVER_LONG
            B23_F128_LONG: cross F128_input_fmt, FP2INT_op, proximity_to_max_long64, result_long64_fmt;
            B23_F128_ULONG: cross F128_input_fmt, FP2INT_op, proximity_to_max_ulong64, result_ulong64_fmt;
        `endif
    `endif

endgroup
