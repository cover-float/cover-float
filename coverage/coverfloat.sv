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

`include "coverfloat_pkg.sv"
`include "coverfloat_interface.sv"
`include "coverfloat_coverage.sv"

module coverfloat (); import coverfloat_pkg::*; // TODO: maybe rename...

    logic clk = 0;
    logic [31:0] vectornum;
    logic [`COVER_VECTOR_WIDTH - 1:0] covervectors;
    logic [2:0] discard; // bits we dont car about (upper 3 bits of sign nibble in vectors)

    coverfloat_coverage coverage_inst;
    coverfloat_interface CFI();

    initial begin

        // file handle used in SCAN_COVERVECTOR_FILES macro to iterate through lines of covervectors
        int fd;

        coverage_inst = new(CFI);

        vectornum = 0;

        `SCAN_COVERVECTOR_FILES

        // fd = $fopen("../tests/covervectors/B#_cv.txt", "r");
        // while ($fscanf(fd, "%h", covervectors) == 1) begin
        //     @(posedge clk);
        // end
        // @(negedge clk);
        // $fclose(fd);


        $stop;

    end

    initial begin
        clk = 0; forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        {CFI.op, CFI.rm, CFI.a, CFI.b, CFI.c, CFI.operandFmt, CFI.result,
         CFI.resultFmt, CFI.exceptionBits, discard[2:0], CFI.intermS, CFI.intermX, CFI.intermM, CFI.fmaPreAddition} = covervectors;
    end

    always @(negedge clk) begin
        // collect coverage
        coverage_inst.sample();

        // $display("%h (%h) %h = %h_%h_%h", CFI.a, CFI.op, CFI.b, CFI.intermS, CFI.intermX, CFI.intermM[191:30]);

        vectornum = vectornum + 1;

    end

endmodule
