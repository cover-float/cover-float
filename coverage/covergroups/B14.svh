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

covergroup B14_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;

    /************************************************************************
     *
     * Multiply-Add operation helper coverpoint
     *
     ************************************************************************/

    FP_madd_ops: coverpoint CFI.op {
        type_option.weight = 0;
        bins op_fma    = {[OP_FMA : OP_FMA | 32'hF]};
        bins op_fmadd  = {OP_FMADD};
        bins op_fmsub  = {OP_FMSUB};
        bins op_fnmadd = {OP_FNMADD};
        bins op_fnmsub = {OP_FNMSUB};
    }

    /************************************************************************
     *
     * Result format helper coverpoints
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
     * Shift classification helper coverpoints
     *
     * Modeled as:
     *   unbiased_exp(result) - unbiased_exp(addend)
     *
     * This reflects the effective alignment shift applied to the addend
     * during the multiply-add.
     *
     ************************************************************************/

    // HALF
    F16_madd_shift: coverpoint $signed(get_product_exponent(CFI.a, CFI.b, FMT_HALF) - int'(CFI.c[F16_E_UPPER : F16_E_LOWER])) {
        type_option.weight = 0;

        bins big_neg_shift = {[ $             : -(2*F16_P + 2)]};
        bins mid_shift[]   = {[-(2*F16_P + 1) :  (F16_P + 1)  ]};~
        bins big_pos_shift = {[ (F16_P   + 2) :  $            ]};

    }

    // BF16
    BF16_madd_shift: coverpoint $signed(get_product_exponent(CFI.a, CFI.b, FMT_BF16) - int'(CFI.c[BF16_E_UPPER : BF16_E_LOWER])) {
        type_option.weight = 0;

        bins big_neg_shift = {[ $              : -(2*BF16_P + 2)]};
        bins mid_shift[]   = {[-(2*BF16_P + 1) :  (BF16_P + 1)  ]};
        bins big_pos_shift = {[ (BF16_P   + 2) :  $             ]};
    }

    // SINGLE
    F32_madd_shift: coverpoint $signed(get_product_exponent(CFI.a, CFI.b, FMT_SINGLE) - int'(CFI.c[F32_E_UPPER : F32_E_LOWER])) {
        type_option.weight = 0;

        bins big_neg_shift = {[ $             : -(2*F32_P + 2)]};
        bins mid_shift[]   = {[-(2*F32_P + 1) :  (F32_P + 1)  ]};
        bins big_pos_shift = {[ (F32_P   + 2) :  $            ]};
    }

    // DOUBLE
    F64_madd_shift: coverpoint $signed(get_product_exponent(CFI.a, CFI.b, FMT_DOUBLE) - int'(CFI.c[F64_E_UPPER : F64_E_LOWER])) {
        type_option.weight = 0;

        bins big_neg_shift = {[ $             : -(2*F64_P + 2)]};
        bins mid_shift[]   = {[-(2*F64_P + 1) :  (F64_P + 1)  ]};
        bins big_pos_shift = {[ (F64_P   + 2) :  $            ]};
    }

    // QUAD
    F128_madd_shift: coverpoint $signed(get_product_exponent(CFI.a, CFI.b, FMT_QUAD) - int'(CFI.c[F128_E_UPPER : F128_E_LOWER])) {
        type_option.weight = 0;

        bins big_neg_shift = {[ $              : -(2*F128_P + 2)]};
        bins mid_shift[]   = {[-(2*F128_P + 1) :  (F128_P + 1)  ]};
        bins big_pos_shift = {[ (F128_P   + 2) :  $             ]};
    }

    /************************************************************************
     *
     * Main crosses (precision-gated)
     *
     ************************************************************************/

    `ifdef COVER_F16
        B14_F16_madd_shift:  cross FP_madd_ops, F16_madd_shift,  F16_result_fmt;
    `endif

    `ifdef COVER_BF16
        B14_BF16_madd_shift: cross FP_madd_ops, BF16_madd_shift, BF16_result_fmt;
    `endif

    `ifdef COVER_F32
        B14_F32_madd_shift:  cross FP_madd_ops, F32_madd_shift,  F32_result_fmt;
    `endif

    `ifdef COVER_F64
        B14_F64_madd_shift:  cross FP_madd_ops, F64_madd_shift,  F64_result_fmt;
    `endif

    `ifdef COVER_F128
        B14_F128_madd_shift: cross FP_madd_ops, F128_madd_shift, F128_result_fmt;
    `endif

endgroup
