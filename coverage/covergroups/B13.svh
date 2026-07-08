// Copyright (C) 2025-26 Harvey Mudd College, Ryan Wolk (rwolk@hmc.edu)
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

covergroup B13_cg (virtual coverfloat_interface CFI);
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

    ADD_SUB_op: coverpoint CFI.op {
        type_option.weight = 0;
        bins add = { OP_ADD };
        bins sub = { OP_SUB };
    }

    // Cancellation Coverpoints

    F32_cancellation: coverpoint
        (
            (
                (CFI.intermX == 0 && CFI.intermM != 0)
                ? -count_leading_zeros(CFI.intermM[INTERM_M_BITS-1:INTERM_M_BITS-256], 256)
                : -F32_M_BITS
            )
                -
            (
                (effective_exponent(CFI.a, FMT_SINGLE) > effective_exponent(CFI.b, FMT_SINGLE))
                ? effective_exponent(CFI.a, FMT_SINGLE) + F32_EXP_BIAS
                : effective_exponent(CFI.b, FMT_SINGLE) + F32_EXP_BIAS
            )
        )
    {
        type_option.weight = 0;
        bins cancel[] = {[-F32_P: 1]};
    }

    F64_cancellation: coverpoint
        (
            (
                (CFI.intermX == 0 && CFI.intermM != 0)
                ? -count_leading_zeros(CFI.intermM[INTERM_M_BITS-1:INTERM_M_BITS-256], 256)
                : -F64_M_BITS
            )
                -
            (
                (effective_exponent(CFI.a, FMT_DOUBLE) > effective_exponent(CFI.b, FMT_DOUBLE))
                ? effective_exponent(CFI.a, FMT_DOUBLE) + F64_EXP_BIAS
                : effective_exponent(CFI.b, FMT_DOUBLE) + F64_EXP_BIAS
            )
        )
    {
        type_option.weight = 0;
        bins cancel[] = {[-F64_P: 1]};
    }

    F128_cancellation: coverpoint
        (
            (
                (CFI.intermX == 0 && CFI.intermM != 0)
                ? -count_leading_zeros(CFI.intermM[INTERM_M_BITS-1:INTERM_M_BITS-256], 256)
                : -F128_M_BITS
            )
                -
            (
                (effective_exponent(CFI.a, FMT_QUAD) > effective_exponent(CFI.b, FMT_QUAD))
                ? effective_exponent(CFI.a, FMT_QUAD) + F128_EXP_BIAS
                : effective_exponent(CFI.b, FMT_QUAD) + F128_EXP_BIAS
            )
        )
    {
        type_option.weight = 0;
        bins cancel[] = {[-F128_P: 1]};
    }

    F16_cancellation: coverpoint
        (
            (
                (CFI.intermX == 0 && CFI.intermM != 0)
                ? -count_leading_zeros(CFI.intermM[INTERM_M_BITS-1:INTERM_M_BITS-256], 256)
                : -F16_M_BITS
            )
                -
            (
                (effective_exponent(CFI.a, FMT_HALF) > effective_exponent(CFI.b, FMT_HALF))
                ? effective_exponent(CFI.a, FMT_HALF) + F16_EXP_BIAS
                : effective_exponent(CFI.b, FMT_HALF) + F16_EXP_BIAS
            )
        )
    {
        type_option.weight = 0;
        bins cancel[] = {[-F16_P: 1]};
    }

    BF16_cancellation: coverpoint
        (
            (
                (CFI.intermX == 0 && CFI.intermM != 0)
                ? -count_leading_zeros(CFI.intermM[INTERM_M_BITS-1:INTERM_M_BITS-256], 256)
                : -BF16_M_BITS
            )
                -
            (
                (effective_exponent(CFI.a, FMT_BF16) > effective_exponent(CFI.b, FMT_BF16))
                ? effective_exponent(CFI.a, FMT_BF16) + BF16_EXP_BIAS
                : effective_exponent(CFI.b, FMT_BF16) + BF16_EXP_BIAS
            )
        )
    {
        type_option.weight = 0;
        bins cancel[] = {[-BF16_P: 1]};
    }

    // Subnormal Exponent Coverpoint
    F32_subnorm_exp: coverpoint(count_leading_zeros(CFI.result[F32_M_UPPER:0], F32_M_BITS)) {
        type_option.weight = 0;
        bins negative_exp[] = {[F32_M_BITS-1:0]};
    }
    F32_subnormal: coverpoint(|CFI.result[F32_E_UPPER:F32_E_LOWER]) {
        type_option.weight = 0;
        bins is_subnormal = { 0 };
    }

    F64_subnorm_exp: coverpoint(count_leading_zeros(CFI.result[F64_M_UPPER:0], F64_M_BITS)) {
        type_option.weight = 0;
        bins negative_exp[] = {[F64_M_BITS-1:0]};
    }
    F64_subnormal: coverpoint(|CFI.result[F64_E_UPPER:F64_E_LOWER]) {
        type_option.weight = 0;
        bins is_subnormal = { 0 };
    }

    F128_subnorm_exp: coverpoint(count_leading_zeros(CFI.result[F128_M_UPPER:0], F128_M_BITS)) {
        type_option.weight = 0;
        bins negative_exp[] = {[F128_M_BITS-1:0]};
    }
    F128_subnormal: coverpoint(|CFI.result[F128_E_UPPER:F128_E_LOWER]) {
        type_option.weight = 0;
        bins is_subnormal = { 0 };
    }

    F16_subnorm_exp: coverpoint(count_leading_zeros(CFI.result[F16_M_UPPER:0], F16_M_BITS)) {
        type_option.weight = 0;
        bins negative_exp[] = {[F16_M_BITS-1:0]};
    }
    F16_subnormal: coverpoint(|CFI.result[F16_E_UPPER:F16_E_LOWER]) {
        type_option.weight = 0;
        bins is_subnormal = { 0 };
    }

    BF16_subnorm_exp: coverpoint(count_leading_zeros(CFI.result[BF16_M_UPPER:0], BF16_M_BITS)) {
        type_option.weight = 0;
        bins negative_exp[] = {[BF16_M_BITS-1:0]};
    }
    BF16_subnormal: coverpoint(|CFI.result[BF16_E_UPPER:BF16_E_LOWER]) {
        type_option.weight = 0;
        bins is_subnormal = { 0 };
    }

    // Main Crosses
    `ifdef COVER_F32
        B13_F32_subnormal_cancel: cross ADD_SUB_op, F32_src_fmt, F32_cancellation, F32_subnorm_exp, F32_subnormal {
            ignore_bins min_subnorm_carry = binsof(F32_subnorm_exp.negative_exp) intersect {F32_M_BITS-1} && binsof(F32_cancellation.cancel) intersect {1};
            ignore_bins min_subnorm_no_cancel = binsof(F32_subnorm_exp.negative_exp) intersect {F32_M_BITS-1} && binsof(F32_cancellation.cancel) intersect {0};
        }
    `endif

    `ifdef COVER_F64
        B13_F64_subnormal_cancel: cross ADD_SUB_op, F64_src_fmt, F64_cancellation, F64_subnorm_exp, F64_subnormal {
            ignore_bins min_subnorm_carry = binsof(F64_subnorm_exp.negative_exp) intersect {F64_M_BITS-1} && binsof(F64_cancellation.cancel) intersect {1};
            ignore_bins min_subnorm_no_cancel = binsof(F64_subnorm_exp.negative_exp) intersect {F64_M_BITS-1} && binsof(F64_cancellation.cancel) intersect {0};
        }
    `endif

    `ifdef COVER_F128
        B13_F128_subnormal_cancel: cross ADD_SUB_op, F128_src_fmt, F128_cancellation, F128_subnorm_exp, F128_subnormal {
            ignore_bins min_subnorm_carry = binsof(F128_subnorm_exp.negative_exp) intersect {F128_M_BITS-1} && binsof(F128_cancellation.cancel) intersect {1};
            ignore_bins min_subnorm_no_cancel = binsof(F128_subnorm_exp.negative_exp) intersect {F128_M_BITS-1} && binsof(F128_cancellation.cancel) intersect {0};
        }
    `endif

    `ifdef COVER_F16
        B13_F16_subnormal_cancel: cross ADD_SUB_op, F16_src_fmt, F16_cancellation, F16_subnorm_exp, F16_subnormal {
            ignore_bins min_subnorm_carry = binsof(F16_subnorm_exp.negative_exp) intersect {F16_M_BITS-1} && binsof(F16_cancellation.cancel) intersect {1};
            ignore_bins min_subnorm_no_cancel = binsof(F16_subnorm_exp.negative_exp) intersect {F16_M_BITS-1} && binsof(F16_cancellation.cancel) intersect {0};
        }
    `endif

    `ifdef COVER_BF16
        B13_BF16_subnormal_cancel: cross ADD_SUB_op, BF16_src_fmt, BF16_cancellation, BF16_subnorm_exp, BF16_subnormal {
            ignore_bins min_subnorm_carry = binsof(BF16_subnorm_exp.negative_exp) intersect {BF16_M_BITS-1} && binsof(BF16_cancellation.cancel) intersect {1};
            ignore_bins min_subnorm_no_cancel = binsof(BF16_subnorm_exp.negative_exp) intersect {BF16_M_BITS-1} && binsof(BF16_cancellation.cancel) intersect {0};
        }
    `endif


endgroup
