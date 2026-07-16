covergroup B19_cg (virtual coverfloat_interface CFI);

    option.per_instance = 0;

    FP_compare_ops: coverpoint CFI.op {
        type_option.weight = 0;

        bins min = {OP_MIN};
        bins max = {OP_MAX};
        bins feq = {OP_FEQ};
        bins flt = {OP_FLT};
        bins fle = {OP_FLE};
    }


    F16_result_fmt: coverpoint CFI.resultFmt == FMT_HALF {
        type_option.weight = 0;
        // half precision format for result
        bins f16 = {1};
    }

    F16_operand_a_sign: coverpoint CFI.a[F16_SIGN_BIT] {
        type_option.weight = 0;

        bins pos = {0};
        bins neg = {1};
    }

    F16_operand_b_sign: coverpoint CFI.b[F16_SIGN_BIT] {
        type_option.weight = 0;

        bins pos = {0};
        bins neg = {1};
    }

    F16_a_norm: coverpoint (CFI.a[F16_E_UPPER : F16_E_LOWER] != 0 && CFI.a[F16_E_UPPER : F16_E_LOWER] != '1) {
        type_option.weight = 0;

        bins normal = {1};
    }

    F16_b_norm: coverpoint (CFI.b[F16_E_UPPER : F16_E_LOWER] != 0 && CFI.b[F16_E_UPPER : F16_E_LOWER] != '1) {
        type_option.weight = 0;

        bins normal = {1};
    }

    F16_a_subnorm: coverpoint (CFI.a[F16_E_UPPER : F16_E_LOWER] == 0 && CFI.a[F16_M_BITS-1 : 0] != 0) {
        type_option.weight = 0;

        bins subnormal = {1};
    }

    F16_b_subnorm: coverpoint (CFI.b[F16_E_UPPER : F16_E_LOWER] == 0 && CFI.b[F16_M_BITS-1 : 0] != 0) {
        type_option.weight = 0;

        bins subnormal = {1};
    }

    F16_a_zero: coverpoint (CFI.a[F16_E_UPPER : 0] == 0) {
        type_option.weight = 0;

        bins zero = {1};
    }

    F16_b_zero: coverpoint (CFI.b[F16_E_UPPER : 0] == 0) {
        type_option.weight = 0;

        bins zero = {1};
    }

    F16_exp_compare: coverpoint $signed(
        (effective_exponent(CFI.a, FMT_HALF)
        - effective_exponent(CFI.b, FMT_HALF)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        bins eq = {0};
        bins gt = {[1 : $]};

    }

    F16_frac_compare: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_HALF)
        - effective_fraction(CFI.b, FMT_HALF)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        bins eq = {0};
        bins gt = {[1 : $]};

    }

    F16_frac_LTE: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_HALF)
        - effective_fraction(CFI.b, FMT_HALF)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        bins eq = {0};
        // bins gt = {[1 : $]};

    }

    F16_frac_GTE: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_HALF)
        - effective_fraction(CFI.b, FMT_HALF)))  {
        type_option.weight = 0;

        // bins lt = {[$ : -1]};
        bins eq = {0};
        bins gt = {[1 : $]};

    }

    F16_frac_LT: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_HALF)
        - effective_fraction(CFI.b, FMT_HALF)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        // bins eq = {0};
        // bins gt = {[1 : $]};

    }

    F16_frac_GT: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_HALF)
        - effective_fraction(CFI.b, FMT_HALF)))  {
        type_option.weight = 0;

        // bins lt = {[$ : -1]};
        // bins eq = {0};
        bins gt = {[1 : $]};

    }


    BF16_result_fmt: coverpoint CFI.resultFmt == FMT_BF16 {
        type_option.weight = 0;
        // BF16 precision format for result
        bins bf16 = {1};
    }

    BF16_operand_a_sign: coverpoint CFI.a[BF16_SIGN_BIT] {
        type_option.weight = 0;

        bins pos = {0};
        bins neg = {1};
    }

    BF16_operand_b_sign: coverpoint CFI.b[BF16_SIGN_BIT] {
        type_option.weight = 0;

        bins pos = {0};
        bins neg = {1};
    }

    BF16_a_norm: coverpoint (CFI.a[BF16_E_UPPER : BF16_E_LOWER] != 0 && CFI.a[BF16_E_UPPER : BF16_E_LOWER] != '1) {
        type_option.weight = 0;

        bins normal = {1};
    }

    BF16_b_norm: coverpoint (CFI.b[BF16_E_UPPER : BF16_E_LOWER] != 0 && CFI.b[BF16_E_UPPER : BF16_E_LOWER] != '1) {
        type_option.weight = 0;

        bins normal = {1};
    }

    BF16_a_subnorm: coverpoint (CFI.a[BF16_E_UPPER : BF16_E_LOWER] == 0 && CFI.a[BF16_M_BITS-1 : 0] != 0) {
        type_option.weight = 0;

        bins subnormal = {1};
    }

    BF16_b_subnorm: coverpoint (CFI.b[BF16_E_UPPER : BF16_E_LOWER] == 0 && CFI.b[BF16_M_BITS-1 : 0] != 0) {
        type_option.weight = 0;

        bins subnormal = {1};
    }

    BF16_a_zero: coverpoint (CFI.a[BF16_E_UPPER : 0] == 0) {
        type_option.weight = 0;

        bins zero = {1};
    }

    BF16_b_zero: coverpoint (CFI.b[BF16_E_UPPER : 0] == 0) {
        type_option.weight = 0;

        bins zero = {1};
    }

    BF16_exp_compare: coverpoint $signed(
        (effective_exponent(CFI.a, FMT_BF16)
        - effective_exponent(CFI.b, FMT_BF16)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        bins eq = {0};
        bins gt = {[1 : $]};

    }

    BF16_frac_compare: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_BF16)
        - effective_fraction(CFI.b, FMT_BF16)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        bins eq = {0};
        bins gt = {[1 : $]};

    }

    BF16_frac_LTE: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_BF16)
        - effective_fraction(CFI.b, FMT_BF16)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        bins eq = {0};
        // bins gt = {[1 : $]};

    }

    BF16_frac_GTE: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_BF16)
        - effective_fraction(CFI.b, FMT_BF16)))  {
        type_option.weight = 0;

        // bins lt = {[$ : -1]};
        bins eq = {0};
        bins gt = {[1 : $]};

    }

    BF16_frac_LT: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_BF16)
        - effective_fraction(CFI.b, FMT_BF16)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        // bins eq = {0};
        // bins gt = {[1 : $]};

    }

    BF16_frac_GT: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_BF16)
        - effective_fraction(CFI.b, FMT_BF16)))  {
        type_option.weight = 0;

        // bins lt = {[$ : -1]};
        // bins eq = {0};
        bins gt = {[1 : $]};

    }

    F32_result_fmt: coverpoint CFI.resultFmt == FMT_SINGLE {
        type_option.weight = 0;
        // single precision format for result
        bins f32 = {1};
    }

    F32_operand_a_sign: coverpoint CFI.a[F32_SIGN_BIT] {
        type_option.weight = 0;

        bins pos = {0};
        bins neg = {1};
    }

    F32_operand_b_sign: coverpoint CFI.b[F32_SIGN_BIT] {
        type_option.weight = 0;

        bins pos = {0};
        bins neg = {1};
    }

    F32_a_norm: coverpoint (CFI.a[F32_E_UPPER : F32_E_LOWER] != 0 && CFI.a[F32_E_UPPER : F32_E_LOWER] != '1) {
        type_option.weight = 0;

        bins normal = {1};
    }

    F32_b_norm: coverpoint (CFI.b[F32_E_UPPER : F32_E_LOWER] != 0 && CFI.b[F32_E_UPPER : F32_E_LOWER] != '1) {
        type_option.weight = 0;

        bins normal = {1};
    }

    F32_a_subnorm: coverpoint (CFI.a[F32_E_UPPER : F32_E_LOWER] == 0 && CFI.a[F32_M_BITS-1 : 0] != 0) {
        type_option.weight = 0;

        bins subnormal = {1};
    }

    F32_b_subnorm: coverpoint (CFI.b[F32_E_UPPER : F32_E_LOWER] == 0 && CFI.b[F32_M_BITS-1 : 0] != 0) {
        type_option.weight = 0;

        bins subnormal = {1};
    }

    F32_a_zero: coverpoint (CFI.a[F32_E_UPPER : 0] == 0) {
        type_option.weight = 0;

        bins zero = {1};
    }

    F32_b_zero: coverpoint (CFI.b[F32_E_UPPER : 0] == 0) {
        type_option.weight = 0;

        bins zero = {1};
    }

    F32_exp_compare: coverpoint $signed(
        (effective_exponent(CFI.a, FMT_SINGLE)
        - effective_exponent(CFI.b, FMT_SINGLE)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        bins eq = {0};
        bins gt = {[1 : $]};

    }

    F32_frac_compare: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_SINGLE)
        - effective_fraction(CFI.b, FMT_SINGLE)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        bins eq = {0};
        bins gt = {[1 : $]};

    }

    F32_frac_LTE: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_SINGLE)
        - effective_fraction(CFI.b, FMT_SINGLE)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        bins eq = {0};
        // bins gt = {[1 : $]};

    }

    F32_frac_GTE: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_SINGLE)
        - effective_fraction(CFI.b, FMT_SINGLE)))  {
        type_option.weight = 0;

        // bins lt = {[$ : -1]};
        bins eq = {0};
        bins gt = {[1 : $]};

    }

    F32_frac_LT: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_SINGLE)
        - effective_fraction(CFI.b, FMT_SINGLE)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        // bins eq = {0};
        // bins gt = {[1 : $]};

    }

    F32_frac_GT: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_SINGLE)
        - effective_fraction(CFI.b, FMT_SINGLE)))  {
        type_option.weight = 0;

        // bins lt = {[$ : -1]};
        // bins eq = {0};
        bins gt = {[1 : $]};

    }


    F64_result_fmt: coverpoint CFI.resultFmt == FMT_DOUBLE {
        type_option.weight = 0;
        // double precision format for result
        bins F64 = {1};
    }

    F64_operand_a_sign: coverpoint CFI.a[F64_SIGN_BIT] {
        type_option.weight = 0;

        bins pos = {0};
        bins neg = {1};
    }

    F64_operand_b_sign: coverpoint CFI.b[F64_SIGN_BIT] {
        type_option.weight = 0;

        bins pos = {0};
        bins neg = {1};
    }

    F64_a_norm: coverpoint (CFI.a[F64_E_UPPER : F64_E_LOWER] != 0 && CFI.a[F64_E_UPPER : F64_E_LOWER] != '1) {
        type_option.weight = 0;

        bins normal = {1};
    }

    F64_b_norm: coverpoint (CFI.b[F64_E_UPPER : F64_E_LOWER] != 0 && CFI.b[F64_E_UPPER : F64_E_LOWER] != '1) {
        type_option.weight = 0;

        bins normal = {1};
    }

    F64_a_subnorm: coverpoint (CFI.a[F64_E_UPPER : F64_E_LOWER] == 0 && CFI.a[F64_M_BITS-1 : 0] != 0) {
        type_option.weight = 0;

        bins subnormal = {1};
    }

    F64_b_subnorm: coverpoint (CFI.b[F64_E_UPPER : F64_E_LOWER] == 0 && CFI.b[F64_M_BITS-1 : 0] != 0) {
        type_option.weight = 0;

        bins subnormal = {1};
    }

    F64_a_zero: coverpoint (CFI.a[F64_E_UPPER : 0] == 0) {
        type_option.weight = 0;

        bins zero = {1};
    }

    F64_b_zero: coverpoint (CFI.b[F64_E_UPPER : 0] == 0) {
        type_option.weight = 0;

        bins zero = {1};
    }

    F64_exp_compare: coverpoint $signed(
        (effective_exponent(CFI.a, FMT_DOUBLE)
        - effective_exponent(CFI.b, FMT_DOUBLE)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        bins eq = {0};
        bins gt = {[1 : $]};

    }

    F64_frac_compare: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_DOUBLE)
        - effective_fraction(CFI.b, FMT_DOUBLE)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        bins eq = {0};
        bins gt = {[1 : $]};

    }

    F64_frac_LTE: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_DOUBLE)
        - effective_fraction(CFI.b, FMT_DOUBLE)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        bins eq = {0};
        // bins gt = {[1 : $]};

    }

    F64_frac_GTE: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_DOUBLE)
        - effective_fraction(CFI.b, FMT_DOUBLE)))  {
        type_option.weight = 0;

        // bins lt = {[$ : -1]};
        bins eq = {0};
        bins gt = {[1 : $]};

    }

    F64_frac_LT: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_DOUBLE)
        - effective_fraction(CFI.b, FMT_DOUBLE)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        // bins eq = {0};
        // bins gt = {[1 : $]};

    }

    F64_frac_GT: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_DOUBLE)
        - effective_fraction(CFI.b, FMT_DOUBLE)))  {
        type_option.weight = 0;

        // bins lt = {[$ : -1]};
        // bins eq = {0};
        bins gt = {[1 : $]};

    }


    F128_result_fmt: coverpoint CFI.resultFmt == FMT_QUAD {
        type_option.weight = 0;
        // quad precision format for result
        bins F128 = {1};
    }

    F128_operand_a_sign: coverpoint CFI.a[F128_SIGN_BIT] {
        type_option.weight = 0;

        bins pos = {0};
        bins neg = {1};
    }

    F128_operand_b_sign: coverpoint CFI.b[F128_SIGN_BIT] {
        type_option.weight = 0;

        bins pos = {0};
        bins neg = {1};
    }

    F128_a_norm: coverpoint (CFI.a[F128_E_UPPER : F128_E_LOWER] != 0 && CFI.a[F128_E_UPPER : F128_E_LOWER] != '1) {
        type_option.weight = 0;

        bins normal = {1};
    }

    F128_b_norm: coverpoint (CFI.b[F128_E_UPPER : F128_E_LOWER] != 0 && CFI.b[F128_E_UPPER : F128_E_LOWER] != '1) {
        type_option.weight = 0;

        bins normal = {1};
    }

    F128_a_subnorm: coverpoint (CFI.a[F128_E_UPPER : F128_E_LOWER] == 0 && CFI.a[F128_M_BITS-1 : 0] != 0) {
        type_option.weight = 0;

        bins subnormal = {1};
    }

    F128_b_subnorm: coverpoint (CFI.b[F128_E_UPPER : F128_E_LOWER] == 0 && CFI.b[F128_M_BITS-1 : 0] != 0) {
        type_option.weight = 0;

        bins subnormal = {1};
    }

    F128_a_zero: coverpoint (CFI.a[F128_E_UPPER : 0] == 0) {
        type_option.weight = 0;

        bins zero = {1};
    }

    F128_b_zero: coverpoint (CFI.b[F128_E_UPPER : 0] == 0) {
        type_option.weight = 0;

        bins zero = {1};
    }

    F128_exp_compare: coverpoint $signed(
        (effective_exponent(CFI.a, FMT_QUAD)
        - effective_exponent(CFI.b, FMT_QUAD)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        bins eq = {0};
        bins gt = {[1 : $]};

    }

    F128_frac_compare: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_QUAD)
        - effective_fraction(CFI.b, FMT_QUAD)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        bins eq = {0};
        bins gt = {[1 : $]};

    }

    F128_frac_LTE: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_QUAD)
        - effective_fraction(CFI.b, FMT_QUAD)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        bins eq = {0};
        // bins gt = {[1 : $]};

    }

    F128_frac_GTE: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_QUAD)
        - effective_fraction(CFI.b, FMT_QUAD)))  {
        type_option.weight = 0;

        // bins lt = {[$ : -1]};
        bins eq = {0};
        bins gt = {[1 : $]};

    }

    F128_frac_LT: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_QUAD)
        - effective_fraction(CFI.b, FMT_QUAD)))  {
        type_option.weight = 0;

        bins lt = {[$ : -1]};
        // bins eq = {0};
        // bins gt = {[1 : $]};

    }

    F128_frac_GT: coverpoint $signed(
        (effective_fraction(CFI.a, FMT_QUAD)
        - effective_fraction(CFI.b, FMT_QUAD)))  {
        type_option.weight = 0;

        // bins lt = {[$ : -1]};
        // bins eq = {0};
        bins gt = {[1 : $]};

    }


    `ifdef COVER_F16
        B19_F16__norm_x_norm:       cross FP_compare_ops, F16_operand_a_sign, F16_operand_b_sign, F16_a_norm, F16_b_norm,
                                          F16_exp_compare,         F16_frac_compare,   F16_result_fmt;

        B19_F16__norm_x_subnorm:    cross FP_compare_ops, F16_operand_a_sign, F16_operand_b_sign, F16_a_norm, F16_b_subnorm,
                                          /* a.EXP > b.EXP*/       F16_frac_compare,   F16_result_fmt;

        B19_F16__subnorm_x_norm:    cross FP_compare_ops, F16_operand_a_sign, F16_operand_b_sign, F16_a_norm, F16_b_subnorm,
                                          /* a.EXP < b.EXP*/       F16_frac_compare,   F16_result_fmt;

        B19_F16__subnorm_x_subnorm: cross FP_compare_ops, F16_operand_a_sign, F16_operand_b_sign, F16_a_norm, F16_b_subnorm,
                                          F16_exp_compare,         F16_frac_compare,   F16_result_fmt;

        B19_F16__zero_x_norm:       cross FP_compare_ops, F16_operand_a_sign, F16_operand_b_sign, F16_a_zero, F16_b_norm,
                                          /* a.EXP < b.EXP*/       F16_frac_LTE,       F16_result_fmt;

        B19_F16__norm_x_zero:       cross FP_compare_ops, F16_operand_a_sign, F16_operand_b_sign, F16_a_norm, F16_b_zero,
                                          /* a.EXP > b.EXP*/       F16_frac_GTE,       F16_result_fmt;

        B19_F16__subnorm_x_zero:       cross FP_compare_ops, F16_operand_a_sign, F16_operand_b_sign, F16_a_subnorm, F16_b_zero,
                                          /* a.EXP < b.EXP*/       F16_frac_LT,       F16_result_fmt;

        B19_F16__zero_x_subnorm:       cross FP_compare_ops, F16_operand_a_sign, F16_operand_b_sign, F16_a_zero, F16_b_subnorm,
                                          /* a.EXP > b.EXP*/       F16_frac_GT,       F16_result_fmt;

        B19_F16__zero_x_zero:       cross FP_compare_ops, F16_operand_a_sign, F16_operand_b_sign, F16_a_zero, F16_b_zero,
                                          /* a.EXP = b.EXP*/    /* a.FRAC = b.FRAC*/   F16_result_fmt;
    `endif // COVER_F16


    `ifdef COVER_BF16
        B19_BF16__norm_x_norm:       cross FP_compare_ops, BF16_operand_a_sign, BF16_operand_b_sign, BF16_a_norm, BF16_b_norm,
                                          BF16_exp_compare,         BF16_frac_compare,   BF16_result_fmt;

        B19_BF16__norm_x_subnorm:    cross FP_compare_ops, BF16_operand_a_sign, BF16_operand_b_sign, BF16_a_norm, BF16_b_subnorm,
                                          /* a.EXP > b.EXP*/       BF16_frac_compare,   BF16_result_fmt;

        B19_BF16__subnorm_x_norm:    cross FP_compare_ops, BF16_operand_a_sign, BF16_operand_b_sign, BF16_a_norm, BF16_b_subnorm,
                                          /* a.EXP < b.EXP*/       BF16_frac_compare,   BF16_result_fmt;

        B19_BF16__subnorm_x_subnorm: cross FP_compare_ops, BF16_operand_a_sign, BF16_operand_b_sign, BF16_a_norm, BF16_b_subnorm,
                                          BF16_exp_compare,         BF16_frac_compare,   BF16_result_fmt;

        B19_BF16__zero_x_norm:       cross FP_compare_ops, BF16_operand_a_sign, BF16_operand_b_sign, BF16_a_zero, BF16_b_norm,
                                          /* a.EXP < b.EXP*/       BF16_frac_LTE,       BF16_result_fmt;

        B19_BF16__norm_x_zero:       cross FP_compare_ops, BF16_operand_a_sign, BF16_operand_b_sign, BF16_a_norm, BF16_b_zero,
                                          /* a.EXP > b.EXP*/       BF16_frac_GTE,       BF16_result_fmt;

        B19_BF16__subnorm_x_zero:       cross FP_compare_ops, BF16_operand_a_sign, BF16_operand_b_sign, BF16_a_subnorm, BF16_b_zero,
                                          /* a.EXP < b.EXP*/       BF16_frac_LT,       BF16_result_fmt;

        B19_BF16__zero_x_subnorm:       cross FP_compare_ops, BF16_operand_a_sign, BF16_operand_b_sign, BF16_a_zero, BF16_b_subnorm,
                                          /* a.EXP > b.EXP*/       BF16_frac_GT,       BF16_result_fmt;

        B19_BF16__zero_x_zero:       cross FP_compare_ops, BF16_operand_a_sign, BF16_operand_b_sign, BF16_a_zero, BF16_b_zero,
                                          /* a.EXP = b.EXP*/    /* a.FRAC = b.FRAC*/   BF16_result_fmt;
    `endif // COVER_BF16


    `ifdef COVER_F32
        B19_F32__norm_x_norm:       cross FP_compare_ops, F32_operand_a_sign, F32_operand_b_sign, F32_a_norm, F32_b_norm,
                                          F32_exp_compare,         F32_frac_compare,   F32_result_fmt;

        B19_F32__norm_x_subnorm:    cross FP_compare_ops, F32_operand_a_sign, F32_operand_b_sign, F32_a_norm, F32_b_subnorm,
                                          /* a.EXP > b.EXP*/       F32_frac_compare,   F32_result_fmt;

        B19_F32__subnorm_x_norm:    cross FP_compare_ops, F32_operand_a_sign, F32_operand_b_sign, F32_a_norm, F32_b_subnorm,
                                          /* a.EXP < b.EXP*/       F32_frac_compare,   F32_result_fmt;

        B19_F32__subnorm_x_subnorm: cross FP_compare_ops, F32_operand_a_sign, F32_operand_b_sign, F32_a_norm, F32_b_subnorm,
                                          F32_exp_compare,         F32_frac_compare,   F32_result_fmt;

        B19_F32__zero_x_norm:       cross FP_compare_ops, F32_operand_a_sign, F32_operand_b_sign, F32_a_zero, F32_b_norm,
                                          /* a.EXP < b.EXP*/       F32_frac_LTE,       F32_result_fmt;

        B19_F32__norm_x_zero:       cross FP_compare_ops, F32_operand_a_sign, F32_operand_b_sign, F32_a_norm, F32_b_zero,
                                          /* a.EXP > b.EXP*/       F32_frac_GTE,       F32_result_fmt;

        B19_F32__subnorm_x_zero:       cross FP_compare_ops, F32_operand_a_sign, F32_operand_b_sign, F32_a_subnorm, F32_b_zero,
                                          /* a.EXP < b.EXP*/       F32_frac_LT,       F32_result_fmt;

        B19_F32__zero_x_subnorm:       cross FP_compare_ops, F32_operand_a_sign, F32_operand_b_sign, F32_a_zero, F32_b_subnorm,
                                          /* a.EXP > b.EXP*/       F32_frac_GT,       F32_result_fmt;

        B19_F32__zero_x_zero:       cross FP_compare_ops, F32_operand_a_sign, F32_operand_b_sign, F32_a_zero, F32_b_zero,
                                          /* a.EXP = b.EXP*/    /* a.FRAC = b.FRAC*/   F32_result_fmt;
    `endif // COVER_F32


    `ifdef COVER_F64
        B19_F64__norm_x_norm:       cross FP_compare_ops, F64_operand_a_sign, F64_operand_b_sign, F64_a_norm, F64_b_norm,
                                          F64_exp_compare,         F64_frac_compare,   F64_result_fmt;

        B19_F64__norm_x_subnorm:    cross FP_compare_ops, F64_operand_a_sign, F64_operand_b_sign, F64_a_norm, F64_b_subnorm,
                                          /* a.EXP > b.EXP*/       F64_frac_compare,   F64_result_fmt;

        B19_F64__subnorm_x_norm:    cross FP_compare_ops, F64_operand_a_sign, F64_operand_b_sign, F64_a_norm, F64_b_subnorm,
                                          /* a.EXP < b.EXP*/       F64_frac_compare,   F64_result_fmt;

        B19_F64__subnorm_x_subnorm: cross FP_compare_ops, F64_operand_a_sign, F64_operand_b_sign, F64_a_norm, F64_b_subnorm,
                                          F64_exp_compare,         F64_frac_compare,   F64_result_fmt;

        B19_F64__zero_x_norm:       cross FP_compare_ops, F64_operand_a_sign, F64_operand_b_sign, F64_a_zero, F64_b_norm,
                                          /* a.EXP < b.EXP*/       F64_frac_LTE,       F64_result_fmt;

        B19_F64__norm_x_zero:       cross FP_compare_ops, F64_operand_a_sign, F64_operand_b_sign, F64_a_norm, F64_b_zero,
                                          /* a.EXP > b.EXP*/       F64_frac_GTE,       F64_result_fmt;

        B19_F64__subnorm_x_zero:       cross FP_compare_ops, F64_operand_a_sign, F64_operand_b_sign, F64_a_subnorm, F64_b_zero,
                                          /* a.EXP < b.EXP*/       F64_frac_LT,       F64_result_fmt;

        B19_F64__zero_x_subnorm:       cross FP_compare_ops, F64_operand_a_sign, F64_operand_b_sign, F64_a_zero, F64_b_subnorm,
                                          /* a.EXP > b.EXP*/       F64_frac_GT,       F64_result_fmt;

        B19_F64__zero_x_zero:       cross FP_compare_ops, F64_operand_a_sign, F64_operand_b_sign, F64_a_zero, F64_b_zero,
                                          /* a.EXP = b.EXP*/    /* a.FRAC = b.FRAC*/   F64_result_fmt;
    `endif // COVER_F64


    `ifdef COVER_F128
        B19_F128__norm_x_norm:       cross FP_compare_ops, F128_operand_a_sign, F128_operand_b_sign, F128_a_norm, F128_b_norm,
                                          F128_exp_compare,         F128_frac_compare,   F128_result_fmt;

        B19_F128__norm_x_subnorm:    cross FP_compare_ops, F128_operand_a_sign, F128_operand_b_sign, F128_a_norm, F128_b_subnorm,
                                          /* a.EXP > b.EXP*/       F128_frac_compare,   F128_result_fmt;

        B19_F128__subnorm_x_norm:    cross FP_compare_ops, F128_operand_a_sign, F128_operand_b_sign, F128_a_norm, F128_b_subnorm,
                                          /* a.EXP < b.EXP*/       F128_frac_compare,   F128_result_fmt;

        B19_F128__subnorm_x_subnorm: cross FP_compare_ops, F128_operand_a_sign, F128_operand_b_sign, F128_a_norm, F128_b_subnorm,
                                          F128_exp_compare,         F128_frac_compare,   F128_result_fmt;

        B19_F128__zero_x_norm:       cross FP_compare_ops, F128_operand_a_sign, F128_operand_b_sign, F128_a_zero, F128_b_norm,
                                          /* a.EXP < b.EXP*/       F128_frac_LTE,       F128_result_fmt;

        B19_F128__norm_x_zero:       cross FP_compare_ops, F128_operand_a_sign, F128_operand_b_sign, F128_a_norm, F128_b_zero,
                                          /* a.EXP > b.EXP*/       F128_frac_GTE,       F128_result_fmt;

        B19_F128__subnorm_x_zero:       cross FP_compare_ops, F128_operand_a_sign, F128_operand_b_sign, F128_a_subnorm, F128_b_zero,
                                          /* a.EXP < b.EXP*/       F128_frac_LT,        F128_result_fmt;

        B19_F128__zero_x_subnorm:       cross FP_compare_ops, F128_operand_a_sign, F128_operand_b_sign, F128_a_zero, F128_b_subnorm,
                                          /* a.EXP > b.EXP*/       F128_frac_GT,       F128_result_fmt;

        B19_F128__zero_x_zero:       cross FP_compare_ops, F128_operand_a_sign, F128_operand_b_sign, F128_a_zero, F128_b_zero,
                                          /* a.EXP = b.EXP*/    /* a.FRAC = b.FRAC*/   F128_result_fmt;
    `endif // COVER_F128


endgroup
