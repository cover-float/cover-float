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

        bins op_add    = { OP_ADD };
        bins op_sub    = { OP_SUB };
        bins op_mul    = { OP_MUL };
        bins op_div    = { OP_DIV };
        bins op_fmadd  = {OP_FMADD};
        bins op_fmsub  = {OP_FMSUB};
        bins op_fnmadd = {OP_FNMADD};
        bins op_fnmsub = {OP_FNMSUB};
    }

    FP_op_cff: coverpoint CFI.op {
        type_option.weight = 0;

        bins op_cff = { OP_CFF };
    }

    rounding_mode_all: coverpoint CFI.rm {
        type_option.weight = 0;
        bins round_near_even   = {ROUND_NEAR_EVEN};
        bins round_minmag      = {ROUND_MINMAG};
        bins round_min         = {ROUND_MIN};
        bins round_max         = {ROUND_MAX};
        bins round_near_maxmag = {ROUND_NEAR_MAXMAG};
    }

    interm_sign: coverpoint CFI.intermS {
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

    F16_operand_fmt: coverpoint (CFI.operandFmt == FMT_HALF) {
        type_option.weight = 0;
        bins f16 = {1};
    }

    BF16_operand_fmt: coverpoint (CFI.operandFmt == FMT_BF16) {
        type_option.weight = 0;
        bins bf16 = {1};
    }

    F32_operand_fmt: coverpoint (CFI.operandFmt == FMT_SINGLE) {
        type_option.weight = 0;
        bins f32 = {1};
    }

    F64_operand_fmt: coverpoint (CFI.operandFmt == FMT_DOUBLE) {
        type_option.weight = 0;
        bins f64 = {1};
    }

    F128_operand_fmt: coverpoint (CFI.operandFmt == FMT_QUAD) {
        type_option.weight = 0;
        bins f128 = {1};
    }

    /************************************************************************
    Underflow Boundary Helper Coverpoints
    ************************************************************************/

    // cases i & ii
    //                                  Guard & LSB                                              Sticky
    F32_maxNorm_pm_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - 1) - (F32_M_BITS - 1) -: 2], |CFI.intermM[(INTERM_M_BITS - 1) - (F32_M_BITS + 1):0]}
        iff (
          (CFI.intermX == F32_MAXNORM_EXP && CFI.intermM[(INTERM_M_BITS - 1) -: F32_M_BITS] == '1) ||
          (CFI.intermX == F32_MAXNORM_EXP+1 && CFI.intermM[(INTERM_M_BITS-1) -: F32_M_BITS] == 0)
        ) {
            type_option.weight = 0;

            bins maxNorm_pm_3ulp[] = {[3'b001 : 3'b111]};
    }
    F64_maxNorm_pm_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - 1) - (F64_M_BITS - 1) -: 2], |CFI.intermM[(INTERM_M_BITS - 1) - (F64_M_BITS + 1):0]}
        iff (
          (CFI.intermX == F64_MAXNORM_EXP && CFI.intermM[(INTERM_M_BITS - 1) -: F64_M_BITS] == '1) ||
          (CFI.intermX == F64_MAXNORM_EXP+1 && CFI.intermM[(INTERM_M_BITS-1) -: F64_M_BITS] == 0)
        ) {
            type_option.weight = 0;

            bins maxNorm_pm_3ulp[] = {[3'b001 : 3'b111]};
    }
    F128_maxNorm_pm_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - 1) - (F128_M_BITS - 1) -: 2], |CFI.intermM[(INTERM_M_BITS - 1) - (F128_M_BITS + 1):0]}
        iff (
          (CFI.intermX == F128_MAXNORM_EXP && CFI.intermM[(INTERM_M_BITS - 1) -: F128_M_BITS] == '1) ||
          (CFI.intermX == F128_MAXNORM_EXP+1 && CFI.intermM[(INTERM_M_BITS-1) -: F128_M_BITS] == 0)
        ) {
            type_option.weight = 0;

            bins maxNorm_pm_3ulp[] = {[3'b001 : 3'b111]};
    }
    F16_maxNorm_pm_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - 1) - (F16_M_BITS - 1) -: 2], |CFI.intermM[(INTERM_M_BITS - 1) - (F16_M_BITS + 1):0]}
        iff (
          (CFI.intermX == F16_MAXNORM_EXP && CFI.intermM[(INTERM_M_BITS - 1) -: F16_M_BITS] == '1) ||
          (CFI.intermX == F16_MAXNORM_EXP+1 && CFI.intermM[(INTERM_M_BITS-1) -: F16_M_BITS] == 0)
        ) {
            type_option.weight = 0;

            bins maxNorm_pm_3ulp[] = {[3'b001 : 3'b111]};
    }
    BF16_maxNorm_pm_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - 1) - (BF16_M_BITS - 1) -: 2], |CFI.intermM[(INTERM_M_BITS - 1) - (BF16_M_BITS + 1):0]}
        iff (
          (CFI.intermX == BF16_MAXNORM_EXP && CFI.intermM[(INTERM_M_BITS - 1) -: BF16_M_BITS] == '1) ||
          (CFI.intermX == BF16_MAXNORM_EXP+1 && CFI.intermM[(INTERM_M_BITS-1) -: BF16_M_BITS] == 0)
        ) {
            type_option.weight = 0;

            bins maxNorm_pm_3ulp[] = {[3'b001 : 3'b111]};
    }

    // cases vii & viii
    F32_gt_maxNorm_p_3ulp: coverpoint CFI.intermM iff (CFI.intermX == F32_MAXNORM_EXP+1) {
        type_option.weight = 0;

        bins gt_maxNorm = {[ (1 << (INTERM_M_BITS - (F32_M_BITS - 2))) : $]};
    }
    F64_gt_maxNorm_p_3ulp: coverpoint CFI.intermM iff (CFI.intermX == F64_MAXNORM_EXP+1) {
        type_option.weight = 0;

        bins gt_maxNorm = {[ (1 << (INTERM_M_BITS - (F64_M_BITS - 2))) : $]};
    }
    F128_gt_maxNorm_p_3ulp: coverpoint CFI.intermM iff (CFI.intermX == F128_MAXNORM_EXP+1) {
        type_option.weight = 0;

        bins gt_maxNorm = {[ (1 << (INTERM_M_BITS - (F128_M_BITS - 2))) : $]};
    }
    F16_gt_maxNorm_p_3ulp: coverpoint CFI.intermM iff (CFI.intermX == F16_MAXNORM_EXP+1) {
        type_option.weight = 0;

        bins gt_maxNorm = {[ (1 << (INTERM_M_BITS - (F16_M_BITS - 2))) : $]};
    }
    BF16_gt_maxNorm_p_3ulp: coverpoint CFI.intermM iff (CFI.intermX == BF16_MAXNORM_EXP+1) {
        type_option.weight = 0;

        bins gt_maxNorm = {[ (1 << (INTERM_M_BITS - (BF16_M_BITS - 2))) : $]};
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
        B4_F32_maxNorm_pm_3ulp:       cross FP_arith_ops_no_sqrt, rounding_mode_all, interm_sign, F32_maxNorm_pm_3ulp,       F32_result_fmt {
            ignore_bins impossible_div = binsof(FP_arith_ops_no_sqrt.op_div);
        }
        B4_F32_gt_maxNorm_p_3ulp:     cross FP_arith_ops_no_sqrt, rounding_mode_all, interm_sign, F32_gt_maxNorm_p_3ulp,     F32_result_fmt;
        B4_F32_maxNorm_pm3_exp_range: cross FP_arith_ops_no_sqrt, rounding_mode_all, interm_sign, F32_maxNorm_pm3_exp_range, F32_result_fmt {
            ignore_bins impossible_add = binsof(FP_arith_ops_no_sqrt.op_add) && (binsof(F32_maxNorm_pm3_exp_range.exp_range) intersect {[F32_MAXNORM_EXP+2:F32_MAXNORM_EXP+3]});
            ignore_bins impossible_sub = binsof(FP_arith_ops_no_sqrt.op_sub) && (binsof(F32_maxNorm_pm3_exp_range.exp_range) intersect {[F32_MAXNORM_EXP+2:F32_MAXNORM_EXP+3]});
        }

        `ifdef COVER_F64
            B4_F32_from_F64_maxNorm_pm_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, F32_maxNorm_pm_3ulp, F32_result_fmt, F64_operand_fmt;
            B4_F32_from_F64_gt_maxNorm_p_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, F32_gt_maxNorm_p_3ulp, F32_result_fmt, F64_operand_fmt;
            B4_F32_from_F64_pm3_exp_range: cross FP_op_cff, rounding_mode_all, interm_sign, F32_maxNorm_pm3_exp_range, F32_result_fmt, F64_operand_fmt;
        `endif

        `ifdef COVER_F128
            B4_F32_from_F128_maxNorm_pm_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, F32_maxNorm_pm_3ulp, F32_result_fmt, F128_operand_fmt;
            B4_F32_from_F128_gt_maxNorm_p_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, F32_gt_maxNorm_p_3ulp, F32_result_fmt, F128_operand_fmt;
            B4_F32_from_F128_pm3_exp_range: cross FP_op_cff, rounding_mode_all, interm_sign, F32_maxNorm_pm3_exp_range, F32_result_fmt, F128_operand_fmt;
        `endif
    `endif

    `ifdef COVER_F64
        B4_F64_maxNorm_pm_3ulp:       cross FP_arith_ops_no_sqrt, rounding_mode_all, interm_sign, F64_maxNorm_pm_3ulp,       F64_result_fmt {
            ignore_bins impossible_div = binsof(FP_arith_ops_no_sqrt.op_div);
        }
        B4_F64_gt_maxNorm_p_3ulp:     cross FP_arith_ops_no_sqrt, rounding_mode_all, interm_sign, F64_gt_maxNorm_p_3ulp,     F64_result_fmt;
        B4_F64_maxNorm_pm3_exp_range: cross FP_arith_ops_no_sqrt, rounding_mode_all, interm_sign, F64_maxNorm_pm3_exp_range, F64_result_fmt {
            ignore_bins impossible_add = binsof(FP_arith_ops_no_sqrt.op_add) && (binsof(F64_maxNorm_pm3_exp_range.exp_range) intersect {[F64_MAXNORM_EXP+2:F64_MAXNORM_EXP+3]});
            ignore_bins impossible_sub = binsof(FP_arith_ops_no_sqrt.op_sub) && (binsof(F64_maxNorm_pm3_exp_range.exp_range) intersect {[F64_MAXNORM_EXP+2:F64_MAXNORM_EXP+3]});
        }

        `ifdef COVER_F128
            B4_F64_from_F128_maxNorm_pm_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, F64_maxNorm_pm_3ulp, F64_result_fmt, F128_operand_fmt;
            B4_F64_from_F128_gt_maxNorm_p_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, F64_gt_maxNorm_p_3ulp, F64_result_fmt, F128_operand_fmt;
            B4_F64_from_F128_pm3_exp_range: cross FP_op_cff, rounding_mode_all, interm_sign, F64_maxNorm_pm3_exp_range, F64_result_fmt, F128_operand_fmt;
        `endif
    `endif

    `ifdef COVER_F128
        B4_F128_maxNorm_pm_3ulp:       cross FP_arith_ops_no_sqrt, rounding_mode_all, interm_sign, F128_maxNorm_pm_3ulp,       F128_result_fmt {
            ignore_bins impossible_div = binsof(FP_arith_ops_no_sqrt.op_div);
        }
        B4_F128_gt_maxNorm_p_3ulp:     cross FP_arith_ops_no_sqrt, rounding_mode_all, interm_sign, F128_gt_maxNorm_p_3ulp,     F128_result_fmt;
        B4_F128_maxNorm_pm3_exp_range: cross FP_arith_ops_no_sqrt, rounding_mode_all, interm_sign, F128_maxNorm_pm3_exp_range, F128_result_fmt {
            ignore_bins impossible_add = binsof(FP_arith_ops_no_sqrt.op_add) && (binsof(F128_maxNorm_pm3_exp_range.exp_range) intersect {[F128_MAXNORM_EXP+2:F128_MAXNORM_EXP+3]});
            ignore_bins impossible_sub = binsof(FP_arith_ops_no_sqrt.op_sub) && (binsof(F128_maxNorm_pm3_exp_range.exp_range) intersect {[F128_MAXNORM_EXP+2:F128_MAXNORM_EXP+3]});
        }
    `endif

    `ifdef COVER_F16
        B4_F16_maxNorm_pm_3ulp:       cross FP_arith_ops_no_sqrt, rounding_mode_all, interm_sign, F16_maxNorm_pm_3ulp,       F16_result_fmt {
            ignore_bins impossible_div = binsof(FP_arith_ops_no_sqrt.op_div);
        }
        B4_F16_gt_maxNorm_p_3ulp:     cross FP_arith_ops_no_sqrt, rounding_mode_all, interm_sign, F16_gt_maxNorm_p_3ulp,     F16_result_fmt;
        B4_F16_maxNorm_pm3_exp_range: cross FP_arith_ops_no_sqrt, rounding_mode_all, interm_sign, F16_maxNorm_pm3_exp_range, F16_result_fmt {
            ignore_bins impossible_add = binsof(FP_arith_ops_no_sqrt.op_add) && (binsof(F16_maxNorm_pm3_exp_range.exp_range) intersect {[F16_MAXNORM_EXP+2:F16_MAXNORM_EXP+3]});
            ignore_bins impossible_sub = binsof(FP_arith_ops_no_sqrt.op_sub) && (binsof(F16_maxNorm_pm3_exp_range.exp_range) intersect {[F16_MAXNORM_EXP+2:F16_MAXNORM_EXP+3]});
        }

        `ifdef COVER_BF16
            // This case is impossible for BF16 --> F16 because the BF16 mantissa isn't big enough
            // B4_F16_from_BF16_maxNorm_pm_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, F16_maxNorm_pm_3ulp, F16_result_fmt, BF16_operand_fmt;

            B4_F16_from_BF16_gt_maxNorm_p_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, F16_gt_maxNorm_p_3ulp, F16_result_fmt, BF16_operand_fmt;
            B4_F16_from_BF16_pm3_exp_range: cross FP_op_cff, rounding_mode_all, interm_sign, F16_maxNorm_pm3_exp_range, F16_result_fmt, BF16_operand_fmt;
        `endif

        `ifdef COVER_F32
            B4_F16_from_F32_maxNorm_pm_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, F16_maxNorm_pm_3ulp, F16_result_fmt, F32_operand_fmt;
            B4_F16_from_F32_gt_maxNorm_p_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, F16_gt_maxNorm_p_3ulp, F16_result_fmt, F32_operand_fmt;
            B4_F16_from_F32_pm3_exp_range: cross FP_op_cff, rounding_mode_all, interm_sign, F16_maxNorm_pm3_exp_range, F16_result_fmt, F32_operand_fmt;
        `endif

        `ifdef COVER_F64
            B4_F16_from_F64_maxNorm_pm_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, F16_maxNorm_pm_3ulp, F16_result_fmt, F64_operand_fmt;
            B4_F16_from_F64_gt_maxNorm_p_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, F16_gt_maxNorm_p_3ulp, F16_result_fmt, F64_operand_fmt;
            B4_F16_from_F64_pm3_exp_range: cross FP_op_cff, rounding_mode_all, interm_sign, F16_maxNorm_pm3_exp_range, F16_result_fmt, F64_operand_fmt;
        `endif

        `ifdef COVER_F128
            B4_F16_from_F128_maxNorm_pm_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, F16_maxNorm_pm_3ulp, F16_result_fmt, F128_operand_fmt;
            B4_F16_from_F128_gt_maxNorm_p_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, F16_gt_maxNorm_p_3ulp, F16_result_fmt, F128_operand_fmt;
            B4_F16_from_F128_pm3_exp_range: cross FP_op_cff, rounding_mode_all, interm_sign, F16_maxNorm_pm3_exp_range, F16_result_fmt, F128_operand_fmt;
        `endif
    `endif

    `ifdef COVER_BF16
        B4_BF16_maxNorm_pm_3ulp:       cross FP_arith_ops_no_sqrt, rounding_mode_all, interm_sign, BF16_maxNorm_pm_3ulp,       BF16_result_fmt {
            ignore_bins impossible_mul = binsof(FP_arith_ops_no_sqrt.op_mul) && (binsof(BF16_maxNorm_pm_3ulp.maxNorm_pm_3ulp) intersect {2});
            ignore_bins impossible_div = binsof(FP_arith_ops_no_sqrt.op_div);
        }
        B4_BF16_gt_maxNorm_p_3ulp:     cross FP_arith_ops_no_sqrt, rounding_mode_all, interm_sign, BF16_gt_maxNorm_p_3ulp,     BF16_result_fmt;
        B4_BF16_maxNorm_pm3_exp_range: cross FP_arith_ops_no_sqrt, rounding_mode_all, interm_sign, BF16_maxNorm_pm3_exp_range, BF16_result_fmt {
            ignore_bins impossible_add = binsof(FP_arith_ops_no_sqrt.op_add) && (binsof(BF16_maxNorm_pm3_exp_range.exp_range) intersect {[BF16_MAXNORM_EXP+2:BF16_MAXNORM_EXP+3]});
            ignore_bins impossible_sub = binsof(FP_arith_ops_no_sqrt.op_sub) && (binsof(BF16_maxNorm_pm3_exp_range.exp_range) intersect {[BF16_MAXNORM_EXP+2:BF16_MAXNORM_EXP+3]});
        }

        `ifdef COVER_F32
            B4_BF16_from_F32_maxNorm_pm_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, BF16_maxNorm_pm_3ulp, BF16_result_fmt, F32_operand_fmt {
                ignore_bins f32_exp_limits = binsof(BF16_maxNorm_pm_3ulp.maxNorm_pm_3ulp) intersect {[1:3]};
            }

            // This is impossible for F32
            // B4_BF16_from_F32_gt_maxNorm_p_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, BF16_gt_maxNorm_p_3ulp, BF16_result_fmt, F32_operand_fmt;

            B4_BF16_from_F32_pm3_exp_range: cross FP_op_cff, rounding_mode_all, interm_sign, BF16_maxNorm_pm3_exp_range, BF16_result_fmt, F32_operand_fmt {
                ignore_bins f32_exp_limits = binsof(BF16_maxNorm_pm3_exp_range.exp_range) intersect {[BF16_MAXNORM_EXP+1:BF16_MAXNORM_EXP+3]};
            }
        `endif

        `ifdef COVER_F64
            B4_BF16_from_F64_maxNorm_pm_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, BF16_maxNorm_pm_3ulp, BF16_result_fmt, F64_operand_fmt;
            B4_BF16_from_F64_gt_maxNorm_p_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, BF16_gt_maxNorm_p_3ulp, BF16_result_fmt, F64_operand_fmt;
            B4_BF16_from_F64_pm3_exp_range: cross FP_op_cff, rounding_mode_all, interm_sign, BF16_maxNorm_pm3_exp_range, BF16_result_fmt, F64_operand_fmt;
        `endif

        `ifdef COVER_F128
            B4_BF16_from_F128_maxNorm_pm_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, BF16_maxNorm_pm_3ulp, BF16_result_fmt, F128_operand_fmt;
            B4_BF16_from_F128_gt_maxNorm_p_3ulp: cross FP_op_cff, rounding_mode_all, interm_sign, BF16_gt_maxNorm_p_3ulp, BF16_result_fmt, F128_operand_fmt;
            B4_BF16_from_F128_pm3_exp_range: cross FP_op_cff, rounding_mode_all, interm_sign, BF16_maxNorm_pm3_exp_range, BF16_result_fmt, F128_operand_fmt;
        `endif
    `endif

endgroup
