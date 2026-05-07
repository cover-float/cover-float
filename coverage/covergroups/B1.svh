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

covergroup B1_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;

    /************************************************************************

    Operation format helper coverpoints

    ************************************************************************/

    FP_result_ops: coverpoint CFI.op {
        type_option.weight = 0;
        // all operations that produce (arbitrary) FP results
        `include "bins_templates/FP_result_op_bins.svh"
    }

    FP_src1_ops: coverpoint CFI.op {
        type_option.weight = 0;
        // all operations where the first operand is FP
        `include "bins_templates/FP_src1_op_bins.svh"
    }

    FP_src2_ops: coverpoint CFI.op {
        type_option.weight = 0;
        // all operations where the second operand is FP
        `include "bins_templates/FP_src2_op_bins.svh"
    }

    FP_src3_ops: coverpoint CFI.op {
        type_option.weight = 0;
        // all operations where the third operand is FP
        `include "bins_templates/FP_src3_op_bins.svh"
    }

    FP_convert_fmt: coverpoint CFI.resultFmt {
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

        bins fmt_int    = {FMT_INT};
        bins fmt_uint   = {FMT_UINT};

        `ifdef COVER_LONG
            bins fmt_long  = {FMT_LONG};
            bins fmt_ulong = {FMT_ULONG};
        `endif // COVER_LONG
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

    /************************************************************************

    Single precision helper coverpoints

    ************************************************************************/

    F32_src_fmt: coverpoint CFI.operandFmt == FMT_SINGLE {
        type_option.weight = 0;
        // single precision format for operands
        bins f32 = {1};
    }

    F32_result_fmt: coverpoint CFI.resultFmt == FMT_SINGLE {
        type_option.weight = 0;
        // single precision format for result
        bins f32 = {1};
    }

    F32_src1_basictypes: coverpoint CFI.a[31:0] {
        type_option.weight = 0;
        `include "bins_templates/F32_basic_types_bins.svh"
    }

    F32_src2_basictypes: coverpoint CFI.b[31:0] {
        type_option.weight = 0;
        `include "bins_templates/F32_basic_types_bins.svh"
    }

    F32_src3_basictypes: coverpoint CFI.c[31:0] {
        type_option.weight = 0;
        `include "bins_templates/F32_basic_types_bins.svh"
    }

    F32_result_basictypes: coverpoint CFI.result[31:0] {
        type_option.weight = 0;
        // Ignore NaN bins in the basic types bin templates since non-cannonical nans cant be produces
        `define IGNORE_NANS
        `include "bins_templates/F32_basic_types_bins.svh"
        `undef  IGNORE_NANS
    }


    /************************************************************************

    Double precision helper coverpoints

    ************************************************************************/

    F64_src_fmt: coverpoint CFI.operandFmt == FMT_DOUBLE {
        type_option.weight = 0;
        // double precision format for operands
        bins f64 = {1};
    }

    F64_result_fmt: coverpoint CFI.resultFmt == FMT_DOUBLE {
        type_option.weight = 0;
        // double precision format for result
        bins f64 = {1};
    }

    F64_src1_basictypes: coverpoint CFI.a[63:0] {
        type_option.weight = 0;
        `include "bins_templates/F64_basic_types_bins.svh"
    }

    F64_src2_basictypes: coverpoint CFI.b[63:0] {
        type_option.weight = 0;
        `include "bins_templates/F64_basic_types_bins.svh"
    }

    F64_src3_basictypes: coverpoint CFI.c[63:0] {
        type_option.weight = 0;
        `include "bins_templates/F64_basic_types_bins.svh"
    }

    F64_result_basictypes: coverpoint CFI.result[63:0] {
        type_option.weight = 0;
        // Ignore NaN bins in the basic types bin templates since non-cannonical nans cant be produces
        `define IGNORE_NANS
        `include "bins_templates/F64_basic_types_bins.svh"
        `undef IGNORE_BINS
    }


    /************************************************************************

    Half precision helper coverpoints

    ************************************************************************/

    F16_src_fmt: coverpoint CFI.operandFmt == FMT_HALF {
        type_option.weight = 0;
        // half precision format for operands
        bins f16 = {1};
    }

    F16_result_fmt: coverpoint CFI.resultFmt == FMT_HALF {
        type_option.weight = 0;
        // half precision format for result
        bins f16 = {1};
    }

    F16_src1_basictypes: coverpoint CFI.a[15:0] {
        type_option.weight = 0;
        `include "bins_templates/F16_basic_types_bins.svh"
    }

    F16_src2_basictypes: coverpoint CFI.b[15:0] {
        type_option.weight = 0;
        `include "bins_templates/F16_basic_types_bins.svh"
    }

    F16_src3_basictypes: coverpoint CFI.c[15:0] {
        type_option.weight = 0;
        `include "bins_templates/F16_basic_types_bins.svh"
    }

    F16_result_basictypes: coverpoint CFI.result[15:0] {
        type_option.weight = 0;
        // Ignore NaN bins in the basic types bin templates since non-cannonical nans cant be produces
        `define IGNORE_NANS
        `include "bins_templates/F16_basic_types_bins.svh"
        `undef IGNORE_NANS
    }


    /************************************************************************

    BFloat16 truncated single precision helper coverpoints

    ************************************************************************/

    BF16_src_fmt: coverpoint CFI.operandFmt == FMT_BF16 {
        type_option.weight = 0;
        // BF16 precision format for operands
        bins bf16 = {1};
    }

    BF16_result_fmt: coverpoint CFI.resultFmt == FMT_BF16 {
        type_option.weight = 0;
        // BF16 precision format for result
        bins bf16 = {1};
    }

    BF16_src1_basictypes: coverpoint CFI.a[15:0] {
        type_option.weight = 0;
        `include "bins_templates/BF16_basic_types_bins.svh"
    }

    BF16_src2_basictypes: coverpoint CFI.b[15:0] {
        type_option.weight = 0;
        `include "bins_templates/BF16_basic_types_bins.svh"
    }

    BF16_src3_basictypes: coverpoint CFI.c[15:0] {
        type_option.weight = 0;
        `include "bins_templates/BF16_basic_types_bins.svh"
    }

    BF16_result_basictypes: coverpoint CFI.result[15:0] {
        type_option.weight = 0;
        // Ignore NaN bins in the basic types bin templates since non-cannonical nans cant be produces
        `define IGNORE_NANS
        `include "bins_templates/BF16_basic_types_bins.svh"
        `undef IGNORE_NANS
    }


    /************************************************************************

    Quad precision helper coverpoints

    ************************************************************************/

    F128_src_fmt: coverpoint CFI.operandFmt == FMT_QUAD {
        type_option.weight = 0;
        // quad precision format for operands
        bins f128 = {1};
    }

    F128_result_fmt: coverpoint CFI.resultFmt == FMT_QUAD {
        type_option.weight = 0;
        // quad precision format for result
        bins f128 = {1};
    }

    F128_src1_basictypes: coverpoint CFI.a[127:0] {
        type_option.weight = 0;
        `include "bins_templates/F128_basic_types_bins.svh"
    }

    F128_src2_basictypes: coverpoint CFI.b[127:0] {
        type_option.weight = 0;
        `include "bins_templates/F128_basic_types_bins.svh"
    }

    F128_src3_basictypes: coverpoint CFI.c[127:0] {
        type_option.weight = 0;
        `include "bins_templates/F128_basic_types_bins.svh"
    }

    F128_result_basictypes: coverpoint CFI.result[127:0] {
        type_option.weight = 0;
        // Ignore NaN bins in the basic types bin templates since non-cannonical nans cant be produces
        `define IGNORE_NANS
        `include "bins_templates/F128_basic_types_bins.svh"
        `undef IGNORE_NANS
    }


    /************************************************************************

    Main coverpoints

    ************************************************************************/

    `ifdef COVER_F32
        B1_F32_1_operands: cross FP_src1_ops,   F32_src1_basictypes,                                           F32_src_fmt;
        B1_F32_2_operands: cross FP_src2_ops,   F32_src1_basictypes, F32_src2_basictypes,                      F32_src_fmt;
        B1_F32_3_operands: cross FP_src3_ops,   F32_src1_basictypes, F32_src2_basictypes, F32_src3_basictypes, F32_src_fmt;
        B1_F32_result:     cross FP_result_ops, F32_result_basictypes,                                         F32_result_fmt {
            ignore_bins negative_sqrt = binsof(FP_result_ops.op_sqrt) with (F32_result_basictypes[31] == 1'b1);
            // ignore_bins posinf_rem    = binsof(F32_result_basictypes.posinfinity) with (FP_result_ops == OP_REM);
            // ignore_bins neginf_rem    = binsof(F32_result_basictypes.neginfinity) with (FP_result_ops == OP_REM);
        }
        B1_F32_convert:    cross FP_convert_ops, F32_src1_basictypes, FP_convert_fmt,                          F32_src_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_single);
        }
    `endif // COVER_F32

    `ifdef COVER_F64
        B1_F64_1_operands: cross FP_src1_ops,   F64_src1_basictypes,                                           F64_src_fmt;
        B1_F64_2_operands: cross FP_src2_ops,   F64_src1_basictypes, F64_src2_basictypes,                      F64_src_fmt;
        B1_F64_3_operands: cross FP_src3_ops,   F64_src1_basictypes, F64_src2_basictypes, F64_src3_basictypes, F64_src_fmt;
        B1_F64_result:     cross FP_result_ops, F64_result_basictypes,                                         F64_result_fmt {
            ignore_bins negative_sqrt = binsof(FP_result_ops.op_sqrt) with (F64_result_basictypes[63] == 1'b1);
            // ignore_bins posinf_rem    = binsof(F64_result_basictypes.posinfinity) with (FP_result_ops == OP_REM);
            // ignore_bins neginf_rem    = binsof(F64_result_basictypes.neginfinity) with (FP_result_ops == OP_REM);
        }
        B1_F64_convert:    cross FP_convert_ops, F64_src1_basictypes, FP_convert_fmt,                          F64_src_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_double);
        }
    `endif // COVER_F64

    `ifdef COVER_F16
        B1_F16_1_operands: cross FP_src1_ops,   F16_src1_basictypes,                                           F16_src_fmt;
        B1_F16_2_operands: cross FP_src2_ops,   F16_src1_basictypes, F16_src2_basictypes,                      F16_src_fmt;
        B1_F16_3_operands: cross FP_src3_ops,   F16_src1_basictypes, F16_src2_basictypes, F16_src3_basictypes, F16_src_fmt;
        B1_F16_result:     cross FP_result_ops, F16_result_basictypes,                                         F16_result_fmt {
            ignore_bins negative_sqrt = binsof(FP_result_ops.op_sqrt) with (F16_result_basictypes[15] == 1'b1);
            // ignore_bins posinf_rem    = binsof(F16_result_basictypes.posinfinity) with (FP_result_ops == OP_REM);
            // ignore_bins neginf_rem    = binsof(F16_result_basictypes.neginfinity) with (FP_result_ops == OP_REM);
        }
        B1_F16_convert:    cross FP_convert_ops, F16_src1_basictypes, FP_convert_fmt,                          F16_src_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_half);
        }
    `endif // COVER_F16

    `ifdef COVER_BF16
        B1_BF16_1_operands: cross FP_src1_ops,   BF16_src1_basictypes,                                             BF16_src_fmt;
        B1_BF16_2_operands: cross FP_src2_ops,   BF16_src1_basictypes, BF16_src2_basictypes,                       BF16_src_fmt;
        B1_BF16_3_operands: cross FP_src3_ops,   BF16_src1_basictypes, BF16_src2_basictypes, BF16_src3_basictypes, BF16_src_fmt;
        B1_BF16_result:     cross FP_result_ops, BF16_result_basictypes,                                           BF16_result_fmt {
            ignore_bins negative_sqrt = binsof(FP_result_ops.op_sqrt) with (BF16_result_basictypes[15] == 1'b1);
            // ignore_bins posinf_rem    = binsof(BF16_result_basictypes.posinfinity) with (FP_result_ops == OP_REM);
            // ignore_bins neginf_rem    = binsof(BF16_result_basictypes.neginfinity) with (FP_result_ops == OP_REM);
        }
        B1_BF16_convert:    cross FP_convert_ops, BF16_src1_basictypes, FP_convert_fmt,                            BF16_src_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_bf16);
        }
    `endif // COVER_BF16


    `ifdef COVER_F128
        B1_F128_1_operands: cross FP_src1_ops,   F128_src1_basictypes,                                             F128_src_fmt;
        B1_F128_2_operands: cross FP_src2_ops,   F128_src1_basictypes, F128_src2_basictypes,                       F128_src_fmt;
        B1_F128_3_operands: cross FP_src3_ops,   F128_src1_basictypes, F128_src2_basictypes, F128_src3_basictypes, F128_src_fmt;
        B1_F128_result:     cross FP_result_ops, F128_result_basictypes,                                           F128_result_fmt {
            ignore_bins negative_sqrt = binsof(FP_result_ops.op_sqrt) with (F128_result_basictypes[127] == 1'b1);
            // ignore_bins posinf_rem    = binsof(F128_result_basictypes.posinfinity) with (FP_result_ops == OP_REM);
            // ignore_bins neginf_rem    = binsof(F128_result_basictypes.neginfinity) with (FP_result_ops == OP_REM);
        }
        B1_F128_convert:    cross FP_convert_ops, F128_src1_basictypes, FP_convert_fmt,                            F128_src_fmt {
            ignore_bins invalid_convert = binsof(FP_convert_fmt.fmt_quad);
        }
    `endif // COVER_F128

endgroup
