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

#include "coverfloat.hpp"
#include <cinttypes>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <sstream>
#include <utility>

#ifndef TEST_FMA
// #define TEST_FMA
#endif

#ifndef TEST_DIV
#define TEST_DIV
#endif

#ifdef UNMODIFIED_SOFTFLOAT
THREAD_LOCAL intermResult_t softfloat_intermediateResult;
THREAD_LOCAL fmaFullShiftInfo_t softfloat_fmaAddShiftInfo;

// Remove Unnecessary Features
#ifdef TEST_DIV
#undef TEST_DIV
#endif

#ifdef TEST_FMA
#undef TEST_FMA
#endif

#endif

namespace mp = boost::multiprecision;

void softFloat_clearFlags(uint_fast8_t clearMask) {
    softfloat_exceptionFlags &= ~clearMask;
}

uint_fast8_t softFloat_getFlags() {
    return softfloat_exceptionFlags;
}

void softFloat_setRoundingMode(uint_fast8_t rm) {
    softfloat_roundingMode = rm;
}

void softfloat_getIntermResults(intermResult_t *result) {

    result->sign = softfloat_intermediateResult.sign;
    result->exp = softfloat_intermediateResult.exp;
    result->sig64 = softfloat_intermediateResult.sig64;
    result->sig0 = softfloat_intermediateResult.sig0;
    result->sigExtra64 = softfloat_intermediateResult.sigExtra64;
    result->sigExtra0 = softfloat_intermediateResult.sigExtra0;

    result->fmaPreAddition[indexWord(4, 3)] = softfloat_intermediateResult.fmaPreAddition[indexWord(4, 3)];
    result->fmaPreAddition[indexWord(4, 2)] = softfloat_intermediateResult.fmaPreAddition[indexWord(4, 2)];
    result->fmaPreAddition[indexWord(4, 1)] = softfloat_intermediateResult.fmaPreAddition[indexWord(4, 1)];
    result->fmaPreAddition[indexWord(4, 0)] = softfloat_intermediateResult.fmaPreAddition[indexWord(4, 0)];
}

void softfloat_getIntermResults(MPIntermResult &result) {
    result.sign = softfloat_intermediateResult.sign;
    result.exp = softfloat_intermediateResult.exp;

    result.sig = softfloat_intermediateResult.sig64;
    result.sig <<= 64;
    result.sig |= softfloat_intermediateResult.sig0;
    result.sig <<= 64;
    result.sig |= softfloat_intermediateResult.sigExtra64;
    result.sig <<= 64;
    result.sig |= softfloat_intermediateResult.sigExtra0;

    result.fma_pre_addition = softfloat_intermediateResult.fmaPreAddition[indexWord(4, 3)];
    result.fma_pre_addition <<= 64;
    result.fma_pre_addition |= softfloat_intermediateResult.fmaPreAddition[indexWord(4, 2)];
    result.fma_pre_addition <<= 64;
    result.fma_pre_addition |= softfloat_intermediateResult.fmaPreAddition[indexWord(4, 1)];
    result.fma_pre_addition <<= 64;
    result.fma_pre_addition |= softfloat_intermediateResult.fmaPreAddition[indexWord(4, 0)];
}

void softfloat_clearIntermResults() {

    softfloat_intermediateResult.sign = 0;
    softfloat_intermediateResult.exp = 0;
    softfloat_intermediateResult.sig64 = 0;
    softfloat_intermediateResult.sig0 = 0;
    softfloat_intermediateResult.sigExtra64 = 0;
    softfloat_intermediateResult.sigExtra0 = 0;
    softfloat_intermediateResult.fmaPreAddition[indexWord(4, 0)] = 0;
    softfloat_intermediateResult.fmaPreAddition[indexWord(4, 1)] = 0;
    softfloat_intermediateResult.fmaPreAddition[indexWord(4, 2)] = 0;
    softfloat_intermediateResult.fmaPreAddition[indexWord(4, 3)] = 0;
}

void softfloat_clearFMAAddShiftInfo() {
    softfloat_fmaAddShiftInfo.mode = fmaFullShiftInfo_t::NONE;
    softfloat_fmaAddShiftInfo.sigProd[indexWord(4, 0)] = 0;
    softfloat_fmaAddShiftInfo.sigProd[indexWord(4, 1)] = 0;
    softfloat_fmaAddShiftInfo.sigProd[indexWord(4, 2)] = 0;
    softfloat_fmaAddShiftInfo.sigProd[indexWord(4, 3)] = 0;
    softfloat_fmaAddShiftInfo.sigC[indexWord(2, 0)] = 0;
    softfloat_fmaAddShiftInfo.sigC[indexWord(2, 1)] = 0;
    softfloat_fmaAddShiftInfo.signed_shift = 0;
}

void softfloat_getFMAAddShiftInfo(MP_fmaFullShiftInfo &info) {
    info.signed_shift = softfloat_fmaAddShiftInfo.signed_shift;

    info.sigC = softfloat_fmaAddShiftInfo.sigC[indexWord(2, 1)];
    info.sigC <<= 64;
    info.sigC |= softfloat_fmaAddShiftInfo.sigC[indexWord(2, 0)];

    info.sigProd = softfloat_fmaAddShiftInfo.sigProd[indexWord(4, 3)];
    info.sigProd <<= 64;
    info.sigProd |= softfloat_fmaAddShiftInfo.sigProd[indexWord(4, 2)];
    info.sigProd <<= 64;
    info.sigProd |= softfloat_fmaAddShiftInfo.sigProd[indexWord(4, 1)];
    info.sigProd <<= 64;
    info.sigProd |= softfloat_fmaAddShiftInfo.sigProd[indexWord(4, 0)];

    switch (softfloat_fmaAddShiftInfo.mode) {
    case fmaFullShiftInfo_t::PROD_ADD_C:
        info.mode = MP_fmaFullShiftInfo::Mode::PROD_ADD_C;
        break;
    case fmaFullShiftInfo_t::PROD_SUB_C:
        info.mode = MP_fmaFullShiftInfo::Mode::PROD_SUB_C;
        break;
    case fmaFullShiftInfo_t::C_SUB_PROD:
        info.mode = MP_fmaFullShiftInfo::Mode::C_SUB_PROD;
        break;
    default:
        info.mode = MP_fmaFullShiftInfo::Mode::NONE;
    }
}

int safe_msb(mp::cpp_int integer) {
    if (integer == 0) {
        return -1;
    }
    return mp::msb(integer);
}

/*
AI CODE NEEDS MODIFICATION
*/

/*
uint128_t parse_hex_128(const char *hex) {
    uint128_t value = {0, 0};

    while (*hex) {
        char c = *hex++;
        uint8_t digit;

        if (c >= '0' && c <= '9') digit = c - '0';
        else if (c >= 'a' && c <= 'f') digit = 10 + (c - 'a');
        else if (c >= 'A' && c <= 'F') digit = 10 + (c - 'A');
        else continue; // skip non-hex chars

        // Shift value left by 4 bits (multiply by 16)
        uint64_t new_upper = (value.upper << 4) | (value.lower >> 60);
        uint64_t new_lower = (value.lower << 4) | digit;

        value.upper = new_upper;
        value.lower = new_lower;
    }

    return value;
}
*/

uint128_t parse_hex_128(const char *hex) {
    uint128_t value = {(uint64_t)0ULL, (uint64_t)0ULL};
    int count = 0;

    while (*hex && count < 32) {
        char c = *hex++;
        uint8_t digit;

        if (c >= '0' && c <= '9') {
            digit = c - '0';
        } else if (c >= 'a' && c <= 'f') {
            digit = 10 + (c - 'a');
        } else if (c >= 'A' && c <= 'F') {
            digit = 10 + (c - 'A');
        } else {
            continue;
        }

        uint64_t upper = (uint64_t)value.upper;
        uint64_t lower = (uint64_t)value.lower;

        value.upper = (upper << 4) | (lower >> 60);
        value.lower = (lower << 4) | (uint64_t)digit;

        // printf("VALUE AT STEP %d: %016x%016x\n", count, value.upper, value.lower);

        count++;
    }

    return value;
}

