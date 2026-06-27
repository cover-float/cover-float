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


covergroup B20_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;

    div_op: coverpoint CFI.op {
        type_option.weight = 0;

        bins div  = {OP_DIV};
    }

    sqrt_ops: coverpoint CFI.op {
        type_option.weight = 0;

        bins sqrt = {OP_SQRT};
    }

    F16_trailing_zeros: coverpoint
    count_trailing_zeros(CFI.intermM[INTERM_M_BITS-2 : INTERM_M_BITS-F16_M_BITS - 1], F16_M_BITS) //nf-bit mantissa window (leading 1 excluded)
    iff (CFI.operandFmt == FMT_HALF && CFI.intermM[INTERM_M_BITS-F16_M_BITS-2 : 0] == '0) {   //gated to F16; guard+sticky region = all zero
        type_option.weight = 0;
        bins tz[] = {[0 : F16_M_BITS]}; //tz[nf] = mantissa all zero (fully exact)
    }

    F32_trailing_zeros: coverpoint
    count_trailing_zeros(CFI.intermM[INTERM_M_BITS-2 : INTERM_M_BITS-F32_M_BITS-1], F32_M_BITS)
    iff (CFI.operandFmt == FMT_SINGLE && CFI.intermM[INTERM_M_BITS-F32_M_BITS-2 : 0] == '0) {
        type_option.weight = 0;
        bins tz[] = {[0 : F32_M_BITS]};
    }

    F64_trailing_zeros: coverpoint
    count_trailing_zeros(CFI.intermM[INTERM_M_BITS-2 : INTERM_M_BITS-F64_M_BITS-1], F64_M_BITS)
    iff (CFI.operandFmt == FMT_DOUBLE && CFI.intermM[INTERM_M_BITS-F64_M_BITS-2 : 0] == '0) {
        type_option.weight = 0;
        bins tz[] = {[0 : F64_M_BITS]};
    }

    F128_trailing_zeros: coverpoint
    count_trailing_zeros(CFI.intermM[INTERM_M_BITS-2 : INTERM_M_BITS-F128_M_BITS-1], F128_M_BITS)
    iff (CFI.operandFmt == FMT_QUAD && CFI.intermM[INTERM_M_BITS-F128_M_BITS-2 : 0] == '0) {
        type_option.weight = 0;
        bins tz[] = {[0 : F128_M_BITS]};
    }

    BF16_trailing_zeros: coverpoint
    count_trailing_zeros(CFI.intermM[INTERM_M_BITS-2 : INTERM_M_BITS-BF16_M_BITS-1], BF16_M_BITS)
    iff (CFI.operandFmt == FMT_BF16 && CFI.intermM[INTERM_M_BITS-BF16_M_BITS-2 : 0] == '0) {
        type_option.weight = 0;
        bins tz[] = {[0 : BF16_M_BITS]};
    }

//Crosses

    // Exact square roots require at least ceil(nf/2) trailing zeros (squaring
    // doubles the trailing-zero count, so the input is representable only when
    // the result already has >= nf/2 of them). Counts below ceil(nf/2) are
    // structurally unreachable for SQRT and are ignored in the SQRT crosses.
    `ifdef COVER_F16
        B20_F16_DIV: cross div_op, F16_trailing_zeros;
        B20_F16_SQRT: cross sqrt_ops, F16_trailing_zeros {
            ignore_bins sqrt_unreachable = binsof(F16_trailing_zeros) intersect {[0 : 4]};
        }

    `endif

    `ifdef COVER_F32
        B20_F32_DIV: cross div_op, F32_trailing_zeros;
        B20_F32_SQRT: cross sqrt_ops, F32_trailing_zeros {
            ignore_bins sqrt_unreachable = binsof(F32_trailing_zeros) intersect {[0 : 11]};
        }
    `endif

    `ifdef COVER_F64
        B20_F64_DIV: cross div_op, F64_trailing_zeros;
        B20_F64_SQRT: cross sqrt_ops, F64_trailing_zeros {
            ignore_bins sqrt_unreachable = binsof(F64_trailing_zeros) intersect {[0 : 25]};
        }
    `endif

    `ifdef COVER_F128
        B20_F128_DIV: cross div_op, F128_trailing_zeros;
        B20_F128_SQRT: cross sqrt_ops, F128_trailing_zeros {
            ignore_bins sqrt_unreachable = binsof(F128_trailing_zeros) intersect {[0 : 55]};
        }
    `endif

    `ifdef COVER_BF16
        B20_BF16_DIV: cross div_op, BF16_trailing_zeros;
        B20_BF16_SQRT: cross sqrt_ops, BF16_trailing_zeros {
            ignore_bins sqrt_unreachable = binsof(BF16_trailing_zeros) intersect {[0 : 3]};
        }
    `endif

endgroup
