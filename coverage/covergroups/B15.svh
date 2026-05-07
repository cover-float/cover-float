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

covergroup B15_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;

    /************************************************************************
     *`
     * Operation helper coverpoint (f{n}m{add|sub})
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

    F16_c_special_sigs:  coverpoint (CFI.c[F16_M_UPPER  : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B15_F16_special_sigs.svh"
    }
    BF16_c_special_sigs: coverpoint (CFI.c[BF16_M_UPPER : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B15_BF16_special_sigs.svh"
    }
    F32_c_special_sigs:  coverpoint (CFI.c[F32_M_UPPER  : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B15_F32_special_sigs.svh"
    }
    F64_c_special_sigs:  coverpoint (CFI.c[F64_M_UPPER  : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B15_F64_special_sigs.svh"
    }
    F128_c_special_sigs: coverpoint (CFI.c[F128_M_UPPER : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B15_F128_special_sigs.svh"
    }

    // 2.2*NF format for prod significand
    F16_prod_special_sigs:  coverpoint (CFI.fmaPreAddition[2*F16_M_BITS + 1 : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B15_F16_prod_special_sigs.svh"
    }
    BF16_prod_special_sigs: coverpoint (CFI.fmaPreAddition[2*BF16_M_BITS + 1 : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B15_BF16_prod_special_sigs.svh"
    }
    F32_prod_special_sigs:  coverpoint (CFI.fmaPreAddition[2*F32_M_BITS + 1  : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B15_F32_prod_special_sigs.svh"
    }
    F64_prod_special_sigs:  coverpoint (CFI.fmaPreAddition[2*F64_M_BITS + 1  : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B15_F64_prod_special_sigs.svh"
    }
    F128_prod_special_sigs: coverpoint (CFI.fmaPreAddition[2*F128_M_BITS + 1 : 0]) {
        type_option.weight = 0;

        `include "bins_templates/generated/B15_F128_prod_special_sigs.svh"
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

    F16_madd_shift: coverpoint $signed(get_product_exponent(CFI.a, CFI.b, FMT_HALF) - int'(CFI.c[F16_E_UPPER : F16_E_LOWER])) {
        type_option.weight = 0;

        bins big_neg_shift[] = {[-2 * F16_M_BITS - 1  : -2 * F16_M_BITS + 1]};
        bins mid_shift[]     = {[-2                   :  2                 ]};
        bins big_pos_shift[] = {[ F16_M_BITS - 2      :  F16_M_BITS        ]};
        bins other_shift     = default;

    }

    BF16_madd_shift: coverpoint $signed(get_product_exponent(CFI.a, CFI.b, FMT_BF16) - int'(CFI.c[BF16_E_UPPER : BF16_E_LOWER])) {
        type_option.weight = 0;

        bins big_neg_shift[] = {[-2 * BF16_M_BITS - 1  : -2 * BF16_M_BITS + 1]};
        bins mid_shift[]     = {[-2                    :  2                  ]};
        bins big_pos_shift[] = {[ BF16_M_BITS - 2      :  BF16_M_BITS        ]};
        bins other_shift     = default;

    }

    F32_madd_shift: coverpoint $signed(get_product_exponent(CFI.a, CFI.b, FMT_SINGLE) - int'(CFI.c[F32_E_UPPER : F32_E_LOWER])) {
        type_option.weight = 0;

        bins big_neg_shift[] = {[-2 * F32_M_BITS - 1  : -2 * F32_M_BITS + 1]};
        bins mid_shift[]     = {[-2                   :  2                 ]};
        bins big_pos_shift[] = {[ F32_M_BITS - 2      :  F32_M_BITS        ]};
        bins other_shift     = default;

    }

    F64_madd_shift: coverpoint $signed(get_product_exponent(CFI.a, CFI.b, FMT_DOUBLE) - int'(CFI.c[F64_E_UPPER : F64_E_LOWER])) {
        type_option.weight = 0;

        bins big_neg_shift[] = {[-2 * F64_M_BITS - 1  : -2 * F64_M_BITS + 1]};
        bins mid_shift[]     = {[-2                   :  2                 ]};
        bins big_pos_shift[] = {[ F64_M_BITS - 2      :  F64_M_BITS        ]};
        bins other_shift     = default;

    }

    F128_madd_shift: coverpoint $signed(get_product_exponent(CFI.a, CFI.b, FMT_QUAD) - int'(CFI.c[F128_E_UPPER : F128_E_LOWER])) {
        type_option.weight = 0;

        bins big_neg_shift[] = {[-2 * F128_M_BITS - 1  : -2 * F128_M_BITS + 1]};
        bins mid_shift[]     = {[-2                    :  2                  ]};
        bins big_pos_shift[] = {[ F128_M_BITS - 2      :  F128_M_BITS        ]};
        bins other_shift     = default;

    }


    /************************************************************************
     *
     * Main crosses (precision-sorted)
     *
     ************************************************************************/

    `ifdef COVER_F16
        B15_F16:  cross FP_madd_ops, F16_madd_shift,  F16_prod_special_sigs,  F16_c_special_sigs,  F16_result_fmt;
    `endif // COVER_F16

    `ifdef COVER_BF16
        B15_BF16: cross FP_madd_ops, BF16_madd_shift, BF16_prod_special_sigs, BF16_c_special_sigs, BF16_result_fmt;
    `endif // COVER_BF16

    `ifdef COVER_F32
        B15_F32:  cross FP_madd_ops, F32_madd_shift,  F32_prod_special_sigs,  F32_c_special_sigs,  F32_result_fmt;
    `endif // COVER_F32

    `ifdef COVER_F64
        B15_F64:  cross FP_madd_ops, F64_madd_shift,  F64_prod_special_sigs,  F64_c_special_sigs,  F64_result_fmt;
    `endif // COVER_F64

    `ifdef COVER_F128
        B15_F128: cross FP_madd_ops, F128_madd_shift, F128_prod_special_sigs, F128_c_special_sigs, F128_result_fmt;
    `endif // COVER_F128


endgroup
