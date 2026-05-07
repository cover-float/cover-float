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

interface coverfloat_interface; import coverfloat_pkg::*;

    // bit         clk;

    // bit         valid;

    bit [31:0]  op;

    bit [7:0]  rm;

    // bit [31:0]  enableBits; // legacy, not required for riscv

    bit [127:0] a, b, c;
    bit [7:0]   operandFmt;

    bit [127:0] result;
    bit [7:0]   resultFmt;

    bit         intermS;
    bit [31:0]  intermX;
    bit [339:0] intermM;

    bit [7:0]  exceptionBits;

    bit [255:0] fmaPreAddition;

endinterface
