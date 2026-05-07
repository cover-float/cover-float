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

covergroup B11_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;

    /************************************************************************
     *
     * Operation helper coverpoint (add, sub)
     *
     ************************************************************************/

    FP_addsub_ops: coverpoint CFI.op {
        type_option.weight = 0;
        bins add = {OP_ADD};
        bins sub = {OP_SUB};
    }

    /************************************************************************
     *
     * Operand format helper coverpoints
     *
     ************************************************************************/

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


    /************************************************************************
     *
     * Special significand helper coverpoints
     *
     ************************************************************************/

    F16_a_special_sigs:  coverpoint (CFI.a[F16_M_UPPER  : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B11_F16_special_sigs.svh"
    }
    BF16_a_special_sigs: coverpoint (CFI.a[BF16_M_UPPER : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B11_BF16_special_sigs.svh"
    }
    F32_a_special_sigs:  coverpoint (CFI.a[F32_M_UPPER  : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B11_F32_special_sigs.svh"
    }
    F64_a_special_sigs:  coverpoint (CFI.a[F64_M_UPPER  : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B11_F64_special_sigs.svh"
    }
    F128_a_special_sigs: coverpoint (CFI.a[F128_M_UPPER : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B11_F128_special_sigs.svh"
    }

    F16_b_special_sigs:  coverpoint (CFI.b[F16_M_UPPER  : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B11_F16_special_sigs.svh"
    }
    BF16_b_special_sigs: coverpoint (CFI.b[BF16_M_UPPER : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B11_BF16_special_sigs.svh"
    }
    F32_b_special_sigs:  coverpoint (CFI.b[F32_M_UPPER  : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B11_F32_special_sigs.svh"
    }
    F64_b_special_sigs:  coverpoint (CFI.b[F64_M_UPPER  : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B11_F64_special_sigs.svh"
    }
    F128_b_special_sigs: coverpoint (CFI.b[F128_M_UPPER : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B11_F128_special_sigs.svh"
    }


    /************************************************************************
     *
     * Shift classification helper coverpoints
     *
     ************************************************************************/

    // exponent difference = exponent(a) - exponent(b)
    // extracted directly from input operands, per format

    F16_exp_diff: coverpoint $signed(int'(CFI.a[F16_E_UPPER : F16_E_LOWER]) - int'(CFI.b[F16_E_UPPER : F16_E_LOWER])) {
        type_option.weight = 0;

        bins big_neg_shift[] = {[-F16_M_BITS     : -F16_M_BITS + 2]};
        bins mid_shift[]     = {[-2              :  2             ]};
        bins big_pos_shift[] = {[ F16_M_BITS - 2 :  F16_M_BITS    ]};
        bins other_shift     = default;

    }

    BF16_exp_diff: coverpoint $signed(int'(CFI.a[BF16_E_UPPER : BF16_E_LOWER]) - int'(CFI.b[BF16_E_UPPER : BF16_E_LOWER])) {
        type_option.weight = 0;

        bins big_neg_shift[] = {[-BF16_M_BITS     : -BF16_M_BITS + 2]};
        bins mid_shift[]     = {[-2               :  2              ]};
        bins big_pos_shift[] = {[ BF16_M_BITS - 2 :  BF16_M_BITS    ]};
        bins other_shift     = default;

    }

    F32_exp_diff: coverpoint $signed(int'(CFI.a[F32_E_UPPER : F32_E_LOWER]) - int'(CFI.b[F32_E_UPPER : F32_E_LOWER])) {
        type_option.weight = 0;

        bins big_neg_shift[] = {[-F32_M_BITS     : -F32_M_BITS + 2]};
        bins mid_shift[]     = {[-2              :  2             ]};
        bins big_pos_shift[] = {[ F32_M_BITS - 2 :  F32_M_BITS    ]};
        bins other_shift     = default;

    }

    F64_exp_diff: coverpoint $signed(int'(CFI.a[F64_E_UPPER : F64_E_LOWER]) - int'(CFI.b[F64_E_UPPER : F64_E_LOWER])) {
        type_option.weight = 0;

        bins big_neg_shift[] = {[-F64_M_BITS     : -F64_M_BITS + 2]};
        bins mid_shift[]     = {[-2              :  2             ]};
        bins big_pos_shift[] = {[ F64_M_BITS - 2 :  F64_M_BITS    ]};
        bins other_shift     = default;

    }

    F128_exp_diff: coverpoint $signed(int'(CFI.a[F128_E_UPPER : F128_E_LOWER]) - int'(CFI.b[F128_E_UPPER : F128_E_LOWER])) {
        type_option.weight = 0;

        bins big_neg_shift[] = {[-F128_M_BITS     : -F128_M_BITS + 2]};
        bins mid_shift[]     = {[-2               :  2              ]};
        bins big_pos_shift[] = {[ F128_M_BITS - 2 :  F128_M_BITS    ]};
        bins other_shift     = default;

    }

    /************************************************************************
     *
     * Main crosses (precision-sorted)
     *
     ************************************************************************/

    `ifdef COVER_F16
        B11_F16:  cross FP_addsub_ops, F16_exp_diff,  F16_a_special_sigs,  F16_b_special_sigs,  F16_result_fmt;
    `endif // COVER_F16

    `ifdef COVER_BF16
        B11_BF16: cross FP_addsub_ops, BF16_exp_diff, BF16_a_special_sigs, BF16_b_special_sigs, BF16_result_fmt;
    `endif // COVER_BF16

    `ifdef COVER_F32
        B11_F32:  cross FP_addsub_ops, F32_exp_diff,  F32_a_special_sigs,  F32_b_special_sigs,  F32_result_fmt;
    `endif // COVER_F32

    `ifdef COVER_F64
        B11_F64:  cross FP_addsub_ops, F64_exp_diff,  F64_a_special_sigs,  F64_b_special_sigs,  F64_result_fmt;
    `endif // COVER_F64

    `ifdef COVER_F128
        B11_F128: cross FP_addsub_ops, F128_exp_diff, F128_a_special_sigs, F128_b_special_sigs, F128_result_fmt;
    `endif // COVER_F128


endgroup
