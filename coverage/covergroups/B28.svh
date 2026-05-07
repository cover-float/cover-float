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

covergroup B28_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;

    // Source Format Helpers

    F16_src_fmt: coverpoint (CFI.operandFmt == FMT_HALF) {
        type_option.weight = 0;
        bins f16 = {1};
    }

    BF16_src_fmt: coverpoint (CFI.operandFmt == FMT_BF16) {
        type_option.weight = 0;
        bins bf16 = {1};
    }

    F32_src_fmt: coverpoint (CFI.operandFmt == FMT_SINGLE) {
        type_option.weight = 0;
        bins f32 = {1};
    }

    F64_src_fmt: coverpoint (CFI.operandFmt == FMT_DOUBLE) {
        type_option.weight = 0;
        bins f64 = {1};
    }

    F128_src_fmt: coverpoint (CFI.operandFmt == FMT_QUAD) {
        type_option.weight = 0;
        bins f128 = {1};
    }

    // RFI Instruction

    RFI_op: coverpoint CFI.op {
        type_option.weight = 0;
        bins rfi = { OP_RFI };
    }



    // F32 Inputs
    F32_basic_inputs: coverpoint CFI.a[30:0] { // Exclude Sign Explicitly
        type_option.weight = 0;

        bins zero = { 'b0 };
        bins one = { F32_ONE };
        bins max = { F32_RFI_MAX };
        // Takes advantage of floating point comparison being integer comparisons, but needs -1, +1 for open interval
        bins zero_to_one = { [32'b1:F32_ONE-1]};
        bins one_to_max = { [F32_ONE+1:F32_RFI_MAX-1] };
    }

    // Captures all ones in exponent and non zero mantissa
    F32_nan: coverpoint (&CFI.a[F32_E_UPPER:F32_E_LOWER] & |CFI.a[F32_M_UPPER:0]){
        type_option.weight = 0;
        bins nan = { 1 };
    }

    // Captures all ones in exponent and zero mantissa
    F32_infinity: coverpoint (&CFI.a[F32_E_UPPER:F32_E_LOWER] & ~&CFI.a[F32_M_UPPER:0]) {
        type_option.weight = 0;
        bins infinity = { 1 };
    }

    F32_case_iv: coverpoint { CFI.a[F32_E_UPPER:F32_E_LOWER], CFI.a[F32_M_UPPER:F32_M_UPPER-2] } {
        type_option.weight = 0;
        bins _1_01 = { (F32_EXP_BIAS << 3) | 3'b010 };
        bins _1_10 = { (F32_EXP_BIAS << 3) | 3'b100 };
        bins _1_11 = { (F32_EXP_BIAS << 3) | 3'b110 };
        bins _10_00 = { ((F32_EXP_BIAS + 1) << 3) | 3'b000 };
        bins _10_01 = { ((F32_EXP_BIAS + 1) << 3) | 3'b001 };
        bins _10_10 = { ((F32_EXP_BIAS + 1) << 3) | 3'b010 };
        bins _10_11 = { ((F32_EXP_BIAS + 1) << 3) | 3'b011 };
    }

    F32_sign: coverpoint CFI.a[F32_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = { 0 };
        bins neg = { 1 };
    }

    // F64 Inputs
    F64_basic_inputs: coverpoint CFI.a[62:0] { // Exclude Sign Explicitly
        type_option.weight = 0;

        bins zero = { 'b0 };
        bins one = { F64_ONE };
        bins max = { F64_RFI_MAX };
        // Takes advantage of floating point comparison being integer comparisons, but needs -1, +1 for open interval
        bins zero_to_one = { [32'b1:F64_ONE-1]};
        bins one_to_max = { [F64_ONE+1:F64_RFI_MAX-1] };
    }

    // Captures all ones in exponent and non zero mantissa
    F64_nan: coverpoint (&CFI.a[F64_E_UPPER:F64_E_LOWER] & |CFI.a[F64_M_UPPER:0]){
        type_option.weight = 0;
        bins nan = { 1 };
    }

    // Captures all ones in exponent and zero mantissa
    F64_infinity: coverpoint (&CFI.a[F64_E_UPPER:F64_E_LOWER] & ~&CFI.a[F64_M_UPPER:0]) {
        type_option.weight = 0;
        bins infinity = { 1 };
    }

    F64_case_iv: coverpoint { CFI.a[F64_E_UPPER:F64_E_LOWER], CFI.a[F64_M_UPPER:F64_M_UPPER-2] } {
        type_option.weight = 0;
        bins _1_01 = { (F64_EXP_BIAS << 3) | 3'b010 };
        bins _1_10 = { (F64_EXP_BIAS << 3) | 3'b100 };
        bins _1_11 = { (F64_EXP_BIAS << 3) | 3'b110 };
        bins _10_00 = { ((F64_EXP_BIAS + 1) << 3) | 3'b000 };
        bins _10_01 = { ((F64_EXP_BIAS + 1) << 3) | 3'b001 };
        bins _10_10 = { ((F64_EXP_BIAS + 1) << 3) | 3'b010 };
        bins _10_11 = { ((F64_EXP_BIAS + 1) << 3) | 3'b011 };
    }

    F64_sign: coverpoint CFI.a[F64_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = { 0 };
        bins neg = { 1 };
    }

    // F128 Inputs
    F128_basic_inputs: coverpoint CFI.a[126:0] { // Exclude Sign Explicitly
        type_option.weight = 0;

        bins zero = { 'b0 };
        bins one = { F128_ONE };
        bins max = { F128_RFI_MAX };
        // Takes advantage of floating point comparison being integer comparisons, but needs -1, +1 for open interval
        bins zero_to_one = { [32'b1:F128_ONE-1]};
        bins one_to_max = { [F128_ONE+1:F128_RFI_MAX-1] };
    }

    // Captures all ones in exponent and non zero mantissa
    F128_nan: coverpoint (&CFI.a[F128_E_UPPER:F128_E_LOWER] & |CFI.a[F128_M_UPPER:0]){
        type_option.weight = 0;
        bins nan = { 1 };
    }

    // Captures all ones in exponent and zero mantissa
    F128_infinity: coverpoint (&CFI.a[F128_E_UPPER:F128_E_LOWER] & ~&CFI.a[F128_M_UPPER:0]) {
        type_option.weight = 0;
        bins infinity = { 1 };
    }

    F128_case_iv: coverpoint { CFI.a[F128_E_UPPER:F128_E_LOWER], CFI.a[F128_M_UPPER:F128_M_UPPER-2] } {
        type_option.weight = 0;
        bins _1_01 = { (F128_EXP_BIAS << 3) | 3'b010 };
        bins _1_10 = { (F128_EXP_BIAS << 3) | 3'b100 };
        bins _1_11 = { (F128_EXP_BIAS << 3) | 3'b110 };
        bins _10_00 = { ((F128_EXP_BIAS + 1) << 3) | 3'b000 };
        bins _10_01 = { ((F128_EXP_BIAS + 1) << 3) | 3'b001 };
        bins _10_10 = { ((F128_EXP_BIAS + 1) << 3) | 3'b010 };
        bins _10_11 = { ((F128_EXP_BIAS + 1) << 3) | 3'b011 };
    }

    F128_sign: coverpoint CFI.a[F128_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = { 0 };
        bins neg = { 1 };
    }

    // F16 Inputs
    F16_basic_inputs: coverpoint CFI.a[14:0] { // Exclude Sign Explicitly
        type_option.weight = 0;

        bins zero = { 'b0 };
        bins one = { F16_ONE };
        bins max = { F16_RFI_MAX };
        // Takes advantage of floating point comparison being integer comparisons, but needs -1, +1 for open interval
        bins zero_to_one = { [32'b1:F16_ONE-1]};
        bins one_to_max = { [F16_ONE+1:F16_RFI_MAX-1] };
    }

    // Captures all ones in exponent and non zero mantissa
    F16_nan: coverpoint (&CFI.a[F16_E_UPPER:F16_E_LOWER] & |CFI.a[F16_M_UPPER:0]){
        type_option.weight = 0;
        bins nan = { 1 };
    }

    // Captures all ones in exponent and zero mantissa
    F16_infinity: coverpoint (&CFI.a[F16_E_UPPER:F16_E_LOWER] & ~&CFI.a[F16_M_UPPER:0]) {
        type_option.weight = 0;
        bins infinity = { 1 };
    }

    F16_case_iv: coverpoint { CFI.a[F16_E_UPPER:F16_E_LOWER], CFI.a[F16_M_UPPER:F16_M_UPPER-2] } {
        type_option.weight = 0;
        bins _1_01 = { (F16_EXP_BIAS << 3) | 3'b010 };
        bins _1_10 = { (F16_EXP_BIAS << 3) | 3'b100 };
        bins _1_11 = { (F16_EXP_BIAS << 3) | 3'b110 };
        bins _10_00 = { ((F16_EXP_BIAS + 1) << 3) | 3'b000 };
        bins _10_01 = { ((F16_EXP_BIAS + 1) << 3) | 3'b001 };
        bins _10_10 = { ((F16_EXP_BIAS + 1) << 3) | 3'b010 };
        bins _10_11 = { ((F16_EXP_BIAS + 1) << 3) | 3'b011 };
    }

    F16_sign: coverpoint CFI.a[F16_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = { 0 };
        bins neg = { 1 };
    }

    // BF16 Inputs
    BF16_basic_inputs: coverpoint CFI.a[14:0] { // Exclude Sign Explicitly
        type_option.weight = 0;

        bins zero = { 'b0 };
        bins one = { BF16_ONE };
        bins max = { BF16_RFI_MAX };
        // Takes advantage of floating point comparison being integer comparisons, but needs -1, +1 for open interval
        bins zero_to_one = { [32'b1:BF16_ONE-1]};
        bins one_to_max = { [BF16_ONE+1:BF16_RFI_MAX-1] };
    }

    // Captures all ones in exponent and non zero mantissa
    BF16_nan: coverpoint (&CFI.a[BF16_E_UPPER:BF16_E_LOWER] & |CFI.a[BF16_M_UPPER:0]){
        type_option.weight = 0;
        bins nan = { 1 };
    }

    // Captures all ones in exponent and zero mantissa
    BF16_infinity: coverpoint (&CFI.a[BF16_E_UPPER:BF16_E_LOWER] & ~&CFI.a[BF16_M_UPPER:0]) {
        type_option.weight = 0;
        bins infinity = { 1 };
    }

    BF16_case_iv: coverpoint { CFI.a[BF16_E_UPPER:BF16_E_LOWER], CFI.a[BF16_M_UPPER:BF16_M_UPPER-2] } {
        type_option.weight = 0;
        bins _1_01 = { (BF16_EXP_BIAS << 3) | 3'b010 };
        bins _1_10 = { (BF16_EXP_BIAS << 3) | 3'b100 };
        bins _1_11 = { (BF16_EXP_BIAS << 3) | 3'b110 };
        bins _10_00 = { ((BF16_EXP_BIAS + 1) << 3) | 3'b000 };
        bins _10_01 = { ((BF16_EXP_BIAS + 1) << 3) | 3'b001 };
        bins _10_10 = { ((BF16_EXP_BIAS + 1) << 3) | 3'b010 };
        bins _10_11 = { ((BF16_EXP_BIAS + 1) << 3) | 3'b011 };
    }

    BF16_sign: coverpoint CFI.a[BF16_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = { 0 };
        bins neg = { 1 };
    }

    // Final Covergroups

    `ifdef COVER_F32
        B28_F32_basic: cross F32_sign, F32_basic_inputs, RFI_op, F32_src_fmt;
        B28_F32_case_iv: cross F32_sign, F32_case_iv, RFI_op, F32_src_fmt;
        B28_F32_infinity: cross F32_sign, F32_infinity, RFI_op, F32_src_fmt;
        B28_F32_nan: cross F32_nan, RFI_op, F32_src_fmt;
    `endif

    `ifdef COVER_F64
        B28_F64_basic: cross F64_sign, F64_basic_inputs, RFI_op, F64_src_fmt;
        B28_F64_case_iv: cross F64_sign, F64_case_iv, RFI_op, F64_src_fmt;
        B28_F64_infinity: cross F64_sign, F64_infinity, RFI_op, F64_src_fmt;
        B28_F64_nan: cross F64_nan, RFI_op, F64_src_fmt;
    `endif

    `ifdef COVER_F128
        B28_F128_basic: cross F128_sign, F128_basic_inputs, RFI_op, F128_src_fmt;
        B28_F128_case_iv: cross F128_sign, F128_case_iv, RFI_op, F128_src_fmt;
        B28_F128_infinity: cross F128_sign, F128_infinity, RFI_op, F128_src_fmt;
        B28_F128_nan: cross F128_nan, RFI_op, F128_src_fmt;
    `endif

    `ifdef COVER_F16
        B28_F16_basic: cross F16_sign, F16_basic_inputs, RFI_op, F16_src_fmt;
        B28_F16_case_iv: cross F16_sign, F16_case_iv, RFI_op, F16_src_fmt;
        B28_F16_infinity: cross F16_sign, F16_infinity, RFI_op, F16_src_fmt;
        B28_F16_nan: cross F16_nan, RFI_op, F16_src_fmt;
    `endif

    `ifdef COVER_BF16
        B28_BF16_basic: cross BF16_sign, BF16_basic_inputs, RFI_op, BF16_src_fmt;
        B28_BF16_case_iv: cross BF16_sign, BF16_case_iv, RFI_op, BF16_src_fmt;
        B28_BF16_infinity: cross BF16_sign, BF16_infinity, RFI_op, BF16_src_fmt;
        B28_BF16_nan: cross BF16_nan, RFI_op, BF16_src_fmt;
    `endif

endgroup
