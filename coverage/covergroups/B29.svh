covergroup B29_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;

    F16_input_fmt: coverpoint (CFI.operandFmt == FMT_HALF) {
        type_option.weight = 0;
        bins f16 = {1};
    }

    BF16_input_fmt: coverpoint (CFI.operandFmt == FMT_BF16) {
        type_option.weight = 0;
        bins bf16 = {1};
    }

    F32_input_fmt: coverpoint (CFI.operandFmt == FMT_SINGLE) {
        type_option.weight = 0;
        bins f32 = {1};
    }

    F64_input_fmt: coverpoint (CFI.operandFmt == FMT_DOUBLE) {
        type_option.weight = 0;
        bins f64 = {1};
    }

    F128_input_fmt: coverpoint (CFI.operandFmt == FMT_QUAD) {
        type_option.weight = 0;
        bins f128 = {1};
    }
    // RFI Instruction

    RFI_op: coverpoint CFI.op {
        type_option.weight = 0;
        bins rfi = { OP_RFI };
    }

    rounding_mode_all: coverpoint CFI.rm {
        type_option.weight = 0;
        bins round_near_even   = {ROUND_NEAR_EVEN};
        bins round_minmag      = {ROUND_MINMAG};
        bins round_min         = {ROUND_MIN};
        bins round_max         = {ROUND_MAX};
        bins round_near_maxmag = {ROUND_NEAR_MAXMAG};
    }

    F32_sign: coverpoint CFI.result[31] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F64_sign: coverpoint CFI.result[63] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F128_sign: coverpoint CFI.result[127] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    F16_sign: coverpoint CFI.result[15] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    BF16_sign: coverpoint CFI.result[15] {
        type_option.weight = 0;
        bins pos = {0};
        bins neg = {1};
    }

    BF16_LGS_Combos: coverpoint {
        CFI.a[BF16_M_UPPER - $signed(get_unbiased_exponent(CFI.a, FMT_BF16)) + 1],
        CFI.a[BF16_M_UPPER - $signed(get_unbiased_exponent(CFI.a, FMT_BF16))],
        |(CFI.a & ((64'b1 << (BF16_M_UPPER - $signed(get_unbiased_exponent(CFI.a, FMT_BF16)))) - 1))
        } {
        type_option.weight = 0;
        bins lgs_combos[] = {[3'b000 : 3'b111]};
    }

    F16_LGS_Combos: coverpoint {
        CFI.a[F16_M_UPPER - $signed(get_unbiased_exponent(CFI.a, FMT_HALF)) + 1],
        CFI.a[F16_M_UPPER - $signed(get_unbiased_exponent(CFI.a, FMT_HALF))],
        |(CFI.a & ((64'b1 << (F16_M_UPPER - $signed(get_unbiased_exponent(CFI.a, FMT_HALF)))) - 1))
        } {
        type_option.weight = 0;
        bins lgs_combos[] = {[3'b000 : 3'b111]};
    }

    F32_LGS_Combos: coverpoint {
        CFI.a[F32_M_UPPER - $signed(get_unbiased_exponent(CFI.a, FMT_SINGLE)) + 1],
        CFI.a[F32_M_UPPER - $signed(get_unbiased_exponent(CFI.a, FMT_SINGLE))],
        |(CFI.a & ((64'b1 << (F32_M_UPPER - $signed(get_unbiased_exponent(CFI.a, FMT_SINGLE)))) - 1))
        } {
        type_option.weight = 0;
        bins lgs_combos[] = {[3'b000 : 3'b111]};
    }


    F64_LGS_Combos: coverpoint {
        CFI.a[F64_M_UPPER - $signed(get_unbiased_exponent(CFI.a, FMT_DOUBLE)) + 1],
        CFI.a[F64_M_UPPER - $signed(get_unbiased_exponent(CFI.a, FMT_DOUBLE))],
        |(CFI.a & ((64'b1 << (F64_M_UPPER - $signed(get_unbiased_exponent(CFI.a, FMT_DOUBLE)))) - 1))
        } {
        type_option.weight = 0;
        bins lgs_combos[] = {[3'b000 : 3'b111]};
    }

    F128_LGS_Combos: coverpoint {
        CFI.a[F128_M_UPPER - $signed(get_unbiased_exponent(CFI.a, FMT_QUAD)) + 1],
        CFI.a[F128_M_UPPER - $signed(get_unbiased_exponent(CFI.a, FMT_QUAD))],
        |(CFI.a & ((64'b1 << (F128_M_UPPER - $signed(get_unbiased_exponent(CFI.a, FMT_QUAD)))) - 1))
        } {
        type_option.weight = 0;
        bins lgs_combos[] = {[3'b000 : 3'b111]};
    }

    `ifdef COVER_F32
        B5_F32_LGS: cross F32_sign, RFI_op, F32_input_fmt, F32_LGS_Combos, rounding_mode_all;
    `endif

    `ifdef COVER_F64
        B5_F64_LGS: cross F64_sign, RFI_op, F64_input_fmt, F64_LGS_Combos, rounding_mode_all;
    `endif

    `ifdef COVER_F128
        B5_F128_LGS: cross F128_sign, RFI_op, F128_input_fmt, F128_LGS_Combos, rounding_mode_all;
    `endif

    `ifdef COVER_F16
        B5_F16_LGS: cross F16_sign, RFI_op, F16_input_fmt, F16_LGS_Combos, rounding_mode_all;
    `endif

    `ifdef COVER_BF16
        B5_BF16_LGS: cross BF16_sign, RFI_op, BF16_input_fmt, BF16_LGS_Combos, rounding_mode_all;
    `endif

endgroup
