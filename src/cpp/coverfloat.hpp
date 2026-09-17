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

#ifndef COVERFLOAT_H_INCLUDED
#define COVERFLOAT_H_INCLUDED

#include "softfloat/internals.h"
#include "softfloat/platform.h"
#include "softfloat/softfloat.h"
#include "softfloat/specialize.h"
#include <boost/multiprecision/cpp_int.hpp>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <string>

// These definitions are in the modified copy, and the build fails without them, even though they are never touched
// in an unmodified coverfloat build.
#ifdef UNMODIFIED_SOFTFLOAT
typedef struct {
    bool sign;
    int32_t exp;
    uint64_t sig64;
    uint64_t sig0;
    uint64_t sigExtra64;
    uint64_t sigExtra0;

    uint64_t fmaPreAddition[4];
} intermResult_t;

typedef struct {
    uint64_t sigProd[4];
    uint64_t sigC[2];
    int32_t signed_shift;
    enum {
        NONE = 0,
        PROD_ADD_C,
        PROD_SUB_C,
        C_SUB_PROD,
    } mode;
} fmaFullShiftInfo_t;

extern THREAD_LOCAL intermResult_t softfloat_intermediateResult;
extern THREAD_LOCAL fmaFullShiftInfo_t softfloat_fmaAddShiftInfo;
#endif

#define TEST_VECTOR_WIDTH_BITS 576
#define COVER_VECTOR_WIDTH_BITS 1208

#define TEST_VECTOR_WIDTH_HEX 144
#define COVER_VECTOR_WIDTH_HEX 302

#define TEST_VECTOR_WIDTH_HEX_WITH_SEPARATORS (TEST_VECTOR_WIDTH_HEX + 8)
#define COVER_VECTOR_WIDTH_HEX_WITH_SEPARATORS (COVER_VECTOR_WIDTH_HEX + 12)

// #define INTERM_SIG_LENGTH 256
static constexpr int INTERM_SIG_LENGTH = (3 * 112) + 4;
constexpr int hex_length(int sig) {
    int hex_length = sig / 4;
    if (hex_length * 4 != sig) {
        hex_length += 1;
    }
    return hex_length;
}
static constexpr int INTERM_SIG_LENGTH_HEX = hex_length(INTERM_SIG_LENGTH);
static constexpr int RFI_DECIMAL_POINT = INTERM_SIG_LENGTH / 2;

// #define TEST_VECTOR_WIDTH_HEX_WITH_SEPARATORS (TEST_VECTOR_WIDTH_HEX + 8)
// #define MAX_LINE_LEN (TEST_VECTOR_WIDTH_HEX_WITH_SEPARATORS + 10)

#define MAX_LINE_LEN 512

#define MAX_TOKEN_LEN 48

// arbitary encoding of IBM paper operations
// numbering scheme: bits 31:4 are major operation (pulled directly form aharoni paper)
//                   bits 3:0 are variant operations (taylored towards riscv instrs)
//                   coverpoint are written such that any variant covers the superset
#define OP_ADD 0x10
#define OP_SUB 0x20
#define OP_MUL 0x30
#define OP_DIV 0x40
#define OP_FMA 0x50
#define OP_FMADD 0x51  /* mult-add            */
#define OP_FMSUB 0x52  /* mult-subtract       */
#define OP_FNMADD 0x53 /* negated (mult-add)  */
#define OP_FNMSUB 0x54 /* negated (mult-sub)  */
#define OP_SQRT 0x60
#define OP_REM 0x70
#define OP_CFI 0x80
// #define OP_FCVTW  0x81 /* fp to int           */
// #define OP_FCVTWU 0x82 /* fp to uint          */
// #define OP_FCVTL  0x83 /* fp to long          */
// #define OP_FCVTLU 0x84 /* fp to ulong         */
#define OP_CFF 0x90
#define OP_CIF 0xA0
#define OP_QC 0xB0
#define OP_FEQ 0xB1 /* quiet equal         */
#define OP_SC 0xC0
#define OP_FLT 0xC1 /* signaling less than */
#define OP_FLE 0xC2 /* signaling LT or eq  */
#define OP_CLASS 0xD0
#define OP_MIN 0xE0
#define OP_MAX 0xF0
#define OP_CSN 0x100 /* copy sign / negate */
#define OP_FSGNJ 0x101
#define OP_FSGNJN 0x102
#define OP_FSGNJX 0x103
#define OP_RFI 0x110

