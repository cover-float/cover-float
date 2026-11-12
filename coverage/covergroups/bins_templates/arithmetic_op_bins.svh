        // all arithmetic operations

        bins op_sqrt   = {[OP_SQRT : OP_SQRT | 32'hF]};
        bins op_add    = {[OP_ADD : OP_ADD | 32'hF]};
        bins op_sub    = {[OP_SUB : OP_SUB | 32'hF]};
        bins op_mul    = {[OP_MUL : OP_MUL | 32'hF]};
        bins op_div    = {[OP_DIV : OP_DIV | 32'hF]};
        // bins op_rem    = {[OP_REM : OP_REM | 32'hF]};
        bins op_fma    = {[OP_FMA : OP_FMA | 32'hF]};
        bins op_fmadd  = {OP_FMADD};
        bins op_fmsub  = {OP_FMSUB};
        bins op_fnmadd = {OP_FNMADD};
        bins op_fnmsub = {OP_FNMSUB};
