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

covergroup B7_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;


    // The sign should be positive
    F32_sign: coverpoint CFI.result[F32_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
    }

    F64_sign: coverpoint CFI.result[F64_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
    }

    F128_sign: coverpoint CFI.result[F128_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
    }

    F16_sign: coverpoint CFI.result[F16_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
    }

    BF16_sign: coverpoint CFI.result[BF16_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
    }

    // Sign for int results
    interm_sign: coverpoint CFI.intermS {
        type_option.weight = 0;
        bins pos = {0};
    }


    // The guard should always be zero
    F16_guard:  coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS - 1] {
        type_option.weight = 0;
        bins zero = {0};
    }
    F32_guard:  coverpoint CFI.intermM[INTERM_M_BITS - F32_M_BITS - 1] {
        type_option.weight = 0;
        bins zero = {0};
    }
    F64_guard:  coverpoint CFI.intermM[INTERM_M_BITS - F64_M_BITS - 1] {
        type_option.weight = 0;
        bins zero = {0};
    }
    F128_guard: coverpoint CFI.intermM[INTERM_M_BITS - F128_M_BITS - 1] {
        type_option.weight = 0;
        bins zero = {0};
    }
    BF16_guard: coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 1] {
        type_option.weight = 0;
        bins zero = {0};
    }
    int_guard:  coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT     ] {
        type_option.weight = 0;
        bins zero = {0};
    }
    uint_guard: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 ] {
        type_option.weight = 0;
        bins zero = {0};
    }
    long_guard: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG    ] {
        type_option.weight = 0;
        bins zero = {0};
    }
    ulong_guard: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1] {
        type_option.weight = 0;
        bins zero = {0};
    }


    // Each operation can reach a different number of sticky bits
    F16_sticky_effective_addition:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F16_M_BITS-2]};
        type_option.weight = 0;
    }
    F16_sticky_effective_subtraction:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F16_M_BITS-1]};
        type_option.weight = 0;
    }
    F16_sticky_multiplication:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F16_M_BITS-1]};
        type_option.weight = 0;
    }
    F16_sticky_fma:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:2*F16_M_BITS-2]}; // 2nf is impossible for half precision
        type_option.weight = 0;
    }

    F32_sticky_effective_addition:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F32_M_BITS-2]};
        type_option.weight = 0;
    }
    F32_sticky_effective_subtraction:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F32_M_BITS-1]};
        type_option.weight = 0;
    }
    F32_sticky_multiplication:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F32_M_BITS-1]};
        type_option.weight = 0;
    }
    F32_sticky_fma:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:2*F32_M_BITS-1]};
        type_option.weight = 0;
    }

    F64_sticky_effective_addition:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F64_M_BITS-2]};
        type_option.weight = 0;
    }
    F64_sticky_effective_subtraction:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F64_M_BITS-1]};
        type_option.weight = 0;
    }
    F64_sticky_multiplication:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F64_M_BITS-1]};
        type_option.weight = 0;
    }
    F64_sticky_fma:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:2*F64_M_BITS-1]};
        type_option.weight = 0;
    }

    F128_sticky_effective_addition:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F128_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F128_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F128_M_BITS-2]};
        type_option.weight = 0;
    }
    F128_sticky_effective_subtraction:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F128_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F128_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F128_M_BITS-1]};
        type_option.weight = 0;
    }
    F128_sticky_multiplication:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F128_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F128_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F128_M_BITS-1]};
        type_option.weight = 0;
    }
    F128_sticky_fma:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F128_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F128_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:2*F128_M_BITS-1]};
        type_option.weight = 0;
    }

    BF16_sticky_effective_addition:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:BF16_M_BITS-2]};
        type_option.weight = 0;
    }
    BF16_sticky_effective_subtraction:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:BF16_M_BITS-1]};
        type_option.weight = 0;
    }
    BF16_sticky_multiplication:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:BF16_M_BITS-1]};
        type_option.weight = 0;
    }
    BF16_sticky_fma:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:2*BF16_M_BITS-1]};
        type_option.weight = 0;
    }



    // For converts the number of accessible sticky bits depends on what the conversion came from
    // CFF
    BF16_sticky_from_F16:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:1]};
        type_option.weight = 0;
    }
    BF16_sticky_from_F32:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:14]};
        type_option.weight = 0;
    }
    BF16_sticky_from_F64:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:43]};
        type_option.weight = 0;
    }
    BF16_sticky_from_F128:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:103]};
        type_option.weight = 0;

        // Because of the bf16 functions that we have access to from softfloat, the conversions have this restriction
        // Limited because of an intermediate conversion to F32
        ignore_bins softfloat_bf16_truncation = {[15:$]};
    }
    F16_sticky_from_F32:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: 256], 256)) iff ($onehot(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:11]};
        type_option.weight = 0;
    }
    F16_sticky_from_F64:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:40]};
        type_option.weight = 0;
    }
    F16_sticky_from_F128:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:100]};
        type_option.weight = 0;
    }
    F32_sticky_from_F64:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:27]};
        type_option.weight = 0;
    }
    F32_sticky_from_F128:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:87]};
        type_option.weight = 0;
    }
    F64_sticky_from_F128:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 -: 256], 256)) iff ($onehot(CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:58]};
        type_option.weight = 0;
    }

    // CIF
    BF16_sticky_from_I32:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:21]};
        type_option.weight = 0;

        // Because of the bf16 functions that we have access to from softfloat, the conversions have this restriction
        // Limited because of an intermediate conversion to F32
        ignore_bins softfloat_bf16_truncation = {[15:$]};
    }
    BF16_sticky_from_U32:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:22]};
        type_option.weight = 0;

        // Because of the bf16 functions that we have access to from softfloat, the conversions have this restriction
        // Limited because of an intermediate conversion to F32
        ignore_bins softfloat_bf16_truncation = {[15:$]};
    }
    BF16_sticky_from_I64:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:53]};
        type_option.weight = 0;

        // Because of the bf16 functions that we have access to from softfloat, the conversions have this restriction
        // Limited because of an intermediate conversion to F64
        ignore_bins softfloat_bf16_truncation = {[44:$]};
    }
    BF16_sticky_from_U64:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:54]};
        type_option.weight = 0;

        // Because of the bf16 functions that we have access to from softfloat, the conversions have this restriction
        // Limited because of an intermediate conversion to F64
        ignore_bins softfloat_bf16_truncation = {[44:$]};
    }
    F16_sticky_from_I32:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:18]};
        type_option.weight = 0;
    }
    F16_sticky_from_U32:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:19]};
        type_option.weight = 0;
    }
    F16_sticky_from_I64:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:50]};
        type_option.weight = 0;
    }
    F16_sticky_from_U64:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:51]};
        type_option.weight = 0;
    }
    F32_sticky_from_I32:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:5]};
        type_option.weight = 0;
    }
    F32_sticky_from_U32:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:6]};
        type_option.weight = 0;
    }
    F32_sticky_from_I64:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:37]};
        type_option.weight = 0;
    }
    F32_sticky_from_U64:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:38]};
        type_option.weight = 0;
    }
    F64_sticky_from_I64:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:8]};
        type_option.weight = 0;
    }
    F64_sticky_from_U64:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 : 0]))
    {
        bins sticky_bit[] = {[0:9]};
        type_option.weight = 0;
    }

    // CFI
    I32_sticky_from_BF16:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 : 0]))
    {
        bins sticky_bit[] = {[0:BF16_M_BITS-2]};
        type_option.weight = 0;
    }
    I32_sticky_from_F16:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 : 0]))
    {
        bins sticky_bit[] = {[0:F16_M_BITS-2]};
        type_option.weight = 0;
    }
    I32_sticky_from_F32:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 : 0]))
    {
        bins sticky_bit[] = {[0:F32_M_BITS-2]};
        type_option.weight = 0;
    }
    I32_sticky_from_F64:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 : 0]))
    {
        bins sticky_bit[] = {[0:F64_M_BITS-2]};
        type_option.weight = 0;
    }
    I32_sticky_from_F128:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 : 0]))
    {
        bins sticky_bit[] = {[0:F128_M_BITS-2]};
        type_option.weight = 0;
    }

    U32_sticky_from_BF16:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2 : 0]))
    {
        bins sticky_bit[] = {[0:BF16_M_BITS-2]};
        type_option.weight = 0;
    }
    U32_sticky_from_F16:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F16_M_BITS-2]};
        type_option.weight = 0;
    }
    U32_sticky_from_F32:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F32_M_BITS-2]};
        type_option.weight = 0;
    }
    U32_sticky_from_F64:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F64_M_BITS-2]};
        type_option.weight = 0;
    }
    U32_sticky_from_F128:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F128_M_BITS-2]};
        type_option.weight = 0;
    }

    I64_sticky_from_BF16:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 : 0]))
    {
        bins sticky_bit[] = {[0:BF16_M_BITS-2]};
        type_option.weight = 0;
    }
    I64_sticky_from_F16:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 : 0]))
    {
        bins sticky_bit[] = {[0:F16_M_BITS-2]};
        type_option.weight = 0;
    }
    I64_sticky_from_F32:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 : 0]))
    {
        bins sticky_bit[] = {[0:F32_M_BITS-2]};
        type_option.weight = 0;
    }
    I64_sticky_from_F64:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 : 0]))
    {
        bins sticky_bit[] = {[0:F64_M_BITS-2]};
        type_option.weight = 0;
    }
    I64_sticky_from_F128:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 : 0]))
    {
        bins sticky_bit[] = {[0:F128_M_BITS-2]};
        type_option.weight = 0;
    }

    U64_sticky_from_BF16:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 : 0]))
    {
        bins sticky_bit[] = {[0:BF16_M_BITS-2]};
        type_option.weight = 0;
    }
    U64_sticky_from_F16:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F16_M_BITS-2]};
        type_option.weight = 0;
    }
    U64_sticky_from_F32:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F32_M_BITS-2]};
        type_option.weight = 0;
    }
    U64_sticky_from_F64:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F64_M_BITS-2]};
        type_option.weight = 0;
    }
    U64_sticky_from_F128:  coverpoint (count_leading_zeros(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 -: 256], 256))
        iff ($onehot(CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 : 0]))
    {
        bins sticky_bit[] = {[0:F128_M_BITS-2]};
        type_option.weight = 0;
    }

    // The rounding mode should be to +inf
    rounding_pos_inf: coverpoint CFI.rm {
        type_option.weight = 0;
        bins round_near_maxmag = {ROUND_MAX};
    }


    FP_op_add: coverpoint CFI.op {
        type_option.weight = 0;
        bins add = {OP_ADD};
    }
    FP_op_sub: coverpoint CFI.op {
        type_option.weight = 0;
        bins sub = {OP_SUB};
    }
    FP_op_mul: coverpoint CFI.op {
        type_option.weight = 0;
        bins mul = {OP_MUL};
    }
    FP_op_fma: coverpoint CFI.op {
        type_option.weight = 0;
        bins fmadd = {OP_FMADD};
        bins fmsub = {OP_FMSUB};
        bins fnmadd = {OP_FNMADD};
        bins fnmsub = {OP_FNMSUB};
    }
    FP_op_cfi: coverpoint CFI.op {
        type_option.weight = 0;
        bins cfi = {OP_CFI};
    }
    FP_op_cif: coverpoint CFI.op {
        type_option.weight = 0;
        bins cif = {OP_CIF};
    }
    FP_op_cff: coverpoint CFI.op {
        type_option.weight = 0;
        bins cff = {OP_CFF};
    }

    // Formats
    F16_result_fmt: coverpoint CFI.resultFmt == FMT_HALF {
        type_option.weight = 0;
        // half precision format for result
        bins f16 = {1};
    }

    BF16_result_fmt: coverpoint CFI.resultFmt == FMT_BF16 {
        type_option.weight = 0;
        // bfloat16 precision format for result
        bins bf16 = {1};
    }

    F32_result_fmt: coverpoint CFI.resultFmt == FMT_SINGLE {
        type_option.weight = 0;
        // single precision format for result
        bins f32 = {1};
    }

    F64_result_fmt: coverpoint CFI.resultFmt == FMT_DOUBLE {
        type_option.weight = 0;
        // half precision format for result
        bins f64 = {1};
    }

    F128_result_fmt: coverpoint CFI.resultFmt == FMT_QUAD {
        type_option.weight = 0;
        // quad precision format for result
        bins f128 = {1};
    }

    int_result_fmt : coverpoint CFI.resultFmt == FMT_INT {
        type_option.weight = 0;
        // int format for result
        bins fmt_int = {1};
    }
    uint_result_fmt : coverpoint CFI.resultFmt == FMT_UINT {
        type_option.weight = 0;
        // uint format for result
        bins fmt_uint = {1};
    }
    long_result_fmt : coverpoint CFI.resultFmt == FMT_LONG {
        type_option.weight = 0;
        // long format for result
        bins fmt_long = {1};
    }
    ulong_result_fmt : coverpoint CFI.resultFmt == FMT_ULONG {
        type_option.weight = 0;
        // ulong format for result
        bins fmt_ulong = {1};
    }

    // Source Formats
    F16_source_fmt: coverpoint CFI.operandFmt == FMT_HALF {
        type_option.weight = 0;
        // half precision format for source
        bins f16 = {1};
    }

    BF16_source_fmt: coverpoint CFI.operandFmt == FMT_BF16 {
        type_option.weight = 0;
        // bfloat16 precision format for source
        bins bf16 = {1};
    }

    F32_source_fmt: coverpoint CFI.operandFmt == FMT_SINGLE {
        type_option.weight = 0;
        // single precision format for source
        bins f32 = {1};
    }

    F64_source_fmt: coverpoint CFI.operandFmt == FMT_DOUBLE {
        type_option.weight = 0;
        // half precision format for source
        bins f64 = {1};
    }

    F128_source_fmt: coverpoint CFI.operandFmt == FMT_QUAD {
        type_option.weight = 0;
        // quad precision format for source
        bins f128 = {1};
    }

    int_source_fmt : coverpoint CFI.operandFmt == FMT_INT {
        type_option.weight = 0;
        // int format for source
        bins fmt_int = {1};
    }
    uint_source_fmt : coverpoint CFI.operandFmt == FMT_UINT {
        type_option.weight = 0;
        // uint format for source
        bins fmt_uint = {1};
    }
    long_source_fmt : coverpoint CFI.operandFmt == FMT_LONG {
        type_option.weight = 0;
        // long format for source
        bins fmt_long = {1};
    }
    ulong_source_fmt : coverpoint CFI.operandFmt == FMT_ULONG {
        type_option.weight = 0;
        // ulong format for source
        bins fmt_ulong = {1};
    }

    // Main Coverpoints
    `ifdef COVER_F32
        B7_F32_add_cross: cross FP_op_add, F32_source_fmt, F32_sign, F32_guard, F32_sticky_effective_addition, rounding_pos_inf;
        B7_F32_sub_cross: cross FP_op_sub, F32_source_fmt, F32_sign, F32_guard, F32_sticky_effective_subtraction, rounding_pos_inf;
        B7_F32_mul_cross: cross FP_op_mul, F32_source_fmt, F32_sign, F32_guard, F32_sticky_multiplication, rounding_pos_inf;
        B7_F32_fma_cross: cross FP_op_fma, F32_source_fmt, F32_sign, F32_guard, F32_sticky_fma, rounding_pos_inf;

        `ifdef COVER_F64
            B7_F32_from_F64_cross: cross FP_op_cff, F64_source_fmt, F32_result_fmt, F32_guard, F32_sign, F32_sticky_from_F64, rounding_pos_inf;
        `endif
        `ifdef COVER_F128
            B7_F32_from_F128_cross: cross FP_op_cff, F128_source_fmt, F32_result_fmt, F32_guard, F32_sign, F32_sticky_from_F128, rounding_pos_inf;
        `endif

        B7_F32_from_I32_cross: cross FP_op_cif, int_source_fmt, F32_result_fmt, F32_guard, F32_sign, F32_sticky_from_I32, rounding_pos_inf;
        B7_F32_from_U32_cross: cross FP_op_cif, uint_source_fmt, F32_result_fmt, F32_guard, F32_sign, F32_sticky_from_U32, rounding_pos_inf;
        `ifdef COVER_LONG
            B7_F32_from_I64_cross: cross FP_op_cif, long_source_fmt, F32_result_fmt, F32_guard, F32_sign, F32_sticky_from_I64, rounding_pos_inf;
        `endif
        `ifdef COVER_ULONG
            B7_F32_from_U64_cross: cross FP_op_cif, ulong_source_fmt, F32_result_fmt, F32_guard, F32_sign, F32_sticky_from_U64, rounding_pos_inf;
        `endif

        B7_I32_from_F32_cross: cross FP_op_cfi, F32_source_fmt, int_result_fmt, int_guard, interm_sign, I32_sticky_from_F32, rounding_pos_inf;
        B7_U32_from_F32_cross: cross FP_op_cfi, F32_source_fmt, uint_result_fmt, uint_guard, interm_sign, U32_sticky_from_F32, rounding_pos_inf;
        `ifdef COVER_LONG
            B7_I64_from_F32_cross: cross FP_op_cfi, F32_source_fmt, long_result_fmt, long_guard, interm_sign, I64_sticky_from_F32, rounding_pos_inf;
        `endif
        `ifdef COVER_ULONG
            B7_U64_from_F32_cross: cross FP_op_cfi, F32_source_fmt, ulong_result_fmt, ulong_guard, interm_sign, U64_sticky_from_F32, rounding_pos_inf;
        `endif
    `endif

    `ifdef COVER_F64
        B7_F64_add_cross: cross FP_op_add, F64_source_fmt, F64_sign, F64_guard, F64_sticky_effective_addition, rounding_pos_inf;
        B7_F64_sub_cross: cross FP_op_sub, F64_source_fmt, F64_sign, F64_guard, F64_sticky_effective_subtraction, rounding_pos_inf;
        B7_F64_mul_cross: cross FP_op_mul, F64_source_fmt, F64_sign, F64_guard, F64_sticky_multiplication, rounding_pos_inf;
        B7_F64_fma_cross: cross FP_op_fma, F64_source_fmt, F64_sign, F64_guard, F64_sticky_fma, rounding_pos_inf;

        `ifdef COVER_F128
            B7_F64_from_F128_cross: cross FP_op_cff, F128_source_fmt, F64_result_fmt, F64_guard, F64_sign, F64_sticky_from_F128, rounding_pos_inf;
        `endif

        `ifdef COVER_LONG
            B7_F64_from_I64_cross: cross FP_op_cif, long_source_fmt, F64_result_fmt, F64_guard, F64_sign, F64_sticky_from_I64, rounding_pos_inf;
        `endif
        `ifdef COVER_ULONG
            B7_F64_from_U64_cross: cross FP_op_cif, ulong_source_fmt, F64_result_fmt, F64_guard, F64_sign, F64_sticky_from_U64, rounding_pos_inf;
        `endif

        B7_I32_from_F64_cross: cross FP_op_cfi, F64_source_fmt, int_result_fmt, int_guard, interm_sign, I32_sticky_from_F64, rounding_pos_inf;
        B7_U32_from_F64_cross: cross FP_op_cfi, F64_source_fmt, uint_result_fmt, uint_guard, interm_sign, U32_sticky_from_F64, rounding_pos_inf;
        `ifdef COVER_LONG
            B7_I64_from_F64_cross: cross FP_op_cfi, F64_source_fmt, long_result_fmt, long_guard, interm_sign, I64_sticky_from_F64, rounding_pos_inf;
        `endif
        `ifdef COVER_ULONG
            B7_U64_from_F64_cross: cross FP_op_cfi, F64_source_fmt, ulong_result_fmt, ulong_guard, interm_sign, U64_sticky_from_F64, rounding_pos_inf;
        `endif
    `endif

    `ifdef COVER_F128
        B7_F128_add_cross: cross FP_op_add, F128_source_fmt, F128_sign, F128_guard, F128_sticky_effective_addition, rounding_pos_inf;
        B7_F128_sub_cross: cross FP_op_sub, F128_source_fmt, F128_sign, F128_guard, F128_sticky_effective_subtraction, rounding_pos_inf;
        B7_F128_mul_cross: cross FP_op_mul, F128_source_fmt, F128_sign, F128_guard, F128_sticky_multiplication, rounding_pos_inf;
        B7_F128_fma_cross: cross FP_op_fma, F128_source_fmt, F128_sign, F128_guard, F128_sticky_fma, rounding_pos_inf;

        B7_I32_from_F128_cross: cross FP_op_cfi, F128_source_fmt, int_result_fmt, int_guard, interm_sign, I32_sticky_from_F128, rounding_pos_inf;
        B7_U32_from_F128_cross: cross FP_op_cfi, F128_source_fmt, uint_result_fmt, uint_guard, interm_sign, U32_sticky_from_F128, rounding_pos_inf;
        `ifdef COVER_LONG
            B7_I64_from_F128_cross: cross FP_op_cfi, F128_source_fmt, long_result_fmt, long_guard, interm_sign, I64_sticky_from_F128, rounding_pos_inf;
        `endif
        `ifdef COVER_ULONG
            B7_U64_from_F128_cross: cross FP_op_cfi, F128_source_fmt, ulong_result_fmt, ulong_guard, interm_sign, U64_sticky_from_F128, rounding_pos_inf;
        `endif
    `endif


    `ifdef COVER_F16
        B7_F16_add_cross: cross FP_op_add, F16_source_fmt, F16_sign, F16_guard, F16_sticky_effective_addition, rounding_pos_inf;
        B7_F16_sub_cross: cross FP_op_sub, F16_source_fmt, F16_sign, F16_guard, F16_sticky_effective_subtraction, rounding_pos_inf;
        B7_F16_mul_cross: cross FP_op_mul, F16_source_fmt, F16_sign, F16_guard, F16_sticky_multiplication, rounding_pos_inf;
        B7_F16_fma_cross: cross FP_op_fma, F16_source_fmt, F16_sign, F16_guard, F16_sticky_fma, rounding_pos_inf;

        `ifdef COVER_F32
            B7_F16_from_F32_cross: cross FP_op_cff, F32_source_fmt, F16_result_fmt, F16_guard, F16_sign, F16_sticky_from_F32, rounding_pos_inf;
        `endif
        `ifdef COVER_F64
            B7_F16_from_F64_cross: cross FP_op_cff, F64_source_fmt, F16_result_fmt, F16_guard, F16_sign, F16_sticky_from_F64, rounding_pos_inf;
        `endif
        `ifdef COVER_F128
            B7_F16_from_F128_cross: cross FP_op_cff, F128_source_fmt, F16_result_fmt, F16_guard, F16_sign, F16_sticky_from_F128, rounding_pos_inf;
        `endif

        B7_F16_from_I32_cross: cross FP_op_cif, int_source_fmt, F16_result_fmt, F16_guard, F16_sign, F16_sticky_from_I32, rounding_pos_inf;
        B7_F16_from_U32_cross: cross FP_op_cif, uint_source_fmt, F16_result_fmt, F16_guard, F16_sign, F16_sticky_from_U32, rounding_pos_inf;
        `ifdef COVER_LONG
            B7_F16_from_I64_cross: cross FP_op_cif, long_source_fmt, F16_result_fmt, F16_guard, F16_sign, F16_sticky_from_I64, rounding_pos_inf;
        `endif
        `ifdef COVER_ULONG
            B7_F16_from_U64_cross: cross FP_op_cif, ulong_source_fmt, F16_result_fmt, F16_guard, F16_sign, F16_sticky_from_U64, rounding_pos_inf;
        `endif

        B7_I32_from_F16_cross: cross FP_op_cfi, F16_source_fmt, int_result_fmt, int_guard, interm_sign, I32_sticky_from_F16, rounding_pos_inf;
        B7_U32_from_F16_cross: cross FP_op_cfi, F16_source_fmt, uint_result_fmt, uint_guard, interm_sign, U32_sticky_from_F16, rounding_pos_inf;
        `ifdef COVER_LONG
            B7_I64_from_F16_cross: cross FP_op_cfi, F16_source_fmt, long_result_fmt, long_guard, interm_sign, I64_sticky_from_F16, rounding_pos_inf;
        `endif
        `ifdef COVER_ULONG
            B7_U64_from_F16_cross: cross FP_op_cfi, F16_source_fmt, ulong_result_fmt, ulong_guard, interm_sign, U64_sticky_from_F16, rounding_pos_inf;
        `endif
    `endif

    `ifdef COVER_BF16
        B7_BF16_add_cross: cross FP_op_add, BF16_source_fmt, BF16_sign, BF16_guard, BF16_sticky_effective_addition, rounding_pos_inf;
        B7_BF16_sub_cross: cross FP_op_sub, BF16_source_fmt, BF16_sign, BF16_guard, BF16_sticky_effective_subtraction, rounding_pos_inf;
        B7_BF16_mul_cross: cross FP_op_mul, BF16_source_fmt, BF16_sign, BF16_guard, BF16_sticky_multiplication, rounding_pos_inf;
        B7_BF16_fma_cross: cross FP_op_fma, BF16_source_fmt, BF16_sign, BF16_guard, BF16_sticky_fma, rounding_pos_inf;

        `ifdef COVER_F16
            B7_BF16_from_F16_cross: cross FP_op_cff, F16_source_fmt, BF16_result_fmt, BF16_guard, BF16_sign, BF16_sticky_from_F16, rounding_pos_inf;
        `endif
        `ifdef COVER_F32
            B7_BF16_from_F32_cross: cross FP_op_cff, F32_source_fmt, BF16_result_fmt, BF16_guard, BF16_sign, BF16_sticky_from_F32, rounding_pos_inf;
        `endif
        `ifdef COVER_F64
            B7_BF16_from_F64_cross: cross FP_op_cff, F64_source_fmt, BF16_result_fmt, BF16_guard, BF16_sign, BF16_sticky_from_F64, rounding_pos_inf;
        `endif
        `ifdef COVER_F128
            B7_BF16_from_F128_cross: cross FP_op_cff, F128_source_fmt, BF16_result_fmt, BF16_guard, BF16_sign, BF16_sticky_from_F128, rounding_pos_inf;
        `endif

        B7_BF16_from_I32_cross: cross FP_op_cif, int_source_fmt, BF16_result_fmt, BF16_guard, BF16_sign, BF16_sticky_from_I32, rounding_pos_inf;
        B7_BF16_from_U32_cross: cross FP_op_cif, uint_source_fmt, BF16_result_fmt, BF16_guard, BF16_sign, BF16_sticky_from_U32, rounding_pos_inf;
        `ifdef COVER_LONG
            B7_BF16_from_I64_cross: cross FP_op_cif, long_source_fmt, BF16_result_fmt, BF16_guard, BF16_sign, BF16_sticky_from_I64, rounding_pos_inf;
        `endif
        `ifdef COVER_ULONG
            B7_BF16_from_U64_cross: cross FP_op_cif, ulong_source_fmt, BF16_result_fmt, BF16_guard, BF16_sign, BF16_sticky_from_U64, rounding_pos_inf;
        `endif

        B7_I32_from_BF16_cross: cross FP_op_cfi, BF16_source_fmt, int_result_fmt, int_guard, interm_sign, I32_sticky_from_BF16, rounding_pos_inf;
        B7_U32_from_BF16_cross: cross FP_op_cfi, BF16_source_fmt, uint_result_fmt, uint_guard, interm_sign, U32_sticky_from_BF16, rounding_pos_inf;
        `ifdef COVER_LONG
            B7_I64_from_BF16_cross: cross FP_op_cfi, BF16_source_fmt, long_result_fmt, long_guard, interm_sign, I64_sticky_from_BF16, rounding_pos_inf;
        `endif
        `ifdef COVER_ULONG
            B7_U64_from_BF16_cross: cross FP_op_cfi, BF16_source_fmt, ulong_result_fmt, ulong_guard, interm_sign, U64_sticky_from_BF16, rounding_pos_inf;
        `endif
    `endif


endgroup
