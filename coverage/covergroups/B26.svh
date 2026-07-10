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


covergroup B26_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;

    // CIF Operation Helper Coverpoint
    CIF_op: coverpoint CFI.op {
        type_option.weight = 0;
        bins cif = {OP_CIF};
    }

    // ---- Significant-bit count of the integer input ----
    // significant_bits = width - count_leading_zeros(|value|, width)
    // Signed: negate when the sign bit is set so we count the MAGNITUDE's bits.
    // Each bin = one Aharoni range ([2,3]=2 sig bits, [4,7]=3, ...), so one bin per count.

    // 32-bit SIGNED  (range 0..31; |MinInt| = 32 bits is excluded by the model)
    int32_sigbits: coverpoint (SIZEOF_INT - count_leading_zeros(
            CFI.a[SIZEOF_INT-1] ? (~CFI.a[SIZEOF_INT-1:0] + 1'b1) : CFI.a[SIZEOF_INT-1:0],
            SIZEOF_INT))
        iff (CFI.operandFmt == FMT_INT) {
            type_option.weight = 0;
            bins sb[] = {[0 : SIZEOF_INT - 1]};
        }

    // 32-bit UNSIGNED (range 0..32)
    uint32_sigbits: coverpoint (SIZEOF_INT - count_leading_zeros(CFI.a[SIZEOF_INT-1:0], SIZEOF_INT))
        iff (CFI.operandFmt == FMT_UINT) {
            type_option.weight = 0;
            bins sb[] = {[0 : SIZEOF_INT]};
        }

    // 64-bit SIGNED  (range 0..63)
    int64_sigbits: coverpoint (SIZEOF_LONG - count_leading_zeros(
            CFI.a[SIZEOF_LONG-1] ? (~CFI.a[SIZEOF_LONG-1:0] + 1'b1) : CFI.a[SIZEOF_LONG-1:0],
            SIZEOF_LONG))
        iff (CFI.operandFmt == FMT_LONG) {
            type_option.weight = 0;
            bins sb[] = {[0 : SIZEOF_LONG - 1]};
        }

    // 64-bit UNSIGNED (range 0..64)
    uint64_sigbits: coverpoint (SIZEOF_LONG - count_leading_zeros(CFI.a[SIZEOF_LONG-1:0], SIZEOF_LONG))
        iff (CFI.operandFmt == FMT_ULONG) {
            type_option.weight = 0;
            bins sb[] = {[0 : SIZEOF_LONG]};
        }

   // Result Format Coverpoints
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

        `ifdef COVER_F16
        B26_INT32_F16:  cross CIF_op, int32_sigbits,  F16_result_fmt;
        B26_UINT32_F16: cross CIF_op, uint32_sigbits, F16_result_fmt;
        `ifdef COVER_LONG
            B26_INT64_F16:  cross CIF_op, int64_sigbits,  F16_result_fmt;
            B26_UINT64_F16: cross CIF_op, uint64_sigbits, F16_result_fmt;
        `endif
    `endif

    `ifdef COVER_BF16
        B26_INT32_BF16:  cross CIF_op, int32_sigbits,  BF16_result_fmt;
        B26_UINT32_BF16: cross CIF_op, uint32_sigbits, BF16_result_fmt;
        `ifdef COVER_LONG
            B26_INT64_BF16:  cross CIF_op, int64_sigbits,  BF16_result_fmt;
            B26_UINT64_BF16: cross CIF_op, uint64_sigbits, BF16_result_fmt;
        `endif
    `endif

    `ifdef COVER_F32
        B26_INT32_F32:  cross CIF_op, int32_sigbits,  F32_result_fmt;
        B26_UINT32_F32: cross CIF_op, uint32_sigbits, F32_result_fmt;
        `ifdef COVER_LONG
            B26_INT64_F32:  cross CIF_op, int64_sigbits,  F32_result_fmt;
            B26_UINT64_F32: cross CIF_op, uint64_sigbits, F32_result_fmt;
        `endif
    `endif

    `ifdef COVER_F64
        B26_INT32_F64:  cross CIF_op, int32_sigbits,  F64_result_fmt;
        B26_UINT32_F64: cross CIF_op, uint32_sigbits, F64_result_fmt;
        `ifdef COVER_LONG
            B26_INT64_F64:  cross CIF_op, int64_sigbits,  F64_result_fmt;
            B26_UINT64_F64: cross CIF_op, uint64_sigbits, F64_result_fmt;
        `endif
    `endif

    `ifdef COVER_F128
        B26_INT32_F128:  cross CIF_op, int32_sigbits,  F128_result_fmt;
        B26_UINT32_F128: cross CIF_op, uint32_sigbits, F128_result_fmt;
        `ifdef COVER_LONG
            B26_INT64_F128:  cross CIF_op, int64_sigbits,  F128_result_fmt;
            B26_UINT64_F128: cross CIF_op, uint64_sigbits, F128_result_fmt;
        `endif
    `endif


endgroup
