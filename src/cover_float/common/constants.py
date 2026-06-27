# Copyright (C) 2025-26 Harvey Mudd College
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, any work distributed under the
# License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific language governing permissions
# and limitations under the License.

# Commonly Use Constants

from dataclasses import dataclass

# Operation codes for test vectors

OP_ADD = "00000010"
OP_SUB = "00000020"
OP_MUL = "00000030"
OP_DIV = "00000040"
OP_FMA = "00000050"
OP_FMADD = "00000051"
OP_FMSUB = "00000052"
OP_FNMADD = "00000053"
OP_FNMSUB = "00000054"
OP_SQRT = "00000060"
OP_REM = "00000070"
OP_CFI = "00000080"
OP_FCVTW = "00000081"
OP_FCVTWU = "00000082"
OP_FCVTL = "00000083"
OP_FCVTLU = "00000084"
OP_CFF = "00000090"
OP_CIF = "000000A0"
OP_QC = "000000B0"
OP_FEQ = "000000B1"
OP_SC = "000000C0"
OP_FLT = "000000C1"
OP_FLE = "000000C2"
OP_CLASS = "000000D0"
OP_MIN = "000000E0"
OP_MAX = "000000F0"
OP_CSN = "00000100"
OP_FSGNJ = "00000101"
OP_FSGNJN = "00000102"
OP_FSGNJX = "00000103"
OP_RFI = "00000110"

# Format codes for test vectors

FMT_INVAL = "FF"  # 11111111
FMT_HALF = "00"  # 00000000
FMT_SINGLE = "01"  # 00000001
FMT_DOUBLE = "02"  # 00000010
FMT_QUAD = "03"  # 00000011
FMT_BF16 = "04"  # 00000100
FMT_INT = "81"  # 10000001
FMT_UINT = "C1"  # 11000001
FMT_LONG = "82"  # 10000010
FMT_ULONG = "C2"  # 11000010

FLOAT_FMTS = [FMT_SINGLE, FMT_DOUBLE, FMT_QUAD, FMT_HALF, FMT_BF16]
INT_FMTS = [FMT_INT, FMT_UINT, FMT_LONG, FMT_ULONG]

FMT_TO_STRING = {
    FMT_BF16: "BF16",
    FMT_HALF: "F16",
    FMT_SINGLE: "F32",
    FMT_DOUBLE: "F64",
    FMT_QUAD: "F128",
}

# Size of each integer in bits
INT_SIZES = {
    FMT_INT: 32,
    FMT_UINT: 32,
    FMT_LONG: 64,
    FMT_ULONG: 64,
}

# Excluding the bit for the sign (i.e. int represents numbers from -2^31 to 2^31 - 1)
INT_MAX_EXPS = {
    FMT_INT: 31,
    FMT_UINT: 32,
    FMT_LONG: 63,
    FMT_ULONG: 64,
}

INT_SIGNED = {
    FMT_INT: True,
    FMT_UINT: False,
    FMT_LONG: True,
    FMT_ULONG: False,
}

# Codes for rounding modes in test vectors

ROUND_NEAR_EVEN = "00"
ROUND_MINMAG = "01"
ROUND_MIN = "02"
ROUND_MAX = "03"
ROUND_NEAR_MAXMAG = "04"
ROUND_ODD = "05"

ROUNDING_MODES = [ROUND_NEAR_EVEN, ROUND_MINMAG, ROUND_MIN, ROUND_MAX, ROUND_NEAR_MAXMAG]

# Defining floating point format constants

EXPONENT_BIAS = {FMT_HALF: 15, FMT_SINGLE: 127, FMT_DOUBLE: 1023, FMT_QUAD: 16383, FMT_BF16: 127}

# ROUNDING_MODES = {ROUND_NEAR_EVEN, ROUND_MINMAG, ROUND_MIN, ROUND_MAX, ROUND_NEAR_MAXMAG, ROUND_ODD}

MANTISSA_BITS = {FMT_HALF: 10, FMT_SINGLE: 23, FMT_DOUBLE: 52, FMT_QUAD: 112, FMT_BF16: 7}

EXPONENT_BITS = {FMT_HALF: 5, FMT_SINGLE: 8, FMT_DOUBLE: 11, FMT_QUAD: 15, FMT_BF16: 8}

BIAS = {FMT_HALF: 15, FMT_SINGLE: 127, FMT_DOUBLE: 1023, FMT_QUAD: 16383, FMT_BF16: 127}

UNBIASED_EXP = {
    FMT_HALF: [-14, 15],
    FMT_SINGLE: [-126, 127],
    FMT_DOUBLE: [-1022, 1023],
    FMT_QUAD: [-16382, 16383],
    FMT_BF16: [-126, 127],
}

BIASED_EXP = {  # Range of biased exponents based on precision
    FMT_HALF: [1, 30],
    FMT_SINGLE: [1, 254],
    FMT_DOUBLE: [1, 2046],
    FMT_QUAD: [1, 32766],
    FMT_BF16: [1, 254],
}

# Test vector widths

TEST_VECTOR_WIDTH_HEX = 144
TEST_VECTOR_WIDTH_HEX_WITH_SEPARATORS = TEST_VECTOR_WIDTH_HEX + 8
COVER_VECTOR_WIDTH_HEX = 302
COVER_VECTOR_WIDTH_HEX_WITH_SEPARATORS = COVER_VECTOR_WIDTH_HEX + 12
INTER_SIGNIFICAND_LENGTH = (3 * 112) + 4
RFI_DECIMAL_POINT = INTER_SIGNIFICAND_LENGTH // 2


@dataclass
class Config:
    FULL_COVERAGE_TESTGEN: bool = True
    CACHE_DIR: str = "build/cache"
    QUIET: bool = False
    RELEASE: bool = False


config = Config()
