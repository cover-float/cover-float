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

import coverfloat_pkg::*;
class coverfloat_coverage;

    `INCLUDE_CGS

    virtual coverfloat_interface CFI;

    enum {
        B1_ACTIVE,
        B2_ACTIVE,
        B3_ACTIVE,
        B4_ACTIVE,
        B5_ACTIVE,
        B6_ACTIVE,
        B7_ACTIVE,
        B8_ACTIVE,
        B9_ACTIVE,
        B10_ACTIVE,
        B11_ACTIVE,
        B12_ACTIVE,
        B13_ACTIVE,
        B14_ACTIVE,
        B15_ACTIVE,
        B16_ACTIVE,
        B17_ACTIVE,
        B18_ACTIVE,
        B19_ACTIVE,
        B20_ACTIVE,
        B21_ACTIVE,
        B22_ACTIVE,
        B23_ACTIVE,
        B24_ACTIVE,
        B25_ACTIVE,
        B26_ACTIVE,
        B27_ACTIVE,
        B28_ACTIVE,
        B29_ACTIVE
    } active_cg;

    // constructor (initializes covergroups)
    function new (virtual coverfloat_interface CFI);
        this.CFI = CFI;
        this.active_cg = B1_ACTIVE;

        `INIT_CGS

    endfunction


    function void sample();

        // Call sample functions
        `SAMPLE_CGS

    endfunction

endclass
