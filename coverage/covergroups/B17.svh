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

covergroup B17_cg (virtual coverfloat_interface CFI);
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

    // FMA Operand Helpers
    FMA_ops: coverpoint (CFI.op) {
        bins fmadd = { OP_FMADD };
        bins fmsub = { OP_FMSUB };
        bins fnmadd = { OP_FNMADD };
        bins fnmsub = { OP_FNMSUB };
    }

    /************************************************************************
     *
     * Cancellation helper coverpoints
     *
     * cancellation = exp(result) - max(exp(prod), effective_exp(c))
     *
     ************************************************************************/

    F16_madd_cancellation: coverpoint
        (
            (
                (CFI.intermX == 0 && CFI.intermM != 0)
                ? -count_leading_zeros(CFI.intermM[INTERM_M_BITS-1:INTERM_M_BITS-256], 256)
                : -F16_M_BITS
            )
                -
            (
                (int'(get_product_exponent(CFI.a, CFI.b, FMT_HALF)) > int'(effective_exponent(CFI.c, FMT_HALF) + F16_EXP_BIAS))
                ? int'(get_product_exponent(CFI.a, CFI.b, FMT_HALF))
                : int'(effective_exponent(CFI.c, FMT_HALF) + F16_EXP_BIAS)
            )
        )
    {
        type_option.weight = 0;
        // The paper says that [-(2p+1), 1] is the bounds, but I am unconvinced that the -2p and -(2p+1) cases
        // are even possible. From the test suite that they have made available, the test count is consistent with
        // not generating these cases.
        // bins cancel[] = {[-(2*F16_P + 1) : 1]};
        bins cancel[] = {[-(2*F16_P - 1) : 1]};
    }

    BF16_madd_cancellation: coverpoint
        (
            (
                (CFI.intermX == 0 && CFI.intermM != 0)
                ? -count_leading_zeros(CFI.intermM[INTERM_M_BITS-1:INTERM_M_BITS-256], 256)
                : -BF16_M_BITS
            )
                -
            (
                (int'(get_product_exponent(CFI.a, CFI.b, FMT_BF16)) > int'(effective_exponent(CFI.c, FMT_BF16) + BF16_EXP_BIAS))
                ? int'(get_product_exponent(CFI.a, CFI.b, FMT_BF16))
                : int'(effective_exponent(CFI.c, FMT_BF16) + BF16_EXP_BIAS)
            )
        )
    {
        type_option.weight = 0;
        // The paper says that [-(2p+1), 1] is the bounds, but I am unconvinced that the -2p and -(2p+1) cases
        // are even possible. From the test suite that they have made available, the test count is consistent with
        // not generating these cases.
        // bins cancel[] = {[-(2*BF16_P + 1) : 1]};
        bins cancel[] = {[-(2*BF16_P - 1) : 1]};
    }

    F32_madd_cancellation: coverpoint
        (
            (
                (CFI.intermX == 0 && CFI.intermM != 0)
                ? -count_leading_zeros(CFI.intermM[INTERM_M_BITS-1:INTERM_M_BITS-256], 256)
                : -F32_M_BITS
            )
                -
            (
                (int'(get_product_exponent(CFI.a, CFI.b, FMT_SINGLE)) > int'(effective_exponent(CFI.c, FMT_SINGLE) + F32_EXP_BIAS))
                ? int'(get_product_exponent(CFI.a, CFI.b, FMT_SINGLE))
                : int'(effective_exponent(CFI.c, FMT_SINGLE) + F32_EXP_BIAS)
            )
        )
    {
        type_option.weight = 0;
        // The paper says that [-(2p+1), 1] is the bounds, but I am unconvinced that the -2p and -(2p+1) cases
        // are even possible. From the test suite that they have made available, the test count is consistent with
        // not generating these cases.
        // bins cancel[] = {[-(2*F32_P + 1) : 1]};
        bins cancel[] = {[-(2*F32_P - 1) : 1]};
    }

    F64_madd_cancellation: coverpoint
        (
            (
                (CFI.intermX == 0 && CFI.intermM != 0)
                ? -count_leading_zeros(CFI.intermM[INTERM_M_BITS-1:INTERM_M_BITS-256], 256)
                : -F64_M_BITS
            )
                -
            (
                (int'(get_product_exponent(CFI.a, CFI.b, FMT_DOUBLE)) > int'(effective_exponent(CFI.c, FMT_DOUBLE) + F64_EXP_BIAS))
                ? int'(get_product_exponent(CFI.a, CFI.b, FMT_DOUBLE))
                : int'(effective_exponent(CFI.c, FMT_DOUBLE) + F64_EXP_BIAS)
            )
        )
    {
        type_option.weight = 0;
        // The paper says that [-(2p+1), 1] is the bounds, but I am unconvinced that the -2p and -(2p+1) cases
        // are even possible. From the test suite that they have made available, the test count is consistent with
        // not generating these cases.
        // bins cancel[] = {[-(2*F64_P + 1) : 1]};
        bins cancel[] = {[-(2*F64_P - 1) : 1]};
    }

    F128_madd_cancellation: coverpoint
        (
            (
                (CFI.intermX == 0 && CFI.intermM != 0)
                ? -count_leading_zeros(CFI.intermM[INTERM_M_BITS-1:INTERM_M_BITS-256], 256)
                : -F128_M_BITS
            )
                -
            (
                (int'(get_product_exponent(CFI.a, CFI.b, FMT_QUAD)) > int'(effective_exponent(CFI.c, FMT_QUAD) + F128_EXP_BIAS))
                ? int'(get_product_exponent(CFI.a, CFI.b, FMT_QUAD))
                : int'(effective_exponent(CFI.c, FMT_QUAD) + F128_EXP_BIAS)
            )
        )
    {
        type_option.weight = 0;
        // The paper says that [-(2p+1), 1] is the bounds, but I am unconvinced that the -2p and -(2p+1) cases
        // are even possible. From the test suite that they have made available, the test count is consistent with
        // not generating these cases.
        // bins cancel[] = {[-(2*F128_P + 1) : 1]};
        bins cancel[] = {[-(2*F128_P - 1) : 1]};
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
        B17_F32_subnormal_cancel: cross FMA_ops, F32_src_fmt, F32_madd_cancellation, F32_subnorm_exp, F32_subnormal {
            ignore_bins min_subnorm_carry = binsof(F32_subnorm_exp.negative_exp) intersect {F32_M_BITS-1} && binsof(F32_madd_cancellation.cancel) intersect {1};
        }
    `endif

    `ifdef COVER_F64
        B17_F64_subnormal_cancel: cross FMA_ops, F64_src_fmt, F64_madd_cancellation, F64_subnorm_exp, F64_subnormal {
            ignore_bins min_subnorm_carry = binsof(F64_subnorm_exp.negative_exp) intersect {F64_M_BITS-1} && binsof(F64_madd_cancellation.cancel) intersect {1};
        }
    `endif

    `ifdef COVER_F128
        B17_F128_subnormal_cancel: cross FMA_ops, F128_src_fmt, F128_madd_cancellation, F128_subnorm_exp, F128_subnormal {
            ignore_bins min_subnorm_carry = binsof(F128_subnorm_exp.negative_exp) intersect {F128_M_BITS-1} && binsof(F128_madd_cancellation.cancel) intersect {1};
        }
    `endif

    `ifdef COVER_F16
        B17_F16_subnormal_cancel: cross FMA_ops, F16_src_fmt, F16_madd_cancellation, F16_subnorm_exp, F16_subnormal {
            ignore_bins min_subnorm_carry = binsof(F16_subnorm_exp.negative_exp) intersect {F16_M_BITS-1} && binsof(F16_madd_cancellation.cancel) intersect {1};
        }
    `endif

    `ifdef COVER_BF16
        B17_BF16_subnormal_cancel: cross FMA_ops, BF16_src_fmt, BF16_madd_cancellation, BF16_subnorm_exp, BF16_subnormal {
            ignore_bins min_subnorm_carry = binsof(BF16_subnorm_exp.negative_exp) intersect {BF16_M_BITS-1} && binsof(BF16_madd_cancellation.cancel) intersect {1};
        }
    `endif
endgroup
