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

covergroup B24_cg (virtual coverfloat_interface CFI);
    option.per_instance = 0;

    //Rounding Mode coverpoint
    rounding_modes: coverpoint(CFI.rm){
        type_option.weight = 0;
        `include "bins_templates/rounding_modes_bins.svh"
    }

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
    F16_sign: coverpoint CFI.result[F16_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    BF16_sign: coverpoint CFI.result[BF16_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F32_sign: coverpoint CFI.result[F32_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F64_sign: coverpoint CFI.result[F64_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F128_sign: coverpoint CFI.result[F128_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    // Operation coverpoint
    FP2INT_op: coverpoint (CFI.op == OP_CFI) {
        type_option.weight = 0;
        bins convert_float_int = {1};
    }

    //Proximity To Zero Coverpoint
    proximity_to_zero: coverpoint $signed(get_proximity_to_zero(CFI.a, CFI.operandFmt)){
        type_option.weight = 0;
        bins zero = {1};
        bins one_quarter = {2};
        bins one_half = {3};
        bins three_quarters = {4};
        bins one = {5};
        bins one_and_one_quarter = {6};
        bins one_and_one_half = {7};
        bins one_and_three_quarters = {8};
    }

    //Result format coverpoints
    result_int32_fmt: coverpoint CFI.resultFmt {
        type_option.weight = 0;

        bins int32 = {FMT_INT};
        bins uint32 = {FMT_UINT};
    }

    result_long64_fmt: coverpoint CFI.resultFmt {
        type_option.weight = 0;

        bins int64 = {FMT_LONG};
        bins uint64 = {FMT_ULONG};
    }

    //Crosses
    //FMT_HALF
    `ifdef COVER_F16
        B22_F16_INT: cross rounding_modes, F16_input_fmt, F16_sign, FP2INT_op, proximity_to_zero, result_int32_fmt;
        `ifdef COVER_LONG
            B22_F16_LONG: cross rounding_modes, F16_input_fmt, F16_sign, FP2INT_op, proximity_to_zero, result_long64_fmt;
        `endif
    `endif

    //FMT_BF16
    `ifdef COVER_BF16
        B22_BF16_INT: cross rounding_modes, BF16_input_fmt, BF16_sign, FP2INT_op, proximity_to_zero, result_int32_fmt;
        `ifdef COVER_LONG
            B22_BF16_LONG: cross rounding_modes, BF16_input_fmt, BF16_sign, FP2INT_op, proximity_to_zero, result_long64_fmt;
        `endif
    `endif

    //FMT_SINGLE
    `ifdef COVER_F32
        B22_F32_INT: cross rounding_modes, F32_input_fmt, F32_sign, FP2INT_op, proximity_to_zero, result_int32_fmt;
        `ifdef COVER_LONG
            B22_F32_LONG: cross rounding_modes, F32_input_fmt, F32_sign, FP2INT_op, proximity_to_zero, result_long64_fmt;
        `endif
    `endif

    //FMT_DOUBLE
    `ifdef COVER_F64
        B22_F64_INT: cross rounding_modes, F64_input_fmt, F64_sign, FP2INT_op, proximity_to_zero, result_int32_fmt;
        `ifdef COVER_LONG
            B22_F64_LONG: cross rounding_modes, F64_input_fmt, F64_sign, FP2INT_op, proximity_to_zero, result_long64_fmt;
        `endif
    `endif

    //FMT_QUAD
    `ifdef COVER_F128
        B22_F128_INT: cross rounding_modes, F128_input_fmt, F128_sign, FP2INT_op, proximity_to_zero, result_int32_fmt;
        `ifdef COVER_LONG
            B22_F128_LONG: cross rounding_modes, F128_input_fmt, F128_sign, FP2INT_op, proximity_to_zero, result_long64_fmt;
        `endif
    `endif

endgroup
