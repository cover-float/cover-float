        // all operations where the first operand is FP

        // 1 fp input
        bins op_sqrt   = {[OP_SQRT : OP_SQRT | 32'hF]};
        bins op_cfi    = {[OP_CFI  : OP_CFI  | 32'hF]};
        bins op_cff    = {[OP_CFF   : OP_CFF   | 32'hF]};
        bins op_class  = {[OP_CLASS : OP_CLASS | 32'hF]};
        bins op_rfi    = {[OP_RFI   : OP_RFI | 32'hf]};
