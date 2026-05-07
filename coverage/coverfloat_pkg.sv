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


`include "../config.svh"
`include "macros.svh"


package coverfloat_pkg;


    // encodings from SoftFloat
    const logic [7:0] FLAG_INEXACT_MASK   =  8'd1;
    const logic [7:0] FLAG_UNDERFLOW_MASK =  8'd2;
    const logic [7:0] FLAG_OVERFLOW_MASK  =  8'd4;
    const logic [7:0] FLAG_INFINITE_MASK  =  8'd8;
    const logic [7:0] FLAG_INVALID_MASK   =  8'd16;

    // arbitary encoding of IBM paper operations
    // numbering scheme: bits 31:4 are major operation (pulled directly form aharoni paper)
    //                   bits 3:0 are variant operations (taylored towards riscv instrs)
    //                   coverpoint are written such that any variant covers the superset
    const logic [31:0] OP_ADD    = 32'h1_0;
    const logic [31:0] OP_SUB    = 32'h2_0;
    const logic [31:0] OP_MUL    = 32'h3_0;
    const logic [31:0] OP_DIV    = 32'h4_0;
    const logic [31:0] OP_FMA    = 32'h5_0;
    const logic [31:0] OP_FMADD  = 32'h5_1; // multiply-add
    const logic [31:0] OP_FMSUB  = 32'h5_2; // multiply-subtract
    const logic [31:0] OP_FNMADD = 32'h5_3; // negated (multiply-add)
    const logic [31:0] OP_FNMSUB = 32'h5_4; // negated (multiply-sub)
    const logic [31:0] OP_SQRT   = 32'h6_0;
    const logic [31:0] OP_REM    = 32'h7_0; // TODO: unused? Remove?
    const logic [31:0] OP_CFI    = 32'h8_0;
    const logic [31:0] OP_CFF    = 32'h9_0;
    const logic [31:0] OP_CIF    = 32'hA_0;
    const logic [31:0] OP_QC     = 32'hB_0;
    const logic [31:0] OP_FEQ    = 32'hB_1; // quiet equal
    const logic [31:0] OP_SC     = 32'hC_0;
    const logic [31:0] OP_FLT    = 32'hC_1; // signaling less than
    const logic [31:0] OP_FLE    = 32'hC_2; // signaling LT or eq
    const logic [31:0] OP_CLASS  = 32'hD_0;
    const logic [31:0] OP_MIN    = 32'hE_0;
    const logic [31:0] OP_MAX    = 32'hF_0;
    const logic [31:0] OP_CSN    = 32'h10_0; // copy sign / negate
    const logic [31:0] OP_FSGNJ  = 32'h10_1;
    const logic [31:0] OP_FSGNJN = 32'h10_2;
    const logic [31:0] OP_FSGNJX = 32'h10_3;
    const logic [32:0] OP_RFI    = 32'h11_0;

    // const logic [31:0] OP_

    // encodings from SoftFloat
    const logic [7:0] ROUND_NEAR_EVEN   = 8'd0;
    const logic [7:0] ROUND_MINMAG      = 8'd1;
    const logic [7:0] ROUND_MIN         = 8'd2;
    const logic [7:0] ROUND_MAX         = 8'd3;
    const logic [7:0] ROUND_NEAR_MAXMAG = 8'd4;
    // const logic [7:0] ROUND_ODD         = 8'd5;

    // format encodings
    //  {(int = 1, float = 0), (unsigned int), others => format encoding}
    const logic [7:0] FMT_INVAL  = 8'b 1_1_111111; // source unused / invalid
    const logic [7:0] FMT_HALF   = 8'b 0_0_000000;
    const logic [7:0] FMT_SINGLE = 8'b 0_0_000001;
    const logic [7:0] FMT_DOUBLE = 8'b 0_0_000010;
    const logic [7:0] FMT_QUAD   = 8'b 0_0_000011;
    const logic [7:0] FMT_BF16   = 8'b 0_0_000100;

    const logic [7:0] FMT_INT    = 8'b 1_0_000001;
    const logic [7:0] FMT_UINT   = 8'b 1_1_000001;
    const logic [7:0] FMT_LONG   = 8'b 1_0_000010;
    const logic [7:0] FMT_ULONG  = 8'b 1_1_000010;


    // TODO: expand with other relvelant parameters

    parameter int INTERM_M_BITS = 340;

    parameter int F16_E_BITS = 5;
    parameter int BF16_E_BITS = 8;
    parameter int F32_E_BITS = 8;
    parameter int F64_E_BITS = 11;
    parameter int F128_E_BITS = 15;

    parameter int F16_M_BITS   = 10;
    parameter int BF16_M_BITS  = 7;
    parameter int F32_M_BITS   = 23;
    parameter int F64_M_BITS   = 52;
    parameter int F128_M_BITS  = 112;

    parameter int F32_FMA_PRE_ADDITION_NF = 2 * F32_M_BITS;
    parameter int F64_FMA_PRE_ADDITION_NF = 2 * F64_M_BITS;
    parameter int F128_FMA_PRE_ADDITION_NF = 2 * F128_M_BITS;
    parameter int F16_FMA_PRE_ADDITION_NF = 2 * F16_M_BITS;
    parameter int BF16_FMA_PRE_ADDITION_NF = 2 * BF16_M_BITS;

    // Precision (p = number of significand bits + 1 implicit bits)
    parameter int F16_P   = F16_M_BITS  + 1;
    parameter int BF16_P  = BF16_M_BITS + 1;
    parameter int F32_P   = F32_M_BITS  + 1;
    parameter int F64_P   = F64_M_BITS  + 1;
    parameter int F128_P  = F128_M_BITS + 1;

    parameter int F16_E_UPPER  = 14;
    parameter int F16_E_LOWER  = 10;
    parameter int BF16_E_UPPER = 14;
    parameter int BF16_E_LOWER = 7;
    parameter int F32_E_UPPER  = 30;
    parameter int F32_E_LOWER  = 23;
    parameter int F64_E_UPPER  = 62;
    parameter int F64_E_LOWER  = 52;
    parameter int F128_E_UPPER = 126;
    parameter int F128_E_LOWER = 112;

    parameter int F16_SIGN_BIT = 15;
    parameter int BF16_SIGN_BIT = 15;
    parameter int F32_SIGN_BIT = 31;
    parameter int F64_SIGN_BIT = 63;
    parameter int F128_SIGN_BIT = 127;

    parameter int F16_M_UPPER  = F16_M_BITS - 1;
    parameter int BF16_M_UPPER = BF16_M_BITS - 1;
    parameter int F32_M_UPPER  = F32_M_BITS - 1;
    parameter int F64_M_UPPER  = F64_M_BITS - 1;
    parameter int F128_M_UPPER = F128_M_BITS - 1;

    parameter int F16_MAXNORM_EXP  = (1 << F16_E_BITS)  - 2;
    parameter int BF16_MAXNORM_EXP = (1 << BF16_E_BITS) - 2;
    parameter int F32_MAXNORM_EXP  = (1 << F32_E_BITS)  - 2;
    parameter int F64_MAXNORM_EXP  = (1 << F64_E_BITS)  - 2;
    parameter int F128_MAXNORM_EXP = (1 << F128_E_BITS) - 2;

    // IEEE-754 floating-point format–derived exponent constants
    // Definitions are derived from IEEE 754-2019, §3.4 (Formats) and §3.5 (Subnormal numbers)
    // See: https://ieeexplore.ieee.org/document/8766229
    // General formulas:
    //   bias              = 2^(E-1) - 1
    //   MinNorm.exp       = 1 - bias
    //   MinSubNorm.exp    = (1 - bias) - (P - 1)
    // where:
    //   E = number of exponent bits
    //   P = precision = fraction bits + hidden leading 1

    // -----------------------------
    // Half precision (binary16)
    // E = 5, P = 11
    // -----------------------------
    parameter int F16_EXP_BIAS        = (1 << (F16_E_BITS - 1)) - 1;
    parameter int F16_MIN_NORM_EXP    = 1 - F16_EXP_BIAS;
    parameter int F16_MIN_SUBNORM_EXP = (1 - F16_EXP_BIAS) - (F16_P - 1);

    // -----------------------------
    // BFloat16
    // E = 8, P = 8
    // -----------------------------
    parameter int BF16_EXP_BIAS        = (1 << (BF16_E_BITS - 1)) - 1;
    parameter int BF16_MIN_NORM_EXP    = 1 - BF16_EXP_BIAS;
    parameter int BF16_MIN_SUBNORM_EXP = (1 - BF16_EXP_BIAS) - (BF16_P - 1);

    // -----------------------------
    // Single precision (binary32)
    // E = 8, P = 24
    // -----------------------------
    parameter int F32_EXP_BIAS        = (1 << (F32_E_BITS - 1)) - 1;
    parameter int F32_MIN_NORM_EXP    = 1 - F32_EXP_BIAS;
    parameter int F32_MIN_SUBNORM_EXP = (1 - F32_EXP_BIAS) - (F32_P - 1);

    // -----------------------------
    // Double precision (binary64)
    // E = 11, P = 53
    // -----------------------------
    parameter int F64_EXP_BIAS        = (1 << (F64_E_BITS - 1)) - 1;
    parameter int F64_MIN_NORM_EXP    = 1 - F64_EXP_BIAS;
    parameter int F64_MIN_SUBNORM_EXP = (1 - F64_EXP_BIAS) - (F64_P - 1);

    // -----------------------------
    // Quad precision (binary128)
    // E = 15, P = 113
    // -----------------------------
    parameter int F128_EXP_BIAS        = (1 << (F128_E_BITS - 1)) - 1;
    parameter int F128_MIN_NORM_EXP    = 1 - F128_EXP_BIAS;
    parameter int F128_MIN_SUBNORM_EXP = (1 - F128_EXP_BIAS) - (F128_P - 1);

    parameter int SIZEOF_INT  = 32;
    parameter int SIZEOF_LONG = 64;
    parameter int UINT_TRAILING_ZEROS = F128_M_BITS - SIZEOF_INT + 1;//add 1 because of hidden 1
    parameter int INT_TRAILING_ZEROS = F128_M_BITS - SIZEOF_INT + 2;//hidden1 + 1
    parameter int LONG_TRAILING_ZEROS = F128_M_BITS - SIZEOF_LONG + 2;//hidden1 + 1
    parameter int ULONG_TRAILING_ZEROS = F128_M_BITS - SIZEOF_LONG + 1;//hidden1

    typedef struct {
    int max_int_exp;
    logic [111:0] max_int_mantissa;
    logic [111:0] one_quarter;
    logic [111:0] one_half;
    logic [111:0] three_quarters;
    logic [111:0] one;
    } max_int_struct;

    // Some Constants For B28
    // This value seems like an odd choice ... because it is a trivial task for rfi,
    // it seems like the intention should be 1.1111 * 2^(precision-2) as that is the maximum value
    // that has some meaning when it goes through rfi
    parameter int F32_RFI_MAX = (F32_EXP_BIAS + F32_M_BITS + 1) << (F32_M_BITS) | ((1 << F32_M_BITS) - 1); // 'h4bff0000
    parameter logic[63:0] F64_RFI_MAX = (F64_EXP_BIAS + F64_M_BITS + 1) << (F64_M_BITS) | ((1 << F64_M_BITS) - 1);
    parameter logic[127:0] F128_RFI_MAX = (F128_EXP_BIAS + F128_M_BITS + 1) << (F128_M_BITS) | ((1 << F128_M_BITS) - 1);
    parameter int F16_RFI_MAX = (F16_EXP_BIAS + F16_M_BITS + 1) << (F16_M_BITS) | ((1 << F16_M_BITS) - 1);
    parameter int BF16_RFI_MAX = (BF16_EXP_BIAS + BF16_M_BITS + 1) << (BF16_M_BITS) | ((1 << BF16_M_BITS) - 1);

    parameter int F32_ONE = (F32_EXP_BIAS) << F32_M_BITS; // 'h3f800000
    parameter logic[63:0] F64_ONE = (F64_EXP_BIAS) << F64_M_BITS;
    parameter logic[127:0] F128_ONE = (F128_EXP_BIAS) << F128_M_BITS;
    parameter int F16_ONE = (F16_EXP_BIAS) << F16_M_BITS;
    parameter int BF16_ONE = (BF16_EXP_BIAS) << BF16_M_BITS;


    // Helper functions for difficult coverpoints

    // determine hamming distance between two signals
    function automatic int sig_hamming_distance(
        input logic [255:0] a,
        input logic [255:0] b,
        input int width
    );
        int i;
        int distance;

        begin
            distance = 0;

            for (i = 0; i < width; i++) begin
                if (a[i] != b[i])
                    distance++;
            end

            return distance;
        end
    endfunction

    // find index of first bit that differs between two signals
    function automatic int sig_diff_index(
        input logic [255:0] a,
        input logic [255:0] b,
        input int width
    );
        int i;

        begin
            for (i = 0; i < width; i++) begin
                if (a[i] != b[i]) begin
                    return i;
                end
            end

            return -1;
        end
    endfunction


    // Count leading zeros (from MSB downward)
    function automatic int count_leading_zeros (
        input logic [255:0] val,
        input int width
    );
        int i;
        begin
            count_leading_zeros = 0;
            for (i = width-1; i >= 0; i--) begin
                if (val[i] == 0)
                    count_leading_zeros++;
                else
                    break;
            end
        end
    endfunction


    // Count leading ones (from MSB downward)
    function automatic int count_leading_ones (
        input logic [255:0] val,
        input int width
    );
        int i;
        begin
            count_leading_ones = 0;
            for (i = width-1; i >= 0; i--) begin
                if (val[i] == 1)
                    count_leading_ones++;
                else
                    break;
            end
        end
    endfunction


    // Count trailing zeros (from LSB upward)
    function automatic int count_trailing_zeros (
        input logic [255:0] val,
        input int width
    );
        int i;
        begin
            count_trailing_zeros = 0;
            for (i = 0; i < width; i++) begin
                if (val[i] == 0)
                    count_trailing_zeros++;
                else
                    break;
            end
        end
    endfunction


    // Count trailing ones (from LSB upward)
    function automatic int count_trailing_ones (
        input logic [255:0] val,
        input int width
    );
        int i;
        begin
            count_trailing_ones = 0;
            for (i = 0; i < width; i++) begin
                if (val[i] == 1)
                    count_trailing_ones++;
                else
                    break;
            end
        end
    endfunction

    // Check for repeating checker pattern with optional partial final run
    // Returns signed run length:
    //   < 0 : first run is 1s
    //   > 0 : first run is 0s
    //   = 0 : invalid pattern
    function automatic int checker_run_length (
        input logic [255:0] val,
        input int width
    );
        int run_len;
        int i;
        int run_idx;
        logic first_bit;
        logic expected;

        begin
            checker_run_length = 0;

            if (width < 2)
                return 0;

            // Determine initial run length from MSB
            first_bit = val[width-1];
            run_len   = 0;

            for (i = width-1; i >= 0; i--) begin
                if (val[i] == first_bit)
                    run_len++;
                else
                    break;
            end

            // Run length must be reasonable
            if (run_len == 0 || run_len > (width >> 1))
                return 0;

            // Verify alternating pattern, allowing partial final run
            for (i = width-1; i >= 0; i--) begin
                run_idx  = (width-1 - i) / run_len;
                expected = (run_idx % 2 == 0) ? first_bit : ~first_bit;

                if (val[i] != expected)
                    return 0;
            end

            // Encode polarity in sign
            checker_run_length = first_bit ? -run_len : run_len;
        end
    endfunction

    // Find the longest contiguous run of ones in the signal
    // Returns length of longest run, or 0 if no ones
    function automatic int longest_seq_of_ones (
        input logic [255:0] val,
        input int width
    );
        int i;
        int curr_len;
        int max_len;

        begin
            longest_seq_of_ones = 0;

            if (width <= 0)
                return 0;

            curr_len = 0;
            max_len  = 0;

            // Scan from LSB to MSB (direction does not matter here)
            for (i = 0; i < width; i++) begin
                if (val[i] == 1) begin
                    curr_len++;
                    if (curr_len > max_len)
                        max_len = curr_len;
                end
                else begin
                    curr_len = 0;
                end
            end

            longest_seq_of_ones = max_len;
        end
    endfunction
    function automatic int get_effective_product_exponent(
        input logic[127:0] a,
        input logic[127:0] b,
        input logic[255:0] pre_addition,
        input logic [7:0] fmt
    );
        int shift_one;

        case (fmt)
            FMT_BF16: begin
                shift_one = pre_addition[BF16_FMA_PRE_ADDITION_NF+1];
            end
            FMT_HALF: begin
                shift_one = pre_addition[F16_FMA_PRE_ADDITION_NF+1];
            end
            FMT_SINGLE: begin
                shift_one = pre_addition[F32_FMA_PRE_ADDITION_NF+1];
            end
            FMT_DOUBLE: begin
                shift_one = pre_addition[F64_FMA_PRE_ADDITION_NF+1];
            end
            FMT_QUAD: begin
                shift_one = pre_addition[F128_FMA_PRE_ADDITION_NF+1];
            end
        endcase
    endfunction

    function automatic int get_product_exponent (
        input logic [127:0] a,
        input logic [127:0] b,
        input logic [7:0]   fmt
    );

        int E_a;
        int E_b;
        int bias;

        case (fmt)

            // --------------------------------------------------
            // HALF (16-bit)
            // sign[15] exp[14:10] frac[9:0]
            // --------------------------------------------------
            FMT_HALF: begin
                logic [F16_E_BITS-1:0] exp_a = a[14:10];
                logic [F16_E_BITS-1:0] exp_b = b[14:10];

                E_a = (exp_a == 0) ?
                        (1 - F16_EXP_BIAS) :
                        (int'(exp_a) - F16_EXP_BIAS);

                E_b = (exp_b == 0) ?
                        (1 - F16_EXP_BIAS) :
                        (int'(exp_b) - F16_EXP_BIAS);

                bias = F16_EXP_BIAS;
            end

            // --------------------------------------------------
            // BF16 (16-bit)
            // sign[15] exp[14:7] frac[6:0]
            // --------------------------------------------------
            FMT_BF16: begin
                logic [BF16_E_BITS-1:0] exp_a = a[14:7];
                logic [BF16_E_BITS-1:0] exp_b = b[14:7];

                E_a = (exp_a == 0) ?
                        (1 - BF16_EXP_BIAS) :
                        (int'(exp_a) - BF16_EXP_BIAS);

                E_b = (exp_b == 0) ?
                        (1 - BF16_EXP_BIAS) :
                        (int'(exp_b) - BF16_EXP_BIAS);

                bias = BF16_EXP_BIAS;
            end

            // --------------------------------------------------
            // SINGLE (32-bit)
            // sign[31] exp[30:23] frac[22:0]
            // --------------------------------------------------
            FMT_SINGLE: begin
                logic [F32_E_BITS-1:0] exp_a = a[30:23];
                logic [F32_E_BITS-1:0] exp_b = b[30:23];

                E_a = (exp_a == 0) ?
                        (1 - F32_EXP_BIAS) :
                        (int'(exp_a) - F32_EXP_BIAS);

                E_b = (exp_b == 0) ?
                        (1 - F32_EXP_BIAS) :
                        (int'(exp_b) - F32_EXP_BIAS);

                bias = F32_EXP_BIAS;
            end

            // --------------------------------------------------
            // DOUBLE (64-bit)
            // sign[63] exp[62:52] frac[51:0]
            // --------------------------------------------------
            FMT_DOUBLE: begin
                logic [F64_E_BITS-1:0] exp_a = a[62:52];
                logic [F64_E_BITS-1:0] exp_b = b[62:52];

                E_a = (exp_a == 0) ?
                        (1 - F64_EXP_BIAS) :
                        (int'(exp_a) - F64_EXP_BIAS);

                E_b = (exp_b == 0) ?
                        (1 - F64_EXP_BIAS) :
                        (int'(exp_b) - F64_EXP_BIAS);

                bias = F64_EXP_BIAS;
            end

            // --------------------------------------------------
            // QUAD (128-bit)
            // sign[127] exp[126:112] frac[111:0]
            // --------------------------------------------------
            FMT_QUAD: begin
                logic [F128_E_BITS-1:0] exp_a = a[126:112];
                logic [F128_E_BITS-1:0] exp_b = b[126:112];

                E_a = (exp_a == 0) ?
                        (1 - F128_EXP_BIAS) :
                        (int'(exp_a) - F128_EXP_BIAS);

                E_b = (exp_b == 0) ?
                        (1 - F128_EXP_BIAS) :
                        (int'(exp_b) - F128_EXP_BIAS);

                bias = F128_EXP_BIAS;

            end

            default: begin
                return 0;
            end

        endcase

        return (E_a + E_b) + bias;

    endfunction

    function automatic int get_unbiased_exponent(
        input logic [127:0] input_val,
        input logic [7:0] fmt
    );

    int unbiased_exp;

    case (fmt)
            FMT_HALF: begin
                logic [F16_E_BITS-1:0] biased_exp = input_val[F16_E_UPPER:F16_E_LOWER];
                unbiased_exp = int'(biased_exp) - F16_EXP_BIAS;
            end
            FMT_BF16: begin
                logic [BF16_E_BITS-1:0] biased_exp = input_val[BF16_E_UPPER:BF16_E_LOWER];
                unbiased_exp = int'(biased_exp) - BF16_EXP_BIAS;
            end
            FMT_SINGLE: begin
                logic [F32_E_BITS-1:0] biased_exp = input_val[F32_E_UPPER:F32_E_LOWER];
                unbiased_exp = int'(biased_exp) - F32_EXP_BIAS;
            end
            FMT_DOUBLE: begin
                logic [F64_E_BITS-1:0] biased_exp = input_val[F64_E_UPPER:F64_E_LOWER];
                unbiased_exp = int'(biased_exp) - F64_EXP_BIAS;
            end
            FMT_QUAD: begin
                logic [F128_E_BITS-1:0] biased_exp = input_val[F128_E_UPPER:F128_E_LOWER];
                unbiased_exp = int'(biased_exp) - F128_EXP_BIAS;
            end

            default: begin
                return 0;
            end
    endcase
        return unbiased_exp;
    endfunction

    //returns the exponent values associated with each maxInt
    function automatic max_int_struct get_max_int(
        input logic [7:0] int_fmt
    );
    max_int_struct target_max_int;

    //Setting up the ranges based on the int format
    case(int_fmt)
        FMT_UINT: begin
            target_max_int.max_int_exp = (SIZEOF_INT - 1);//2^31
            target_max_int.max_int_mantissa = F128_M_BITS'({(SIZEOF_INT - 1){1'b1}}) << (UINT_TRAILING_ZEROS);//upper 31 bits are 1s, lower bits are 0s; 31 bits because of hidden 1
            target_max_int.one_quarter = F128_M_BITS'(1'b1) << (UINT_TRAILING_ZEROS - 2);//31 0s, 01
            target_max_int.one_half = F128_M_BITS'(1'b1) << (UINT_TRAILING_ZEROS - 1);//31 0s, 1
            target_max_int.three_quarters = F128_M_BITS'(2'b11) << (UINT_TRAILING_ZEROS - 2);//31 0s, 11
            target_max_int.one = F128_M_BITS'(1'b1) << UINT_TRAILING_ZEROS;//30 0s, 1
        end
        FMT_INT: begin
            target_max_int.max_int_exp = (SIZEOF_INT - 2);//2^30
            target_max_int.max_int_mantissa = F128_M_BITS'({(SIZEOF_INT - 2){1'b1}}) << (INT_TRAILING_ZEROS);//leading 0, next 31 bits are 1s, lower bits are 0s
            target_max_int.one_quarter = F128_M_BITS'(1'b1) << (INT_TRAILING_ZEROS - 2);//30 0s, 01
            target_max_int.one_half = F128_M_BITS'(1'b1) << (INT_TRAILING_ZEROS - 1);//30 0s, 1
            target_max_int.three_quarters = F128_M_BITS'(2'b11) << (INT_TRAILING_ZEROS - 2);//30 0s, 11
            target_max_int.one = F128_M_BITS'(1'b1) << INT_TRAILING_ZEROS;//30 0s, 1
        end
        FMT_ULONG: begin
            target_max_int.max_int_exp = (SIZEOF_LONG - 1);//2^63
            target_max_int.max_int_mantissa = F128_M_BITS'({(SIZEOF_LONG - 1){1'b1}}) << (ULONG_TRAILING_ZEROS);//upper 63 bits are 1s, lower bits are 0s
            target_max_int.one_quarter = F128_M_BITS'(1'b1) << (ULONG_TRAILING_ZEROS - 2);//63 0s, 01
            target_max_int.one_half = F128_M_BITS'(1'b1) << (ULONG_TRAILING_ZEROS - 1);//63 0s, 1
            target_max_int.three_quarters = F128_M_BITS'(2'b11) << (ULONG_TRAILING_ZEROS - 2);//63 0s, 11
            target_max_int.one = F128_M_BITS'(1'b1) << ULONG_TRAILING_ZEROS;//62 0s, 1
        end
        FMT_LONG: begin
            target_max_int.max_int_exp = (SIZEOF_LONG - 2);//2^62
            target_max_int.max_int_mantissa = F128_M_BITS'({(SIZEOF_LONG - 2){1'b1}}) << (LONG_TRAILING_ZEROS);//leading 0, upper 62 bits are 1s, lower bits are 0s
            target_max_int.one_quarter = F128_M_BITS'(1'b1) << (LONG_TRAILING_ZEROS - 2);//62 0s, 01
            target_max_int.one_half = F128_M_BITS'(1'b1) << (LONG_TRAILING_ZEROS - 1);//62 0s, 1
            target_max_int.three_quarters = F128_M_BITS'(2'b11) << (LONG_TRAILING_ZEROS - 2);//62 0s, 11
            target_max_int.one = F128_M_BITS'(1'b1) << LONG_TRAILING_ZEROS;//61 0s, 1
        end
        default: begin//fill everything with 0s if an unrecognized int_fmt
            target_max_int.max_int_exp = 0;
            target_max_int.max_int_mantissa = '0;
            target_max_int.one_quarter = '0;
            target_max_int.one_half = '0;
            target_max_int.three_quarters = '0;
            target_max_int.one = '0;
        end
    endcase
    return target_max_int;
    endfunction

    function automatic int get_proximity_to_max_int(
        input logic [127:0] input_val,
        input logic [7:0] fp_fmt,
        input logic [7:0] int_fmt
    );

    max_int_struct target_int = get_max_int(int_fmt);
    int input_exp = get_unbiased_exponent(input_val, fp_fmt);
    logic [111:0] input_mantissa = input_val[111:0];

    //Shift the double mantissa so the mantissa fills the upper bits
    //This allows for one comparison regardless of whether the input is double or quad
    if(fp_fmt == FMT_DOUBLE) begin
        input_mantissa = F128_M_BITS'(input_val[F64_M_UPPER:0]) << (F128_M_BITS - F64_M_BITS);
    end

    //Comparison, returns the number corresponding to the test that each condition satisfies
    if(input_exp == target_int.max_int_exp) begin
        if(input_mantissa == target_int.max_int_mantissa) begin
            return 1;//+-MaxInt
        end
        else if(input_mantissa > target_int.max_int_mantissa) begin
            if(input_mantissa <= (target_int.max_int_mantissa + target_int.one_quarter)) begin
                return 2;//+-MaxInt + (1/4)
            end
            else if(input_mantissa <= (target_int.max_int_mantissa + target_int.one_half)) begin
                return 3;//+-MaxInt + (1/2)
            end
            else if(input_mantissa <= (target_int.max_int_mantissa + target_int.three_quarters)) begin
                return 4;//+-MaxInt + (3/4)
            end
        end
        else if(input_mantissa < target_int.max_int_mantissa) begin
            if(input_mantissa >= (target_int.max_int_mantissa - target_int.one_quarter)) begin
                return 2;//+-MaxInt - (1/4)
            end
            else if(input_mantissa >= (target_int.max_int_mantissa - target_int.one_half)) begin
                return 3;//+-MaxInt - (1/2)
            end
            else if(input_mantissa >= (target_int.max_int_mantissa - target_int.three_quarters)) begin
                return 4;//+-MaxInt - (3/4)
            end
            else if(input_mantissa >= (target_int.max_int_mantissa - target_int.one)) begin
                return 5;//+-MaxInt - 1
            end
        end
    end
    else if (input_exp == target_int.max_int_exp + 1)begin
        if(input_mantissa == '0) begin
            return 5;//+- MaxInt + 1
        end
    end
    return 0;
    endfunction

    function automatic int get_proximity_to_zero(
        input logic [127:0] input_val,
        input logic [7:0]   fmt
    );

    int exp_bias;
    int unbiased_exp = get_unbiased_exponent(input_val, fmt);
    int m_bits;//the first bit in the mantissa is the msb, the last is the lsb. Below examples of the mantissa are half precision
    logic less_than_one_mantissa;// Checking if the value of the mantissa <= msb; mantissa = [0000_0000_00, 1000_0000_00]
    logic less_than_two_mantissa;// Checking if the value of the mantissa <= (msb/2); mantissa = [0000_0000_00, 0100_0000_00]
    logic less_than_three_mantissa;// Checking if the value of the mantissa <= (3msb/2); mantissa = [0000_0000_00, 1100_0000_00]
    logic zero_mantissa;// flag corresponding to whether the mantissa is all 0s; mantissa = 0000_0000_00

    case (fmt)
            FMT_HALF: begin
                exp_bias = F16_EXP_BIAS;
                less_than_one_mantissa = (input_val[F16_M_UPPER:0] <= 112'b1 << (F16_M_BITS - 1));// <= 1000_0000_00
                less_than_two_mantissa = (input_val[F16_M_UPPER:0] <= 112'b1 << (F16_M_BITS - 2));// <= 0100_0000_00
                less_than_three_mantissa = (input_val[F16_M_UPPER:0] <= 112'b11 << (F16_M_BITS - 2));// <= 1100_0000_00
                zero_mantissa = (input_val[F16_M_UPPER:0] == '0);
            end
            FMT_BF16: begin
                exp_bias = BF16_EXP_BIAS;
                less_than_one_mantissa = (input_val[BF16_M_UPPER:0] <= 112'b1 << (BF16_M_BITS - 1));
                less_than_two_mantissa = (input_val[BF16_M_UPPER:0] <= 112'b1 << (BF16_M_BITS - 2));
                less_than_three_mantissa = (input_val[BF16_M_UPPER:0] <= 112'b11 << (BF16_M_BITS - 2));
                zero_mantissa = (input_val[BF16_M_UPPER:0] == '0);
            end
            FMT_SINGLE: begin
                exp_bias = F32_EXP_BIAS;
                less_than_one_mantissa = (input_val[F32_M_UPPER:0] <= 112'b1 << (F32_M_BITS - 1));
                less_than_two_mantissa = (input_val[F32_M_UPPER:0] <= 112'b1 << (F32_M_BITS - 2));
                less_than_three_mantissa = (input_val[F32_M_UPPER:0] <= 112'b11 << (F32_M_BITS - 2));
                zero_mantissa = (input_val[F32_M_UPPER:0] == '0);
            end
            FMT_DOUBLE: begin
                exp_bias = F64_EXP_BIAS;
                less_than_one_mantissa = (input_val[F64_M_UPPER:0] <= 112'b1 << (F64_M_BITS - 1));
                less_than_two_mantissa = (input_val[F64_M_UPPER:0] <= 112'b1 << (F64_M_BITS - 2));
                less_than_three_mantissa = (input_val[F64_M_UPPER:0] <= 112'b11 << (F64_M_BITS - 2));
                zero_mantissa = (input_val[F64_M_UPPER:0] == '0);
            end
            FMT_QUAD: begin
                exp_bias = F128_EXP_BIAS;
                less_than_one_mantissa = (input_val[F128_M_UPPER:0] <= 112'b1 << (F128_M_BITS - 1));
                less_than_two_mantissa = (input_val[F128_M_UPPER:0] <= 112'b1 << (F128_M_BITS - 2));
                less_than_three_mantissa = (input_val[F128_M_UPPER:0] <= 112'b11 << (F128_M_BITS - 2));
                zero_mantissa = (input_val[F128_M_UPPER:0] == '0);
            end
            default: begin
                exp_bias = 0;
                less_than_one_mantissa = 0;
                less_than_two_mantissa = 0;
                less_than_three_mantissa = 0;
                zero_mantissa = 0;
            end
    endcase

    //return value corresponds to the test number number which is satisfied
    if((unbiased_exp == -exp_bias) && (zero_mantissa)) begin//0 must have all 0s unbiased exp and all 0s mantissa
        return 1;//+-0
    end
    else if(((unbiased_exp == -2) && (zero_mantissa)) || (unbiased_exp < -2)) begin//<= 2^-2
        return 2;//+-(1/4)
    end
    else if(((unbiased_exp == -1) && (zero_mantissa)) || (unbiased_exp < -1)) begin//<= 2^-1
        return 3;//+-(1/2)
    end
    else if((unbiased_exp == -1) && (less_than_one_mantissa)) begin//<= 2^-1 + 2^-2
        return 4;//+-(3/4)
    end
    else if(((unbiased_exp == 0) && (zero_mantissa)) || (unbiased_exp < 0)) begin//<= 2^0
        return 5;//+-1
    end
    else if(((unbiased_exp == 0) && (less_than_two_mantissa))) begin //<= 2^0 + 2^-2
        return 6;//+-(5/4)
    end
    else if(((unbiased_exp == 0) && (less_than_one_mantissa))) begin//<= 2^0 + 2^-1
        return 7;//+-(3/2)
    end
    else if(((unbiased_exp == 0) && (less_than_three_mantissa))) begin// <= 2^0 + 2^-1 + 2^-2
        return 8;//+-(7/4)
    end
    else begin
        return 0;//corresponds to no test number, will not satisfy the coverpoint
    end

    endfunction
function automatic int effective_exponent (
    input logic [255:0] val,
    input logic [7:0]   fmt
);

    int exp_field;
    logic [255:0] frac_field;

    int bias;
    int min_norm_exp;
    int frac_bits;

    int shift;

    // ----------------------------------------
    // Decode format + extract fields (CONST!)
    // ----------------------------------------
    case (fmt)

        FMT_HALF: begin
            exp_field    = val[F16_E_UPPER:F16_E_LOWER];
            frac_field   = val[F16_M_UPPER:0];
            bias         = F16_EXP_BIAS;
            min_norm_exp = F16_MIN_NORM_EXP;
            frac_bits    = F16_M_BITS;
        end

        FMT_BF16: begin
            exp_field    = val[BF16_E_UPPER:BF16_E_LOWER];
            frac_field   = val[BF16_M_UPPER:0];
            bias         = BF16_EXP_BIAS;
            min_norm_exp = BF16_MIN_NORM_EXP;
            frac_bits    = BF16_M_BITS;
        end

        FMT_SINGLE: begin
            exp_field    = val[F32_E_UPPER:F32_E_LOWER];
            frac_field   = val[F32_M_UPPER:0];
            bias         = F32_EXP_BIAS;
            min_norm_exp = F32_MIN_NORM_EXP;
            frac_bits    = F32_M_BITS;
        end

        FMT_DOUBLE: begin
            exp_field    = val[F64_E_UPPER:F64_E_LOWER];
            frac_field   = val[F64_M_UPPER:0];
            bias         = F64_EXP_BIAS;
            min_norm_exp = F64_MIN_NORM_EXP;
            frac_bits    = F64_M_BITS;
        end

        FMT_QUAD: begin
            exp_field    = val[F128_E_UPPER:F128_E_LOWER];
            frac_field   = val[F128_M_UPPER:0];
            bias         = F128_EXP_BIAS;
            min_norm_exp = F128_MIN_NORM_EXP;
            frac_bits    = F128_M_BITS;
        end

        default: begin
            return 0;
        end

    endcase

    // ----------------------------------------
    // Normal numbers
    // ----------------------------------------
    if (exp_field != 0) begin
        return exp_field - bias;
    end

  // ----------------------------------------
  // Zero
  // ----------------------------------------
  if (frac_field == 0) begin
      return min_norm_exp - frac_bits; // MIN_SUBNORM_EXP
  end

  // ----------------------------------------
  // Subnormal
  // ----------------------------------------
  shift = 0;
  for (int i = frac_bits-1; i >= 0; i--) begin
      if (frac_field[i] == 1'b0)
          shift++;
      else
          break;
  end

  return min_norm_exp - shift - 1;

endfunction

function automatic logic [127:0] effective_fraction (
    input logic [255:0] val,
    input logic [7:0]   fmt
);
    int frac_bits;
    int e_lower;
    int min_norm_exp;
    logic [127:0] frac_field;
    logic [127:0] mask;
    int exp_field;
    int shift = 0;

    // ---------------------------------------------
    // select format
    // ---------------------------------------------
    case (fmt)
        FMT_HALF: begin
            frac_bits    = F16_M_BITS;
            e_lower      = F16_E_LOWER;
            min_norm_exp = F16_MIN_NORM_EXP;
        end
        FMT_BF16: begin
            frac_bits    = BF16_M_BITS;
            e_lower      = BF16_E_LOWER;
            min_norm_exp = BF16_MIN_NORM_EXP;
        end
        FMT_SINGLE: begin
            frac_bits    = F32_M_BITS;
            e_lower      = F32_E_LOWER;
            min_norm_exp = F32_MIN_NORM_EXP;
        end
        FMT_DOUBLE: begin
            frac_bits    = F64_M_BITS;
            e_lower      = F64_E_LOWER;
            min_norm_exp = F64_MIN_NORM_EXP;
        end
        FMT_QUAD: begin
            frac_bits    = F128_M_BITS;
            e_lower      = F128_E_LOWER;
            min_norm_exp = F128_MIN_NORM_EXP;
        end
        default: begin
            frac_bits    = F32_M_BITS;
            e_lower      = F32_E_LOWER;
            min_norm_exp = F32_MIN_NORM_EXP;
        end
    endcase

    // ---------------------------------------------
    // mask fraction bits
    // ---------------------------------------------
    mask = (128'b1 << frac_bits) - 1;
    frac_field = val & mask;

    // ---------------------------------------------
    // extract exponent
    // ---------------------------------------------
    exp_field = (val >> e_lower) & ((1 << (frac_bits + 1)) - 1); // any exponent width

    // ---------------------------------------------
    // normal number → return fraction as-is
    // ---------------------------------------------
    if (exp_field != 0)
        return frac_field;

    // ---------------------------------------------
    // subnormal → shift fraction left until MSB=1
    // mask off any bits that shift past width
    // ---------------------------------------------
    for (int i = frac_bits-1; i >= 0; i--) begin
        if (frac_field[i] == 0)
            shift++;
        else
            break;
    end
    shift++; // shift out leading 1 from fraction

    // shift, then mask to ensure it stays within frac_bits
    return (frac_field << shift) & mask;
endfunction


endpackage
