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

covergroup B4_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;

    /************************************************************************
    General Helper Coverpoints
    ************************************************************************/

    FP_arith_ops_no_sqrt: coverpoint CFI.op {
        type_option.weight = 0;

        bins op_add    = {[OP_ADD : OP_ADD | 32'hF]};
        bins op_sub    = {[OP_SUB : OP_SUB | 32'hF]};
        bins op_mul    = {[OP_MUL : OP_MUL | 32'hF]};
        bins op_div    = {[OP_DIV : OP_DIV | 32'hF]};
        bins op_fma    = {[OP_FMA : OP_FMA | 32'hF]};
        bins op_fmadd  = {OP_FMADD};
        bins op_fmsub  = {OP_FMSUB};
        bins op_fnmadd = {OP_FNMADD};
        bins op_fnmsub = {OP_FNMSUB};
    }

    rounding_mode_all: coverpoint CFI.rm {
        type_option.weight = 0;
        bins round_near_even   = {ROUND_NEAR_EVEN};
        bins round_minmag      = {ROUND_MINMAG};
        bins round_min         = {ROUND_MIN};
        bins round_max         = {ROUND_MAX};
        bins round_near_maxmag = {ROUND_NEAR_MAXMAG};
    }

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
    Underflow Boundary Helper Coverpoints
    ************************************************************************/

    // cases i & ii
    F32_maxNorm_pm_3ulp: coverpoint CFI.intermM[(INTERM_M_BITS - F32_M_BITS) -: 3]
        iff (CFI.intermX == F32_MAXNORM_EXP && CFI.intermM[(INTERM_M_BITS - 1) -: F32_M_BITS - 1] == '1) {
            type_option.weight = 0;

            bins maxNorm_pm_3ulp[] = {[3'b001 : 3'b111]};
    }

    F64_maxNorm_pm_3ulp: coverpoint CFI.intermM[(INTERM_M_BITS - F64_M_BITS) -: 3]
        iff (CFI.intermX == F64_MAXNORM_EXP && CFI.intermM[(INTERM_M_BITS - 1) -: F64_M_BITS - 1] == '1) {
            type_option.weight = 0;

            bins maxNorm_pm_3ulp[] = {[3'b001 : 3'b111]};
    }

    F128_maxNorm_pm_3ulp: coverpoint CFI.intermM[(INTERM_M_BITS - F128_M_BITS) -: 3]
        iff (CFI.intermX == F128_MAXNORM_EXP && CFI.intermM[(INTERM_M_BITS - 1) -: F128_M_BITS - 1] == '1) {
            type_option.weight = 0;

            bins maxNorm_pm_3ulp[] = {[3'b001 : 3'b111]};
    }

    F16_maxNorm_pm_3ulp: coverpoint CFI.intermM[(INTERM_M_BITS - F16_M_BITS) -: 3]
        iff (CFI.intermX == F16_MAXNORM_EXP && CFI.intermM[(INTERM_M_BITS - 1) -: F16_M_BITS - 1] == '1) {
            type_option.weight = 0;

            bins maxNorm_pm_3ulp[] = {[3'b001 : 3'b111]};
    }

    BF16_maxNorm_pm_3ulp: coverpoint CFI.intermM[(INTERM_M_BITS - BF16_M_BITS) -: 3]
        iff (CFI.intermX == BF16_MAXNORM_EXP && CFI.intermM[(INTERM_M_BITS - 1) -: BF16_M_BITS - 1] == '1) {
            type_option.weight = 0;

            bins maxNorm_pm_3ulp[] = {[3'b001 : 3'b111]};
    }

    // cases vii & viii
    F32_gt_maxNorm_p_3ulp: coverpoint CFI.intermM iff (CFI.intermX == F32_MAXNORM_EXP) {
        type_option.weight = 0;

        bins gt_maxNorm = {[ ('1 << (INTERM_M_BITS - F32_M_BITS - 2)) : $]};
    }

    F64_gt_maxNorm_p_3ulp: coverpoint CFI.intermM iff (CFI.intermX == F64_MAXNORM_EXP) {
        type_option.weight = 0;

        bins gt_maxNorm = {[ ('1 << (INTERM_M_BITS - F64_M_BITS - 2)) : $]};
    }

    F128_gt_maxNorm_p_3ulp: coverpoint CFI.intermM iff (CFI.intermX == F128_MAXNORM_EXP) {
        type_option.weight = 0;

        bins gt_maxNorm = {[ ('1 << (INTERM_M_BITS - F128_M_BITS - 2)) : $]};
    }

    F16_gt_maxNorm_p_3ulp: coverpoint CFI.intermM iff (CFI.intermX == F16_MAXNORM_EXP) {
        type_option.weight = 0;

        bins gt_maxNorm = {[ ('1 << (INTERM_M_BITS - F16_M_BITS - 2)) : $]};
    }

    BF16_gt_maxNorm_p_3ulp: coverpoint CFI.intermM iff (CFI.intermX == BF16_MAXNORM_EXP) {
        type_option.weight = 0;

        bins gt_maxNorm = {[ ('1 << (INTERM_M_BITS - BF16_M_BITS - 2)) : $]};
    }

    // case v
    F32_maxNorm_pm3_exp_range: coverpoint CFI.intermX {
        type_option.weight = 0;

        bins exp_range[] = {[ F32_MAXNORM_EXP - 3 : F32_MAXNORM_EXP + 3 ]};
    }
    F64_maxNorm_pm3_exp_range: coverpoint CFI.intermX {
        type_option.weight = 0;

        bins exp_range[] = {[ F64_MAXNORM_EXP - 3 : F64_MAXNORM_EXP + 3 ]};
    }
    F128_maxNorm_pm3_exp_range: coverpoint CFI.intermX {
        type_option.weight = 0;

        bins exp_range[] = {[ F128_MAXNORM_EXP - 3 : F128_MAXNORM_EXP + 3 ]};
    }
    F16_maxNorm_pm3_exp_range: coverpoint CFI.intermX {
        type_option.weight = 0;

        bins exp_range[] = {[ F16_MAXNORM_EXP - 3 : F16_MAXNORM_EXP + 3 ]};
    }
    BF16_maxNorm_pm3_exp_range: coverpoint CFI.intermX {
        type_option.weight = 0;

        bins exp_range[] = {[ BF16_MAXNORM_EXP - 3 : BF16_MAXNORM_EXP + 3 ]};
    }



    /************************************************************************
    Main Coverpoints
    ************************************************************************/

    `ifdef COVER_F32
        B4_F32_maxNorm_pm_3ulp:       cross FP_arith_ops_no_sqrt, rounding_mode_all, F32_sign, F32_maxNorm_pm_3ulp,       F32_result_fmt;
        B4_F32_gt_maxNorm_p_3ulp:     cross FP_arith_ops_no_sqrt, rounding_mode_all, F32_sign, F32_gt_maxNorm_p_3ulp,     F32_result_fmt;
        B4_F32_maxNorm_pm3_exp_range: cross FP_arith_ops_no_sqrt, rounding_mode_all, F32_sign, F32_maxNorm_pm3_exp_range, F32_result_fmt;
    `endif

    `ifdef COVER_F64
        B4_F64_maxNorm_pm_3ulp:       cross FP_arith_ops_no_sqrt, rounding_mode_all, F64_sign, F64_maxNorm_pm_3ulp,       F64_result_fmt;
        B4_F64_gt_maxNorm_p_3ulp:     cross FP_arith_ops_no_sqrt, rounding_mode_all, F64_sign, F64_gt_maxNorm_p_3ulp,     F64_result_fmt;
        B4_F64_maxNorm_pm3_exp_range: cross FP_arith_ops_no_sqrt, rounding_mode_all, F64_sign, F64_maxNorm_pm3_exp_range, F64_result_fmt;
    `endif

    `ifdef COVER_F128
        B4_F128_maxNorm_pm_3ulp:       cross FP_arith_ops_no_sqrt, rounding_mode_all, F128_sign, F128_maxNorm_pm_3ulp,       F128_result_fmt;
        B4_F128_gt_maxNorm_p_3ulp:     cross FP_arith_ops_no_sqrt, rounding_mode_all, F128_sign, F128_gt_maxNorm_p_3ulp,     F128_result_fmt;
        B4_F128_maxNorm_pm3_exp_range: cross FP_arith_ops_no_sqrt, rounding_mode_all, F128_sign, F128_maxNorm_pm3_exp_range, F128_result_fmt;
    `endif

    `ifdef COVER_F16
        B4_F16_maxNorm_pm_3ulp:       cross FP_arith_ops_no_sqrt, rounding_mode_all, F16_sign, F16_maxNorm_pm_3ulp,       F16_result_fmt;
        B4_F16_gt_maxNorm_p_3ulp:     cross FP_arith_ops_no_sqrt, rounding_mode_all, F16_sign, F16_gt_maxNorm_p_3ulp,     F16_result_fmt;
        B4_F16_maxNorm_pm3_exp_range: cross FP_arith_ops_no_sqrt, rounding_mode_all, F16_sign, F16_maxNorm_pm3_exp_range, F16_result_fmt;
    `endif

    `ifdef COVER_BF16
        B4_BF16_maxNorm_pm_3ulp:       cross FP_arith_ops_no_sqrt, rounding_mode_all, BF16_sign, BF16_maxNorm_pm_3ulp,       BF16_result_fmt;
        B4_BF16_gt_maxNorm_p_3ulp:     cross FP_arith_ops_no_sqrt, rounding_mode_all, BF16_sign, BF16_gt_maxNorm_p_3ulp,     BF16_result_fmt;
        B4_BF16_maxNorm_pm3_exp_range: cross FP_arith_ops_no_sqrt, rounding_mode_all, BF16_sign, BF16_maxNorm_pm3_exp_range, BF16_result_fmt;
    `endif

endgroup