std::pair<int, std::string> reference_model(
    const uint32_t op,
    const uint8_t rm,
    const mp::uint128_t &a,
    const mp::uint128_t &b,
    const mp::uint128_t &c,
    const uint8_t operandFmt,
    const uint8_t resultFmt,

    mp::uint128_t &result,
    uint8_t *flags,
    MPIntermResult &intermResult
) {

    // clear flags so we get only triggered flags
    softFloat_clearFlags(0xFF);

    // clear intermediate result to avoid reporting intermediate results for results that were not rounded
    softfloat_clearIntermResults();

    // set rounding mode
    softFloat_setRoundingMode(rm);

    // nested switch statements to call softfloat functions

    switch (op) {
    case OP_ADD: {

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            resultf = f32_add(af, bf);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            resultf = f64_add(af, bf);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af, bf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            resultf = f128_add(af, bf);
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf = f16_add(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf = bf16_add(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }
        break;
    }

    case OP_SUB: {

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            resultf = f32_sub(af, bf);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            resultf = f64_sub(af, bf);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af, bf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            resultf = f128_sub(af, bf);
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf = f16_sub(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf = bf16_sub(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_MUL: {

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            resultf = f32_mul(af, bf);
            FLOAT32_TO_MP(result, resultf);

            // printf("performing single precision mul!!\n");
            // printf("int operands are: %x and %x\n", *a, *b);
            // printf("float operands are: %x and %x\n", af.v, bf.v);
            // printf("float result is %x\n", resultf.v);
            // printf("int result is %032x%032x\n", result->upper, result->lower);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            resultf = f64_mul(af, bf);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af, bf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            resultf = f128_mul(af, bf);
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf = f16_mul(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf = bf16_mul(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_DIV: {
        /* We can extract more intermediate bits using mp::cpp_ints instead of what softfloat gives, look
           at their fast approach to calculating single precision div for the motivation */

        mp::cpp_int sigA, sigB;
        bool a_subnorm = false;
        bool b_subnorm = false;
        int nf;
        int softfloat_undershift = (resultFmt == FMT_QUAD) ? 16 : 2;

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            resultf = f32_div(af, bf);
            FLOAT32_TO_MP(result, resultf);

            sigA = fracF32UI(a);
            sigB = fracF32UI(b);
            nf = 23;

            a_subnorm = expF32UI(a) == 0;
            b_subnorm = expF32UI(b) == 0;

            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            resultf = f64_div(af, bf);
            FLOAT64_TO_MP(result, resultf);

            sigA = fracF64UI(a);
            sigB = fracF64UI(b);
            nf = 52;

            a_subnorm = expF64UI(a) == 0;
            b_subnorm = expF64UI(b) == 0;

            break;
        }

        case FMT_QUAD: {
            float128_t af, bf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            resultf = f128_div(af, bf);
            FLOAT128_TO_MP(result, resultf);

            sigA = fracF128UI64(a >> 64);
            sigA <<= 64;
            sigA |= static_cast<uint64_t>(a);
            sigB = fracF128UI64(b >> 64);
            sigB <<= 64;
            sigB |= static_cast<uint64_t>(b);
            nf = 112;

            a_subnorm = expF128UI64(a >> 64) == 0;
            b_subnorm = expF128UI64(b >> 64) == 0;

            break;
        }

        case FMT_HALF: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf = f16_div(af, bf);
            FLOAT16_TO_MP(result, resultf);

            sigA = fracF16UI(a);
            sigB = fracF16UI(b);
            nf = 10;

            a_subnorm = expF16UI(a) == 0;
            b_subnorm = expF16UI(b) == 0;

            break;
        }

        case FMT_BF16: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf = bf16_div(af, bf);
            FLOAT16_TO_MP(result, resultf);

            sigA = fracBF16UI(a);
            sigB = fracBF16UI(b);
            nf = 7;

            a_subnorm = expBF16UI(a) == 0;
            b_subnorm = expBF16UI(b) == 0;
            break;
        }
        default: {
            return {EXIT_FAILURE, "Bad Operand Format For Div " + operandFmt};
        }
        }

        if (operandFmt == FMT_BF16) {
            // Their approach gives more bits
            break;
        }

        // If we have a trivial intermediate result
        if (softfloat_intermediateResult.sig64 == 0 && softfloat_intermediateResult.sig0 == 0 &&
            softfloat_intermediateResult.sigExtra64 == 0 && softfloat_intermediateResult.sigExtra0 == 0) {
            break;
        }

        if (!a_subnorm) {
            sigA |= (mp::cpp_int(1) << nf);
        } else {
            int align_shift = nf - safe_msb(sigA);
            sigA <<= align_shift;
        }
        if (!b_subnorm) {
            sigB |= (mp::cpp_int(1) << nf);
        } else {
            int align_shift = nf - safe_msb(sigB);
            sigB <<= align_shift;
        }

        int extra_bits = nf + 3;
        mp::cpp_int shifted_sigA = sigA << (nf + extra_bits);
        mp::cpp_int pre_rounding = (shifted_sigA) / sigB;

        if (pre_rounding * sigB != shifted_sigA) {
            pre_rounding |= 1;
        }

        // Now compare to the extracted bits
        // msb is zero indexed, so this has the intended effect
        int alignment_shift = 256 - mp::msb(pre_rounding) - softfloat_undershift;
        if (alignment_shift > 0) {
            pre_rounding <<= alignment_shift;
        } else {
            pre_rounding >>= -alignment_shift;
        }

        // Sanity Checks
#ifdef TEST_DIV
        mp::cpp_int softfloat_computed = 0;
        softfloat_computed |= softfloat_intermediateResult.sig64;
        softfloat_computed <<= 64;
        softfloat_computed |= softfloat_intermediateResult.sig0;
        softfloat_computed <<= 64;
        softfloat_computed |= softfloat_intermediateResult.sigExtra64;
        softfloat_computed <<= 64;
        softfloat_computed |= softfloat_intermediateResult.sigExtra0;

        // std::string pre_rounding_binary = pre_rounding.str(0, std::ios_base::binary);
        // std::string softfloat_computed_binary = softfloat_computed.str(0, std::ios_base::binary);

        bool only_zeros = true;
        for (int i = 0; i < 256; i++) {
            mp::cpp_int bit_mask = mp::cpp_int(1) << i;

            bool softfloat_bit = (softfloat_computed & bit_mask) != 0;
            bool pre_rounding_bit = (pre_rounding & bit_mask) != 0;

            if (softfloat_bit != pre_rounding_bit) {
                if (!only_zeros) {
                    mp::cpp_int sig_mask = ((mp::cpp_int(1) << (nf + 1)) - 1);
                    int align_shift = 256 - mp::msb(sig_mask) - softfloat_undershift;
                    sig_mask <<= align_shift;

                    mp::cpp_int guard_mask = mp::cpp_int(1) << (align_shift - 1);
                    mp::cpp_int sticky_mask = sig_mask | guard_mask;

                    bool dirty = ((pre_rounding & sig_mask) != (softfloat_computed & sig_mask)) ||
                                 ((pre_rounding & guard_mask) != (softfloat_computed & guard_mask)) ||
                                 (((pre_rounding & sticky_mask) != 0) ^ ((pre_rounding & sticky_mask) != 0));

                    // Exact Sticky Bits are Wrong for Doubles, but overall correct (normally)
                    std::stringstream msg;
                    if (!(operandFmt == FMT_DOUBLE || operandFmt == FMT_QUAD) || dirty) {
                        msg << "Division Prerounding Calculation Failed: Softfloat gave ";
                        msg << std::hex << std::setfill('0') << std::setw(48) << softfloat_computed;
                        msg << " We generated: " << std::setw(48) << pre_rounding << "\n";
                    }

                    if ((pre_rounding & sig_mask) != (softfloat_computed & sig_mask)) {
                        msg << "Sigs Disagree" << "\n";
                    }
                    if ((pre_rounding & guard_mask) != (softfloat_computed & guard_mask)) {
                        msg << "Guards Disagree" << "\n";
                    }
                    if (((pre_rounding & sticky_mask) != 0) ^ ((pre_rounding & sticky_mask) != 0)) {
                        msg << "Stickies Disagree" << "\n";
                    }

                    if (dirty) {
                        return {EXIT_FAILURE, msg.str()};
                    }
                }
            }

            if (only_zeros && softfloat_bit == 1) {
                // Because of the way their sticky calculation works, we should let the last bit of
                // softfloats sticky differ from ours
                only_zeros = false;
            }
        }
#endif

        softfloat_intermediateResult.sig64 = static_cast<uint64_t>(pre_rounding >> 192);
        softfloat_intermediateResult.sig0 = static_cast<uint64_t>(pre_rounding >> 128);
        softfloat_intermediateResult.sigExtra64 = static_cast<uint64_t>(pre_rounding >> 64);
        softfloat_intermediateResult.sigExtra0 = static_cast<uint64_t>(pre_rounding);

        break;
    }

    case OP_REM: {

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            resultf = f32_rem(af, bf);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            resultf = f64_rem(af, bf);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af, bf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            resultf = f128_rem(af, bf);
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf = f16_rem(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        // TODO: not currently implemented as a function through softfloat
        case FMT_BF16: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            // resultf = bf16_rem(af, bf);
            float32_t f32A = {(uint32_t)af.v << 16};
            float32_t f32B = {(uint32_t)bf.v << 16};
            resultf = f32_to_bf16(f32_div(f32A, f32B));

            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_FEQ: {

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            resultf.v = f32_eq(af, bf);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            resultf.v = f64_eq(af, bf);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af, bf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            resultf.v[1] = 0;
            resultf.v[0] = f128_eq(af, bf);
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf.v = f16_eq(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf.v = bf16_eq(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_FLT: {

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            resultf.v = f32_lt(af, bf);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            resultf.v = f64_lt(af, bf);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af, bf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            resultf.v[1] = 0;
            resultf.v[0] = f128_lt(af, bf);
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf.v = f16_lt(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf.v = bf16_lt(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_FLE: {

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            resultf.v = f32_le(af, bf);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            resultf.v = f64_le(af, bf);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af, bf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            resultf.v[1] = 0;
            resultf.v[0] = f128_le(af, bf);
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf.v = f16_le(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf.v = bf16_le(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_MIN: {

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            resultf = f32_min(af, bf);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            resultf = f64_min(af, bf);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        // TODO: Missing softfloat function
        case FMT_QUAD: {
            float128_t af, bf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            resultf = f128_min(af, bf);
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf = f16_min(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf = bf16_min(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_MAX: {

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            resultf = f32_max(af, bf);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            resultf = f64_max(af, bf);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        // NOTE: Missing softfloat function, added custom
        case FMT_QUAD: {
            float128_t af, bf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            resultf = f128_max(af, bf);
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf = f16_max(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf = bf16_max(af, bf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_FSGNJ: {

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            resultf.v = (af.v & 0x7FFFFFFF) | (bf.v & 0x80000000);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            resultf.v = (af.v & 0x7FFFFFFFFFFFFFFF) | (bf.v & 0x8000000000000000);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af, bf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            resultf.v[1] = (af.v[1] & 0x7FFFFFFFFFFFFFFF) | (bf.v[1] & 0x8000000000000000);
            resultf.v[0] = af.v[0];
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf.v = (af.v & 0x7FFF) | (bf.v & 0x8000);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf.v = (af.v & 0x7FFF) | (bf.v & 0x8000);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_FSGNJN: {

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            resultf.v = (af.v & 0x7FFFFFFF) | (~(bf.v) & 0x80000000);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            resultf.v = (af.v & 0x7FFFFFFFFFFFFFFF) | (~(bf.v) & 0x8000000000000000);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af, bf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            resultf.v[1] = (af.v[1] & 0x7FFFFFFFFFFFFFFF) | (~(bf.v[1]) & 0x8000000000000000);
            resultf.v[0] = af.v[0];
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf.v = (af.v & 0x7FFF) | (~(bf.v) & 0x8000);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf.v = (af.v & 0x7FFF) | (~(bf.v) & 0x8000);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_FSGNJX: {

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            resultf.v = (af.v & 0x7FFFFFFF) | ((af.v ^ bf.v) & 0x80000000);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            resultf.v = (af.v & 0x7FFFFFFFFFFFFFFF) | ((af.v ^ bf.v) & 0x8000000000000000);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af, bf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            resultf.v[1] = (af.v[1] & 0x7FFFFFFFFFFFFFFF) | ((af.v[1] ^ bf.v[1]) & 0x8000000000000000);
            resultf.v[0] = af.v[0];
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf.v = (af.v & 0x7FFF) | ((af.v ^ bf.v) & 0x8000);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, bf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            resultf.v = (af.v & 0x7FFF) | ((af.v ^ bf.v) & 0x8000);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_CIF: {
        switch (resultFmt) {
        case FMT_HALF: {
            float16_t out;
            switch (operandFmt) {
            case FMT_INT: {
                uint32_t serialized_input = static_cast<uint32_t>(a);
                int32_t input;
                // We need to be careful not to throw out the signed part of it
                // a direct conversion to int32_t is UB
                memcpy(&input, &serialized_input, sizeof(input));
                out = i32_to_f16(input);
                break;
            }
            case FMT_UINT: {
                uint32_t input = static_cast<uint32_t>(a);
                out = ui32_to_f16(input);
                break;
            }
            case FMT_LONG: {
                uint64_t serialized_input = static_cast<uint64_t>(a);
                int64_t input;
                // We need to be careful not to throw out the signed part of it
                // a direct conversion to int32_t is UB
                memcpy(&input, &serialized_input, sizeof(input));
                out = i64_to_f16(input);
                break;
            }
            case FMT_ULONG: {
                uint64_t input = static_cast<uint64_t>(a);
                out = ui64_to_f16(input);
                break;
            }
            default: {
                std::stringstream msg;
                msg << "ERROR: int to float conversion with non-int operand format: " << std::hex << operandFmt;
                return {EXIT_FAILURE, msg.str()};
            }
            }

            FLOAT16_TO_MP(result, out);
            break;
        }
        case FMT_BF16: {
            float16_t out;
            switch (operandFmt) {
            case FMT_INT: {
                uint32_t serialized_input = static_cast<uint32_t>(a);
                int32_t input;
                // We need to be careful not to throw out the signed part of it
                // a direct conversion to int32_t is UB
                memcpy(&input, &serialized_input, sizeof(input));
                out = i32_to_bf16(input);
                break;
            }
            case FMT_UINT: {
                uint32_t input = static_cast<uint32_t>(a);
                out = ui32_to_bf16(input);
                break;
            }
            case FMT_LONG: {
                uint64_t serialized_input = static_cast<uint64_t>(a);
                int64_t input;
                // We need to be careful not to throw out the signed part of it
                // a direct conversion to int64_t is UB
                memcpy(&input, &serialized_input, sizeof(input));

                softFloat_setRoundingMode(softfloat_round_odd);
                float64_t out_64 = i64_to_f64(input);
                softFloat_setRoundingMode(rm);
                out = f64_to_bf16(out_64);

                break;
            }
            case FMT_ULONG: {
                uint64_t input = static_cast<uint64_t>(a);

                softFloat_setRoundingMode(softfloat_round_odd);
                float64_t out_64 = ui64_to_f64(input);
                softFloat_setRoundingMode(rm);
                out = f64_to_bf16(out_64);

                break;
            }
            default: {
                std::stringstream msg;
                msg << "ERROR: int to float conversion with non-int operand format: " << std::hex << operandFmt;
                return {EXIT_FAILURE, msg.str()};
            }
            }

            FLOAT16_TO_MP(result, out);
            break;
        }
        case FMT_SINGLE: {
            float32_t out;
            switch (operandFmt) {
            case FMT_INT: {
                uint32_t serialized_input = static_cast<uint32_t>(a);
                int32_t input;
                // We need to be careful not to throw out the signed part of it
                // a direct conversion to int32_t is UB
                memcpy(&input, &serialized_input, sizeof(input));
                out = i32_to_f32(input);
                break;
            }
            case FMT_UINT: {
                uint32_t input = static_cast<uint32_t>(a);
                out = ui32_to_f32(input);
                break;
            }
            case FMT_LONG: {
                uint64_t serialized_input = static_cast<uint64_t>(a);
                int64_t input;
                // We need to be careful not to throw out the signed part of it
                // a direct conversion to int32_t is UB
                memcpy(&input, &serialized_input, sizeof(input));
                out = i64_to_f32(input);
                break;
            }
            case FMT_ULONG: {
                uint64_t input = static_cast<uint64_t>(a);
                out = ui64_to_f32(input);
                break;
            }
            default: {
                std::stringstream msg;
                msg << "ERROR: int to float conversion with non-int operand format: " << std::hex << operandFmt;
                return {EXIT_FAILURE, msg.str()};
            }
            }

            FLOAT32_TO_MP(result, out);
            break;
        }
        case FMT_DOUBLE: {
            float64_t out;
            switch (operandFmt) {
            case FMT_INT: {
                uint32_t serialized_input = static_cast<uint32_t>(a);
                int32_t input;
                // We need to be careful not to throw out the signed part of it
                // a direct conversion to int32_t is UB
                memcpy(&input, &serialized_input, sizeof(input));
                out = i32_to_f64(input);
                break;
            }
            case FMT_UINT: {
                uint32_t input = static_cast<uint32_t>(a);
                out = ui32_to_f64(input);
                break;
            }
            case FMT_LONG: {
                uint64_t serialized_input = static_cast<uint64_t>(a);
                int64_t input;
                // We need to be careful not to throw out the signed part of it
                // a direct conversion to int32_t is UB
                memcpy(&input, &serialized_input, sizeof(input));
                out = i64_to_f64(input);
                break;
            }
            case FMT_ULONG: {
                uint64_t input = static_cast<uint64_t>(a);
                out = ui64_to_f64(input);
                break;
            }
            default: {
                std::stringstream msg;
                msg << "ERROR: int to float conversion with non-int operand format: " << std::hex << operandFmt;
                return {EXIT_FAILURE, msg.str()};
            }
            }

            FLOAT64_TO_MP(result, out);
            break;
        }
        case FMT_QUAD: {
            float128_t out;
            switch (operandFmt) {
            case FMT_INT: {
                uint32_t serialized_input = static_cast<uint32_t>(a);
                int32_t input;
                // We need to be careful not to throw out the signed part of it
                // a direct conversion to int32_t is UB
                memcpy(&input, &serialized_input, sizeof(input));
                out = i32_to_f128(input);
                break;
            }
            case FMT_UINT: {
                uint32_t input = static_cast<uint32_t>(a);
                out = ui32_to_f128(input);
                break;
            }
            case FMT_LONG: {
                uint64_t serialized_input = static_cast<uint64_t>(a);
                int64_t input;
                // We need to be careful not to throw out the signed part of it
                // a direct conversion to int32_t is UB
                memcpy(&input, &serialized_input, sizeof(input));
                out = i64_to_f128(input);
                break;
            }
            case FMT_ULONG: {
                uint64_t input = static_cast<uint64_t>(a);
                out = ui64_to_f128(input);
                break;
            }
            default: {
                std::stringstream msg;
                msg << "ERROR: int to float conversion with non-int operand format: " << std::hex << operandFmt;
                return {EXIT_FAILURE, msg.str()};
            }
            }

            FLOAT128_TO_MP(result, out);
            break;
        }
        default: {
            std::stringstream msg;
            msg << "ERROR: int to float conversion with unsupported result format: " << std::hex << resultFmt;
            return {EXIT_FAILURE, msg.str()};
        }
        }

        break;
    }

    case OP_CFI: {
        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af;
            // TODO: maybe sign extend...
            MP_TO_FLOAT32(af, a);
            switch (resultFmt) {
            case FMT_INT: {
                result = signed_to_unsigned(f32_to_i32(af, rm, true));
                break;
            }
            case FMT_UINT: {
                result = f32_to_ui32(af, rm, true);
                break;
            }
            case FMT_LONG: {
                result = signed_to_unsigned(f32_to_i64(af, rm, true));
                break;
            }
            case FMT_ULONG: {
                result = f32_to_ui64(af, rm, true);
                break;
            }
            default: {
                return {EXIT_FAILURE, "ERROR: float to int conversion with non-int result format"};
            }
            }
            // FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af;
            MP_TO_FLOAT64(af, a);
            switch (resultFmt) {
            case FMT_INT: {
                result = signed_to_unsigned(f64_to_i32(af, rm, true));
                break;
            }
            case FMT_UINT: {
                result = f64_to_ui32(af, rm, true);
                break;
            }
            case FMT_LONG: {
                result = signed_to_unsigned(f64_to_i64(af, rm, true));
                break;
            }
            case FMT_ULONG: {
                result = f64_to_ui64(af, rm, true);
                break;
            }
            default: {
                return {EXIT_FAILURE, "ERROR: float to int conversion with non-int result format"};
            }
            }
            // FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af;
            MP_TO_FLOAT128(af, a);
            switch (resultFmt) {
            case FMT_INT: {
                result = signed_to_unsigned(f128_to_i32(af, rm, true));
                break;
            }
            case FMT_UINT: {
                result = f128_to_ui32(af, rm, true);
                break;
            }
            case FMT_LONG: {
                result = signed_to_unsigned(f128_to_i64(af, rm, true));
                break;
            }
            case FMT_ULONG: {
                result = f128_to_ui64(af, rm, true);
                break;
            }
            default: {
                return {EXIT_FAILURE, "ERROR: float to int conversion with non-int result format"};
            }
            }
            // FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af;
            MP_TO_FLOAT16(af, a);
            switch (resultFmt) {
            case FMT_INT: {
                result = signed_to_unsigned(f16_to_i32(af, rm, true));
                break;
            }
            case FMT_UINT: {
                result = f16_to_ui32(af, rm, true);
                break;
            }
            case FMT_LONG: {
                result = signed_to_unsigned(f16_to_i64(af, rm, true));
                break;
            }
            case FMT_ULONG: {
                result = f16_to_ui64(af, rm, true);
                break;
            }
            default: {
                return {EXIT_FAILURE, "ERROR: float to int conversion with non-int result format"};
            }
            }
            // FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af;
            MP_TO_FLOAT16(af, a);
            switch (resultFmt) {
            case FMT_INT: {
                result = signed_to_unsigned(bf16_to_i32(af, rm, true));
                break;
            }
            case FMT_UINT: {
                result = bf16_to_ui32(af, rm, true);
                break;
            }
            case FMT_LONG: {
                result = f32_to_i64(bf16_to_f32(af), rm, true);
                break;
            }
            case FMT_ULONG: {
                result = f32_to_ui64(bf16_to_f32(af), rm, true);
                break;
            }
            default: {
                return {EXIT_FAILURE, "ERROR: float to int conversion with non-int result format"};
            }
            }
            // FLOAT16_TO_MP(result, resultf);
            break;
        }
        default: {
            return {EXIT_FAILURE, "ERROR: float to int conversion with non-float source format"};
        }
        }

        break;
    }

    /* TODO: float to float instructions */
    case OP_CFF: {

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af;
            MP_TO_FLOAT32(af, a);
            switch (resultFmt) {
            case FMT_HALF: {
                float16_t resultf = f32_to_f16(af);
                FLOAT16_TO_MP(result, resultf);
                break;
            }
            case FMT_BF16: {
                bfloat16_t resultf = f32_to_bf16(af);
                FLOAT16_TO_MP(result, resultf);
                break;
            }
            case FMT_SINGLE: {
                return {
                    EXIT_FAILURE,
                    "ERROR: float to float conversion with the same operand and result format (single)"
                };
            }
            case FMT_DOUBLE: {
                float64_t resultf = f32_to_f64(af);
                FLOAT64_TO_MP(result, resultf);
                break;
            }
            case FMT_QUAD: {
                float128_t resultf = f32_to_f128(af);
                FLOAT128_TO_MP(result, resultf);
                break;
            }
            default: {
                return {EXIT_FAILURE, "ERROR: float to float conversion with non-float result format"};
            }
            }
            // FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af;
            MP_TO_FLOAT64(af, a);
            switch (resultFmt) {
            case FMT_HALF: {
                float16_t resultf = f64_to_f16(af);
                FLOAT16_TO_MP(result, resultf);
                break;
            }
            case FMT_BF16: {
                bfloat16_t resultf = f64_to_bf16(af);
                FLOAT16_TO_MP(result, resultf);
                break;
            }
            case FMT_SINGLE: {
                float32_t resultf = f64_to_f32(af);
                FLOAT32_TO_MP(result, resultf);
                break;
            }
            case FMT_DOUBLE: {
                return {
                    EXIT_FAILURE,
                    "ERROR: float to float conversion with the same operand and result format (double)"
                };
            }
            case FMT_QUAD: {
                float128_t resultf = f64_to_f128(af);
                FLOAT128_TO_MP(result, resultf);
                break;
            }
            default: {
                return {EXIT_FAILURE, "ERROR: float to float conversion with non-float result format"};
            }
            }
            // FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af;
            MP_TO_FLOAT128(af, a);
            switch (resultFmt) {
            case FMT_HALF: {
                float16_t resultf = f128_to_f16(af);
                FLOAT16_TO_MP(result, resultf);
                break;
            }
            case FMT_BF16: {
                softFloat_setRoundingMode(softfloat_round_odd);
                float32_t af_32 = f128_to_f32(af);
                softFloat_setRoundingMode(rm);

                bfloat16_t resultf = f32_to_bf16(af_32);
                FLOAT16_TO_MP(result, resultf);
                break;
            }
            case FMT_SINGLE: {
                float32_t resultf = f128_to_f32(af);
                FLOAT32_TO_MP(result, resultf);
                break;
            }
            case FMT_DOUBLE: {
                float64_t resultf = f128_to_f64(af);
                FLOAT64_TO_MP(result, resultf);
                break;
            }
            case FMT_QUAD: {
                return {
                    EXIT_FAILURE,
                    "ERROR: float to float conversion with the same operand and result format (quad)"
                };
            }
            default: {
                return {EXIT_FAILURE, "ERROR: float to float conversion with non-float result format"};
            }
            }
            // FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af;
            MP_TO_FLOAT16(af, a);
            switch (resultFmt) {
            case FMT_HALF: {
                return {
                    EXIT_FAILURE,
                    "ERROR: float to float conversion with the same operand and result format (half)"
                };
            }
            case FMT_BF16: {
                bfloat16_t resultf = f32_to_bf16(f16_to_f32(af));
                FLOAT16_TO_MP(result, resultf);
                break;
            }
            case FMT_SINGLE: {
                float32_t resultf = f16_to_f32(af);
                FLOAT32_TO_MP(result, resultf);
                break;
            }
            case FMT_DOUBLE: {
                float64_t resultf = f16_to_f64(af);
                FLOAT64_TO_MP(result, resultf);
                break;
            }
            case FMT_QUAD: {
                float128_t resultf = f16_to_f128(af);
                FLOAT128_TO_MP(result, resultf);
                break;
            }
            default: {
                return {EXIT_FAILURE, "ERROR: float to float conversion with non-float result format"};
            }
            }
            // FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af;
            MP_TO_FLOAT16(af, a);
            switch (resultFmt) {
            case FMT_HALF: {
                float16_t resultf = f32_to_f16(bf16_to_f32(af));
                FLOAT16_TO_MP(result, resultf);
                break;
            }
            case FMT_BF16: {
                return {
                    EXIT_FAILURE,
                    "ERROR: float to float conversion with the same operand and result format (bf16)"
                };
            }
            case FMT_SINGLE: {
                float32_t resultf = bf16_to_f32(af);
                FLOAT32_TO_MP(result, resultf);
                break;
            }
            case FMT_DOUBLE: {
                float64_t resultf = f32_to_f64(bf16_to_f32(af));
                FLOAT64_TO_MP(result, resultf);
                break;
            }
            case FMT_QUAD: {
                float128_t resultf = f32_to_f128(bf16_to_f32(af));
                FLOAT128_TO_MP(result, resultf);
                break;
            }
            default: {
                return {EXIT_FAILURE, "ERROR: float to float conversion with non-float result format"};
            }
            }
            // FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_SQRT: {

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, resultf;
            MP_TO_FLOAT32(af, a);
            resultf = f32_sqrt(af);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, resultf;
            MP_TO_FLOAT64(af, a);
            resultf = f64_sqrt(af);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af, resultf;
            MP_TO_FLOAT128(af, a);
            resultf = f128_sqrt(af);
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, resultf;
            MP_TO_FLOAT16(af, a);
            resultf = f16_sqrt(af);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, resultf;
            MP_TO_FLOAT16(af, a);
            resultf = bf16_sqrt(af);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_CLASS: {

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, resultf;
            MP_TO_FLOAT32(af, a);
            resultf.v = f32_classify(af);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, resultf;
            MP_TO_FLOAT64(af, a);
            resultf.v = f64_classify(af);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af, resultf;
            MP_TO_FLOAT128(af, a);
            resultf.v[1] = 0;
            resultf.v[0] = f128_classify(af);
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, resultf;
            MP_TO_FLOAT16(af, a);
            resultf.v = f16_classify(af);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, resultf;
            MP_TO_FLOAT16(af, a);
            resultf.v = bf16_classify(af);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_FMADD: {
        softfloat_clearFMAAddShiftInfo();

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, cf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            MP_TO_FLOAT32(cf, c);
            resultf = f32_mulAdd(af, bf, cf);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, cf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            MP_TO_FLOAT64(cf, c);
            resultf = f64_mulAdd(af, bf, cf);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af, bf, cf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            MP_TO_FLOAT128(cf, c);
            resultf = f128_mulAdd(af, bf, cf);
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, bf, cf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            MP_TO_FLOAT16(cf, c);
            resultf = f16_mulAdd(af, bf, cf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, bf, cf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            MP_TO_FLOAT16(cf, c);
            resultf = bf16_mulAdd(af, bf, cf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_FMSUB: {
        softfloat_clearFMAAddShiftInfo();

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, cf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            MP_TO_FLOAT32(cf, c);
            cf.v ^= 0x80000000; // flip sign
            resultf = f32_mulAdd(af, bf, cf);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, cf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            MP_TO_FLOAT64(cf, c);
            cf.v ^= 0x8000000000000000; // flip sign
            resultf = f64_mulAdd(af, bf, cf);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af, bf, cf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            MP_TO_FLOAT128(cf, c);
            cf.v[1] ^= 0x8000000000000000; // flip sign
            resultf = f128_mulAdd(af, bf, cf);
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, bf, cf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            MP_TO_FLOAT16(cf, c);
            cf.v ^= 0x8000; // flip sign
            resultf = f16_mulAdd(af, bf, cf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, bf, cf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            MP_TO_FLOAT16(cf, c);
            cf.v ^= 0x8000; // flip sign
            resultf = bf16_mulAdd(af, bf, cf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_FNMADD: {
        softfloat_clearFMAAddShiftInfo();

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, cf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            MP_TO_FLOAT32(cf, c);
            af.v ^= 0x80000000; // flip sign
            cf.v ^= 0x80000000; // flip sign
            resultf = f32_mulAdd(af, bf, cf);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, cf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            MP_TO_FLOAT64(cf, c);
            af.v ^= 0x8000000000000000; // flip sign
            cf.v ^= 0x8000000000000000; // flip sign
            resultf = f64_mulAdd(af, bf, cf);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af, bf, cf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            MP_TO_FLOAT128(cf, c);
            af.v[1] ^= 0x8000000000000000; // flip sign
            cf.v[1] ^= 0x8000000000000000; // flip sign
            resultf = f128_mulAdd(af, bf, cf);
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, bf, cf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            MP_TO_FLOAT16(cf, c);
            af.v ^= 0x8000; // flip sign
            cf.v ^= 0x8000; // flip sign
            resultf = f16_mulAdd(af, bf, cf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, bf, cf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            MP_TO_FLOAT16(cf, c);
            af.v ^= 0x8000; // flip sign
            cf.v ^= 0x8000; // flip sign
            resultf = bf16_mulAdd(af, bf, cf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_FNMSUB: {
        softfloat_clearFMAAddShiftInfo();

        switch (operandFmt) {
        case FMT_SINGLE: {
            float32_t af, bf, cf, resultf;
            MP_TO_FLOAT32(af, a);
            MP_TO_FLOAT32(bf, b);
            MP_TO_FLOAT32(cf, c);
            af.v ^= 0x80000000; // flip sign
            resultf = f32_mulAdd(af, bf, cf);
            FLOAT32_TO_MP(result, resultf);
            break;
        }

        case FMT_DOUBLE: {
            float64_t af, bf, cf, resultf;
            MP_TO_FLOAT64(af, a);
            MP_TO_FLOAT64(bf, b);
            MP_TO_FLOAT64(cf, c);
            af.v ^= 0x8000000000000000; // flip sign
            resultf = f64_mulAdd(af, bf, cf);
            FLOAT64_TO_MP(result, resultf);
            break;
        }

        case FMT_QUAD: {
            float128_t af, bf, cf, resultf;
            MP_TO_FLOAT128(af, a);
            MP_TO_FLOAT128(bf, b);
            MP_TO_FLOAT128(cf, c);
            af.v[1] ^= 0x8000000000000000; // flip sign
            resultf = f128_mulAdd(af, bf, cf);
            FLOAT128_TO_MP(result, resultf);
            break;
        }

        case FMT_HALF: {
            float16_t af, bf, cf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            MP_TO_FLOAT16(cf, c);
            af.v ^= 0x8000; // flip sign
            resultf = f16_mulAdd(af, bf, cf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }

        case FMT_BF16: {
            float16_t af, bf, cf, resultf;
            MP_TO_FLOAT16(af, a);
            MP_TO_FLOAT16(bf, b);
            MP_TO_FLOAT16(cf, c);
            af.v ^= 0x8000; // flip sign
            resultf = bf16_mulAdd(af, bf, cf);
            FLOAT16_TO_MP(result, resultf);
            break;
        }
        }

        break;
    }

    case OP_RFI: {
        // Place the decimal place in bit 128 (for rounding reporting)
        mp::cpp_int sig = 0;
        int shift_amount = 0;

        switch (operandFmt) {
        case FMT_BF16: {
            bfloat16_t af, resultf;
            MP_TO_FLOAT16(af, a);

            float32_t as_f32 = bf16_to_f32(af);
            float32_t rounded_to_int_f32 = f32_roundToInt(as_f32, softfloat_round_odd, true);
            resultf = f32_to_bf16(rounded_to_int_f32);

            sig = fracBF16UI(a);
            shift_amount = expBF16UI(a) - BF16_EXP_BIAS;
            intermResult.exp = expBF16UI(a);
            intermResult.sign = signBF16UI(a);

            if (intermResult.exp) {
                sig |= BF16_IMPLICIT_ONE;
            }

            FLOAT16_TO_MP(result, resultf);
            break;
        }
        case FMT_HALF: {
            float16_t af, resultf;
            MP_TO_FLOAT16(af, a);
            resultf = f16_roundToInt(af, rm, true);
            FLOAT16_TO_MP(result, resultf);

            sig = fracF16UI(a);
            shift_amount = expF16UI(a) - 15;
            intermResult.exp = expF16UI(a);
            intermResult.sign = signF16UI(a);

            if (intermResult.exp) {
                sig |= mp::cpp_int(1) << 10;
            }

            break;
        }
        case FMT_SINGLE: {
            float32_t af, resultf;
            MP_TO_FLOAT32(af, a);
            resultf = f32_roundToInt(af, rm, true);
            FLOAT32_TO_MP(result, resultf);

            sig = fracF32UI(a);
            shift_amount = expF32UI(a) - F32_EXP_BIAS;
            intermResult.exp = expF32UI(a);
            intermResult.sign = signF32UI(a);

            if (intermResult.exp) {
                sig |= mp::cpp_int(1) << 23;
            }

            break;
        }
        case FMT_DOUBLE: {
            float64_t af, resultf;
            MP_TO_FLOAT64(af, a);
            resultf = f64_roundToInt(af, rm, true);
            FLOAT64_TO_MP(result, resultf);

            sig = fracF64UI(a);
            shift_amount = expF64UI(a) - 1023;
            intermResult.exp = expF64UI(a);
            intermResult.sign = signF64UI(a);

            if (intermResult.exp) {
                sig |= mp::cpp_int(1) << 52;
            }

            break;
        }
        case FMT_QUAD: {
            float128_t af, resultf;
            MP_TO_FLOAT128(af, a);
            resultf = f128_roundToInt(af, rm, true);
            FLOAT128_TO_MP(result, resultf);

            sig = mp::cpp_int(fracF128UI64(static_cast<uint64_t>(a >> 64))) << 64 | static_cast<uint64_t>(a);
            shift_amount = expF128UI64(static_cast<uint64_t>(a >> 64)) - 16383;
            intermResult.exp = expF128UI64(static_cast<uint64_t>(a >> 64));
            intermResult.sign = signF128UI64(static_cast<uint64_t>(a >> 64));

            if (intermResult.exp) {
                sig |= mp::cpp_int(1) << 112;
            }

            break;
        }
        }

        if (sig != 0) {
            int sig_msb = mp::msb(sig);
            sig <<= RFI_DECIMAL_POINT - sig_msb;

            if (shift_amount > 0) {
                sig <<= std::min(shift_amount, INTERM_SIG_LENGTH);
            } else {
                mp::cpp_int mask = (mp::cpp_int(1) << -shift_amount) - 1;
                bool jam = (sig & mask) != 0;
                sig >>= std::min(-shift_amount, RFI_DECIMAL_POINT + 1);
                sig |= jam;
            }

            intermResult.fma_pre_addition = 0;
            intermResult.sig = sig;
        }

        mp::cpp_int mask = (mp::cpp_int(1) << INTERM_SIG_LENGTH) - 1;
        intermResult.sig &= mask;
        *flags = softFloat_getFlags();

        // DO NOT FALL THROUGH TO THE NORMAL POST-PROCESSING!
        return {EXIT_SUCCESS, ""};
    }

    default: {
        std::stringstream msg;
        msg << "Unsupported Operation Called, OP: " << std::hex << op;
        return {EXIT_FAILURE, msg.str()};
    }
    }

    *flags = softFloat_getFlags();
    softfloat_getIntermResults(intermResult);

    if (op == OP_CFI && operandFmt == FMT_HALF && (resultFmt == FMT_LONG || resultFmt == FMT_ULONG)) {
        intermResult.sig >>= 32;
    }

    if (intermResult.exp == 0 && intermResult.sig == 0) {
        // Then we need to extract an intermediate result from the result
        switch (resultFmt) {
        case FMT_BF16: {
            uint64_t sig = static_cast<uint64_t>(fracBF16UI(result));
            uint32_t exp = expBF16UI(result);

            // No leading one if subnorm or zero
            if (exp != 0) {
                sig |= BF16_IMPLICIT_ONE;
            }
            intermResult.sig = mp::cpp_int(sig) << (INTERM_SIG_LENGTH - 2 - BF16_SIG_BITS);

            intermResult.exp = exp;

            if (exp == 0 && sig != 0) {
                // In theory, we place the leading one (zero for subnormals) in the INTERM_SIG - 2 position
                // so an effective exponent of 0 means that the leading digit is in the INTERM_SIG - 3 position
                intermResult.exp = -(INTERM_SIG_LENGTH - 3 - safe_msb(intermResult.sig));
            }

            intermResult.sign = signBF16UI(result);
            break;
        }
        case FMT_HALF: {
            uint64_t sig = static_cast<uint64_t>(fracF16UI(result));
            uint32_t exp = expF16UI(result);

            // No leading one if it is a subnorm or a zero
            if (exp != 0) {
                sig |= (1 << 10);
            }

            intermResult.sig = mp::cpp_int(sig) << (INTERM_SIG_LENGTH - 2 - 10);

            intermResult.exp = exp;

            if (exp == 0 && sig != 0) {
                intermResult.exp = -(INTERM_SIG_LENGTH - 3 - safe_msb(intermResult.sig));
            }

            intermResult.sign = signF16UI(result);
            break;
        }
        case FMT_SINGLE: {
            uint64_t sig = static_cast<uint64_t>(fracF32UI(result));
            uint32_t exp = expF32UI(result);

            if (exp != 0) {
                sig |= (1 << 23);
            }

            intermResult.sig = mp::cpp_int(sig) << (INTERM_SIG_LENGTH - 2 - 23);

            intermResult.exp = exp;

            if (exp == 0 && sig != 0) {
                intermResult.exp = -(INTERM_SIG_LENGTH - 3 - safe_msb(intermResult.sig));
            }

            intermResult.sign = signF32UI(result);
            break;
        }
        case FMT_DOUBLE: {
            uint64_t sig = static_cast<uint64_t>(fracF64UI(result));
            uint32_t exp = expF64UI(result);

            if (exp != 0) {
                sig |= (1UL << 52);
            }

            intermResult.sig = mp::cpp_int(sig) << (INTERM_SIG_LENGTH - 2 - 52);

            intermResult.exp = exp;

            if (exp == 0 && sig != 0) {
                intermResult.exp = -(INTERM_SIG_LENGTH - 3 - safe_msb(intermResult.sig));
            }

            intermResult.sign = signF64UI(result);
            break;
        }
        case FMT_QUAD: {
            mp::uint256_t sig = fracF128UI64(result >> 64);
            sig <<= 64;
            sig |= static_cast<uint64_t>(result);
            uint32_t exp = expF128UI64(result >> 64);

            // Exp = 0 is a subnorm or a zero
            if (exp != 0) {
                sig |= ((mp::uint128_t)1) << 112;
            }
            // intermResult.sig64 = static_cast<uint64_t>(sig >> 64);
            // intermResult.sig0 = static_cast<uint64_t>(sig);
            intermResult.sig = sig << (INTERM_SIG_LENGTH - 128);

            intermResult.exp = exp;

            if (exp == 0 && sig != 0) {
                intermResult.exp = -(INTERM_SIG_LENGTH - 3 - safe_msb(intermResult.sig));
            }

            intermResult.sign = signF128UI64(result >> 64);
            break;
        }

        default:
            // Int format
            break;
        }
    }

    // If we took an fma operation, there is now an alignment shift that needs to take place
    // AND we need to make a calculation on the full intermediate mantissa
    if ((op & ~(0xf)) == OP_FMA) {
        if (operandFmt == FMT_SINGLE) {
            intermResult.fma_pre_addition >>= 14;
        } else if (operandFmt == FMT_DOUBLE) {
            intermResult.fma_pre_addition >>= 20;
        } else if (operandFmt == FMT_QUAD) {
            intermResult.fma_pre_addition >>= 23;
        } else if (operandFmt == FMT_HALF) {
            intermResult.fma_pre_addition >>= 8;
        } else if (operandFmt == FMT_BF16) {
            intermResult.fma_pre_addition >>= 38;
        }

        MP_fmaFullShiftInfo info;
        softfloat_getFMAAddShiftInfo(info);

        // First thing to do is align the significands, then figure out where to go next
        int prod_msb = safe_msb(info.sigProd);
        info.sigProd <<= (INTERM_SIG_LENGTH + 1) - prod_msb;

        int c_msb = safe_msb(info.sigC);
        info.sigC <<= (INTERM_SIG_LENGTH + 1) - c_msb;

        if (info.signed_shift > 0) {
            mp::cpp_int lost_bits_mask = (mp::cpp_int(1) << std::min(info.signed_shift, INTERM_SIG_LENGTH + 2)) - 1;
            bool jam = (info.sigC & lost_bits_mask) != 0;

            info.sigC >>= info.signed_shift;
            info.sigC |= jam;
        } else if (info.signed_shift != 0) {
            mp::cpp_int lost_bits_mask = (mp::cpp_int(1) << std::min(-info.signed_shift, INTERM_SIG_LENGTH + 2)) - 1;
            bool jam = (info.sigProd & lost_bits_mask) != 0;

            info.sigProd >>= -info.signed_shift;
            info.sigProd |= jam;
        }

        mp::cpp_int Z = 0;
        bool did_work = true;

        switch (info.mode) {
        case MP_fmaFullShiftInfo::Mode::PROD_ADD_C:
            Z = info.sigProd + info.sigC;
            break;
        case MP_fmaFullShiftInfo::Mode::PROD_SUB_C:
            Z = info.sigProd - info.sigC;
            break;
        case MP_fmaFullShiftInfo::Mode::C_SUB_PROD:
            Z = info.sigC - info.sigProd;
            break;
        default:
            did_work = false;
            break;
        }

        if (did_work) {
            // Otherwise, we just use the default handling

            if (Z < 0) {
                Z = -Z;
            }

#ifdef TEST_FMA
            // Generically the bits should be exactly equal to intermResult.sig, until a point when intermResult.sig
            // is going to be 1, then all zeros

            mp::cpp_int softfloat_computed = intermResult.sig;
            int softfloat_msb = safe_msb(softfloat_computed);
            int our_msb = safe_msb(Z);

            if (softfloat_msb > our_msb) {
                int shift = softfloat_msb - our_msb;
                mp::cpp_int lost_bits_mask = (mp::cpp_int(1) << std::min(shift, INTERM_SIG_LENGTH + 1)) - 1;
                bool jam = (softfloat_computed & lost_bits_mask) != 0;

                softfloat_computed >>= shift;
                softfloat_computed |= jam;

                if (jam) {
                    std::stringstream msg;
                    msg << "FMA Interm Mantissa Reconstruction Lost Information Compared to Softfloat" << std::hex
                        << " Softfloat: " << softfloat_computed << " Ours: " << Z << "\n";

                    return {EXIT_FAILURE, msg.str()};
                }
            } else {
                softfloat_computed <<= our_msb - softfloat_msb;
            }

            bool only_zeros = true;
            for (int i = 0; i < safe_msb(Z); i++) {
                mp::cpp_int bit_mask = mp::cpp_int(1) << i;
                bool softfloat_bit = (softfloat_computed & bit_mask) != 0;
                bool pre_rounding_bit = (Z & bit_mask) != 0;

                if (softfloat_bit != pre_rounding_bit && !only_zeros) {
                    std::stringstream msg;
                    msg << "FMA Interm Mantissa Reconstruction Lost Information Compared to Softfloat" << std::hex
                        << " Softfloat: " << softfloat_computed << " Ours: " << Z << "\n";

                    return {EXIT_FAILURE, msg.str()};
                }

                if (softfloat_bit == 1 && only_zeros) {
                    only_zeros = false;
                }
            }

#endif

            intermResult.sig = Z;
        }
    }

    // Post Process the Intermediate Results:
    // 1. Align them with where they should be
    // 2. Handle Subnormals to be Shifted into Correct Places
    // 3. Mask off leading one
    int shift_amount = 0;
    if (intermResult.sig != 0) {
        shift_amount = INTERM_SIG_LENGTH - safe_msb(intermResult.sig);
    }

    // 1. Alignment (float formats and int formats differ here)
    bool int_format = false;
    if (resultFmt == FMT_INT || resultFmt == FMT_UINT || resultFmt == FMT_LONG || resultFmt == FMT_ULONG) {
        // Softfloat aligns them to 254 (sic) bits for us, so
        shift_amount = INTERM_SIG_LENGTH - 254;
        int_format = true;
    }

    if (shift_amount > 0) {
        intermResult.sig <<= shift_amount;
    } else if (shift_amount != 0) {
        mp::cpp_int lost_bits_mask = (mp::cpp_int(1) << std::min(-shift_amount, INTERM_SIG_LENGTH + 1)) - 1;
        bool jam = (intermResult.sig & lost_bits_mask) != 0;
        intermResult.sig >>= -shift_amount;
        intermResult.sig |= jam;
    }

    // 2. Subnormal Handling
    if (intermResult.exp <= 0 && !int_format) {
        // We add 1 here to account for there being no leading one. Consider intermResult.exp=0,
        // in this case, we need to shift the result over by one.
        int32_t shift_dist = -intermResult.exp + 1;

        // Lets shift right jam ourselves now!
        mp::cpp_int mask = (mp::cpp_int(1) << shift_dist) - 1;
        int should_jam = 0;
        if (intermResult.sig & mask) {
            should_jam = 1;
        }

        intermResult.sig >>= shift_dist;
        intermResult.sig |= should_jam;
        intermResult.exp = 0;
    }

    // 3. Now remove the leading one
    mp::cpp_int mask = (mp::cpp_int(1) << INTERM_SIG_LENGTH) - 1;
    intermResult.sig &= mask;

    return {EXIT_SUCCESS, ""};
}

// TODO move to own file
float128_t f128_min(float128_t a, float128_t b) {
    bool less = f128_lt_quiet(a, b) || (f128_eq(a, b) && signF128UI64(a.v[1]));

    if (isNaNF128UI(a.v[1], a.v[0]) && isNaNF128UI(b.v[1], b.v[0])) {
        union ui128_f128 ui;
        ui.ui.v64 = defaultNaNF128UI64;
        ui.ui.v0 = defaultNaNF128UI0;
        return ui.f;
    } else {
        return (less || isNaNF128UI(b.v[0], b.v[1])) ? a : b;
    }
}

float128_t f128_max(float128_t a, float128_t b) {
    bool greater = f128_lt_quiet(b, a) || (f128_eq(b, a) && signF128UI64(b.v[1]));

    if (isNaNF128UI(a.v[1], a.v[0]) && isNaNF128UI(b.v[1], b.v[0])) {
        union ui128_f128 ui;
        ui.ui.v64 = defaultNaNF128UI64;
        ui.ui.v0 = defaultNaNF128UI0;
        return ui.f;
    } else {
        return (greater || isNaNF128UI(b.v[0], b.v[1])) ? a : b;
    }
}

std::string coverfloat_runtestvector(const std::string &input, bool suppress_error_check) {

#if 0
    char op_str[MAX_TOKEN_LEN + 1]; // plus one for space for null terminator
    char rm_str[MAX_TOKEN_LEN + 1];
    char a_str[MAX_TOKEN_LEN + 1];
    char b_str[MAX_TOKEN_LEN + 1];
    char c_str[MAX_TOKEN_LEN + 1];
    char opFmt_str[MAX_TOKEN_LEN + 1];
    char res_str[MAX_TOKEN_LEN + 1];
    char resFmt_str[MAX_TOKEN_LEN + 1];
    char flags_str[MAX_TOKEN_LEN + 1];

    if (sscanf(
            input,
            "%48[^_]_%48[^_]_%48[^_]_%48[^_]_%48[^_]_%48[^_]_%48[^_]_%48[^_]_%48[^_ \t\r\n]",
            op_str,
            rm_str,
            a_str,
            b_str,
            c_str,
            opFmt_str,
            res_str,
            resFmt_str,
            flags_str
        ) != 9) {
        snprintf(output, output_size, "Error: malformed testvector: %s\n", input);

        return EXIT_FAILURE;
    }

    // unpack test vector tokens into integers to pass to the reference model

    uint32_t op = parse_hex_128(op_str).lower;
    uint8_t rm = parse_hex_128(rm_str).lower;
    uint128_t a = parse_hex_128(a_str);
    uint128_t b = parse_hex_128(b_str);
    uint128_t c = parse_hex_128(c_str);
    uint8_t opFmt = parse_hex_128(opFmt_str).lower;
    uint8_t resFmt = parse_hex_128(resFmt_str).lower;
    uint128_t res = parse_hex_128(res_str);
    uint8_t flags = parse_hex_128(flags_str).lower;
#else
    std::stringstream ss(input);
    ss >> std::hex;

    uint32_t op;
    uint16_t rm16;
    mp::uint128_t a, b, c;
    uint16_t opFmt16;
    mp::uint128_t res;
    uint16_t resFmt16;
    uint16_t flags;

    ss >> op;
    ss.ignore(1);
    ss >> rm16;
    ss.ignore(1);
    ss >> a;
    ss.ignore(1);
    ss >> b;
    ss.ignore(1);
    ss >> c;
    ss.ignore(1);
    ss >> opFmt16;
    ss.ignore(1);
    ss >> res;
    ss.ignore(1);
    ss >> resFmt16;
    ss.ignore(1);
    ss >> flags;

    uint8_t rm = static_cast<uint8_t>(rm16);
    uint8_t opFmt = static_cast<uint8_t>(opFmt16);
    uint8_t resFmt = static_cast<uint8_t>(resFmt16);
#endif

    mp::uint128_t newRes;
    uint8_t newFlags;
    MPIntermResult intermRes;

    // Call reference model

    auto [success, msg] = reference_model(op, rm, a, b, c, opFmt, resFmt, newRes, &newFlags, intermRes);

    if (success == EXIT_FAILURE) {
        return msg;
    }

    // newRes += newRes128.upper;
    // newRes <<= 64;
    // newRes += newRes128.lower;

    // char output[512];

    std::stringstream output;
    output << std::hex << std::setfill('0');
    output << std::setw(8) << op << '_';
    output << std::setw(2) << rm16 << '_';
    output << std::setw(32) << a << '_' << std::setw(32) << b << '_' << std::setw(32) << c << '_';
    output << std::setw(2) << opFmt16 << '_';
    output << std::setw(32) << newRes << '_';
    output << std::setw(2) << resFmt16 << '_' << std::setw(2) << static_cast<uint16_t>(newFlags) << '_';
    output << std::setw(1) << intermRes.sign << '_';
    output << std::setw(8) << intermRes.exp << '_';
    output << std::setw(INTERM_SIG_LENGTH_HEX) << intermRes.sig << '_';
    output << std::setw(64) << intermRes.fma_pre_addition;

    output << "\n";

    // snprintf(
    //     output,
    //     512,
    //     "%08x_%02x_%016llx%016llx_%016llx%016llx_%016llx%016llx_%02x_%016llx%016llx_%02x_%02x_%01x_%08x_%016llx%"
    //     "016llx%016llx\n",
    //     op,
    //     rm,
    //     a128.upper,
    //     a128.lower,
    //     b128.upper,
    //     b128.lower,
    //     c128.upper,
    //     c128.lower,
    //     opFmt,
    //     newRes.upper,
    //     newRes.lower,
    //     resFmt,
    //     newFlags,
    //     intermRes.sign,
    //     intermRes.exp,
    //     intermRes.sig64,
    //     intermRes.sig0,
    //     intermRes.sigExtra
    // );

    if (!suppress_error_check) {
        if (res != newRes || flags != newFlags) { // Outputs or flags do not match
            // res128.upper != newRes.upper || res128.lower != newRes.lower || // outputs don't match
            // flags != newFlags) {                                            // flags   don't match
            output = std::stringstream();
            output << "Error: testvector output doesn't match expected value\nTestVector output: ";
            output << std::hex << std::setfill('0') << std::setw(32) << res;
            output << "\nExpected output: ";
            output << std::setw(32) << newRes;
            output << "\nTestVector Flags: " << std::setw(2) << flags << "\nExpected Flags: " << std::setw(2)
                   << static_cast<uint16_t>(newFlags) << "\nOperation: " << std::setw(8) << op << "\n";
            // snprintf(
            //     output,
            //     512,
            //     "Error: testvector output doesn't match expected value\nTestVector output: %016llx%016llx\nExpected "
            //     "output:   %016llx%016llx\nTestVector Flags: %02x\nExpected Flags: %02x\nOperation: %08x\n",
            //     res128.upper,
            //     res128.lower,
            //     newRes128.upper,
            //     newRes128.lower,
            //     flags,
            //     newFlags,
            //     op
            // );

            return output.str();
        }
    }

    return output.str();
}
