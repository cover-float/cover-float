// Copyright (C) 2026 Harvey Mudd College, Ryan Wolk (rwolk@hmc.edu)
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

covergroup B8_cg (virtual coverfloat_interface CFI);
    option.per_instance = 0;

    // Sign
    F32_sign: coverpoint CFI.result[F32_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F64_sign: coverpoint CFI.result[F64_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F128_sign: coverpoint CFI.result[F128_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F16_sign: coverpoint CFI.result[F16_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    BF16_sign: coverpoint CFI.result[BF16_SIGN_BIT] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    interm_sign: coverpoint CFI.intermS {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    // LSB
    F16_LSB:   coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS     ] {
        type_option.weight = 0;
    }
    F32_LSB:   coverpoint CFI.intermM[INTERM_M_BITS - F32_M_BITS     ] {
        type_option.weight = 0;
    }
    F64_LSB:   coverpoint CFI.intermM[INTERM_M_BITS - F64_M_BITS     ] {
        type_option.weight = 0;
    }
    F128_LSB:  coverpoint CFI.intermM[INTERM_M_BITS - F128_M_BITS    ] {
        type_option.weight = 0;
    }
    BF16_LSB:  coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS    ] {
        type_option.weight = 0;
    }
    I32_LSB:   coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT + 1 ] {
        type_option.weight = 0;
    }
    U32_LSB:  coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT     ] {
        type_option.weight = 0;
    }
    I64_LSB:  coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG + 1 ] {
        type_option.weight = 0;
    }
    U64_LSB: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG     ] {
        type_option.weight = 0;
    }

    // Guard
    F16_guard:   coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS - 1 ] {
        type_option.weight = 0;
    }
    F32_guard:   coverpoint CFI.intermM[INTERM_M_BITS - F32_M_BITS - 1 ] {
        type_option.weight = 0;
    }
    F64_guard:   coverpoint CFI.intermM[INTERM_M_BITS - F64_M_BITS - 1 ] {
        type_option.weight = 0;
    }
    F128_guard:  coverpoint CFI.intermM[INTERM_M_BITS - F128_M_BITS - 1] {
        type_option.weight = 0;
    }
    BF16_guard:  coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 1] {
        type_option.weight = 0;
    }
    I32_guard:  coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT     ] {
        type_option.weight = 0;
    }
    U32_guard: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 ] {
        type_option.weight = 0;
    }
    I64_guard: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG    ] {
        type_option.weight = 0;
    }
    U64_guard: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1] {
        type_option.weight = 0;
    }

    // Rounding Mode
    rounding_mode_all: coverpoint CFI.rm {
        type_option.weight = 0;
        bins round_near_even   = {ROUND_NEAR_EVEN};
        bins round_minmag      = {ROUND_MINMAG};
        bins round_min         = {ROUND_MIN};
        bins round_max         = {ROUND_MAX};
        bins round_near_maxmag = {ROUND_NEAR_MAXMAG};
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
    I32_result_fmt: coverpoint CFI.resultFmt == FMT_INT {
        type_option.weight = 0;
        bins i32 = {1};
    }
    U32_result_fmt: coverpoint CFI.resultFmt == FMT_UINT {
        type_option.weight = 0;
        bins u32 = {1};
    }
    I64_result_fmt: coverpoint CFI.resultFmt == FMT_LONG {
        type_option.weight = 0;
        bins i64 = {1};
    }
    U64_result_fmt: coverpoint CFI.resultFmt == FMT_ULONG {
        type_option.weight = 0;
        bins u64 = {1};
    }

    F16_operand_fmt: coverpoint CFI.operandFmt == FMT_HALF {
        type_option.weight = 0;
        // half precision format for operand
        bins f16 = {1};
    }
    BF16_operand_fmt: coverpoint CFI.operandFmt == FMT_BF16 {
        type_option.weight = 0;
        // bfloat16 precision format for operand
        bins bf16 = {1};
    }
    F32_operand_fmt: coverpoint CFI.operandFmt == FMT_SINGLE {
        type_option.weight = 0;
        // single precision format for operand
        bins f32 = {1};
    }
    F64_operand_fmt: coverpoint CFI.operandFmt == FMT_DOUBLE {
        type_option.weight = 0;
        // half precision format for operand
        bins f64 = {1};
    }
    F128_operand_fmt: coverpoint CFI.operandFmt == FMT_QUAD {
        type_option.weight = 0;
        // quad precision format for operand
        bins f128 = {1};
    }
    I32_operand_fmt: coverpoint CFI.operandFmt == FMT_INT {
        type_option.weight = 0;
        bins i32 = {1};
    }
    U32_operand_fmt: coverpoint CFI.operandFmt == FMT_UINT {
        type_option.weight = 0;
        bins u32 = {1};
    }
    I64_operand_fmt: coverpoint CFI.operandFmt == FMT_LONG {
        type_option.weight = 0;
        bins i64 = {1};
    }
    U64_operand_fmt: coverpoint CFI.operandFmt == FMT_ULONG {
        type_option.weight = 0;
        bins u64 = {1};
    }

    // Arithmetic Instructions
    FP_op_div: coverpoint CFI.op {
        type_option.weight = 0;
        bins div = { OP_DIV };
    }
    FP_op_mul: coverpoint CFI.op {
        type_option.weight = 0;
        bins mul = { OP_MUL };
    }
    FP_op_fma: coverpoint CFI.op {
        type_option.weight = 0;
        bins fmadd = { OP_FMADD };
        bins fmsub = { OP_FMSUB };
        bins fnmadd = { OP_FNMADD };
        bins fnmsub = { OP_FNMSUB };
    }
    FP_op_sub: coverpoint CFI.op {
        type_option.weight = 0;
        bins sub = { OP_SUB };
    }
    FP_op_add: coverpoint CFI.op {
        type_option.weight = 0;
        bins add = { OP_ADD };
    }

    // DIV: nf - 2 bits
    // MUL: nf bits
    // FMA: 2nf bits
    // ADD: nf - 1
    // SUB: nf

    F32_nf_m_2_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: F32_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(F32_M_BITS-4){1'b1}},{2'b00}}:{(F32_M_BITS-2){1'b1}}]};
    }
    F32_nf_m_1_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: F32_M_BITS - 1] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(F32_M_BITS-3){1'b1}},{2'b00}}:{(F32_M_BITS-1){1'b1}}]};
    }
    F32_nf_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: F32_M_BITS] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(F32_M_BITS-2){1'b1}},{2'b00}}:{(F32_M_BITS){1'b1}}]};
    }
    F32_2nf_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: 2*F32_M_BITS] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(2*F32_M_BITS-2){1'b1}},{2'b00}}:{(2*F32_M_BITS){1'b1}}]};
    }

    F64_nf_m_2_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 -: F64_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(F64_M_BITS-4){1'b1}},{2'b00}}:{(F64_M_BITS-2){1'b1}}]};
    }
    F64_nf_m_1_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 -: F64_M_BITS - 1] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(F64_M_BITS-3){1'b1}},{2'b00}}:{(F64_M_BITS-1){1'b1}}]};
    }
    F64_nf_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 -: F64_M_BITS] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(F64_M_BITS-2){1'b1}},{2'b00}}:{(F64_M_BITS){1'b1}}]};
    }
    F64_2nf_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 -: 2*F64_M_BITS] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(2*F64_M_BITS-2){1'b1}},{2'b00}}:{(2*F64_M_BITS){1'b1}}]};
    }

    F128_nf_m_2_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F128_M_BITS - 2 -: F128_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(F128_M_BITS-4){1'b1}},{2'b00}}:{(F128_M_BITS-2){1'b1}}]};
    }
    F128_nf_m_1_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F128_M_BITS - 2 -: F128_M_BITS - 1] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(F128_M_BITS-3){1'b1}},{2'b00}}:{(F128_M_BITS-1){1'b1}}]};
    }
    F128_nf_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F128_M_BITS - 2 -: F128_M_BITS] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(F128_M_BITS-2){1'b1}},{2'b00}}:{(F128_M_BITS){1'b1}}]};
    }
    F128_2nf_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F128_M_BITS - 2 -: 2*F128_M_BITS] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(2*F128_M_BITS-2){1'b1}},{2'b00}}:{(2*F128_M_BITS){1'b1}}]};
    }

    F16_nf_m_2_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: F16_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(F16_M_BITS-4){1'b1}},{2'b00}}:{(F16_M_BITS-2){1'b1}}]};
    }
    F16_nf_m_1_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: F16_M_BITS - 1] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(F16_M_BITS-3){1'b1}},{2'b00}}:{(F16_M_BITS-1){1'b1}}]};
    }
    F16_nf_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: F16_M_BITS] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(F16_M_BITS-2){1'b1}},{2'b00}}:{(F16_M_BITS){1'b1}}]};
    }
    F16_2nf_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: 2*F16_M_BITS] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(2*F16_M_BITS-2){1'b1}},{2'b00}}:{(2*F16_M_BITS){1'b1}}]};
    }

    BF16_nf_m_2_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: BF16_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(BF16_M_BITS-4){1'b1}},{2'b00}}:{(BF16_M_BITS-2){1'b1}}]};
    }
    BF16_nf_m_1_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: BF16_M_BITS - 1] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(BF16_M_BITS-3){1'b1}},{2'b00}}:{(BF16_M_BITS-1){1'b1}}]};
    }
    BF16_nf_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: BF16_M_BITS] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(BF16_M_BITS-2){1'b1}},{2'b00}}:{(BF16_M_BITS){1'b1}}]};
    }
    BF16_2nf_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: 2*BF16_M_BITS] {
        type_option.weight = 0;
        bins case_i[] = {[1:3]};
        bins case_ii[] = {[{{(2*BF16_M_BITS-2){1'b1}},{2'b00}}:{(2*BF16_M_BITS){1'b1}}]};
    }



    // Converts
    FP_op_cff: coverpoint (CFI.op) {
        type_option.weight = 0;
        bins cff = { OP_CFF };
    }
    FP_op_cif: coverpoint (CFI.op) {
        type_option.weight = 0;
        bins cif = { OP_CIF };
    }
    FP_op_cfi: coverpoint (CFI.op) {
        type_option.weight = 0;
        bins cfi = { OP_CFI };
    }

    // CFI: nf - 1
    I32_from_F32_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 -: F32_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F32_M_BITS - 3){1'b1}},{2'b00}}:{(F32_M_BITS - 1){1'b1}}]};
    }
    U32_from_F32_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2 -: F32_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F32_M_BITS - 3){1'b1}},{2'b00}}:{(F32_M_BITS - 1){1'b1}}]};
    }
    I64_from_F32_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 -: F32_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F32_M_BITS - 3){1'b1}},{2'b00}}:{(F32_M_BITS - 1){1'b1}}]};
    }
    U64_from_F32_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 -: F32_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F32_M_BITS - 3){1'b1}},{2'b00}}:{(F32_M_BITS - 1){1'b1}}]};
    }

    I32_from_F64_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 -: F64_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F64_M_BITS - 3){1'b1}},{2'b00}}:{(F64_M_BITS - 1){1'b1}}]};
    }
    U32_from_F64_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2 -: F64_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F64_M_BITS - 3){1'b1}},{2'b00}}:{(F64_M_BITS - 1){1'b1}}]};
    }
    I64_from_F64_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 -: F64_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F64_M_BITS - 3){1'b1}},{2'b00}}:{(F64_M_BITS - 1){1'b1}}]};
    }
    U64_from_F64_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 -: F64_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F64_M_BITS - 3){1'b1}},{2'b00}}:{(F64_M_BITS - 1){1'b1}}]};
    }

    I32_from_F128_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 -: F128_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F128_M_BITS - 3){1'b1}},{2'b00}}:{(F128_M_BITS - 1){1'b1}}]};
    }
    U32_from_F128_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2 -: F128_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F128_M_BITS - 3){1'b1}},{2'b00}}:{(F128_M_BITS - 1){1'b1}}]};
    }
    I64_from_F128_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 -: F128_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F128_M_BITS - 3){1'b1}},{2'b00}}:{(F128_M_BITS - 1){1'b1}}]};
    }
    U64_from_F128_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 -: F128_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F128_M_BITS - 3){1'b1}},{2'b00}}:{(F128_M_BITS - 1){1'b1}}]};
    }

    I32_from_F16_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 -: F16_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F16_M_BITS - 3){1'b1}},{2'b00}}:{(F16_M_BITS - 1){1'b1}}]};
    }
    U32_from_F16_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2 -: F16_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F16_M_BITS - 3){1'b1}},{2'b00}}:{(F16_M_BITS - 1){1'b1}}]};
    }
    I64_from_F16_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 -: F16_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F16_M_BITS - 3){1'b1}},{2'b00}}:{(F16_M_BITS - 1){1'b1}}]};
    }
    U64_from_F16_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 -: F16_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F16_M_BITS - 3){1'b1}},{2'b00}}:{(F16_M_BITS - 1){1'b1}}]};
    }

    I32_from_BF16_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 -: BF16_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(BF16_M_BITS - 3){1'b1}},{2'b00}}:{(BF16_M_BITS - 1){1'b1}}]};
    }
    U32_from_BF16_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2 -: BF16_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(BF16_M_BITS - 3){1'b1}},{2'b00}}:{(BF16_M_BITS - 1){1'b1}}]};
    }
    I64_from_BF16_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 -: BF16_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(BF16_M_BITS - 3){1'b1}},{2'b00}}:{(BF16_M_BITS - 1){1'b1}}]};
    }
    U64_from_BF16_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 -: BF16_M_BITS-1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(BF16_M_BITS - 3){1'b1}},{2'b00}}:{(BF16_M_BITS - 1){1'b1}}]};
    }


    // CFF: nf_1 - nf_2 - 1
    BF16_from_F16_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: F16_M_BITS - BF16_M_BITS - 1] {
        type_option.weight = 0;
        bins non_zero[] = {[1:$]};
    }
    BF16_from_F32_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: F32_M_BITS - BF16_M_BITS - 1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F32_M_BITS - BF16_M_BITS - 3){1'b1}},{2'b00}}:{(F32_M_BITS - BF16_M_BITS - 1){1'b1}}]};
    }
    BF16_from_F64_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: F64_M_BITS - BF16_M_BITS - 1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F64_M_BITS - BF16_M_BITS - 3){1'b1}},{2'b00}}:{(F64_M_BITS - BF16_M_BITS - 1){1'b1}}]};
    }
    BF16_from_F128_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: F128_M_BITS - BF16_M_BITS - 1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F128_M_BITS - BF16_M_BITS - 3){1'b1}},{2'b00}}:{(F128_M_BITS - BF16_M_BITS - 1){1'b1}}]};
    }

    F16_from_F32_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: F32_M_BITS - F16_M_BITS - 1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F32_M_BITS - F16_M_BITS - 3){1'b1}},{2'b00}}:{(F32_M_BITS - F16_M_BITS - 1){1'b1}}]};
    }
    F16_from_F64_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: F64_M_BITS - F16_M_BITS - 1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F64_M_BITS - F16_M_BITS - 3){1'b1}},{2'b00}}:{(F64_M_BITS - F16_M_BITS - 1){1'b1}}]};
    }
    F16_from_F128_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: F128_M_BITS - F16_M_BITS - 1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F128_M_BITS - F16_M_BITS - 3){1'b1}},{2'b00}}:{(F128_M_BITS - F16_M_BITS - 1){1'b1}}]};
    }

    F32_from_F64_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: F64_M_BITS - F32_M_BITS - 1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F64_M_BITS - F32_M_BITS - 3){1'b1}},{2'b00}}:{(F64_M_BITS - F32_M_BITS - 1){1'b1}}]};
    }
    F32_from_F128_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: F128_M_BITS - F32_M_BITS - 1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F128_M_BITS - F32_M_BITS - 3){1'b1}},{2'b00}}:{(F128_M_BITS - F32_M_BITS - 1){1'b1}}]};
    }

    F64_from_F128_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 -: F128_M_BITS - F64_M_BITS - 1] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(F128_M_BITS - F64_M_BITS - 3){1'b1}},{2'b00}}:{(F128_M_BITS - F64_M_BITS - 1){1'b1}}]};
    }

    // CIF: int_bits - nf - 2
    BF16_from_I32_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: SIZEOF_INT - 1 - BF16_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(SIZEOF_INT - 1 - BF16_M_BITS - 4){1'b1}},{2'b00}}:{(SIZEOF_INT - 1 - BF16_M_BITS - 2){1'b1}}]};
    }
    BF16_from_U32_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: SIZEOF_INT - BF16_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(SIZEOF_INT - BF16_M_BITS - 4){1'b1}},{2'b00}}:{(SIZEOF_INT - BF16_M_BITS - 2){1'b1}}]};
    }
    BF16_from_I64_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: SIZEOF_LONG - 1 - BF16_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(SIZEOF_LONG - 1 - BF16_M_BITS - 4){1'b1}},{2'b00}}:{(SIZEOF_LONG - 1 - BF16_M_BITS - 2){1'b1}}]};
    }
    BF16_from_U64_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - BF16_M_BITS - 2 -: SIZEOF_LONG - BF16_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(SIZEOF_LONG - BF16_M_BITS - 4){1'b1}},{2'b00}}:{(SIZEOF_LONG - BF16_M_BITS - 2){1'b1}}]};
    }

    F16_from_I32_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: SIZEOF_INT - 1 - F16_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(SIZEOF_INT - 1 - F16_M_BITS - 4){1'b1}},{2'b00}}:{(SIZEOF_INT - 1 - F16_M_BITS - 2){1'b1}}]};
    }
    F16_from_U32_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: SIZEOF_INT - F16_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(SIZEOF_INT - F16_M_BITS - 4){1'b1}},{2'b00}}:{(SIZEOF_INT - F16_M_BITS - 2){1'b1}}]};
    }
    F16_from_I64_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: SIZEOF_LONG - 1 - F16_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(SIZEOF_LONG - 1 - F16_M_BITS - 4){1'b1}},{2'b00}}:{(SIZEOF_LONG - 1 - F16_M_BITS - 2){1'b1}}]};
    }
    F16_from_U64_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F16_M_BITS - 2 -: SIZEOF_LONG - F16_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(SIZEOF_LONG - F16_M_BITS - 4){1'b1}},{2'b00}}:{(SIZEOF_LONG - F16_M_BITS - 2){1'b1}}]};
    }

    F32_from_I32_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: SIZEOF_INT - 1 - F32_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(SIZEOF_INT - 1 - F32_M_BITS - 4){1'b1}},{2'b00}}:{(SIZEOF_INT - 1 - F32_M_BITS - 2){1'b1}}]};
    }
    F32_from_U32_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: SIZEOF_INT - F32_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(SIZEOF_INT - F32_M_BITS - 4){1'b1}},{2'b00}}:{(SIZEOF_INT - F32_M_BITS - 2){1'b1}}]};
    }
    F32_from_I64_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: SIZEOF_LONG - 1 - F32_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(SIZEOF_LONG - 1 - F32_M_BITS - 4){1'b1}},{2'b00}}:{(SIZEOF_LONG - 1 - F32_M_BITS - 2){1'b1}}]};
    }
    F32_from_U64_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F32_M_BITS - 2 -: SIZEOF_LONG - F32_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(SIZEOF_LONG - F32_M_BITS - 4){1'b1}},{2'b00}}:{(SIZEOF_LONG - F32_M_BITS - 2){1'b1}}]};
    }

    F64_from_I64_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 -: SIZEOF_LONG - 1 - F64_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(SIZEOF_LONG - 1 - F64_M_BITS - 4){1'b1}},{2'b00}}:{(SIZEOF_LONG - 1 - F64_M_BITS - 2){1'b1}}]};
    }
    F64_from_U64_extra_bits: coverpoint CFI.intermM[INTERM_M_BITS - F64_M_BITS - 2 -: SIZEOF_LONG - F64_M_BITS - 2] {
        type_option.weight = 0;
        bins case_i[] = { [1:3] };
        bins case_ii[] = {[{{(SIZEOF_LONG - F64_M_BITS - 4){1'b1}},{2'b00}}:{(SIZEOF_LONG - F64_M_BITS - 2){1'b1}}]};
    }


    // Main Crosses
    `ifdef COVER_F32
        B8_F32_div_cross: cross F32_result_fmt, FP_op_div, F32_sign, F32_LSB, F32_guard, F32_nf_m_2_extra_bits, rounding_mode_all;
        B8_F32_mul_cross: cross F32_result_fmt, FP_op_mul, F32_sign, F32_LSB, F32_guard, F32_nf_extra_bits, rounding_mode_all;
        B8_F32_fma_cross: cross F32_result_fmt, FP_op_fma, F32_sign, F32_LSB, F32_guard, F32_2nf_extra_bits, rounding_mode_all;
        B8_F32_add_cross: cross F32_result_fmt, FP_op_add, F32_sign, F32_LSB, F32_guard, F32_nf_m_1_extra_bits, rounding_mode_all;
        B8_F32_sub_cross: cross F32_result_fmt, FP_op_sub, F32_sign, F32_LSB, F32_guard, F32_nf_m_1_extra_bits, rounding_mode_all;

        // CFF
        `ifdef COVER_F64
            B8_F32_from_F64_cross: cross F32_result_fmt, F64_operand_fmt, FP_op_cff, F32_sign, F32_LSB, F32_guard, F32_from_F64_extra_bits, rounding_mode_all;
        `endif
        `ifdef COVER_F128
            B8_F32_from_F128_cross: cross F32_result_fmt, F128_operand_fmt, FP_op_cff, F32_sign, F32_LSB, F32_guard, F32_from_F128_extra_bits, rounding_mode_all;
        `endif

        // CIF
        B8_F32_from_I32_cross: cross F32_result_fmt, I32_operand_fmt, FP_op_cif, F32_sign, F32_LSB, F32_guard, F32_from_I32_extra_bits, rounding_mode_all;
        B8_F32_from_U32_cross: cross F32_result_fmt, U32_operand_fmt, FP_op_cif, F32_LSB, F32_guard, F32_from_U32_extra_bits, rounding_mode_all;
        `ifdef COVER_LONG
            B8_F32_from_I64_cross: cross F32_result_fmt, I64_operand_fmt, FP_op_cif, F32_sign, F32_LSB, F32_guard, F32_from_I64_extra_bits, rounding_mode_all;
            B8_F32_from_U64_cross: cross F32_result_fmt, U64_operand_fmt, FP_op_cif, F32_LSB, F32_guard, F32_from_U64_extra_bits, rounding_mode_all;
        `endif

        // // CFI
        B8_I32_from_F32_cross: cross I32_result_fmt, F32_operand_fmt, FP_op_cfi, interm_sign, I32_LSB, I32_guard, I32_from_F32_extra_bits, rounding_mode_all;
        B8_U32_from_F32_cross: cross U32_result_fmt, F32_operand_fmt, FP_op_cfi, U32_LSB, U32_guard, U32_from_F32_extra_bits, rounding_mode_all;
        `ifdef COVER_LONG
            B8_I64_from_F32_cross: cross I64_result_fmt, F32_operand_fmt, FP_op_cfi, interm_sign, I64_LSB, I64_guard, I64_from_F32_extra_bits, rounding_mode_all;
            B8_U64_from_F32_cross: cross U64_result_fmt, F32_operand_fmt, FP_op_cfi, U64_LSB, U64_guard, U64_from_F32_extra_bits, rounding_mode_all;
        `endif
    `endif

    `ifdef COVER_F64
        B8_F64_div_cross: cross F64_result_fmt, FP_op_div, F64_sign, F64_LSB, F64_guard, F64_nf_m_2_extra_bits, rounding_mode_all;
        B8_F64_mul_cross: cross F64_result_fmt, FP_op_mul, F64_sign, F64_LSB, F64_guard, F64_nf_extra_bits, rounding_mode_all;
        B8_F64_fma_cross: cross F64_result_fmt, FP_op_fma, F64_sign, F64_LSB, F64_guard, F64_2nf_extra_bits, rounding_mode_all;
        B8_F64_add_cross: cross F64_result_fmt, FP_op_add, F64_sign, F64_LSB, F64_guard, F64_nf_m_1_extra_bits, rounding_mode_all;
        B8_F64_sub_cross: cross F64_result_fmt, FP_op_sub, F64_sign, F64_LSB, F64_guard, F64_nf_m_1_extra_bits, rounding_mode_all;

        // CFF
        `ifdef COVER_F128
            B8_F64_from_F128_cross: cross F64_result_fmt, F128_operand_fmt, FP_op_cff, F64_sign, F64_LSB, F64_guard, F64_from_F128_extra_bits, rounding_mode_all;
        `endif

        // CIF
        `ifdef COVER_LONG
            B8_F64_from_I64_cross: cross F64_result_fmt, I64_operand_fmt, FP_op_cif, F64_sign, F64_LSB, F64_guard, F64_from_I64_extra_bits, rounding_mode_all;
            B8_F64_from_U64_cross: cross F64_result_fmt, U64_operand_fmt, FP_op_cif, F64_LSB, F64_guard, F64_from_U64_extra_bits, rounding_mode_all;
        `endif

        // CFI
        B8_I32_from_F64_cross: cross I32_result_fmt, F64_operand_fmt, FP_op_cfi, interm_sign, I32_LSB, I32_guard, I32_from_F64_extra_bits, rounding_mode_all;
        B8_U32_from_F64_cross: cross U32_result_fmt, F64_operand_fmt, FP_op_cfi, U32_LSB, U32_guard, U32_from_F64_extra_bits, rounding_mode_all;
        `ifdef COVER_LONG
            B8_I64_from_F64_cross: cross I64_result_fmt, F64_operand_fmt, FP_op_cfi, interm_sign, I64_LSB, I64_guard, I64_from_F64_extra_bits, rounding_mode_all;
            B8_U64_from_F64_cross: cross U64_result_fmt, F64_operand_fmt, FP_op_cfi, U64_LSB, U64_guard, U64_from_F64_extra_bits, rounding_mode_all;
        `endif
    `endif

    `ifdef COVER_F128
        B8_F128_div_cross: cross F128_result_fmt, FP_op_div, F128_sign, F128_LSB, F128_guard, F128_nf_m_2_extra_bits, rounding_mode_all;
        B8_F128_mul_cross: cross F128_result_fmt, FP_op_mul, F128_sign, F128_LSB, F128_guard, F128_nf_extra_bits, rounding_mode_all;
        B8_F128_fma_cross: cross F128_result_fmt, FP_op_fma, F128_sign, F128_LSB, F128_guard, F128_2nf_extra_bits, rounding_mode_all;
        B8_F128_add_cross: cross F128_result_fmt, FP_op_add, F128_sign, F128_LSB, F128_guard, F128_nf_m_1_extra_bits, rounding_mode_all;
        B8_F128_sub_cross: cross F128_result_fmt, FP_op_sub, F128_sign, F128_LSB, F128_guard, F128_nf_m_1_extra_bits, rounding_mode_all;

        // CFI
        B8_I32_from_F128_cross: cross I32_result_fmt, F128_operand_fmt, FP_op_cfi, interm_sign, I32_LSB, I32_guard, I32_from_F128_extra_bits, rounding_mode_all;
        B8_U32_from_F128_cross: cross U32_result_fmt, F128_operand_fmt, FP_op_cfi, U32_LSB, U32_guard, U32_from_F128_extra_bits, rounding_mode_all;
        `ifdef COVER_LONG
            B8_I64_from_F128_cross: cross I64_result_fmt, F128_operand_fmt, FP_op_cfi, interm_sign, I64_LSB, I64_guard, I64_from_F128_extra_bits, rounding_mode_all;
            B8_U64_from_F128_cross: cross U64_result_fmt, F128_operand_fmt, FP_op_cfi, U64_LSB, U64_guard, U64_from_F128_extra_bits, rounding_mode_all;
        `endif
    `endif

    `ifdef COVER_F16
        B8_F16_div_cross: cross F16_result_fmt, FP_op_div, F16_sign, F16_LSB, F16_guard, F16_nf_m_2_extra_bits, rounding_mode_all;
        B8_F16_mul_cross: cross F16_result_fmt, FP_op_mul, F16_sign, F16_LSB, F16_guard, F16_nf_extra_bits, rounding_mode_all;
        B8_F16_fma_cross: cross F16_result_fmt, FP_op_fma, F16_sign, F16_LSB, F16_guard, F16_2nf_extra_bits, rounding_mode_all;
        B8_F16_add_cross: cross F16_result_fmt, FP_op_add, F16_sign, F16_LSB, F16_guard, F16_nf_m_1_extra_bits, rounding_mode_all;
        B8_F16_sub_cross: cross F16_result_fmt, FP_op_sub, F16_sign, F16_LSB, F16_guard, F16_nf_m_1_extra_bits, rounding_mode_all;

        // CFF
        `ifdef COVER_F32
            B8_F16_from_F32_cross: cross F16_result_fmt, F32_operand_fmt, FP_op_cff, F16_sign, F16_LSB, F16_guard, F16_from_F32_extra_bits, rounding_mode_all;
        `endif
        `ifdef COVER_F64
            B8_F16_from_F64_cross: cross F16_result_fmt, F64_operand_fmt, FP_op_cff, F16_sign, F16_LSB, F16_guard, F16_from_F64_extra_bits, rounding_mode_all;
        `endif
        `ifdef COVER_F128
            B8_F16_from_F128_cross: cross F16_result_fmt, F128_operand_fmt, FP_op_cff, F16_sign, F16_LSB, F16_guard, F16_from_F128_extra_bits, rounding_mode_all;
        `endif

        // CIF
        B8_F16_from_I32_cross: cross F16_result_fmt, I32_operand_fmt, FP_op_cif, F16_sign, F16_LSB, F16_guard, F16_from_I32_extra_bits, rounding_mode_all;
        B8_F16_from_U32_cross: cross F16_result_fmt, U32_operand_fmt, FP_op_cif, F16_LSB, F16_guard, F16_from_U32_extra_bits, rounding_mode_all;
        `ifdef COVER_LONG
            B8_F16_from_I64_cross: cross F16_result_fmt, I64_operand_fmt, FP_op_cif, F16_sign, F16_LSB, F16_guard, F16_from_I64_extra_bits, rounding_mode_all;
            B8_F16_from_U64_cross: cross F16_result_fmt, U64_operand_fmt, FP_op_cif, F16_LSB, F16_guard, F16_from_U64_extra_bits, rounding_mode_all;
        `endif

        // CFI
        B8_I32_from_F16_cross: cross I32_result_fmt, F16_operand_fmt, FP_op_cfi, interm_sign, I32_LSB, I32_guard, I32_from_F16_extra_bits, rounding_mode_all;
        B8_U32_from_F16_cross: cross U32_result_fmt, F16_operand_fmt, FP_op_cfi, U32_LSB, U32_guard, U32_from_F16_extra_bits, rounding_mode_all;
        `ifdef COVER_LONG
            B8_I64_from_F16_cross: cross I64_result_fmt, F16_operand_fmt, FP_op_cfi, interm_sign, I64_LSB, I64_guard, I64_from_F16_extra_bits, rounding_mode_all;
            B8_U64_from_F16_cross: cross U64_result_fmt, F16_operand_fmt, FP_op_cfi, U64_LSB, U64_guard, U64_from_F16_extra_bits, rounding_mode_all;
        `endif
    `endif

    `ifdef COVER_BF16
        B8_BF16_div_cross: cross BF16_result_fmt, FP_op_div, BF16_sign, BF16_LSB, BF16_guard, BF16_nf_m_2_extra_bits, rounding_mode_all;
        B8_BF16_mul_cross: cross BF16_result_fmt, FP_op_mul, BF16_sign, BF16_LSB, BF16_guard, BF16_nf_extra_bits, rounding_mode_all;
        B8_BF16_fma_cross: cross BF16_result_fmt, FP_op_fma, BF16_sign, BF16_LSB, BF16_guard, BF16_2nf_extra_bits, rounding_mode_all;
        B8_BF16_add_cross: cross BF16_result_fmt, FP_op_add, BF16_sign, BF16_LSB, BF16_guard, BF16_nf_m_1_extra_bits, rounding_mode_all;
        B8_BF16_sub_cross: cross BF16_result_fmt, FP_op_sub, BF16_sign, BF16_LSB, BF16_guard, BF16_nf_m_1_extra_bits, rounding_mode_all;

        // CFF
        `ifdef COVER_F16
            B8_BF16_from_F16_cross: cross BF16_result_fmt, F16_operand_fmt, FP_op_cff, BF16_sign, BF16_LSB, BF16_guard, BF16_from_F16_extra_bits, rounding_mode_all;
        `endif
        `ifdef COVER_F32
            B8_BF16_from_F32_cross: cross BF16_result_fmt, F32_operand_fmt, FP_op_cff, BF16_sign, BF16_LSB, BF16_guard, BF16_from_F32_extra_bits, rounding_mode_all;
        `endif
        `ifdef COVER_F64
            B8_BF16_from_F64_cross: cross BF16_result_fmt, F64_operand_fmt, FP_op_cff, BF16_sign, BF16_LSB, BF16_guard, BF16_from_F64_extra_bits, rounding_mode_all;
        `endif


        // As of now, these cannot collect coverage due to softfloat limitations
        // `ifdef COVER_F128
        //     B8_BF16_from_F128_cross: cross BF16_result_fmt, F128_operand_fmt, FP_op_cff, BF16_sign, BF16_LSB, BF16_guard, BF16_from_F128_extra_bits, rounding_mode_all;
        // `endif

        // // CIF
        // B8_BF16_from_I32_cross: cross BF16_result_fmt, I32_operand_fmt, FP_op_cif, BF16_sign, BF16_LSB, BF16_guard, BF16_from_I32_extra_bits, rounding_mode_all;
        // B8_BF16_from_U32_cross: cross BF16_result_fmt, U32_operand_fmt, FP_op_cif, BF16_LSB, BF16_guard, BF16_from_U32_extra_bits, rounding_mode_all;
        // `ifdef COVER_LONG
        //     B8_BF16_from_I64_cross: cross BF16_result_fmt, I64_operand_fmt, FP_op_cif, BF16_sign, BF16_LSB, BF16_guard, BF16_from_I64_extra_bits, rounding_mode_all;
        //     B8_BF16_from_U64_cross: cross BF16_result_fmt, U64_operand_fmt, FP_op_cif, BF16_LSB, BF16_guard, BF16_from_U64_extra_bits, rounding_mode_all;
        // `endif

        // // CFI
        // B8_I32_from_BF16_cross: cross I32_result_fmt, BF16_operand_fmt, FP_op_cfi, interm_sign, I32_LSB, I32_guard, I32_from_BF16_extra_bits, rounding_mode_all;
        // B8_U32_from_BF16_cross: cross U32_result_fmt, BF16_operand_fmt, FP_op_cfi, U32_LSB, U32_guard, U32_from_BF16_extra_bits, rounding_mode_all;
        // `ifdef COVER_LONG
        //     B8_I64_from_BF16_cross: cross I64_result_fmt, BF16_operand_fmt, FP_op_cfi, interm_sign, I64_LSB, I64_guard, I64_from_BF16_extra_bits, rounding_mode_all;
        //     B8_U64_from_BF16_cross: cross U64_result_fmt, BF16_operand_fmt, FP_op_cfi, U64_LSB, U64_guard, U64_from_BF16_extra_bits, rounding_mode_all;
        // `endif
    `endif
endgroup
