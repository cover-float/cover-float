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

covergroup B21_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;

    FP_div_ops: coverpoint CFI.op {
        type_option.weight = 0;

        bins div = {OP_DIV};
        // bins rem = {OP_REM};
    }

    F32_a_type: coverpoint CFI.a[30:0] {
        type_option.weight = 0;

        bins zero     = {0};
        bins non_zero = {[1 : 31'h7f7FFFFF]};
        bins inf      = {31'h7f800000};
        bins nan      = {[31'h7F800001 : 31'h7FFFFFFF]};
    }

    F32_b_type: coverpoint CFI.b[30:0] {
        type_option.weight = 0;

        bins zero     = {0};
        bins non_zero = {[1 : 31'h7f7FFFFF]};
        bins inf      = {31'h7f800000};
        bins nan      = {[31'h7F800001 : 31'h7FFFFFFF]};
    }

    F64_a_type: coverpoint CFI.a[62:0] {
        type_option.weight = 0;

        bins zero     = {0};
        bins non_zero = {[1 : 63'h7FEFFFFFFFFFFFFF]};
        bins inf      = {63'h7FF0000000000000};
        bins nan      = {[63'h7FF0000000000001 : 63'h7FFFFFFFFFFFFFFF]};
    }

    F64_b_type: coverpoint CFI.b[62:0] {
        type_option.weight = 0;

        bins zero     = {0};
        bins non_zero = {[1 : 63'h7FEFFFFFFFFFFFFF]};
        bins inf      = {63'h7FF0000000000000};
        bins nan      = {[63'h7FF0000000000001 : 63'h7FFFFFFFFFFFFFFF]};
    }

    F128_a_type: coverpoint CFI.a[126:0] {
        type_option.weight = 0;

        bins zero     = {0};
        bins non_zero = {[1 : 127'h7FFEFFFFFFFFFFFFFFFFFFFFFFFFFFFF]};
        bins inf      = {127'h7FFF0000000000000000000000000000};
        bins nan      = {[127'h7FFF0000000000000000000000000001 : 127'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF]};
    }

    F128_b_type: coverpoint CFI.b[126:0] {
        type_option.weight = 0;

        bins zero     = {0};
        bins non_zero = {[1 : 127'h7FFEFFFFFFFFFFFFFFFFFFFFFFFFFFFF]};
        bins inf      = {127'h7FFF0000000000000000000000000000};
        bins nan      = {[127'h7FFF0000000000000000000000000001 : 127'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF]};
    }

    F16_a_type: coverpoint CFI.a[14:0] {
        type_option.weight = 0;

        bins zero     = {0};
        bins non_zero = {[1 : 15'h7BFF]};
        bins inf      = {15'h7C00};
        bins nan      = {[15'h7C01 : 15'h7FFF]};
    }

    F16_b_type: coverpoint CFI.b[14:0] {
        type_option.weight = 0;

        bins zero     = {0};
        bins non_zero = {[1 : 15'h7BFF]};
        bins inf      = {15'h7C00};
        bins nan      = {[15'h7C01 : 15'h7FFF]};
    }

    BF16_a_type: coverpoint CFI.a[14:0] {
        type_option.weight = 0;

        bins zero     = {0};
        bins non_zero = {[1 : 15'h7F7F]};
        bins inf      = {15'h7F80};
        bins nan      = {[15'h7F81 : 15'h7FFF]};
    }

    BF16_b_type: coverpoint CFI.b[14:0] {
        type_option.weight = 0;

        bins zero     = {0};
        bins non_zero = {[1 : 15'h7F7F]};
        bins inf      = {15'h7F80};
        bins nan      = {[15'h7F81 : 15'h7FFF]};
    }


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

    `ifdef COVER_F32
        B21_F32: cross FP_div_ops, F32_a_type, F32_b_type, F32_result_fmt;
    `endif

    `ifdef COVER_F64
        B21_F64: cross FP_div_ops, F64_a_type, F64_b_type, F64_result_fmt;
    `endif

    `ifdef COVER_F128
        B21_F128: cross FP_div_ops, F128_a_type, F128_b_type, F128_result_fmt;
    `endif

    `ifdef COVER_F16
        B21_F16: cross FP_div_ops, F16_a_type, F16_b_type, F16_result_fmt;
    `endif

    `ifdef COVER_BF16
        B21_BF16: cross FP_div_ops, BF16_a_type, BF16_b_type, BF16_result_fmt;
    `endif

endgroup
