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

covergroup B2_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;

    FP_arith_ops: coverpoint CFI.op {
        type_option.weight = 0;
        `include "bins_templates/arithmetic_op_bins.svh"
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

    // near zero
    F32_near_zero: coverpoint sig_diff_index(CFI.result[F32_M_UPPER : 0], {F32_M_BITS{1'b0}}, F32_M_BITS)
        iff (sig_hamming_distance(CFI.result[F32_M_UPPER : 0], {F32_M_BITS{1'b0}}, F32_M_BITS) == 1 && // zero.sig = 0
             CFI.result[F32_E_UPPER : F32_E_LOWER] == {F32_E_BITS{1'b0}}) { // zero.exp = 0

            type_option.weight = 0;

            bins hamm_dist_1_from_zero[] = {[0 : F32_M_BITS - 1]};
    }

    F64_near_zero: coverpoint sig_diff_index(CFI.result[F64_M_UPPER : 0], {F64_M_BITS{1'b0}}, F64_M_BITS)
        iff (sig_hamming_distance(CFI.result[F64_M_UPPER : 0], {F64_M_BITS{1'b0}}, F64_M_BITS) == 1 && // zero.sig = 0
             CFI.result[F64_E_UPPER : F64_E_LOWER] == {F64_E_BITS{1'b0}}) { // zero.exp = 0

            type_option.weight = 0;

            bins hamm_dist_1_from_zero[] = {[0 : F64_M_BITS - 1]};
    }

    F128_near_zero: coverpoint sig_diff_index(CFI.result[F128_M_UPPER : 0], {F128_M_BITS{1'b0}}, F128_M_BITS)
        iff (sig_hamming_distance(CFI.result[F128_M_UPPER : 0], {F128_M_BITS{1'b0}}, F128_M_BITS) == 1 && // zero.sig = 0
             CFI.result[F128_E_UPPER : F128_E_LOWER] == {F128_E_BITS{1'b0}}) { // zero.exp = 0

            type_option.weight = 0;

            bins hamm_dist_1_from_zero[] = {[0 : F128_M_BITS - 1]};
    }

    F16_near_zero: coverpoint sig_diff_index(CFI.result[F16_M_UPPER : 0], {F16_M_BITS{1'b0}}, F16_M_BITS)
        iff (sig_hamming_distance(CFI.result[F16_M_UPPER : 0], {F16_M_BITS{1'b0}}, F16_M_BITS) == 1 && // zero.sig = 0
             CFI.result[F16_E_UPPER : F16_E_LOWER] == {F16_E_BITS{1'b0}}) { // zero.exp = 0

            type_option.weight = 0;

            bins hamm_dist_1_from_zero[] = {[0 : F16_M_BITS - 1]};
    }

    BF16_near_zero: coverpoint sig_diff_index(CFI.result[BF16_M_UPPER : 0], {BF16_M_BITS{1'b0}}, BF16_M_BITS)
        iff (sig_hamming_distance(CFI.result[BF16_M_UPPER : 0], {BF16_M_BITS{1'b0}}, BF16_M_BITS) == 1 && // zero.sig = 0
             CFI.result[BF16_E_UPPER : BF16_E_LOWER] == {BF16_E_BITS{1'b0}}) { // zero.exp = 0

            type_option.weight = 0;

            bins hamm_dist_1_from_zero[] = {[0 : BF16_M_BITS - 1]};
    }


    // near one
    F32_near_one: coverpoint sig_diff_index(CFI.result[F32_M_UPPER : 0], {F32_M_BITS{1'b0}}, F32_M_BITS)
        iff (sig_hamming_distance(CFI.result[F32_M_UPPER : 0], {F32_M_BITS{1'b0}}, F32_M_BITS) == 1 && // one.sig = 0
             CFI.result[F32_E_UPPER : F32_E_LOWER] == {1'b0, {(F32_E_BITS - 1){1'b1}}}) { // one.exp = 011...11

            type_option.weight = 0;

            bins hamm_dist_1_from_one[] = {[0 : F32_M_BITS - 1]};
    }

    F64_near_one: coverpoint sig_diff_index(CFI.result[F64_M_UPPER : 0], {F64_M_BITS{1'b0}}, F64_M_BITS)
        iff (sig_hamming_distance(CFI.result[F64_M_UPPER : 0], {F64_M_BITS{1'b0}}, F64_M_BITS) == 1 && // one.sig = 0
             CFI.result[F64_E_UPPER : F64_E_LOWER] == {1'b0, {(F64_E_BITS - 1){1'b1}}}) { // one.exp = 011...11

            type_option.weight = 0;

            bins hamm_dist_1_from_one[] = {[0 : F64_M_BITS - 1]};
    }

    F128_near_one: coverpoint sig_diff_index(CFI.result[F128_M_UPPER : 0], {F128_M_BITS{1'b0}}, F128_M_BITS)
        iff (sig_hamming_distance(CFI.result[F128_M_UPPER : 0], {F128_M_BITS{1'b0}}, F128_M_BITS) == 1 && // one.sig = 0
             CFI.result[F128_E_UPPER : F128_E_LOWER] == {1'b0, {(F128_E_BITS - 1){1'b1}}}) { // one.exp = 011...11

            type_option.weight = 0;

            bins hamm_dist_1_from_one[] = {[0 : F128_M_BITS - 1]};
    }

    F16_near_one: coverpoint sig_diff_index(CFI.result[F16_M_UPPER : 0], {F16_M_BITS{1'b0}}, F16_M_BITS)
        iff (sig_hamming_distance(CFI.result[F16_M_UPPER : 0], {F16_M_BITS{1'b0}}, F16_M_BITS) == 1 && // one.sig = 0
             CFI.result[F16_E_UPPER : F16_E_LOWER] == {1'b0, {(F16_E_BITS - 1){1'b1}}}) { // one.exp = 011...11

            type_option.weight = 0;

            bins hamm_dist_1_from_one[] = {[0 : F16_M_BITS - 1]};
    }

    BF16_near_one: coverpoint sig_diff_index(CFI.result[BF16_M_UPPER : 0], {BF16_M_BITS{1'b0}}, BF16_M_BITS)
        iff (sig_hamming_distance(CFI.result[BF16_M_UPPER : 0], {BF16_M_BITS{1'b0}}, BF16_M_BITS) == 1 && // one.sig = 0
             CFI.result[BF16_E_UPPER : BF16_E_LOWER] == {1'b0, {(BF16_E_BITS - 1){1'b1}}}) { // one.exp = 011...11

            type_option.weight = 0;

            bins hamm_dist_1_from_one[] = {[0 : BF16_M_BITS - 1]};
    }


    // near minsubnorm
    F32_near_minsubnorm: coverpoint sig_diff_index(CFI.result[F32_M_UPPER : 0], {{F32_M_BITS-1{1'b0}}, 1'b1}, F32_M_BITS)
        iff (sig_hamming_distance(CFI.result[F32_M_UPPER : 0], {{F32_M_BITS-1{1'b0}}, 1'b1}, F32_M_BITS) == 1 && // minsubnorm.sig = 00...001
             CFI.result[F32_E_UPPER : F32_E_LOWER] == {F32_E_BITS{1'b0}}) { // subnorm.exp = 0

            type_option.weight = 0;

            bins hamm_dist_1_from_minsubnorm[] = {[0 : F32_M_BITS - 1]};
    }

    F64_near_minsubnorm: coverpoint sig_diff_index(CFI.result[F64_M_UPPER : 0], {{F64_M_BITS-1{1'b0}}, 1'b1}, F64_M_BITS)
        iff (sig_hamming_distance(CFI.result[F64_M_UPPER : 0], {{F64_M_BITS-1{1'b0}}, 1'b1}, F64_M_BITS) == 1 && // minsubnorm.sig = 00...001
             CFI.result[F64_E_UPPER : F64_E_LOWER] == {F64_E_BITS{1'b0}}) { // subnorm.exp = 0

            type_option.weight = 0;

            bins hamm_dist_1_from_minsubnorm[] = {[0 : F64_M_BITS - 1]};
    }

    F128_near_minsubnorm: coverpoint sig_diff_index(CFI.result[F128_M_UPPER : 0], {{F128_M_BITS-1{1'b0}}, 1'b1}, F128_M_BITS)
        iff (sig_hamming_distance(CFI.result[F128_M_UPPER : 0], {{F128_M_BITS-1{1'b0}}, 1'b1}, F128_M_BITS) == 1 && // minsubnorm.sig = 00...001
             CFI.result[F128_E_UPPER : F128_E_LOWER] == {F128_E_BITS{1'b0}}) { // subnorm.exp = 0

            type_option.weight = 0;

            bins hamm_dist_1_from_minsubnorm[] = {[0 : F128_M_BITS - 1]};
    }

    F16_near_minsubnorm: coverpoint sig_diff_index(CFI.result[F16_M_UPPER : 0], {{F16_M_BITS-1{1'b0}}, 1'b1}, F16_M_BITS)
        iff (sig_hamming_distance(CFI.result[F16_M_UPPER : 0], {{F16_M_BITS-1{1'b0}}, 1'b1}, F16_M_BITS) == 1 && // minsubnorm.sig = 00...001
             CFI.result[F16_E_UPPER : F16_E_LOWER] == {F16_E_BITS{1'b0}}) { // subnorm.exp = 0

            type_option.weight = 0;

            bins hamm_dist_1_from_minsubnorm[] = {[0 : F16_M_BITS - 1]};
    }

    BF16_near_minsubnorm: coverpoint sig_diff_index(CFI.result[BF16_M_UPPER : 0], {{BF16_M_BITS-1{1'b0}}, 1'b1}, BF16_M_BITS)
        iff (sig_hamming_distance(CFI.result[BF16_M_UPPER : 0], {{BF16_M_BITS-1{1'b0}}, 1'b1}, BF16_M_BITS) == 1 && // minsubnorm.sig = 00...001
             CFI.result[BF16_E_UPPER : BF16_E_LOWER] == {BF16_E_BITS{1'b0}}) { // subnorm.exp = 0

            type_option.weight = 0;

            bins hamm_dist_1_from_minsubnorm[] = {[0 : BF16_M_BITS - 1]};
    }

    // near maxsubnorm
    F32_near_maxsubnorm: coverpoint sig_diff_index(CFI.result[F32_M_UPPER : 0], {F32_M_BITS{1'b1}}, F32_M_BITS)
        iff (sig_hamming_distance(CFI.result[F32_M_UPPER : 0], {F32_M_BITS{1'b1}}, F32_M_BITS) == 1 && // maxsubnorm.sig = 11...111
             CFI.result[F32_E_UPPER : F32_E_LOWER] == {F32_E_BITS{1'b0}}) { // subnorm.exp = 0

            type_option.weight = 0;

            bins hamm_dist_1_from_maxsubnorm[] = {[0 : F32_M_BITS - 1]};
    }

    F64_near_maxsubnorm: coverpoint sig_diff_index(CFI.result[F64_M_UPPER : 0], {F64_M_BITS{1'b1}}, F64_M_BITS)
        iff (sig_hamming_distance(CFI.result[F64_M_UPPER : 0], {F64_M_BITS{1'b1}}, F64_M_BITS) == 1 && // maxsubnorm.sig = 11...111
             CFI.result[F64_E_UPPER : F64_E_LOWER] == {F64_E_BITS{1'b0}}) { // subnorm.exp = 0

            type_option.weight = 0;

            bins hamm_dist_1_from_maxsubnorm[] = {[0 : F64_M_BITS - 1]};
    }

    F128_near_maxsubnorm: coverpoint sig_diff_index(CFI.result[F128_M_UPPER : 0], {F128_M_BITS{1'b1}}, F128_M_BITS)
        iff (sig_hamming_distance(CFI.result[F128_M_UPPER : 0], {F128_M_BITS{1'b1}}, F128_M_BITS) == 1 && // maxsubnorm.sig = 11...111
             CFI.result[F128_E_UPPER : F128_E_LOWER] == {F128_E_BITS{1'b0}}) { // subnorm.exp = 0

            type_option.weight = 0;

            bins hamm_dist_1_from_maxsubnorm[] = {[0 : F128_M_BITS - 1]};
    }

    F16_near_maxsubnorm: coverpoint sig_diff_index(CFI.result[F16_M_UPPER : 0], {F16_M_BITS{1'b1}}, F16_M_BITS)
        iff (sig_hamming_distance(CFI.result[F16_M_UPPER : 0], {F16_M_BITS{1'b1}}, F16_M_BITS) == 1 && // maxsubnorm.sig = 11...111
             CFI.result[F16_E_UPPER : F16_E_LOWER] == {F16_E_BITS{1'b0}}) { // subnorm.exp = 0

            type_option.weight = 0;

            bins hamm_dist_1_from_maxsubnorm[] = {[0 : F16_M_BITS - 1]};
    }

    BF16_near_maxsubnorm: coverpoint sig_diff_index(CFI.result[BF16_M_UPPER : 0], {BF16_M_BITS{1'b1}}, BF16_M_BITS)
        iff (sig_hamming_distance(CFI.result[BF16_M_UPPER : 0], {BF16_M_BITS{1'b1}}, BF16_M_BITS) == 1 && // maxsubnorm.sig = 11...111
             CFI.result[BF16_E_UPPER : BF16_E_LOWER] == {BF16_E_BITS{1'b0}}) { // subnorm.exp = 0

            type_option.weight = 0;

            bins hamm_dist_1_from_maxsubnorm[] = {[0 : BF16_M_BITS - 1]};
    }

    // near minnorm
    F32_near_minnorm: coverpoint sig_diff_index(CFI.result[F32_M_UPPER : 0], {F32_M_BITS{1'b0}}, F32_M_BITS)
        iff (sig_hamming_distance(CFI.result[F32_M_UPPER : 0], {F32_M_BITS{1'b0}}, F32_M_BITS) == 1 && // minnorm.sig = 0
             CFI.result[F32_E_UPPER : F32_E_LOWER] == {{F32_E_BITS-1{1'b0}}, 1'b1}) { // minnorm.exp = 00...001

            type_option.weight = 0;

            bins hamm_dist_1_from_minnorm[] = {[0 : F32_M_BITS - 1]};
    }

    F64_near_minnorm: coverpoint sig_diff_index(CFI.result[F64_M_UPPER : 0], {F64_M_BITS{1'b0}}, F64_M_BITS)
        iff (sig_hamming_distance(CFI.result[F64_M_UPPER : 0], {F64_M_BITS{1'b0}}, F64_M_BITS) == 1 && // minnorm.sig = 0
             CFI.result[F64_E_UPPER : F64_E_LOWER] == {{F64_E_BITS-1{1'b0}}, 1'b1}) { // minnorm.exp = 00...001

            type_option.weight = 0;

            bins hamm_dist_1_from_minnorm[] = {[0 : F64_M_BITS - 1]};
    }

    F128_near_minnorm: coverpoint sig_diff_index(CFI.result[F128_M_UPPER : 0], {F128_M_BITS{1'b0}}, F128_M_BITS)
        iff (sig_hamming_distance(CFI.result[F128_M_UPPER : 0], {F128_M_BITS{1'b0}}, F128_M_BITS) == 1 && // minnorm.sig = 0
             CFI.result[F128_E_UPPER : F128_E_LOWER] == {{F128_E_BITS-1{1'b0}}, 1'b1}) { // minnorm.exp = 00...001

            type_option.weight = 0;

            bins hamm_dist_1_from_minnorm[] = {[0 : F128_M_BITS - 1]};
    }

    F16_near_minnorm: coverpoint sig_diff_index(CFI.result[F16_M_UPPER : 0], {F16_M_BITS{1'b0}}, F16_M_BITS)
        iff (sig_hamming_distance(CFI.result[F16_M_UPPER : 0], {F16_M_BITS{1'b0}}, F16_M_BITS) == 1 && // minnorm.sig = 0
             CFI.result[F16_E_UPPER : F16_E_LOWER] == {{F16_E_BITS-1{1'b0}}, 1'b1}) { // minnorm.exp = 00...001

            type_option.weight = 0;

            bins hamm_dist_1_from_minnorm[] = {[0 : F16_M_BITS - 1]};
    }

    BF16_near_minnorm: coverpoint sig_diff_index(CFI.result[BF16_M_UPPER : 0], {BF16_M_BITS{1'b0}}, BF16_M_BITS)
        iff (sig_hamming_distance(CFI.result[BF16_M_UPPER : 0], {BF16_M_BITS{1'b0}}, BF16_M_BITS) == 1 && // minnorm.sig = 0
             CFI.result[BF16_E_UPPER : BF16_E_LOWER] == {{BF16_E_BITS-1{1'b0}}, 1'b1}) { // minnorm.exp = 00...001

            type_option.weight = 0;

            bins hamm_dist_1_from_minnorm[] = {[0 : BF16_M_BITS - 1]};
    }

    // near maxnorm
    F32_near_maxnorm: coverpoint sig_diff_index(CFI.result[F32_M_UPPER : 0], {F32_M_BITS{1'b1}}, F32_M_BITS)
        iff (sig_hamming_distance(CFI.result[F32_M_UPPER : 0], {F32_M_BITS{1'b1}}, F32_M_BITS) == 1 && // maxnorm.sig = 11...111
             CFI.result[F32_E_UPPER : F32_E_LOWER] == {{F32_E_BITS-1{1'b1}}, 1'b0}) { // maxnorm.exp = 11...110

            type_option.weight = 0;

            bins hamm_dist_1_from_maxnorm[] = {[0 : F32_M_BITS - 1]};
    }

    F64_near_maxnorm: coverpoint sig_diff_index(CFI.result[F64_M_UPPER : 0], {F64_M_BITS{1'b1}}, F64_M_BITS)
        iff (sig_hamming_distance(CFI.result[F64_M_UPPER : 0], {F64_M_BITS{1'b1}}, F64_M_BITS) == 1 && // maxnorm.sig = 11...111
             CFI.result[F64_E_UPPER : F64_E_LOWER] == {{F64_E_BITS-1{1'b1}}, 1'b0}) { // maxnorm.exp = 11...110

            type_option.weight = 0;

            bins hamm_dist_1_from_maxnorm[] = {[0 : F64_M_BITS - 1]};
    }

    F128_near_maxnorm: coverpoint sig_diff_index(CFI.result[F128_M_UPPER : 0], {F128_M_BITS{1'b1}}, F128_M_BITS)
        iff (sig_hamming_distance(CFI.result[F128_M_UPPER : 0], {F128_M_BITS{1'b1}}, F128_M_BITS) == 1 && // maxnorm.sig = 11...111
             CFI.result[F128_E_UPPER : F128_E_LOWER] == {{F128_E_BITS-1{1'b1}}, 1'b0}) { // maxnorm.exp = 11...110

            type_option.weight = 0;

            bins hamm_dist_1_from_maxnorm[] = {[0 : F128_M_BITS - 1]};
    }

    F16_near_maxnorm: coverpoint sig_diff_index(CFI.result[F16_M_UPPER : 0], {F16_M_BITS{1'b1}}, F16_M_BITS)
        iff (sig_hamming_distance(CFI.result[F16_M_UPPER : 0], {F16_M_BITS{1'b1}}, F16_M_BITS) == 1 && // maxnorm.sig = 11...111
             CFI.result[F16_E_UPPER : F16_E_LOWER] == {{F16_E_BITS-1{1'b1}}, 1'b0}) { // maxnorm.exp = 11...110

            type_option.weight = 0;

            bins hamm_dist_1_from_maxnorm[] = {[0 : F16_M_BITS - 1]};
    }

    BF16_near_maxnorm: coverpoint sig_diff_index(CFI.result[BF16_M_UPPER : 0], {BF16_M_BITS{1'b1}}, BF16_M_BITS)
        iff (sig_hamming_distance(CFI.result[BF16_M_UPPER : 0], {BF16_M_BITS{1'b1}}, BF16_M_BITS) == 1 && // maxnorm.sig = 11...111
             CFI.result[BF16_E_UPPER : BF16_E_LOWER] == {{BF16_E_BITS-1{1'b1}}, 1'b0}) { // maxnorm.exp = 11...110

            type_option.weight = 0;

            bins hamm_dist_1_from_maxnorm[] = {[0 : BF16_M_BITS - 1]};
    }


    // main coverpoints
    `ifdef COVER_F32
        B2_F32_near_one        : cross FP_arith_ops, F32_sign, F32_near_one,        F32_result_fmt {
            ignore_bins negative_sqrt = binsof(FP_arith_ops.op_sqrt) with (F32_sign == 1'b1);
        }
        B2_F32_near_zero       : cross FP_arith_ops, F32_sign, F32_near_zero,       F32_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_F32_near_minsubnorm : cross FP_arith_ops, F32_sign, F32_near_minsubnorm, F32_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_F32_near_maxsubnorm : cross FP_arith_ops, F32_sign, F32_near_maxsubnorm, F32_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_F32_near_minnorm    : cross FP_arith_ops, F32_sign, F32_near_minnorm,    F32_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_F32_near_maxnorm    : cross FP_arith_ops, F32_sign, F32_near_maxnorm,    F32_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
    `endif // COVER_F32

    `ifdef COVER_F64
        B2_F64_near_one        : cross FP_arith_ops, F64_sign, F64_near_one,        F64_result_fmt {
            ignore_bins negative_sqrt = binsof(FP_arith_ops.op_sqrt) with (F64_sign == 1'b1);

        }
        B2_F64_near_zero       : cross FP_arith_ops, F64_sign, F64_near_zero,       F64_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_F64_near_minsubnorm : cross FP_arith_ops, F64_sign, F64_near_minsubnorm, F64_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_F64_near_maxsubnorm : cross FP_arith_ops, F64_sign, F64_near_maxsubnorm, F64_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_F64_near_minnorm    : cross FP_arith_ops, F64_sign, F64_near_minnorm,    F64_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_F64_near_maxnorm    : cross FP_arith_ops, F64_sign, F64_near_maxnorm,    F64_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
    `endif // COVER_F64

    `ifdef COVER_F16
        B2_F16_near_one        : cross FP_arith_ops, F16_sign, F16_near_one,        F16_result_fmt {
            ignore_bins negative_sqrt = binsof(FP_arith_ops.op_sqrt) with (F16_sign == 1'b1);

        }
        B2_F16_near_zero       : cross FP_arith_ops, F16_sign, F16_near_zero,       F16_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_F16_near_minsubnorm : cross FP_arith_ops, F16_sign, F16_near_minsubnorm, F16_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_F16_near_maxsubnorm : cross FP_arith_ops, F16_sign, F16_near_maxsubnorm, F16_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_F16_near_minnorm    : cross FP_arith_ops, F16_sign, F16_near_minnorm,    F16_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_F16_near_maxnorm    : cross FP_arith_ops, F16_sign, F16_near_maxnorm,    F16_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
    `endif // COVER_F16

    `ifdef COVER_BF16
        B2_BF16_near_one        : cross FP_arith_ops, BF16_sign, BF16_near_one,        BF16_result_fmt {
            ignore_bins negative_sqrt = binsof(FP_arith_ops.op_sqrt) with (BF16_sign == 1'b1);
        }
        B2_BF16_near_zero       : cross FP_arith_ops, BF16_sign, BF16_near_zero,       BF16_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_BF16_near_minsubnorm : cross FP_arith_ops, BF16_sign, BF16_near_minsubnorm, BF16_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_BF16_near_maxsubnorm : cross FP_arith_ops, BF16_sign, BF16_near_maxsubnorm, BF16_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_BF16_near_minnorm    : cross FP_arith_ops, BF16_sign, BF16_near_minnorm,    BF16_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_BF16_near_maxnorm    : cross FP_arith_ops, BF16_sign, BF16_near_maxnorm,    BF16_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
    `endif // COVER_BF16

    `ifdef COVER_F128
        B2_F128_near_one        : cross FP_arith_ops, F128_sign, F128_near_one,        F128_result_fmt {
            ignore_bins negative_sqrt = binsof(FP_arith_ops.op_sqrt) with (F128_sign == 1'b1);
        }
        B2_F128_near_zero       : cross FP_arith_ops, F128_sign, F128_near_zero,       F128_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_F128_near_minsubnorm : cross FP_arith_ops, F128_sign, F128_near_minsubnorm, F128_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_F128_near_maxsubnorm : cross FP_arith_ops, F128_sign, F128_near_maxsubnorm, F128_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_F128_near_minnorm    : cross FP_arith_ops, F128_sign, F128_near_minnorm,    F128_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
        B2_F128_near_maxnorm    : cross FP_arith_ops, F128_sign, F128_near_maxnorm,    F128_result_fmt {
            ignore_bins impossible_sqrt = binsof(FP_arith_ops.op_sqrt);
        }
    `endif // COVER_F128


endgroup
