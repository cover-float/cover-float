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

covergroup B5_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;

    /************************************************************************
    General Helper Coverpoints
    ************************************************************************/

    FP_result_ops: coverpoint CFI.op {
        type_option.weight = 0;
        bins add    = {OP_ADD};
        bins sub    = {OP_SUB};
        bins mul    = {OP_MUL};
        bins div    = {OP_DIV};
        bins fmadd  = {OP_FMADD};
        bins fmsub  = {OP_FMSUB};
        bins fnmadd = {OP_FNMADD};
        bins fnmsub = {OP_FNMSUB};
}

    rounding_mode_all: coverpoint CFI.rm {
        type_option.weight = 0;
        bins round_near_even   = {ROUND_NEAR_EVEN};
        bins round_minmag      = {ROUND_MINMAG};
        bins round_min         = {ROUND_MIN};
        bins round_max         = {ROUND_MAX};
        bins round_near_maxmag = {ROUND_NEAR_MAXMAG};
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

    FP_convert_ops: coverpoint CFI.op {
        type_option.weight = 0;
        // checks that a convert is happening (F2X, X2F, or F2F)
        // operand and result formats infer which type

        bins convert = {OP_CFI, OP_CFF, OP_CIF};
        // bins op_cfi
        // bins op_cff
        // bins op_cif
    }

    FP_convert_fmt: coverpoint CFI.operandFmt {
        type_option.weight = 0;
        // all formats to convert to

        `ifdef COVER_F16
            bins fmt_half   = {FMT_HALF};
        `endif // COVER_F16

        `ifdef COVER_F32
            bins fmt_single = {FMT_SINGLE};
        `endif // COVER_F32

        `ifdef COVER_F64
            bins fmt_double = {FMT_DOUBLE};
        `endif // COVER_F64

        `ifdef COVER_F128
            bins fmt_quad   = {FMT_QUAD};
        `endif // COVER_F128

        `ifdef COVER_BF16
            bins fmt_bf16   = {FMT_BF16};
        `endif // COVER_BF16
    }

    /************************************************************************
    Underflow Boundary Helper Coverpoints
    ************************************************************************/

    // cases i & ii
    FP_subnorm: coverpoint (CFI.intermX == 0 && CFI.intermM != 0) {
        type_option.weight = 0;

        bins subnorm = {1};
    }

    // cases iii & iv

    //                                          Guard bit                                       sticky bit
    int_minSubNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - SIZEOF_INT)], |CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 : INTERM_M_BITS - SIZEOF_INT +1] == 1) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    uint_minSubNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - SIZEOF_INT - 1)], |CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2  : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 : INTERM_M_BITS - SIZEOF_INT] == 1) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    long_minSubNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - SIZEOF_LONG)], |CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 : INTERM_M_BITS - SIZEOF_LONG +1] == 1) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    ulong_minSubNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - SIZEOF_LONG - 1)], |CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 : INTERM_M_BITS - SIZEOF_LONG] == 1) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    int_minSubNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - SIZEOF_INT)], |CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 : INTERM_M_BITS - SIZEOF_INT +1] == 0) {
            type_option.weight = 0;

            bins minNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    uint_minSubNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - SIZEOF_INT - 1)], |CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2  : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 : INTERM_M_BITS - SIZEOF_INT] == 0) {
            type_option.weight = 0;

            bins minNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    long_minSubNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - SIZEOF_LONG)], |CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 : INTERM_M_BITS - SIZEOF_LONG +1] == 0) {
            type_option.weight = 0;

            bins minNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    ulong_minSubNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - SIZEOF_LONG - 1)], |CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 : INTERM_M_BITS - SIZEOF_LONG] == 0) {
            type_option.weight = 0;

            bins minNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    F32_minSubNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - F32_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - F32_M_BITS - 2) : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 -: F32_M_BITS +1] == 1) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    F32_minSubNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - F32_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - F32_M_BITS - 2) : 0]}
    //   implicit leading 0 (subnorm)           all zeros fraction (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 -: F32_M_BITS +1] == 0) {
            type_option.weight = 0;

            bins minSubNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    F64_minSubNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - F64_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - F64_M_BITS - 2) : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 -: F64_M_BITS +1] == 1) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    F64_minSubNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - F64_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - F64_M_BITS - 2) : 0]}
    //   implicit leading 0 (subnorm)           all zeros fraction (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 -: F64_M_BITS +1] == 0) {
            type_option.weight = 0;

            bins minSubNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    F128_minSubNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - F128_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - F128_M_BITS - 2) : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 -: F128_M_BITS +1] == 1) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    F128_minSubNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - F128_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - F128_M_BITS - 2) : 0]}
    //   implicit leading 0 (subnorm)           all zeros fraction (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 -: F128_M_BITS +1] == 0) {
            type_option.weight = 0;

            bins minSubNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    F16_minSubNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - F16_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - F16_M_BITS - 2) : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 -: F16_M_BITS +1] == 1) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    F16_minSubNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - F16_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - F16_M_BITS - 2) : 0]}
    //   implicit leading 0 (subnorm)           all zeros fraction (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 -: F16_M_BITS +1] == 0) {
            type_option.weight = 0;

            bins minSubNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    BF16_minSubNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - BF16_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - BF16_M_BITS - 2) : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 -: BF16_M_BITS +1] == 1) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    BF16_minSubNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - BF16_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - BF16_M_BITS - 2) : 0]}
    //   implicit leading 0 (subnorm)           all zeros fraction (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 -: BF16_M_BITS +1] == 0) {
            type_option.weight = 0;

            bins minSubNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    // cases v & vi

    //                                          Guard bit                                       sticky bit
    int_minNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - SIZEOF_INT)], |CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX != 0 && CFI.intermM[INTERM_M_BITS -1 : INTERM_M_BITS - SIZEOF_INT +1] == 0) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    uint_minNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - SIZEOF_INT - 1)], |CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2  : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX != 0 && CFI.intermM[INTERM_M_BITS -1 : INTERM_M_BITS - SIZEOF_INT] == 0) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    long_minNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - SIZEOF_LONG)], |CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX != 0 && CFI.intermM[INTERM_M_BITS -1 : INTERM_M_BITS - SIZEOF_LONG +1] == 0) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    ulong_minNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - SIZEOF_LONG - 1)], |CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX != 0 && CFI.intermM[INTERM_M_BITS -1 : INTERM_M_BITS - SIZEOF_LONG] == 0) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    int_minNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - SIZEOF_INT)], |CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 1 : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 : INTERM_M_BITS - SIZEOF_INT +1] == '1) {
            type_option.weight = 0;

            bins minNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    uint_minNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - SIZEOF_INT - 1)], |CFI.intermM[INTERM_M_BITS - SIZEOF_INT - 2  : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 : INTERM_M_BITS - SIZEOF_INT] == '1) {
            type_option.weight = 0;

            bins minNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    long_minNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - SIZEOF_LONG)], |CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 1 : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 : INTERM_M_BITS - SIZEOF_LONG +1] == '1) {
            type_option.weight = 0;

            bins minNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    ulong_minNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - SIZEOF_LONG - 1)], |CFI.intermM[INTERM_M_BITS - SIZEOF_LONG - 2 : 0]}
    //   implicit leading 0 (subnorm)           single 1 in LSB (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 : INTERM_M_BITS - SIZEOF_LONG] == '1) {
            type_option.weight = 0;

            bins minNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    F32_minNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - F32_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - F32_M_BITS - 2) : 0]}
    //   implicit leading 1 (norm)           all zero fraction (except for Guard and sticky)
        iff (CFI.intermX != 0 && CFI.intermM[INTERM_M_BITS -1 -: F32_M_BITS] == 0) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    F32_minNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - F32_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - F32_M_BITS - 2) : 0]}
    //   implicit leading 0 (subnorm)           all ones fraction (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 -: F32_M_BITS] == '1) {
            type_option.weight = 0;

            bins minNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    F64_minNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - F64_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - F64_M_BITS - 2) : 0]}
    //   implicit leading 1 (norm)           all zero fraction (except for Guard and sticky)
        iff (CFI.intermX != 0 && CFI.intermM[INTERM_M_BITS -1 -: F64_M_BITS] == 0) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    F64_minNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - F64_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - F64_M_BITS - 2) : 0]}
    //   implicit leading 0 (subnorm)           all ones fraction (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 -: F64_M_BITS] == '1) {
            type_option.weight = 0;

            bins minNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    F128_minNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - F128_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - F128_M_BITS - 2) : 0]}
    //   implicit leading 1 (norm)           all zero fraction (except for Guard and sticky)
        iff (CFI.intermX != 0 && CFI.intermM[INTERM_M_BITS -1 -: F128_M_BITS] == 0) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    F128_minNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - F128_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - F128_M_BITS - 2) : 0]}
    //   implicit leading 0 (subnorm)           all ones fraction (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 -: F128_M_BITS] == '1) {
            type_option.weight = 0;

            bins minNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    F16_minNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - F16_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - F16_M_BITS - 2) : 0]}
    //   implicit leading 1 (norm)           all zero fraction (except for Guard and sticky)
        iff (CFI.intermX != 0 && CFI.intermM[INTERM_M_BITS -1 -: F16_M_BITS] == 0) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    F16_minNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - F16_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - F16_M_BITS - 2) : 0]}
    //   implicit leading 0 (subnorm)           all ones fraction (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 -: F16_M_BITS] == '1) {
            type_option.weight = 0;

            bins minNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    BF16_minNorm_p_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - BF16_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - BF16_M_BITS - 2) : 0]}
    //   implicit leading 1 (norm)           all zero fraction (except for Guard and sticky)
        iff (CFI.intermX != 0 && CFI.intermM[INTERM_M_BITS -1 -: BF16_M_BITS] == 0) {
            type_option.weight = 0;

            bins minNorm_p_3ulp[] = {[2'b00 : 2'b11]};
    }

    //                                          Guard bit                                       sticky bit
    BF16_minNorm_m_3ulp: coverpoint {CFI.intermM[(INTERM_M_BITS - BF16_M_BITS - 1)], |CFI.intermM[(INTERM_M_BITS - BF16_M_BITS - 2) : 0]}
    //   implicit leading 0 (subnorm)           all ones fraction (except for Guard and sticky)
        iff (CFI.intermX == 0 && CFI.intermM[INTERM_M_BITS -1 -: BF16_M_BITS] == '1) {
            type_option.weight = 0;

            bins minNorm_m_3ulp[] = {[2'b01 : 2'b11]};
    }


    // cases vii & viii

    int_btw_minSubNorm_zero: coverpoint CFI.intermM iff (CFI.intermX == 0) {
        type_option.weight = 0;

        // shift 1 into the ULP position, subtract one to be in the exclusive range (0 , minSubNorm)
        bins btw_minSubNorm_zero = {[1 : ((INTERM_M_BITS'(1) << (INTERM_M_BITS - SIZEOF_INT - 1)) - 1)]};
    }

    uint_btw_minSubNorm_zero: coverpoint CFI.intermM iff (CFI.intermX == 0) {
        type_option.weight = 0;

        // shift 1 into the ULP position, subtract one to be in the exclusive range (0 , minSubNorm)
        bins btw_minSubNorm_zero = {[1 : ((INTERM_M_BITS'(1) << (INTERM_M_BITS - SIZEOF_INT - 2)) - 1)]};
    }

    long_btw_minSubNorm_zero: coverpoint CFI.intermM iff (CFI.intermX == 0) {
        type_option.weight = 0;

        // shift 1 into the ULP position, subtract one to be in the exclusive range (0 , minSubNorm)
        bins btw_minSubNorm_zero = {[1 : ((INTERM_M_BITS'(1) << (INTERM_M_BITS - SIZEOF_LONG - 1)) - 1)]};
    }

    ulong_btw_minSubNorm_zero: coverpoint CFI.intermM iff (CFI.intermX == 0) {
        type_option.weight = 0;

        // shift 1 into the ULP position, subtract one to be in the exclusive range (0 , minSubNorm)
        bins btw_minSubNorm_zero = {[1 : ((INTERM_M_BITS'(1) << (INTERM_M_BITS - SIZEOF_LONG - 2)) - 1)]};
    }

    F32_btw_minSubNorm_zero: coverpoint CFI.intermM iff (CFI.intermX == 0) {
        type_option.weight = 0;

        // shift 1 into the ULP position, subtract one to be in the exclusive range (0 , minSubNorm)
        bins btw_minSubNorm_zero = {[1 : ((INTERM_M_BITS'(1) << (INTERM_M_BITS - F32_M_BITS - 2)) - 1)]};
    }

    F64_btw_minSubNorm_zero: coverpoint CFI.intermM iff (CFI.intermX == 0) {
        type_option.weight = 0;

        // shift 1 into the ULP position, subtract one to be in the exclusive range (0 , minSubNorm)
        bins btw_minSubNorm_zero = {[1 : ((INTERM_M_BITS'(1) << (INTERM_M_BITS - F64_M_BITS - 2)) - 1)]};
    }

    F128_btw_minSubNorm_zero: coverpoint CFI.intermM iff (CFI.intermX == 0) {
        type_option.weight = 0;

        // shift 1 into the ULP position, subtract one to be in the exclusive range (0 , minSubNorm)
        bins btw_minSubNorm_zero = {[1 : ((INTERM_M_BITS'(1) << (INTERM_M_BITS - F128_M_BITS - 2)) - 1)]};
    }

    F16_btw_minSubNorm_zero: coverpoint CFI.intermM iff (CFI.intermX == 0) {
        type_option.weight = 0;

        // shift 1 into the ULP position, subtract one to be in the exclusive range (0 , minSubNorm)
        bins btw_minSubNorm_zero = {[1 : ((INTERM_M_BITS'(1) << (INTERM_M_BITS - F16_M_BITS - 2)) - 1)]};
    }

    BF16_btw_minSubNorm_zero: coverpoint CFI.intermM iff (CFI.intermX == 0) {
        type_option.weight = 0;

        // shift 1 into the ULP position, subtract one to be in the exclusive range (0 , minSubNorm)
        bins btw_minSubNorm_zero = {[1 : ((INTERM_M_BITS'(1) << (INTERM_M_BITS - BF16_M_BITS - 2)) - 1)]};
    }

    // case ix
    FP_minNorm_p5_exp_range: coverpoint CFI.intermX {
        type_option.weight = 0;

        // minnorm.exp is 1 (unbiased) regardless of precision, so this covers the range [minnorm.exp , minnorm.exp + 5]
        bins exp_range[] = {[1:6]};
    }

    /************************************************************************
    Main Coverpoints
    ************************************************************************/

// TODO: need to add helper coverpoints for int formats, and fmt coverpoints for available conversion destination formats

    B5_int_convert_subnorm:  cross FP_convert_ops, rounding_mode_all, FP_subnorm, FP_convert_fmt,  int_result_fmt {
        bins narrow_f64_to_int  = binsof(FP_convert_fmt.fmt_double);
        bins narrow_f128_to_int = binsof(FP_convert_fmt.fmt_quad);
    }
    B5_uint_convert_subnorm: cross FP_convert_ops, rounding_mode_all, FP_subnorm, FP_convert_fmt, uint_result_fmt {
        bins narrow_f64_to_uint  = binsof(FP_convert_fmt.fmt_double);
        bins narrow_f128_to_uint = binsof(FP_convert_fmt.fmt_quad);
    }

    B5_int_convert_minSubNorm_p_3ulp:  cross FP_convert_ops, rounding_mode_all, int_minSubNorm_p_3ulp, FP_convert_fmt,  int_result_fmt {
        bins narrow_f64_to_int  = binsof(FP_convert_fmt.fmt_double);
        bins narrow_f128_to_int = binsof(FP_convert_fmt.fmt_quad);
    }
    B5_uint_convert_minSubNorm_p_3ulp: cross FP_convert_ops, rounding_mode_all, uint_minSubNorm_p_3ulp, FP_convert_fmt, uint_result_fmt {
        bins narrow_f64_to_uint  = binsof(FP_convert_fmt.fmt_double);
        bins narrow_f128_to_uint = binsof(FP_convert_fmt.fmt_quad);
    }

    B5_int_convert_minSubNorm_m_3ulp:  cross FP_convert_ops, rounding_mode_all, int_minSubNorm_m_3ulp, FP_convert_fmt,  int_result_fmt {
        bins narrow_f64_to_int  = binsof(FP_convert_fmt.fmt_double);
        bins narrow_f128_to_int = binsof(FP_convert_fmt.fmt_quad);
    }
    B5_uint_convert_minSubNorm_m_3ulp: cross FP_convert_ops, rounding_mode_all, uint_minSubNorm_m_3ulp, FP_convert_fmt, uint_result_fmt {
        bins narrow_f64_to_uint  = binsof(FP_convert_fmt.fmt_double);
        bins narrow_f128_to_uint = binsof(FP_convert_fmt.fmt_quad);
    }

    B5_int_convert_minNorm_p_3ulp:  cross FP_convert_ops, rounding_mode_all, int_minNorm_p_3ulp, FP_convert_fmt,  int_result_fmt {
        bins narrow_f64_to_int  = binsof(FP_convert_fmt.fmt_double);
        bins narrow_f128_to_int = binsof(FP_convert_fmt.fmt_quad);
    }
    B5_uint_convert_minNorm_p_3ulp: cross FP_convert_ops, rounding_mode_all, uint_minNorm_p_3ulp, FP_convert_fmt, uint_result_fmt {
        bins narrow_f64_to_uint  = binsof(FP_convert_fmt.fmt_double);
        bins narrow_f128_to_uint = binsof(FP_convert_fmt.fmt_quad);
    }

    B5_int_convert_minNorm_m_3ulp:  cross FP_convert_ops, rounding_mode_all, int_minNorm_m_3ulp, FP_convert_fmt,  int_result_fmt {
        bins narrow_f64_to_int  = binsof(FP_convert_fmt.fmt_double);
        bins narrow_f128_to_int = binsof(FP_convert_fmt.fmt_quad);
    }
    B5_uint_convert_minNorm_m_3ulp: cross FP_convert_ops, rounding_mode_all, uint_minNorm_m_3ulp, FP_convert_fmt, uint_result_fmt {
        bins narrow_f64_to_uint  = binsof(FP_convert_fmt.fmt_double);
        bins narrow_f128_to_uint = binsof(FP_convert_fmt.fmt_quad);
    }

    B5_int_convert_btw_minSubNorm_zero:  cross FP_convert_ops, rounding_mode_all, int_btw_minSubNorm_zero, FP_convert_fmt,  int_result_fmt {
        bins narrow_f64_to_int  = binsof(FP_convert_fmt.fmt_double);
        bins narrow_f128_to_int = binsof(FP_convert_fmt.fmt_quad);
    }
    B5_uint_convert_btw_minSubNorm_zero: cross FP_convert_ops, rounding_mode_all, uint_btw_minSubNorm_zero, FP_convert_fmt, uint_result_fmt {
        bins narrow_f64_to_uint  = binsof(FP_convert_fmt.fmt_double);
        bins narrow_f128_to_uint = binsof(FP_convert_fmt.fmt_quad);
    }

    B5_int_convert_minNorm_p5_exp_range:  cross FP_convert_ops, rounding_mode_all, FP_minNorm_p5_exp_range, FP_convert_fmt,  int_result_fmt {
        bins narrow_f64_to_int  = binsof(FP_convert_fmt.fmt_double);
        bins narrow_f128_to_int = binsof(FP_convert_fmt.fmt_quad);
    }
    B5_uint_convert_minNorm_p5_exp_range: cross FP_convert_ops, rounding_mode_all, FP_minNorm_p5_exp_range, FP_convert_fmt, uint_result_fmt {
        bins narrow_f64_to_uint  = binsof(FP_convert_fmt.fmt_double);
        bins narrow_f128_to_uint = binsof(FP_convert_fmt.fmt_quad);
    }

    `ifdef COVER_LONG

        B5_long_convert_subnorm:  cross FP_convert_ops, rounding_mode_all, FP_subnorm, FP_convert_fmt,  long_result_fmt {
            bins narrow_f64_to_long  = binsof(FP_convert_fmt.fmt_double);
            bins narrow_f128_to_long = binsof(FP_convert_fmt.fmt_quad);
        }
        B5_ulong_convert_subnorm: cross FP_convert_ops, rounding_mode_all, FP_subnorm, FP_convert_fmt, ulong_result_fmt {
            bins narrow_f64_to_ulong  = binsof(FP_convert_fmt.fmt_double);
            bins narrow_f128_to_ulong = binsof(FP_convert_fmt.fmt_quad);
        }

        B5_long_convert_minSubNorm_p_3ulp:  cross FP_convert_ops, rounding_mode_all, long_minSubNorm_p_3ulp, FP_convert_fmt,  long_result_fmt {
            bins narrow_f64_to_long  = binsof(FP_convert_fmt.fmt_double);
            bins narrow_f128_to_long = binsof(FP_convert_fmt.fmt_quad);
        }
        B5_ulong_convert_minSubNorm_p_3ulp: cross FP_convert_ops, rounding_mode_all, ulong_minSubNorm_p_3ulp, FP_convert_fmt, ulong_result_fmt {
            bins narrow_f64_to_ulong  = binsof(FP_convert_fmt.fmt_double);
            bins narrow_f128_to_ulong = binsof(FP_convert_fmt.fmt_quad);
        }

        B5_long_convert_minSubNorm_m_3ulp:  cross FP_convert_ops, rounding_mode_all, long_minSubNorm_m_3ulp, FP_convert_fmt,  long_result_fmt {
            bins narrow_f64_to_long  = binsof(FP_convert_fmt.fmt_double);
            bins narrow_f128_to_long = binsof(FP_convert_fmt.fmt_quad);
        }
        B5_ulong_convert_minSubNorm_m_3ulp: cross FP_convert_ops, rounding_mode_all, ulong_minSubNorm_m_3ulp, FP_convert_fmt, ulong_result_fmt {
            bins narrow_f64_to_ulong  = binsof(FP_convert_fmt.fmt_double);
            bins narrow_f128_to_ulong = binsof(FP_convert_fmt.fmt_quad);
        }

        B5_long_convert_minNorm_p_3ulp:  cross FP_convert_ops, rounding_mode_all, long_minNorm_p_3ulp, FP_convert_fmt,  long_result_fmt {
            bins narrow_f64_to_long  = binsof(FP_convert_fmt.fmt_double);
            bins narrow_f128_to_long = binsof(FP_convert_fmt.fmt_quad);
        }
        B5_ulong_convert_minNorm_p_3ulp: cross FP_convert_ops, rounding_mode_all, ulong_minNorm_p_3ulp, FP_convert_fmt, ulong_result_fmt {
            bins narrow_f64_to_ulong  = binsof(FP_convert_fmt.fmt_double);
            bins narrow_f128_to_ulong = binsof(FP_convert_fmt.fmt_quad);
        }

        B5_long_convert_minNorm_m_3ulp:  cross FP_convert_ops, rounding_mode_all, long_minNorm_m_3ulp, FP_convert_fmt,  long_result_fmt {
            bins narrow_f64_to_long  = binsof(FP_convert_fmt.fmt_double);
            bins narrow_f128_to_long = binsof(FP_convert_fmt.fmt_quad);
        }
        B5_ulong_convert_minNorm_m_3ulp: cross FP_convert_ops, rounding_mode_all, ulong_minNorm_m_3ulp, FP_convert_fmt, ulong_result_fmt {
            bins narrow_f64_to_ulong  = binsof(FP_convert_fmt.fmt_double);
            bins narrow_f128_to_ulong = binsof(FP_convert_fmt.fmt_quad);
        }

        B5_long_convert_btw_minSubNorm_zero:  cross FP_convert_ops, rounding_mode_all, long_btw_minSubNorm_zero, FP_convert_fmt,  long_result_fmt {
            bins narrow_f64_to_long  = binsof(FP_convert_fmt.fmt_double);
            bins narrow_f128_to_long = binsof(FP_convert_fmt.fmt_quad);
        }
        B5_ulong_convert_btw_minSubNorm_zero: cross FP_convert_ops, rounding_mode_all, ulong_btw_minSubNorm_zero, FP_convert_fmt, ulong_result_fmt {
            bins narrow_f64_to_ulong  = binsof(FP_convert_fmt.fmt_double);
            bins narrow_f128_to_ulong = binsof(FP_convert_fmt.fmt_quad);
        }

        B5_long_convert_minNorm_p5_exp_range:  cross FP_convert_ops, rounding_mode_all, FP_minNorm_p5_exp_range, FP_convert_fmt,  long_result_fmt {
            bins narrow_f64_to_long  = binsof(FP_convert_fmt.fmt_double);
            bins narrow_f128_to_long = binsof(FP_convert_fmt.fmt_quad);
        }
        B5_ulong_convert_minNorm_p5_exp_range: cross FP_convert_ops, rounding_mode_all, FP_minNorm_p5_exp_range, FP_convert_fmt, ulong_result_fmt {
            bins narrow_f64_to_ulong  = binsof(FP_convert_fmt.fmt_double);
            bins narrow_f128_to_ulong = binsof(FP_convert_fmt.fmt_quad);
        }
    `endif // COVER_LONG

    `ifdef COVER_F32
        B5_F32_subnorm:              cross FP_result_ops, rounding_mode_all, FP_subnorm,              F32_result_fmt;
        B5_F32_minSubNorm_p_3ulp:    cross FP_result_ops, rounding_mode_all, F32_minSubNorm_p_3ulp,   F32_result_fmt;
        B5_F32_minSubNorm_m_3ulp:    cross FP_result_ops, rounding_mode_all, F32_minSubNorm_m_3ulp,   F32_result_fmt {
            ignore_bins impossible_addsub = binsof(FP_result_ops.add) && binsof(FP_result_ops.add);
        }
        B5_F32_minNorm_p_3ulp:       cross FP_result_ops, rounding_mode_all, F32_minNorm_p_3ulp,      F32_result_fmt;
        B5_F32_minNorm_m_3ulp:       cross FP_result_ops, rounding_mode_all, F32_minNorm_m_3ulp,      F32_result_fmt;
        B5_F32_btw_minSubNorm_zero:  cross FP_result_ops, rounding_mode_all, F32_btw_minSubNorm_zero, F32_result_fmt;
        B5_F32_minNorm_p5_exp_range: cross FP_result_ops, rounding_mode_all, FP_minNorm_p5_exp_range, F32_result_fmt;


        B5_F32_convert_subnorm:  cross FP_convert_ops, rounding_mode_all, FP_subnorm, FP_convert_fmt,  F32_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_single);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f32 = binsof(FP_convert_fmt.fmt_single);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f32 = binsof(FP_convert_fmt.fmt_single);
            `endif // COVER_BF16

        }

        B5_F32_convert_minSubNorm_p_3ulp:  cross FP_convert_ops, rounding_mode_all, F32_minSubNorm_p_3ulp, FP_convert_fmt,  F32_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_single);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f32 = binsof(FP_convert_fmt.fmt_single);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f32 = binsof(FP_convert_fmt.fmt_single);
            `endif // COVER_BF16

        }

        B5_F32_convert_minSubNorm_m_3ulp:  cross FP_convert_ops, rounding_mode_all, F32_minSubNorm_m_3ulp, FP_convert_fmt,  F32_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_single);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f32 = binsof(FP_convert_fmt.fmt_single);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f32 = binsof(FP_convert_fmt.fmt_single);
            `endif // COVER_BF16

        }

        B5_F32_convert_minNorm_p_3ulp:  cross FP_convert_ops, rounding_mode_all, F32_minNorm_p_3ulp, FP_convert_fmt,  F32_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_single);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f32 = binsof(FP_convert_fmt.fmt_single);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f32 = binsof(FP_convert_fmt.fmt_single);
            `endif // COVER_BF16

        }

        B5_F32_convert_minNorm_m_3ulp:  cross FP_convert_ops, rounding_mode_all, F32_minNorm_m_3ulp, FP_convert_fmt,  F32_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_single);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f32 = binsof(FP_convert_fmt.fmt_single);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f32 = binsof(FP_convert_fmt.fmt_single);
            `endif // COVER_BF16

        }

        B5_F32_convert_btw_minSubNorm_zero:  cross FP_result_ops, rounding_mode_all, F32_btw_minSubNorm_zero, FP_convert_fmt, F32_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_single);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f32 = binsof(FP_convert_fmt.fmt_single);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f32 = binsof(FP_convert_fmt.fmt_single);
            `endif // COVER_BF16

        }

        B5_F32_convert_minNorm_p5_exp_range:  cross FP_convert_ops, rounding_mode_all, FP_minNorm_p5_exp_range, FP_convert_fmt,  F32_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_single);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f32 = binsof(FP_convert_fmt.fmt_single);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f32 = binsof(FP_convert_fmt.fmt_single);
            `endif // COVER_BF16

        }

    `endif

    `ifdef COVER_F64
        B5_F64_subnorm:              cross FP_result_ops, rounding_mode_all, FP_subnorm,              F64_result_fmt;
        B5_F64_minSubNorm_p_3ulp:    cross FP_result_ops, rounding_mode_all, F64_minSubNorm_p_3ulp,   F64_result_fmt;
        B5_F64_minSubNorm_m_3ulp:    cross FP_result_ops, rounding_mode_all, F64_minSubNorm_m_3ulp,   F64_result_fmt {
            ignore_bins impossible_addsub = binsof(FP_result_ops.add) && binsof(FP_result_ops.add);
        }
        B5_F64_minNorm_p_3ulp:       cross FP_result_ops, rounding_mode_all, F64_minNorm_p_3ulp,      F64_result_fmt;
        B5_F64_minNorm_m_3ulp:       cross FP_result_ops, rounding_mode_all, F64_minNorm_m_3ulp,      F64_result_fmt;
        B5_F64_btw_minSubNorm_zero:  cross FP_result_ops, rounding_mode_all, F64_btw_minSubNorm_zero, F64_result_fmt;
        B5_F64_minNorm_p5_exp_range: cross FP_result_ops, rounding_mode_all, FP_minNorm_p5_exp_range, F64_result_fmt;


        B5_F64_convert_subnorm:  cross FP_convert_ops, rounding_mode_all, FP_subnorm, FP_convert_fmt,  F64_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_double);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_BF16


            `ifdef COVER_F32
                ignore_bins widen_f32_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_F32

        }

        B5_F64_convert_minSubNorm_p_3ulp:  cross FP_convert_ops, rounding_mode_all, F64_minSubNorm_p_3ulp, FP_convert_fmt,  F64_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_double);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_BF16


            `ifdef COVER_F32
                ignore_bins widen_f32_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_F32

        }

        B5_F64_convert_minSubNorm_m_3ulp:  cross FP_convert_ops, rounding_mode_all, F64_minSubNorm_m_3ulp, FP_convert_fmt,  F64_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_double);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_BF16


            `ifdef COVER_F32
                ignore_bins widen_f32_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_F32

        }

        B5_F64_convert_minNorm_p_3ulp:  cross FP_convert_ops, rounding_mode_all, F64_minNorm_p_3ulp, FP_convert_fmt,  F64_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_double);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_BF16


            `ifdef COVER_F32
                ignore_bins widen_f32_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_F32

        }

        B5_F64_convert_minNorm_m_3ulp:  cross FP_convert_ops, rounding_mode_all, F64_minNorm_m_3ulp, FP_convert_fmt,  F64_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_double);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_BF16


            `ifdef COVER_F32
                ignore_bins widen_f32_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_F32

        }

        B5_F64_convert_btw_minSubNorm_zero:  cross FP_result_ops, rounding_mode_all, F64_btw_minSubNorm_zero, FP_convert_fmt, F64_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_double);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_BF16


            `ifdef COVER_F32
                ignore_bins widen_f32_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_F32

        }

        B5_F64_convert_minNorm_p5_exp_range:  cross FP_convert_ops, rounding_mode_all, FP_minNorm_p5_exp_range, FP_convert_fmt,  F64_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_double);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_BF16


            `ifdef COVER_F32
                ignore_bins widen_f32_to_f64 = binsof(FP_convert_fmt.fmt_double);
            `endif // COVER_F32

        }

    `endif

    `ifdef COVER_F128
        B5_F128_subnorm:              cross FP_result_ops, rounding_mode_all, FP_subnorm,               F128_result_fmt;
        B5_F128_minSubNorm_p_3ulp:    cross FP_result_ops, rounding_mode_all, F128_minSubNorm_p_3ulp,   F128_result_fmt;
        B5_F128_minSubNorm_m_3ulp:    cross FP_result_ops, rounding_mode_all, F128_minSubNorm_m_3ulp,   F128_result_fmt {
            ignore_bins impossible_addsub = binsof(FP_result_ops.add) && binsof(FP_result_ops.add);
        }
        B5_F128_minNorm_p_3ulp:       cross FP_result_ops, rounding_mode_all, F128_minNorm_p_3ulp,      F128_result_fmt;
        B5_F128_minNorm_m_3ulp:       cross FP_result_ops, rounding_mode_all, F128_minNorm_m_3ulp,      F128_result_fmt;
        B5_F128_btw_minSubNorm_zero:  cross FP_result_ops, rounding_mode_all, F128_btw_minSubNorm_zero, F128_result_fmt;
        B5_F128_minNorm_p5_exp_range: cross FP_result_ops, rounding_mode_all, FP_minNorm_p5_exp_range,  F128_result_fmt;


        B5_F128_convert_subnorm:  cross FP_convert_ops, rounding_mode_all, FP_subnorm, FP_convert_fmt,  F128_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_quad);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_BF16


            `ifdef COVER_F32
                ignore_bins widen_f32_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F32


            `ifdef COVER_F64
                ignore_bins widen_f64_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F64

        }

        B5_F128_convert_minSubNorm_p_3ulp:  cross FP_convert_ops, rounding_mode_all, F128_minSubNorm_p_3ulp, FP_convert_fmt,  F128_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_quad);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_BF16


            `ifdef COVER_F32
                ignore_bins widen_f32_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F32


            `ifdef COVER_F64
                ignore_bins widen_f64_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F64

        }

        B5_F128_convert_minSubNorm_m_3ulp:  cross FP_convert_ops, rounding_mode_all, F128_minSubNorm_m_3ulp, FP_convert_fmt,  F128_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_quad);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_BF16


            `ifdef COVER_F32
                ignore_bins widen_f32_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F32


            `ifdef COVER_F64
                ignore_bins widen_f64_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F64

        }

        B5_F128_convert_minNorm_p_3ulp:  cross FP_convert_ops, rounding_mode_all, F128_minNorm_p_3ulp, FP_convert_fmt,  F128_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_quad);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_BF16


            `ifdef COVER_F32
                ignore_bins widen_f32_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F32


            `ifdef COVER_F64
                ignore_bins widen_f64_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F64

        }

        B5_F128_convert_minNorm_m_3ulp:  cross FP_convert_ops, rounding_mode_all, F128_minNorm_m_3ulp, FP_convert_fmt,  F128_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_quad);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_BF16


            `ifdef COVER_F32
                ignore_bins widen_f32_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F32


            `ifdef COVER_F64
                ignore_bins widen_f64_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F64

        }

        B5_F128_convert_btw_minSubNorm_zero:  cross FP_result_ops, rounding_mode_all, F128_btw_minSubNorm_zero, FP_convert_fmt, F128_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_quad);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_BF16


            `ifdef COVER_F32
                ignore_bins widen_f32_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F32


            `ifdef COVER_F64
                ignore_bins widen_f64_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F64

        }

        B5_F128_convert_minNorm_p5_exp_range:  cross FP_convert_ops, rounding_mode_all, FP_minNorm_p5_exp_range, FP_convert_fmt,  F128_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_quad);

            `ifdef COVER_F16
                ignore_bins widen_f16_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F16


            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_BF16


            `ifdef COVER_F32
                ignore_bins widen_f32_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F32


            `ifdef COVER_F64
                ignore_bins widen_f64_to_f128 = binsof(FP_convert_fmt.fmt_quad);
            `endif // COVER_F64

        }

    `endif

    `ifdef COVER_F16
        B5_F16_subnorm:              cross FP_result_ops, rounding_mode_all, FP_subnorm,              F16_result_fmt;
        B5_F16_minSubNorm_p_3ulp:    cross FP_result_ops, rounding_mode_all, F16_minSubNorm_p_3ulp,   F16_result_fmt;
        B5_F16_minSubNorm_m_3ulp:    cross FP_result_ops, rounding_mode_all, F16_minSubNorm_m_3ulp,   F16_result_fmt {
            ignore_bins impossible_addsub = binsof(FP_result_ops.add) && binsof(FP_result_ops.add);
        }
        B5_F16_minNorm_p_3ulp:       cross FP_result_ops, rounding_mode_all, F16_minNorm_p_3ulp,      F16_result_fmt;
        B5_F16_minNorm_m_3ulp:       cross FP_result_ops, rounding_mode_all, F16_minNorm_m_3ulp,      F16_result_fmt;
        B5_F16_btw_minSubNorm_zero:  cross FP_result_ops, rounding_mode_all, F16_btw_minSubNorm_zero, F16_result_fmt;
        B5_F16_minNorm_p5_exp_range: cross FP_result_ops, rounding_mode_all, FP_minNorm_p5_exp_range, F16_result_fmt;


        B5_F16_convert_subnorm:  cross FP_convert_ops, rounding_mode_all, FP_subnorm, FP_convert_fmt,  F16_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_half);

            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f16 = binsof(FP_convert_fmt.fmt_half);
            `endif // COVER_BF16

        }

        B5_F16_convert_minSubNorm_p_3ulp:  cross FP_convert_ops, rounding_mode_all, F16_minSubNorm_p_3ulp, FP_convert_fmt,  F16_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_half);

            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f16 = binsof(FP_convert_fmt.fmt_half);
            `endif // COVER_BF16

        }

        B5_F16_convert_minSubNorm_m_3ulp:  cross FP_convert_ops, rounding_mode_all, F16_minSubNorm_m_3ulp, FP_convert_fmt,  F16_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_half);

            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f16 = binsof(FP_convert_fmt.fmt_half);
            `endif // COVER_BF16

        }

        B5_F16_convert_minNorm_p_3ulp:  cross FP_convert_ops, rounding_mode_all, F16_minNorm_p_3ulp, FP_convert_fmt,  F16_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_half);

            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f16 = binsof(FP_convert_fmt.fmt_half);
            `endif // COVER_BF16

        }

        B5_F16_convert_minNorm_m_3ulp:  cross FP_convert_ops, rounding_mode_all, F16_minNorm_m_3ulp, FP_convert_fmt,  F16_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_half);

            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f16 = binsof(FP_convert_fmt.fmt_half);
            `endif // COVER_BF16

        }

        B5_F16_convert_btw_minSubNorm_zero:  cross FP_result_ops, rounding_mode_all, F16_btw_minSubNorm_zero, FP_convert_fmt, F16_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_half);

            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f16 = binsof(FP_convert_fmt.fmt_half);
            `endif // COVER_BF16

        }

        B5_F16_convert_minNorm_p5_exp_range:  cross FP_convert_ops, rounding_mode_all, FP_minNorm_p5_exp_range, FP_convert_fmt,  F16_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_half);

            `ifdef COVER_BF16
                ignore_bins widen_bf16_to_f16 = binsof(FP_convert_fmt.fmt_half);
            `endif // COVER_BF16

        }

    `endif

    `ifdef COVER_BF16
        B5_BF16_subnorm:              cross FP_result_ops, rounding_mode_all, FP_subnorm,               BF16_result_fmt;
        B5_BF16_minSubNorm_p_3ulp:    cross FP_result_ops, rounding_mode_all, BF16_minSubNorm_p_3ulp,   BF16_result_fmt;
        B5_BF16_minSubNorm_m_3ulp:    cross FP_result_ops, rounding_mode_all, BF16_minSubNorm_m_3ulp,   BF16_result_fmt {
            ignore_bins impossible_addsub = binsof(FP_result_ops.add) && binsof(FP_result_ops.add);
        }
        B5_BF16_minNorm_p_3ulp:       cross FP_result_ops, rounding_mode_all, BF16_minNorm_p_3ulp,      BF16_result_fmt;
        B5_BF16_minNorm_m_3ulp:       cross FP_result_ops, rounding_mode_all, BF16_minNorm_m_3ulp,      BF16_result_fmt;
        B5_BF16_btw_minSubNorm_zero:  cross FP_result_ops, rounding_mode_all, BF16_btw_minSubNorm_zero, BF16_result_fmt;
        B5_BF16_minNorm_p5_exp_range: cross FP_result_ops, rounding_mode_all, FP_minNorm_p5_exp_range,  BF16_result_fmt;


        B5_BF16_convert_subnorm:  cross FP_convert_ops, rounding_mode_all, FP_subnorm, FP_convert_fmt,  BF16_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_bf16);
        }

        B5_BF16_convert_minSubNorm_p_3ulp:  cross FP_convert_ops, rounding_mode_all, BF16_minSubNorm_p_3ulp, FP_convert_fmt,  BF16_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_bf16);
        }

        B5_BF16_convert_minSubNorm_m_3ulp:  cross FP_convert_ops, rounding_mode_all, BF16_minSubNorm_m_3ulp, FP_convert_fmt,  BF16_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_bf16);
        }

        B5_BF16_convert_minNorm_p_3ulp:  cross FP_convert_ops, rounding_mode_all, BF16_minNorm_p_3ulp, FP_convert_fmt,  BF16_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_bf16);
        }

        B5_BF16_convert_minNorm_m_3ulp:  cross FP_convert_ops, rounding_mode_all, BF16_minNorm_m_3ulp, FP_convert_fmt,  BF16_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_bf16);
        }

        B5_BF16_convert_btw_minSubNorm_zero:  cross FP_result_ops, rounding_mode_all, BF16_btw_minSubNorm_zero, FP_convert_fmt, BF16_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_bf16);
        }

        B5_BF16_convert_minNorm_p5_exp_range:  cross FP_convert_ops, rounding_mode_all, FP_minNorm_p5_exp_range, FP_convert_fmt,  BF16_result_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_bf16);
        }

    `endif

endgroup