// format encodings
//  {(int = 1, float = 0), (unsigned int), others => format encoding}
#define FMT_INVAL 0b11111111 /* source unused / invalid */
#define FMT_HALF 0b00000000
#define FMT_SINGLE 0b00000001
#define FMT_DOUBLE 0b00000010
#define FMT_QUAD 0b00000011
#define FMT_BF16 0b00000100
#define FMT_INT 0b10000001
#define FMT_UINT 0b11000001
#define FMT_LONG 0b10000010
#define FMT_ULONG 0b11000010

typedef struct {
    uint64_t upper;
    uint64_t lower;
} uint128_t;

#define UINT128_TO_FLOAT16(f, x) (f.v = (uint16_t)(x->lower & 0xFFFF))
#define UINT128_TO_FLOAT32(f, x) (f.v = (uint32_t)(x->lower & 0xFFFFFFFF))
#define UINT128_TO_FLOAT64(f, x) (f.v = (uint64_t)(x->lower))
#define UINT128_TO_FLOAT128(f, x)                                                                                      \
    do {                                                                                                               \
        f.v[1] = x->upper;                                                                                             \
        f.v[0] = x->lower;                                                                                             \
    } while (0)

#define FLOAT16_TO_UINT128(x, f)                                                                                       \
    do {                                                                                                               \
        x->upper = 0;                                                                                                  \
        x->lower = f.v;                                                                                                \
    } while (0)

#define FLOAT32_TO_UINT128(x, f)                                                                                       \
    do {                                                                                                               \
        x->upper = 0;                                                                                                  \
        x->lower = f.v;                                                                                                \
    } while (0)

#define FLOAT64_TO_UINT128(x, f)                                                                                       \
    do {                                                                                                               \
        x->upper = 0;                                                                                                  \
        x->lower = f.v;                                                                                                \
    } while (0)

#define FLOAT128_TO_UINT128(x, f)                                                                                      \
    do {                                                                                                               \
        x->upper = f.v[1];                                                                                             \
        x->lower = f.v[0];                                                                                             \
    } while (0)

#define MP_TO_FLOAT16(f, x) (f.v = static_cast<uint16_t>(x & 0xFFFF))
#define MP_TO_FLOAT32(f, x) (f.v = static_cast<uint32_t>(x & 0xFFFFFFFF))
#define MP_TO_FLOAT64(f, x) (f.v = static_cast<uint64_t>(x))
#define MP_TO_FLOAT128(f, x)                                                                                           \
    do {                                                                                                               \
        f.v[1] = static_cast<uint64_t>(x >> 64);                                                                       \
        f.v[0] = static_cast<uint64_t>(x);                                                                             \
    } while (0)

#define FLOAT16_TO_MP(x, f) x = f.v
#define FLOAT32_TO_MP(x, f) x = f.v;
#define FLOAT64_TO_MP(x, f) x = f.v;
#define FLOAT128_TO_MP(x, f)                                                                                           \
    do {                                                                                                               \
        x = f.v[1];                                                                                                    \
        x <<= 64;                                                                                                      \
        x |= f.v[0];                                                                                                   \
    } while (0)

struct MPIntermResult {
    bool sign;
    int32_t exp;
    boost::multiprecision::cpp_int sig;
    boost::multiprecision::uint256_t fma_pre_addition;
};

struct MP_fmaFullShiftInfo {
    boost::multiprecision::cpp_int sigProd;
    boost::multiprecision::cpp_int sigC;
    int32_t signed_shift;

    enum class Mode {
        PROD_ADD_C,
        PROD_SUB_C,
        C_SUB_PROD,
        NONE,
    } mode;
};

inline uint32_t signed_to_unsigned(int32_t in) {
    uint32_t out;
    std::memcpy(&out, &in, sizeof(uint32_t));
    return out;
}

inline uint64_t signed_to_unsigned(int64_t in) {
    uint64_t out;
    std::memcpy(&out, &in, sizeof(uint64_t));
    return out;
}

void softFloat_clearFlags(uint_fast8_t);

uint_fast8_t softFloat_getFlags();

void softFloat_setRoundingMode(uint_fast8_t);

void softfloat_getIntermResults(intermResult_t *);

std::string coverfloat_runtestvector(const std::string &input, bool suppress_error_check);

// TODO move to own file
float128_t f128_min(float128_t a, float128_t b);
float128_t f128_max(float128_t a, float128_t b);

#endif
