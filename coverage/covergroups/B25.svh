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


covergroup B25_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;

    // CIF Operation Helper Coverpoint
    CIF_op: coverpoint CFI.op {
        type_option.weight = 0;
        bins cif = { OP_CIF };
    }

    // Input Format

    INT32_input_fmt: coverpoint (CFI.operandFmt == FMT_INT) {
        type_option.weight = 0;
        bins int32 = {1};
    }

    UINT32_input_fmt: coverpoint (CFI.operandFmt == FMT_UINT) {
        type_option.weight = 0;
        bins uint32 = {1};
    }

    INT64_input_fmt: coverpoint (CFI.operandFmt == FMT_LONG) {
        type_option.weight = 0;
        bins int64 = {1};
    }

    UINT64_input_fmt: coverpoint (CFI.operandFmt == FMT_ULONG) {
        type_option.weight = 0;
        bins uint64 = {1};
    }

    // Inputs
    // Special-value coverpoints (guarded by signedness)
    // 32-bit SIGNED input
    int32_special: coverpoint CFI.a[SIZEOF_INT-1:0] iff (CFI.operandFmt == FMT_INT) {
        type_option.weight = 0;
        bins zero    = {0};
        bins pos_one = {1};
        bins neg_one = {'1};                                                   // 0xFFFF_FFFF = -1
        bins pos_max = {{1'b0, {(SIZEOF_INT-1){1'b1}}}};                       // 0x7FFF_FFFF =  MaxInt
        bins neg_int_max = {{1'b1, {(SIZEOF_INT-2){1'b0}}, 1'b1}};             // 0x8000_0001 = -MaxInt
        bins neg_max = {{1'b1, {(SIZEOF_INT-1){1'b0}}}};                       // 0x8000_0000 =  NegMaxInt
        bins random  = {[2:32'h7fff_ffff-1], [32'h8000_0002:32'hffff_ffff-1]}; // Catch-All for "Random number"
    }

    // 32-bit UNSIGNED input
    uint32_special: coverpoint CFI.a[SIZEOF_INT-1:0] iff (CFI.operandFmt == FMT_UINT) {
        type_option.weight = 0;
        bins zero     = {0};
        bins one      = {1};
        bins max_uint = {'1};                                // 0xFFFF_FFFF = MaxUInt
        bins random   = {[2:32'hffff_ffff-1]};
    }

    // 64-bit SIGNED input
    int64_special: coverpoint CFI.a[SIZEOF_LONG-1:0] iff (CFI.operandFmt == FMT_LONG) {
        type_option.weight = 0;
        bins zero    = {0};
        bins pos_one = {1};
        bins neg_one = {'1};
        bins pos_max = {{1'b0, {(SIZEOF_LONG-1){1'b1}}}};
        bins neg_int_max = {{1'b1, {(SIZEOF_LONG-2){1'b0}}, 1'b1}};
        bins neg_max = {{1'b1, {(SIZEOF_LONG-1){1'b0}}}};
        bins random  = {[2:64'h7fff_ffff_ffff_ffff-1], [64'h8000_0000_0000_0002:64'hffff_ffff_ffff_ffff-1]};
    }

    // 64-bit UNSIGNED input
    uint64_special: coverpoint CFI.a[SIZEOF_LONG-1:0] iff (CFI.operandFmt == FMT_ULONG) {
        type_option.weight = 0;
        bins zero     = {0};
        bins one      = {1};
        bins max_uint = {'1};
        bins random   = {[2:64'hffff_ffff_ffff_ffff-1]};
    }


    // Result Format Coverpoints
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

    // Crosses

    `ifdef COVER_F16
        B25_INT32_F16:  cross CIF_op, int32_special, F16_result_fmt;
        B25_UINT32_F16: cross CIF_op, uint32_special, F16_result_fmt;
        `ifdef COVER_LONG
            B25_INT64_F16:  cross CIF_op, int64_special, F16_result_fmt;
            B25_UINT64_F16: cross CIF_op, uint64_special, F16_result_fmt;
        `endif
    `endif

    `ifdef COVER_BF16
        B25_INT32_BF16:  cross CIF_op, int32_special, BF16_result_fmt;
        B25_UINT32_BF16: cross CIF_op, uint32_special, BF16_result_fmt;
        `ifdef COVER_LONG
            B25_INT64_BF16:  cross CIF_op, int64_special, BF16_result_fmt;
            B25_UINT64_BF16: cross CIF_op, uint64_special, BF16_result_fmt;
        `endif
    `endif

    `ifdef COVER_F32
        B25_INT32_F32:  cross CIF_op, int32_special,  F32_result_fmt;
        B25_UINT32_F32: cross CIF_op, uint32_special, F32_result_fmt;
        `ifdef COVER_LONG
            B25_INT64_F32:  cross CIF_op, int64_special,  F32_result_fmt;
            B25_UINT64_F32: cross CIF_op, uint64_special, F32_result_fmt;
        `endif
    `endif

    `ifdef COVER_F64
        B25_INT32_F64:  cross CIF_op, int32_special, F64_result_fmt;
        B25_UINT32_F64: cross CIF_op, uint32_special, F64_result_fmt;
        `ifdef COVER_LONG
            B25_INT64_F64:  cross CIF_op, int64_special, F64_result_fmt;
            B25_UINT64_F64: cross CIF_op, uint64_special, F64_result_fmt;
        `endif
    `endif

    `ifdef COVER_F128
        B25_INT32_F128:  cross CIF_op, int32_special, F128_result_fmt;
        B25_UINT32_F128: cross CIF_op, uint32_special, F128_result_fmt;
        `ifdef COVER_LONG
            B25_INT64_F128:  cross CIF_op, int64_special, F128_result_fmt;
            B25_UINT64_F128: cross CIF_op, uint64_special, F128_result_fmt;
        `endif
    `endif

endgroup
