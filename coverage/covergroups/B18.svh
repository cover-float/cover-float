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

// Ryan Wolk (rwolk@g.hmc.edu)

covergroup B18_cg (virtual coverfloat_interface CFI);

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

    // FMA Instructions

    FMA_ops: coverpoint CFI.op {
        type_option.weight = 0;
        bins fmadd = { OP_FMADD };
        bins fmsub = { OP_FMSUB };
        bins fnmadd = { OP_FNMADD };
        bins fnmsub = { OP_FNMSUB };
    }

    /******************************************************************
     * Case I: Rounding Results
     ******************************************************************/

    // The FMA Pre-Addition Result is of the form 2.2nf, so here there are
    // 2.(23 bits of mantissa) (guard: nf-1) (sticky: nf-2 --> 0)
    F32_product_lsb: coverpoint (
        CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF+1] == 1
            ? CFI.fmaPreAddition[F32_M_BITS+1]
            : CFI.fmaPreAddition[F32_M_BITS]
    ) {
        type_option.weight = 0;
        bins lsb0 = { 0 };
        bins lsb1 = { 1 };
    }
    F32_product_guard: coverpoint (
        CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF+1] == 1
            ? CFI.fmaPreAddition[F32_M_BITS]
            : CFI.fmaPreAddition[F32_M_BITS-1]
    ) {
        type_option.weight = 0;
        bins guard0 = { 0 };
        bins guard1 = { 1 };
    }
    F32_product_sticky: coverpoint (
        CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF+1] == 1
            ? |CFI.fmaPreAddition[F32_M_BITS-1:0]
            : |CFI.fmaPreAddition[F32_M_BITS-2:0]
    ) {
        type_option.weight = 0;
        bins sticky0 = { 0 };
        bins sticky1 = { 1 };
    }
    F32_interm_guard_zero:  coverpoint CFI.intermM[INTERM_M_BITS - F32_M_BITS - 1] {
        type_option.weight = 0;
        bins zero = { 0 };
    }
    F32_interm_sticky_zero:  coverpoint |CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 : 0] {
        type_option.weight = 0;
        bins zero = { 0 };
    }

    F64_product_lsb: coverpoint (
        CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF+1] == 1
            ? CFI.fmaPreAddition[F64_M_BITS+1]
            : CFI.fmaPreAddition[F64_M_BITS]
    ) {
        type_option.weight = 0;
        bins lsb0 = { 0 };
        bins lsb1 = { 1 };
    }
    F64_product_guard: coverpoint (
        CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF+1] == 1
            ? CFI.fmaPreAddition[F64_M_BITS]
            : CFI.fmaPreAddition[F64_M_BITS-1]
    ) {
        type_option.weight = 0;
        bins guard0 = { 0 };
        bins guard1 = { 1 };
    }
    F64_product_sticky: coverpoint (
        CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF+1] == 1
            ? |CFI.fmaPreAddition[F64_M_BITS-1:0]
            : |CFI.fmaPreAddition[F64_M_BITS-2:0]
    ) {
        type_option.weight = 0;
        bins sticky0 = { 0 };
        bins sticky1 = { 1 };
    }
    F64_interm_guard_zero:  coverpoint CFI.intermM[INTERM_M_BITS - F64_M_BITS - 1] {
        type_option.weight = 0;
        bins zero = { 0 };
    }
    F64_interm_sticky_zero:  coverpoint |CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 : 0] {
        type_option.weight = 0;
        bins zero = { 0 };
    }

    F128_product_lsb: coverpoint (
        CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF+1] == 1
            ? CFI.fmaPreAddition[F128_M_BITS+1]
            : CFI.fmaPreAddition[F128_M_BITS]
    ) {
        type_option.weight = 0;
        bins lsb0 = { 0 };
        bins lsb1 = { 1 };
    }
    F128_product_guard: coverpoint (
        CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF+1] == 1
            ? CFI.fmaPreAddition[F128_M_BITS]
            : CFI.fmaPreAddition[F128_M_BITS-1]
    ) {
        type_option.weight = 0;
        bins guard0 = { 0 };
        bins guard1 = { 1 };
    }
    F128_product_sticky: coverpoint (
        CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF+1] == 1
            ? |CFI.fmaPreAddition[F128_M_BITS-1:0]
            : |CFI.fmaPreAddition[F128_M_BITS-2:0]
    ) {
        type_option.weight = 0;
        bins sticky0 = { 0 };
        bins sticky1 = { 1 };
    }
    F128_interm_guard_zero:  coverpoint CFI.intermM[INTERM_M_BITS - F128_M_BITS - 1] {
        type_option.weight = 0;
        bins zero = { 0 };
    }
    F128_interm_sticky_zero:  coverpoint |CFI.intermM[INTERM_M_BITS - F128_M_BITS - 2 : 0] {
        type_option.weight = 0;
        bins zero = { 0 };
    }

    F16_product_lsb: coverpoint (
        CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF+1] == 1
            ? CFI.fmaPreAddition[F16_M_BITS+1]
            : CFI.fmaPreAddition[F16_M_BITS]
    ) {
        type_option.weight = 0;
        bins lsb0 = { 0 };
        bins lsb1 = { 1 };
    }
    F16_product_guard: coverpoint (
        CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF+1] == 1
            ? CFI.fmaPreAddition[F16_M_BITS]
            : CFI.fmaPreAddition[F16_M_BITS-1]
    ) {
        type_option.weight = 0;
        bins guard0 = { 0 };
        bins guard1 = { 1 };
    }
    F16_product_sticky: coverpoint (
        CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF+1] == 1
            ? |CFI.fmaPreAddition[F16_M_BITS-1:0]
            : |CFI.fmaPreAddition[F16_M_BITS-2:0]
    ) {
        type_option.weight = 0;
        bins sticky0 = { 0 };
        bins sticky1 = { 1 };
    }
    F16_interm_guard_zero:  coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS - 1] {
        type_option.weight = 0;
        bins zero = { 0 };
    }
    F16_interm_sticky_zero:  coverpoint |CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 : 0] {
        type_option.weight = 0;
        bins zero = { 0 };
    }

    BF16_product_lsb: coverpoint (
        CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF+1] == 1
            ? CFI.fmaPreAddition[BF16_M_BITS+1]
            : CFI.fmaPreAddition[BF16_M_BITS]
    ) {
        type_option.weight = 0;
        bins lsb0 = { 0 };
        bins lsb1 = { 1 };
    }
    BF16_product_guard: coverpoint (
        CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF+1] == 1
            ? CFI.fmaPreAddition[BF16_M_BITS]
            : CFI.fmaPreAddition[BF16_M_BITS-1]
    ) {
        type_option.weight = 0;
        bins guard0 = { 0 };
        bins guard1 = { 1 };
    }
    BF16_product_sticky: coverpoint (
        CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF+1] == 1
            ? |CFI.fmaPreAddition[BF16_M_BITS-1:0]
            : |CFI.fmaPreAddition[BF16_M_BITS-2:0]
    ) {
        type_option.weight = 0;
        bins sticky0 = { 0 };
        bins sticky1 = { 1 };
    }
    BF16_interm_guard_zero:  coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 1] {
        type_option.weight = 0;
        bins zero = { 0 };
    }
    BF16_interm_sticky_zero:  coverpoint |CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 : 0] {
        type_option.weight = 0;
        bins zero = { 0 };
    }

    // We will constrain these cases to only take on normal numbers in the fma phase, because coverage
    // does not seem possible to write for both normal and subnormal cases with SystemVerilog  as it
    // requires a dynamic access of the fmaPreAddition bits
    F32_normal_multiplication: coverpoint (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_SINGLE) > 0 && CFI.fmaPreAddition != 0) {
        type_option.weight = 0;

        bins normal_multiplication = {1};
    }
    F64_normal_multiplication: coverpoint (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_DOUBLE) > 0 && CFI.fmaPreAddition != 0) {
        type_option.weight = 0;

        bins normal_multiplication = {1};
    }
    F128_normal_multiplication: coverpoint (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_QUAD) > 0 && CFI.fmaPreAddition != 0) {
        type_option.weight = 0;

        bins normal_multiplication = {1};
    }
    F16_normal_multiplication: coverpoint (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_HALF) > 0 && CFI.fmaPreAddition != 0) {
        type_option.weight = 0;

        bins normal_multiplication = {1};
    }
    BF16_normal_multiplication: coverpoint (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_BF16) > 0 && CFI.fmaPreAddition != 0) {
        type_option.weight = 0;

        bins normal_multiplication = {1};
    }

    // Useful coverpoint for both case ii and case iii
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

    F32_prod_sign: coverpoint (CFI.a[F32_SIGN_BIT] ^ CFI.b[F32_SIGN_BIT] ^ (CFI.op == OP_FNMADD || CFI.op == OP_FNMSUB)) {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F64_prod_sign: coverpoint (CFI.a[F64_SIGN_BIT] ^ CFI.b[F64_SIGN_BIT] ^ (CFI.op == OP_FNMADD || CFI.op == OP_FNMSUB)) {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F128_prod_sign: coverpoint (CFI.a[F128_SIGN_BIT] ^ CFI.b[F128_SIGN_BIT] ^ (CFI.op == OP_FNMADD || CFI.op == OP_FNMSUB)) {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F16_prod_sign: coverpoint (CFI.a[F16_SIGN_BIT] ^ CFI.b[F16_SIGN_BIT] ^ (CFI.op == OP_FNMADD || CFI.op == OP_FNMSUB)) {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    BF16_prod_sign: coverpoint (CFI.a[BF16_SIGN_BIT] ^ CFI.b[BF16_SIGN_BIT] ^ (CFI.op == OP_FNMADD || CFI.op == OP_FNMSUB)) {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    /************************************************************************
     * Overflow Boundary Helper Coverpoints (inspired by B4, written by Corey Hickson)
     ************************************************************************/

    // cases i & ii
    F32_maxNorm_pm_3ulp: coverpoint (
        CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF + 1)] == 1
            //  lsb                                                               guard                                                           sticky
            ? { CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF + 1) - F32_M_BITS], CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF + 1) - F32_M_BITS - 1], |CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF + 1) - F32_M_BITS - 2 : 0] }
            : { CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF - F32_M_BITS], CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF) - F32_M_BITS - 1], |CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF) - F32_M_BITS - 2 : 0] }
    ) iff (
        (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_SINGLE) == F32_MAXNORM_EXP) &&
        (&CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF -: F32_M_BITS] == 1) // Leading ones check (this doesn't need special cases as it redundantly checks the leading one in the 1.2nf case)
    ) {
            type_option.weight = 0;

            // Account for the leading ones
            bins maxNorm_pm_3ulp[] = {[3'b001 : 3'b111]};
    }

    F64_maxNorm_pm_3ulp: coverpoint (
        CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF + 1)] == 1
            //  lsb                                                               guard                                                           sticky
            ? { CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF + 1) - F64_M_BITS], CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF + 1) - F64_M_BITS - 1], |CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF + 1) - F64_M_BITS - 2 : 0] }
            : { CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF - F64_M_BITS], CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF) - F64_M_BITS - 1], |CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF) - F64_M_BITS - 2 : 0] }
    ) iff (
        (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_DOUBLE) == F64_MAXNORM_EXP) &&
        (&CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF -: F64_M_BITS] == 1) // Leading ones check (this doesn't need special cases as it redundantly checks the leading one in the 1.2nf case)
    ) {
            type_option.weight = 0;

            // Account for the leading ones
            bins maxNorm_pm_3ulp[] = {[3'b001 : 3'b111]};
    }

    F128_maxNorm_pm_3ulp: coverpoint (
        CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF + 1)] == 1
            //  lsb                                                               guard                                                           sticky
            ? { CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF + 1) - F128_M_BITS], CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF + 1) - F128_M_BITS - 1], |CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF + 1) - F128_M_BITS - 2 : 0] }
            : { CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF - F128_M_BITS], CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF) - F128_M_BITS - 1], |CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF) - F128_M_BITS - 2 : 0] }
    ) iff (
        (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_QUAD) == F128_MAXNORM_EXP) &&
        (&CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF -: F128_M_BITS] == 1) // Leading ones check (this doesn't need special cases as it redundantly checks the leading one in the 1.2nf case)
    ) {
            type_option.weight = 0;

            // Account for the leading ones
            bins maxNorm_pm_3ulp[] = {[3'b001 : 3'b111]};
    }

    F16_maxNorm_pm_3ulp: coverpoint (
        CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF + 1)] == 1
            //  lsb                                                               guard                                                           sticky
            ? { CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF + 1) - F16_M_BITS], CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF + 1) - F16_M_BITS - 1], |CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF + 1) - F16_M_BITS - 2 : 0] }
            : { CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF - F16_M_BITS], CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF) - F16_M_BITS - 1], |CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF) - F16_M_BITS - 2 : 0] }
    ) iff (
        (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_HALF) == F16_MAXNORM_EXP) &&
        (&CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF -: F16_M_BITS] == 1) // Leading ones check (this doesn't need special cases as it redundantly checks the leading one in the 1.2nf case)
    ) {
            type_option.weight = 0;

            // Account for the leading ones
            bins maxNorm_pm_3ulp[] = {[3'b001 : 3'b111]};
    }

    BF16_maxNorm_pm_3ulp: coverpoint (
        CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF + 1)] == 1
            //  lsb                                                               guard                                                           sticky
            ? { CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF + 1) - BF16_M_BITS], CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF + 1) - BF16_M_BITS - 1], |CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF + 1) - BF16_M_BITS - 2 : 0] }
            : { CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF - BF16_M_BITS], CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF) - BF16_M_BITS - 1], |CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF) - BF16_M_BITS - 2 : 0] }
    ) iff (
        (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_BF16) == BF16_MAXNORM_EXP) &&
        (&CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF -: BF16_M_BITS] == 1) // Leading ones check (this doesn't need special cases as it redundantly checks the leading one in the 1.2nf case)
    ) {
            type_option.weight = 0;

            // Account for the leading ones
            bins maxNorm_pm_3ulp[] = {[3'b001 : 3'b111]};
    }

    // cases iii & iv

    // If we are greater than p_3 ulp, something is in the first M_BITS fractional bits
    F32_gt_maxNorm_p_3ulp: coverpoint (
        (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_SINGLE) == F32_MAXNORM_EXP + 1)
            ? (CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF + 1)] == 1
                ? |CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF -: F32_M_BITS]
                : |CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF - 1 -: F32_M_BITS])
            : 1
    ) iff (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_SINGLE) > F32_MAXNORM_EXP) {
        type_option.weight = 0;

        bins gt_maxNorm_p_3ulp = { 1 };
    }

    F64_gt_maxNorm_p_3ulp: coverpoint (
        (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_DOUBLE) == F64_MAXNORM_EXP + 1)
            ? (CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF + 1)] == 1
                ? |CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF -: F64_M_BITS]
                : |CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF - 1 -: F64_M_BITS])
            : 1
    ) iff (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_DOUBLE) > F64_MAXNORM_EXP) {
        type_option.weight = 0;

        bins gt_maxNorm_p_3ulp = { 1 };
    }

    F128_gt_maxNorm_p_3ulp: coverpoint (
        (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_QUAD) == F128_MAXNORM_EXP + 1)
            ? (CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF + 1)] == 1
                ? |CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF -: F128_M_BITS]
                : |CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF - 1 -: F128_M_BITS])
            : 1
    ) iff (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_QUAD) > F128_MAXNORM_EXP) {
        type_option.weight = 0;

        bins gt_maxNorm_p_3ulp = { 1 };
    }

    F16_gt_maxNorm_p_3ulp: coverpoint (
        (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_HALF) == F16_MAXNORM_EXP + 1)
            ? (CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF + 1)] == 1
                ? |CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF -: F16_M_BITS]
                : |CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF - 1 -: F16_M_BITS])
            : 1
    ) iff (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_HALF) > F16_MAXNORM_EXP) {
        type_option.weight = 0;

        bins gt_maxNorm_p_3ulp = { 1 };
    }

    BF16_gt_maxNorm_p_3ulp: coverpoint (
        (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_BF16) == BF16_MAXNORM_EXP + 1)
            ? (CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF + 1)] == 1
                ? |CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF -: BF16_M_BITS]
                : |CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF - 1 -: BF16_M_BITS])
            : 1
    ) iff (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_BF16) > BF16_MAXNORM_EXP) {
        type_option.weight = 0;

        bins gt_maxNorm_p_3ulp = { 1 };
    }

    // case v
    F32_maxNorm_pm3_exp_range: coverpoint get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_SINGLE) {
        type_option.weight = 0;

        // We can't undo overflow past MAXNORM_EXP + 1 (subtracting maxnorm still overflows)
        bins exp_range[] = {[ F32_MAXNORM_EXP - 3 : F32_MAXNORM_EXP + 1 ]};
    }
    F64_maxNorm_pm3_exp_range: coverpoint get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_DOUBLE) {
        type_option.weight = 0;

        // We can't undo overflow past MAXNORM_EXP + 1 (subtracting maxnorm still overflows)
        bins exp_range[] = {[ F64_MAXNORM_EXP - 3 : F64_MAXNORM_EXP + 1 ]};
    }
    F128_maxNorm_pm3_exp_range: coverpoint get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_QUAD) {
        type_option.weight = 0;

        // We can't undo overflow past MAXNORM_EXP + 1 (subtracting maxnorm still overflows)
        bins exp_range[] = {[ F128_MAXNORM_EXP - 3 : F128_MAXNORM_EXP + 1 ]};
    }
    F16_maxNorm_pm3_exp_range: coverpoint get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_HALF) {
        type_option.weight = 0;

        // We can't undo overflow past MAXNORM_EXP + 1 (subtracting maxnorm still overflows)
        bins exp_range[] = {[ F16_MAXNORM_EXP - 3 : F16_MAXNORM_EXP + 1 ]};
    }
    BF16_maxNorm_pm3_exp_range: coverpoint get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_BF16) {
        type_option.weight = 0;

        // We can't undo overflow past MAXNORM_EXP + 1 (subtracting maxnorm still overflows)
        bins exp_range[] = {[ BF16_MAXNORM_EXP - 3 : BF16_MAXNORM_EXP + 1 ]};
    }


    /************************************************************************
    Underflow Boundary Helper Coverpoints (inspired by B5, commit: f5a2369 by Corey Hickson)
    ************************************************************************/

     // cases i & ii
    F32_subnorm: coverpoint (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_SINGLE) <= 0 && CFI.fmaPreAddition != 0) {
        type_option.weight = 0;

        bins subnorm = {1};
    }
    F64_subnorm: coverpoint (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_DOUBLE) <= 0 && CFI.fmaPreAddition != 0) {
        type_option.weight = 0;

        bins subnorm = {1};
    }
    F128_subnorm: coverpoint (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_QUAD) <= 0 && CFI.fmaPreAddition != 0) {
        type_option.weight = 0;

        bins subnorm = {1};
    }
    F16_subnorm: coverpoint (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_HALF) <= 0 && CFI.fmaPreAddition != 0) {
        type_option.weight = 0;

        bins subnorm = {1};
    }
    BF16_subnorm: coverpoint (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_BF16) <= 0 && CFI.fmaPreAddition != 0) {
        type_option.weight = 0;

        bins subnorm = {1};
    }

    // cases iii & iv

    F32_minSubNorm_p_3ulp: coverpoint (
        CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF + 1)] == 1
            ? { CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF+1 -: 2], |CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF-1:0] }
            : { CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF -: 2], |CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF-2:0] }
    ) iff ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_SINGLE)) == -(F32_M_BITS-1)) {
        type_option.weight = 0;

        // Factors in the lsb which must be one
        bins minSubNorm_p_3ulp[] = {[3'b100 : 3'b111]};
    }
    F32_minSubNorm_m_1_2ulp: coverpoint (
        CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF + 1)] == 1
            ? { CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF+1], |CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF:0] }
            : { CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF], |CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF-1:0] }
    ) iff ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_SINGLE)) == -F32_M_BITS) {
        type_option.weight = 0;

        bins minSubNorm_m_1ulp = { 2'b11 };
        bins minSubNorm_m_2ulp = { 2'b10 };
    }
    F32_minSubNorm_m_3ulp: coverpoint (
        CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF + 1)] == 1
            ? |CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF+1:0]
            : |CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF:0]
    ) iff ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_SINGLE)) <= -(F32_M_BITS+1)) {
        type_option.weight = 0;

        bins minSubNorm_m_3ulp = { '1 };
    }

    F64_minSubNorm_p_3ulp: coverpoint (
        CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF + 1)] == 1
            ? { CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF+1 -: 2], |CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF-1:0] }
            : { CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF -: 2], |CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF-2:0] }
    ) iff ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_DOUBLE)) == -(F64_M_BITS-1)) {
        type_option.weight = 0;

        // Factors in the lsb which must be one
        bins minSubNorm_p_3ulp[] = {[3'b100 : 3'b111]};
    }
    F64_minSubNorm_m_1_2ulp: coverpoint (
        CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF + 1)] == 1
            ? { CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF+1], |CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF:0] }
            : { CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF], |CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF-1:0] }
    ) iff ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_DOUBLE)) == -F64_M_BITS) {
        type_option.weight = 0;

        bins minSubNorm_m_1ulp = { 2'b11 };
        bins minSubNorm_m_2ulp = { 2'b10 };
    }
    F64_minSubNorm_m_3ulp: coverpoint (
        CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF + 1)] == 1
            ? |CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF+1:0]
            : |CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF:0]
    ) iff ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_DOUBLE)) <= -(F64_M_BITS+1)) {
        type_option.weight = 0;

        bins minSubNorm_m_3ulp = { '1 };
    }

    F128_minSubNorm_p_3ulp: coverpoint (
        CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF + 1)] == 1
            ? { CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF+1 -: 2], |CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF-1:0] }
            : { CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF -: 2], |CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF-2:0] }
    ) iff ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_QUAD)) == -(F128_M_BITS-1)) {
        type_option.weight = 0;

        // Factors in the lsb which must be one
        bins minSubNorm_p_3ulp[] = {[3'b100 : 3'b111]};
    }
    F128_minSubNorm_m_1_2ulp: coverpoint (
        CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF + 1)] == 1
            ? { CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF+1], |CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF:0] }
            : { CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF], |CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF-1:0] }
    ) iff ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_QUAD)) == -F128_M_BITS) {
        type_option.weight = 0;

        bins minSubNorm_m_1ulp = { 2'b11 };
        bins minSubNorm_m_2ulp = { 2'b10 };
    }
    F128_minSubNorm_m_3ulp: coverpoint (
        CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF + 1)] == 1
            ? |CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF+1:0]
            : |CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF:0]
    ) iff ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_QUAD)) <= -(F128_M_BITS+1)) {
        type_option.weight = 0;

        bins minSubNorm_m_3ulp = { '1 };
    }

    F16_minSubNorm_p_3ulp: coverpoint (
        CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF + 1)] == 1
            ? { CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF+1 -: 2], |CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF-1:0] }
            : { CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF -: 2], |CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF-2:0] }
    ) iff ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_HALF)) == -(F16_M_BITS-1)) {
        type_option.weight = 0;

        // Factors in the lsb which must be one
        bins minSubNorm_p_3ulp[] = {[3'b100 : 3'b111]};
    }
    F16_minSubNorm_m_1_2ulp: coverpoint (
        CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF + 1)] == 1
            ? { CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF+1], |CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF:0] }
            : { CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF], |CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF-1:0] }
    ) iff ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_HALF)) == -F16_M_BITS) {
        type_option.weight = 0;

        bins minSubNorm_m_1ulp = { 2'b11 };
        bins minSubNorm_m_2ulp = { 2'b10 };
    }
    F16_minSubNorm_m_3ulp: coverpoint (
        CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF + 1)] == 1
            ? |CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF+1:0]
            : |CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF:0]
    ) iff ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_HALF)) <= -(F16_M_BITS+1)) {
        type_option.weight = 0;

        bins minSubNorm_m_3ulp = { '1 };
    }

    BF16_minSubNorm_p_3ulp: coverpoint (
        CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF + 1)] == 1
            ? { CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF+1 -: 2], |CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF-1:0] }
            : { CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF -: 2], |CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF-2:0] }
    ) iff ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_BF16)) == -(BF16_M_BITS-1)) {
        type_option.weight = 0;

        // Factors in the lsb which must be one
        bins minSubNorm_p_3ulp[] = {[3'b100 : 3'b111]};
    }
    BF16_minSubNorm_m_1_2ulp: coverpoint (
        CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF + 1)] == 1
            ? { CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF+1], |CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF:0] }
            : { CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF], |CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF-1:0] }
    ) iff ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_BF16)) == -BF16_M_BITS) {
        type_option.weight = 0;

        bins minSubNorm_m_1ulp = { 2'b11 };
        bins minSubNorm_m_2ulp = { 2'b10 };
    }
    BF16_minSubNorm_m_3ulp: coverpoint (
        CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF + 1)] == 1
            ? |CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF+1:0]
            : |CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF:0]
    ) iff ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_BF16)) <= -(BF16_M_BITS+1)) {
        type_option.weight = 0;

        bins minSubNorm_m_3ulp = { '1 };
    }


    // cases v & vi

    F32_minNorm_p_3ulp: coverpoint (
        CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF + 1)] == 1
            //  leading zeros                                                    guard                                                           sticky
            ? { |CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF -: F32_M_BITS], CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF + 1) - F32_M_BITS - 1], |CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF + 1) - F32_M_BITS - 2 : 0] }
            : { |CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF - 1) -: F32_M_BITS], CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF) - F32_M_BITS - 1], |CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF) - F32_M_BITS - 2 : 0] }
    ) iff (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_SINGLE) == 1) {
            type_option.weight = 0;

            // Zero for an all zero fraction
            bins minNorm_p_3ulp[] = {[3'b000 : 3'b011]};
    }
    F32_minNorm_m_3ulp: coverpoint (
        CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF + 1)] == 1
            //  leading ones                                                    guard                                                           sticky
            ? { &CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF -: F32_M_BITS-1], CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF + 1) - F32_M_BITS], |CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF + 1) - F32_M_BITS - 1 : 0] }
            : { &CFI.fmaPreAddition[F32_FMA_PRE_ADDITION_NF -: F32_M_BITS-1], CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF) - F32_M_BITS], |CFI.fmaPreAddition[(F32_FMA_PRE_ADDITION_NF) - F32_M_BITS - 1 : 0] }
    ) iff (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_SINGLE) == 0) {
            type_option.weight = 0;

            // One for an all ones fraction
            bins minNorm_m_3ulp[] = {[3'b101 : 3'b111]};
    }

    F64_minNorm_p_3ulp: coverpoint (
        CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF + 1)] == 1
            //  leading zeros                                                    guard                                                           sticky
            ? { |CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF -: F64_M_BITS], CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF + 1) - F64_M_BITS - 1], |CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF + 1) - F64_M_BITS - 2 : 0] }
            : { |CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF - 1) -: F64_M_BITS], CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF) - F64_M_BITS - 1], |CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF) - F64_M_BITS - 2 : 0] }
    ) iff (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_DOUBLE) == 1) {
            type_option.weight = 0;

            // Zero for an all zero fraction
            bins minNorm_p_3ulp[] = {[3'b000 : 3'b011]};
    }
    F64_minNorm_m_3ulp: coverpoint (
        CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF + 1)] == 1
            //  leading ones                                                    guard                                                           sticky
            ? { &CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF -: F64_M_BITS-1], CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF + 1) - F64_M_BITS], |CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF + 1) - F64_M_BITS - 1 : 0] }
            : { &CFI.fmaPreAddition[F64_FMA_PRE_ADDITION_NF -: F64_M_BITS-1], CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF) - F64_M_BITS], |CFI.fmaPreAddition[(F64_FMA_PRE_ADDITION_NF) - F64_M_BITS - 1 : 0] }
    ) iff (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_DOUBLE) == 0) {
            type_option.weight = 0;

            // One for an all ones fraction
            bins minNorm_m_3ulp[] = {[3'b101 : 3'b111]};
    }

    F128_minNorm_p_3ulp: coverpoint (
        CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF + 1)] == 1
            //  leading zeros                                                    guard                                                           sticky
            ? { |CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF -: F128_M_BITS], CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF + 1) - F128_M_BITS - 1], |CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF + 1) - F128_M_BITS - 2 : 0] }
            : { |CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF - 1) -: F128_M_BITS], CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF) - F128_M_BITS - 1], |CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF) - F128_M_BITS - 2 : 0] }
    ) iff (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_QUAD) == 1) {
            type_option.weight = 0;

            // Zero for an all zero fraction
            bins minNorm_p_3ulp[] = {[3'b000 : 3'b011]};
    }
    F128_minNorm_m_3ulp: coverpoint (
        CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF + 1)] == 1
            //  leading ones                                                    guard                                                           sticky
            ? { &CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF -: F128_M_BITS-1], CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF + 1) - F128_M_BITS], |CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF + 1) - F128_M_BITS - 1 : 0] }
            : { &CFI.fmaPreAddition[F128_FMA_PRE_ADDITION_NF -: F128_M_BITS-1], CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF) - F128_M_BITS], |CFI.fmaPreAddition[(F128_FMA_PRE_ADDITION_NF) - F128_M_BITS - 1 : 0] }
    ) iff (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_QUAD) == 0) {
            type_option.weight = 0;

            // One for an all ones fraction
            bins minNorm_m_3ulp[] = {[3'b101 : 3'b111]};
    }

    F16_minNorm_p_3ulp: coverpoint (
        CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF + 1)] == 1
            //  leading zeros                                                    guard                                                           sticky
            ? { |CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF -: F16_M_BITS], CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF + 1) - F16_M_BITS - 1], |CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF + 1) - F16_M_BITS - 2 : 0] }
            : { |CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF - 1) -: F16_M_BITS], CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF) - F16_M_BITS - 1], |CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF) - F16_M_BITS - 2 : 0] }
    ) iff (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_HALF) == 1) {
            type_option.weight = 0;

            // Zero for an all zero fraction
            bins minNorm_p_3ulp[] = {[3'b000 : 3'b011]};
    }
    F16_minNorm_m_3ulp: coverpoint (
        CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF + 1)] == 1
            //  leading ones                                                    guard                                                           sticky
            ? { &CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF -: F16_M_BITS-1], CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF + 1) - F16_M_BITS], |CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF + 1) - F16_M_BITS - 1 : 0] }
            : { &CFI.fmaPreAddition[F16_FMA_PRE_ADDITION_NF -: F16_M_BITS-1], CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF) - F16_M_BITS], |CFI.fmaPreAddition[(F16_FMA_PRE_ADDITION_NF) - F16_M_BITS - 1 : 0] }
    ) iff (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_HALF) == 0) {
            type_option.weight = 0;

            // One for an all ones fraction
            bins minNorm_m_3ulp[] = {[3'b101 : 3'b111]};
    }

    BF16_minNorm_p_3ulp: coverpoint (
        CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF + 1)] == 1
            //  leading zeros                                                    guard                                                           sticky
            ? { |CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF -: BF16_M_BITS], CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF + 1) - BF16_M_BITS - 1], |CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF + 1) - BF16_M_BITS - 2 : 0] }
            : { |CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF - 1) -: BF16_M_BITS], CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF) - BF16_M_BITS - 1], |CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF) - BF16_M_BITS - 2 : 0] }
    ) iff (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_BF16) == 1) {
            type_option.weight = 0;

            // Zero for an all zero fraction
            bins minNorm_p_3ulp[] = {[3'b000 : 3'b011]};
    }
    BF16_minNorm_m_3ulp: coverpoint (
        CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF + 1)] == 1
            //  leading ones                                                    guard                                                           sticky
            ? { &CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF -: BF16_M_BITS-1], CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF + 1) - BF16_M_BITS], |CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF + 1) - BF16_M_BITS - 1 : 0] }
            : { &CFI.fmaPreAddition[BF16_FMA_PRE_ADDITION_NF -: BF16_M_BITS-1], CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF) - BF16_M_BITS], |CFI.fmaPreAddition[(BF16_FMA_PRE_ADDITION_NF) - BF16_M_BITS - 1 : 0] }
    ) iff (get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_BF16) == 0) {
            type_option.weight = 0;

            // One for an all ones fraction
            bins minNorm_m_3ulp[] = {[3'b101 : 3'b111]};
    }

    // cases vii & viii
    F32_btw_minSubNorm_zero: coverpoint ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_SINGLE)))
        iff (CFI.fmaPreAddition != 0) {
            type_option.weight = 0;

            // shift 1 into the ULP position, subtract one to be in the exclusive range (0 , minSubNorm)
            bins btw_minSubNorm_zero = {[$:-F32_M_BITS]};
    }
    F64_btw_minSubNorm_zero: coverpoint ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_DOUBLE)))
        iff (CFI.fmaPreAddition != 0) {
            type_option.weight = 0;

            // shift 1 into the ULP position, subtract one to be in the exclusive range (0 , minSubNorm)
            bins btw_minSubNorm_zero = {[$:-F64_M_BITS]};
    }
    F128_btw_minSubNorm_zero: coverpoint ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_QUAD)))
        iff (CFI.fmaPreAddition != 0) {
            type_option.weight = 0;

            // shift 1 into the ULP position, subtract one to be in the exclusive range (0 , minSubNorm)
            bins btw_minSubNorm_zero = {[$:-F128_M_BITS]};
    }
    F16_btw_minSubNorm_zero: coverpoint ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_HALF)))
        iff (CFI.fmaPreAddition != 0) {
            type_option.weight = 0;

            // shift 1 into the ULP position, subtract one to be in the exclusive range (0 , minSubNorm)
            bins btw_minSubNorm_zero = {[$:-F16_M_BITS]};
    }
    BF16_btw_minSubNorm_zero: coverpoint ($signed(get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_BF16)))
        iff (CFI.fmaPreAddition != 0) {
            type_option.weight = 0;

            // shift 1 into the ULP position, subtract one to be in the exclusive range (0 , minSubNorm)
            bins btw_minSubNorm_zero = {[$:-BF16_M_BITS]};
    }

    // case ix
    F32_minNorm_p5_exp_range: coverpoint get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_SINGLE) {
        type_option.weight = 0;

        // minnorm.exp is 1 (unbiased) regardless of precision, so this covers the range [minnorm.exp , minnorm.exp + 5]
        bins exp_range[] = {[1:6]};
    }
    F64_minNorm_p5_exp_range: coverpoint get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_DOUBLE) {
        type_option.weight = 0;

        // minnorm.exp is 1 (unbiased) regardless of precision, so this covers the range [minnorm.exp , minnorm.exp + 5]
        bins exp_range[] = {[1:6]};
    }
    F128_minNorm_p5_exp_range: coverpoint get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_QUAD) {
        type_option.weight = 0;

        // minnorm.exp is 1 (unbiased) regardless of precision, so this covers the range [minnorm.exp , minnorm.exp + 5]
        bins exp_range[] = {[1:6]};
    }
    F16_minNorm_p5_exp_range: coverpoint get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_HALF) {
        type_option.weight = 0;

        // minnorm.exp is 1 (unbiased) regardless of precision, so this covers the range [minnorm.exp , minnorm.exp + 5]
        bins exp_range[] = {[1:6]};
    }
    BF16_minNorm_p5_exp_range: coverpoint get_effective_product_exponent(CFI.a, CFI.b, CFI.fmaPreAddition, FMT_BF16) {
        type_option.weight = 0;

        // minnorm.exp is 1 (unbiased) regardless of precision, so this covers the range [minnorm.exp , minnorm.exp + 5]
        bins exp_range[] = {[1:6]};
    }

    /****************************************************
     * Coverpoints to detect overflow and underflow flags
     ****************************************************/

    FP_no_overflow: coverpoint (CFI.exceptionBits & FLAG_OVERFLOW_MASK) {
        type_option.weight = 0;

        bins no_overflow = { 0 };
    }

    FP_no_underflow: coverpoint (CFI.exceptionBits & FLAG_UNDERFLOW_MASK) {
        type_option.weight = 0;

        bins no_underflow = { 0 };
    }


    `ifdef COVER_F32
        B18_case_i_f32: cross F32_src_fmt, FMA_ops, F32_product_lsb, F32_product_guard, F32_product_sticky, F32_interm_guard_zero, F32_interm_sticky_zero, F32_normal_multiplication;

        B18_case_ii_b4_maxNorm_pm_3ulp_f32: cross F32_src_fmt, FMA_ops, F32_prod_sign, F32_maxNorm_pm_3ulp, FP_no_overflow;
        B18_case_ii_b4_gt_maxNorm_p_3ulp_f32: cross F32_src_fmt, FMA_ops, F32_prod_sign, F32_gt_maxNorm_p_3ulp, FP_no_overflow;
        B18_case_ii_b4_maxNorm_pm3_exp_range_f32: cross F32_src_fmt, FMA_ops, F32_prod_sign, F32_maxNorm_pm3_exp_range, FP_no_overflow;

        B18_case_iii_b5_subnorm_f32: cross F32_src_fmt, FMA_ops, F32_prod_sign, F32_subnorm, FP_no_underflow;
        B18_case_iii_b5_minSubNorm_p_3ulp_f32: cross F32_src_fmt, FMA_ops, F32_prod_sign, F32_minSubNorm_p_3ulp, FP_no_underflow;
        B18_case_iii_b5_minSubNorm_m_1_2ulp_f32: cross F32_src_fmt, FMA_ops, F32_prod_sign, F32_minSubNorm_m_1_2ulp, FP_no_underflow;
        B18_case_iii_b5_minSubNorm_m_3ulp_f32: cross F32_src_fmt, FMA_ops, F32_prod_sign, F32_minSubNorm_m_3ulp, FP_no_underflow;
        B18_case_iii_b5_minNorm_p_3ulp_f32: cross F32_src_fmt, FMA_ops, F32_prod_sign, F32_minNorm_p_3ulp, FP_no_underflow;
        B18_case_iii_b5_minNorm_m_3ulp_f32: cross F32_src_fmt, FMA_ops, F32_prod_sign, F32_minNorm_m_3ulp, FP_no_underflow;
        B18_case_iii_b5_btw_minSubNorm_zero_f32: cross F32_src_fmt, FMA_ops, F32_prod_sign, F32_btw_minSubNorm_zero, FP_no_underflow;
        B18_case_iii_b5_minNorm_p5_exp_range_f32: cross F32_src_fmt, FMA_ops, F32_minNorm_p5_exp_range, FP_no_underflow; // No Sign in Aharoni et al
    `endif

    `ifdef COVER_F64
        B18_case_i_f64: cross F64_src_fmt, FMA_ops, F64_product_lsb, F64_product_guard, F64_product_sticky, F64_interm_guard_zero, F64_interm_sticky_zero, F64_normal_multiplication;

        B18_case_ii_b4_maxNorm_pm_3ulp_f64: cross F64_src_fmt, FMA_ops, F64_prod_sign, F64_maxNorm_pm_3ulp, FP_no_overflow;
        B18_case_ii_b4_gt_maxNorm_p_3ulp_f64: cross F64_src_fmt, FMA_ops, F64_prod_sign, F64_gt_maxNorm_p_3ulp, FP_no_overflow;
        B18_case_ii_b4_maxNorm_pm3_exp_range_f64: cross F64_src_fmt, FMA_ops, F64_prod_sign, F64_maxNorm_pm3_exp_range, FP_no_overflow;

        B18_case_iii_b5_subnorm_f64: cross F64_src_fmt, FMA_ops, F64_prod_sign, F64_subnorm, FP_no_underflow;
        B18_case_iii_b5_minSubNorm_p_3ulp_f64: cross F64_src_fmt, FMA_ops, F64_prod_sign, F64_minSubNorm_p_3ulp, FP_no_underflow;
        B18_case_iii_b5_minSubNorm_m_1_2ulp_f64: cross F64_src_fmt, FMA_ops, F64_prod_sign, F64_minSubNorm_m_1_2ulp, FP_no_underflow;
        B18_case_iii_b5_minSubNorm_m_3ulp_f64: cross F64_src_fmt, FMA_ops, F64_prod_sign, F64_minSubNorm_m_3ulp, FP_no_underflow;
        B18_case_iii_b5_minNorm_p_3ulp_f64: cross F64_src_fmt, FMA_ops, F64_prod_sign, F64_minNorm_p_3ulp, FP_no_underflow;
        B18_case_iii_b5_minNorm_m_3ulp_f64: cross F64_src_fmt, FMA_ops, F64_prod_sign, F64_minNorm_m_3ulp, FP_no_underflow;
        B18_case_iii_b5_btw_minSubNorm_zero_f64: cross F64_src_fmt, FMA_ops, F64_prod_sign, F64_btw_minSubNorm_zero, FP_no_underflow;
        B18_case_iii_b5_minNorm_p5_exp_range_f64: cross F64_src_fmt, FMA_ops, F64_minNorm_p5_exp_range, FP_no_underflow; // No Sign in Aharoni et al
    `endif

    `ifdef COVER_F128
        B18_case_i_f128: cross F128_src_fmt, FMA_ops, F128_product_lsb, F128_product_guard, F128_product_sticky, F128_interm_guard_zero, F128_interm_sticky_zero, F128_normal_multiplication;

        B18_case_ii_b4_maxNorm_pm_3ulp_f128: cross F128_src_fmt, FMA_ops, F128_prod_sign, F128_maxNorm_pm_3ulp, FP_no_overflow;
        B18_case_ii_b4_gt_maxNorm_p_3ulp_f128: cross F128_src_fmt, FMA_ops, F128_prod_sign, F128_gt_maxNorm_p_3ulp, FP_no_overflow;
        B18_case_ii_b4_maxNorm_pm3_exp_range_f128: cross F128_src_fmt, FMA_ops, F128_prod_sign, F128_maxNorm_pm3_exp_range, FP_no_overflow;

        B18_case_iii_b5_subnorm_f128: cross F128_src_fmt, FMA_ops, F128_prod_sign, F128_subnorm, FP_no_underflow;
        B18_case_iii_b5_minSubNorm_p_3ulp_f128: cross F128_src_fmt, FMA_ops, F128_prod_sign, F128_minSubNorm_p_3ulp, FP_no_underflow;
        B18_case_iii_b5_minSubNorm_m_1_2ulp_f128: cross F128_src_fmt, FMA_ops, F128_prod_sign, F128_minSubNorm_m_1_2ulp, FP_no_underflow;
        B18_case_iii_b5_minSubNorm_m_3ulp_f128: cross F128_src_fmt, FMA_ops, F128_prod_sign, F128_minSubNorm_m_3ulp, FP_no_underflow;
        B18_case_iii_b5_minNorm_p_3ulp_f128: cross F128_src_fmt, FMA_ops, F128_prod_sign, F128_minNorm_p_3ulp, FP_no_underflow;
        B18_case_iii_b5_minNorm_m_3ulp_f128: cross F128_src_fmt, FMA_ops, F128_prod_sign, F128_minNorm_m_3ulp, FP_no_underflow;
        B18_case_iii_b5_btw_minSubNorm_zero_f128: cross F128_src_fmt, FMA_ops, F128_prod_sign, F128_btw_minSubNorm_zero, FP_no_underflow;
        B18_case_iii_b5_minNorm_p5_exp_range_f128: cross F128_src_fmt, FMA_ops, F128_minNorm_p5_exp_range, FP_no_underflow; // No Sign in Aharoni et al
    `endif

    `ifdef COVER_F16
        B18_case_i_f16: cross F16_src_fmt, FMA_ops, F16_product_lsb, F16_product_guard, F16_product_sticky, F16_interm_guard_zero, F16_interm_sticky_zero, F16_normal_multiplication;

        B18_case_ii_b4_maxNorm_pm_3ulp_f16: cross F16_src_fmt, FMA_ops, F16_prod_sign, F16_maxNorm_pm_3ulp, FP_no_overflow {
            ignore_bins impossible_mul = binsof(F16_maxNorm_pm_3ulp.maxNorm_pm_3ulp) intersect {2};
        }
        B18_case_ii_b4_gt_maxNorm_p_3ulp_f16: cross F16_src_fmt, FMA_ops, F16_prod_sign, F16_gt_maxNorm_p_3ulp, FP_no_overflow;
        B18_case_ii_b4_maxNorm_pm3_exp_range_f16: cross F16_src_fmt, FMA_ops, F16_prod_sign, F16_maxNorm_pm3_exp_range, FP_no_overflow;

        B18_case_iii_b5_subnorm_f16: cross F16_src_fmt, FMA_ops, F16_prod_sign, F16_subnorm, FP_no_underflow;
        B18_case_iii_b5_minSubNorm_p_3ulp_f16: cross F16_src_fmt, FMA_ops, F16_prod_sign, F16_minSubNorm_p_3ulp, FP_no_underflow;
        B18_case_iii_b5_minSubNorm_m_1_2ulp_f16: cross F16_src_fmt, FMA_ops, F16_prod_sign, F16_minSubNorm_m_1_2ulp, FP_no_underflow;
        B18_case_iii_b5_minSubNorm_m_3ulp_f16: cross F16_src_fmt, FMA_ops, F16_prod_sign, F16_minSubNorm_m_3ulp, FP_no_underflow;
        B18_case_iii_b5_minNorm_p_3ulp_f16: cross F16_src_fmt, FMA_ops, F16_prod_sign, F16_minNorm_p_3ulp, FP_no_underflow;
        B18_case_iii_b5_minNorm_m_3ulp_f16: cross F16_src_fmt, FMA_ops, F16_prod_sign, F16_minNorm_m_3ulp, FP_no_underflow;
        B18_case_iii_b5_btw_minSubNorm_zero_f16: cross F16_src_fmt, FMA_ops, F16_prod_sign, F16_btw_minSubNorm_zero, FP_no_underflow;
        B18_case_iii_b5_minNorm_p5_exp_range_f16: cross F16_src_fmt, FMA_ops, F16_minNorm_p5_exp_range, FP_no_underflow; // No Sign in Aharoni et al
    `endif

    `ifdef COVER_BF16
        B18_case_i_bf16: cross BF16_src_fmt, FMA_ops, BF16_product_lsb, BF16_product_guard, BF16_product_sticky, BF16_interm_guard_zero, BF16_interm_sticky_zero, BF16_normal_multiplication;

        B18_case_ii_b4_maxNorm_pm_3ulp_bf16: cross BF16_src_fmt, FMA_ops, BF16_prod_sign, BF16_maxNorm_pm_3ulp, FP_no_overflow {
            ignore_bins impossible_mul = binsof(BF16_maxNorm_pm_3ulp.maxNorm_pm_3ulp) intersect {2};
        }
        B18_case_ii_b4_gt_maxNorm_p_3ulp_bf16: cross BF16_src_fmt, FMA_ops, BF16_prod_sign, BF16_gt_maxNorm_p_3ulp, FP_no_overflow;
        B18_case_ii_b4_maxNorm_pm3_exp_range_bf16: cross BF16_src_fmt, FMA_ops, BF16_prod_sign, BF16_maxNorm_pm3_exp_range, FP_no_overflow;

        B18_case_iii_b5_subnorm_bf16: cross BF16_src_fmt, FMA_ops, BF16_prod_sign, BF16_subnorm, FP_no_underflow;
        B18_case_iii_b5_minSubNorm_p_3ulp_bf16: cross BF16_src_fmt, FMA_ops, BF16_prod_sign, BF16_minSubNorm_p_3ulp, FP_no_underflow;
        B18_case_iii_b5_minSubNorm_m_1_2ulp_bf16: cross BF16_src_fmt, FMA_ops, BF16_prod_sign, BF16_minSubNorm_m_1_2ulp, FP_no_underflow;
        B18_case_iii_b5_minSubNorm_m_3ulp_bf16: cross BF16_src_fmt, FMA_ops, BF16_prod_sign, BF16_minSubNorm_m_3ulp, FP_no_underflow;
        B18_case_iii_b5_minNorm_p_3ulp_bf16: cross BF16_src_fmt, FMA_ops, BF16_prod_sign, BF16_minNorm_p_3ulp, FP_no_underflow {
            ignore_bins impossible_mul = binsof(BF16_minNorm_p_3ulp.minNorm_p_3ulp) intersect {2};
        }
        B18_case_iii_b5_minNorm_m_3ulp_bf16: cross BF16_src_fmt, FMA_ops, BF16_prod_sign, BF16_minNorm_m_3ulp, FP_no_underflow;
        B18_case_iii_b5_btw_minSubNorm_zero_bf16: cross BF16_src_fmt, FMA_ops, BF16_prod_sign, BF16_btw_minSubNorm_zero, FP_no_underflow;
        B18_case_iii_b5_minNorm_p5_exp_range_bf16: cross BF16_src_fmt, FMA_ops, BF16_minNorm_p5_exp_range, FP_no_underflow; // No Sign in Aharoni et al
    `endif
endgroup
