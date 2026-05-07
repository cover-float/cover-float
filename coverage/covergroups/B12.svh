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

covergroup B12_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;

    /************************************************************************
     *
     * Operation helper coverpoint (Add / Sub only)
     *
     ************************************************************************/

    FP_addsub_ops: coverpoint CFI.op {
        type_option.weight = 0;
        bins add = {OP_ADD};
        bins sub = {OP_SUB};
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
     * Cancellation helper coverpoints
     *
     * cancellation = exp(result) - max(exp(a), exp(b))
     *
     ************************************************************************/

    F16_cancellation: coverpoint
        (
            $signed(int'(CFI.intermX)) -
            (
                (int'(CFI.a[F16_E_UPPER:F16_E_LOWER]) > int'(CFI.b[F16_E_UPPER:F16_E_LOWER]))
                ? int'(CFI.a[F16_E_UPPER:F16_E_LOWER])
                : int'(CFI.b[F16_E_UPPER:F16_E_LOWER])
            )
        )
    {
        type_option.weight = 0;
        bins cancel[] = {[-F16_P : 1]};
    }

    BF16_cancellation: coverpoint
        (
            $signed(int'(CFI.intermX)) -
            (
                (int'(CFI.a[BF16_E_UPPER:BF16_E_LOWER]) > int'(CFI.b[BF16_E_UPPER:BF16_E_LOWER]))
                ? int'(CFI.a[BF16_E_UPPER:BF16_E_LOWER])
                : int'(CFI.b[BF16_E_UPPER:BF16_E_LOWER])
            )
        )
    {
        type_option.weight = 0;
        bins cancel[] = {[-BF16_P : 1]};
    }

    F32_cancellation: coverpoint
        (
            $signed(int'(CFI.intermX)) -
            (
                (int'(CFI.a[F32_E_UPPER:F32_E_LOWER]) > int'(CFI.b[F32_E_UPPER:F32_E_LOWER]))
                ? int'(CFI.a[F32_E_UPPER:F32_E_LOWER])
                : int'(CFI.b[F32_E_UPPER:F32_E_LOWER])
            )
        )
    {
        type_option.weight = 0;
        bins cancel[] = {[-F32_P : 1]};
    }

    F64_cancellation: coverpoint
        (
            $signed(int'(CFI.intermX)) -
            (
                (int'(CFI.a[F64_E_UPPER:F64_E_LOWER]) > int'(CFI.b[F64_E_UPPER:F64_E_LOWER]))
                ? int'(CFI.a[F64_E_UPPER:F64_E_LOWER])
                : int'(CFI.b[F64_E_UPPER:F64_E_LOWER])
            )
        )
    {
        type_option.weight = 0;
        bins cancel[] = {[-F64_P : 1]};
    }

    F128_cancellation: coverpoint
        (
            $signed(int'(CFI.intermX)) -
            (
                (int'(CFI.a[F128_E_UPPER:F128_E_LOWER]) > int'(CFI.b[F128_E_UPPER:F128_E_LOWER]))
                ? int'(CFI.a[F128_E_UPPER:F128_E_LOWER])
                : int'(CFI.b[F128_E_UPPER:F128_E_LOWER])
            )
        )
    {
        type_option.weight = 0;
        bins cancel[] = {[-F128_P : 1]};
    }

    /************************************************************************
     *
     * Main crosses (precision-gated)
     *
     ************************************************************************/

    `ifdef COVER_F16
        B12_F16_addsub_cancel:  cross FP_addsub_ops, F16_cancellation,  F16_result_fmt;
    `endif

    `ifdef COVER_BF16
        B12_BF16_addsub_cancel: cross FP_addsub_ops, BF16_cancellation, BF16_result_fmt;
    `endif

    `ifdef COVER_F32
        B12_F32_addsub_cancel:  cross FP_addsub_ops, F32_cancellation,  F32_result_fmt;
    `endif

    `ifdef COVER_F64
        B12_F64_addsub_cancel:  cross FP_addsub_ops, F64_cancellation,  F64_result_fmt;
    `endif

    `ifdef COVER_F128
        B12_F128_addsub_cancel: cross FP_addsub_ops, F128_cancellation, F128_result_fmt;
    `endif

endgroup
