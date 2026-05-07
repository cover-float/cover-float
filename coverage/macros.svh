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

`define COVER_VECTOR_WIDTH 1208

`define INCLUDE_CGS \
    `ifdef COVER_B1 \
        `include  "covergroups/B1.svh" \
    `endif \
    `ifdef COVER_B2 \
        `include  "covergroups/B2.svh" \
    `endif \
    `ifdef COVER_B3 \
        `include  "covergroups/B3.svh" \
    `endif \
    `ifdef COVER_B4 \
        `include  "covergroups/B4.svh" \
    `endif \
    `ifdef COVER_B5 \
        `include  "covergroups/B5.svh" \
    `endif \
    `ifdef COVER_B6 \
        `include  "covergroups/B6.svh" \
    `endif \
    `ifdef COVER_B7 \
        `include  "covergroups/B7.svh" \
    `endif \
    `ifdef COVER_B8 \
        `include  "covergroups/B8.svh" \
    `endif \
    `ifdef COVER_B9 \
        `include  "covergroups/B9.svh" \
    `endif \
    `ifdef COVER_B10 \
        `include  "covergroups/B10.svh" \
    `endif \
    `ifdef COVER_B11 \
        `include  "covergroups/B11.svh" \
    `endif \
    `ifdef COVER_B12 \
        `include  "covergroups/B12.svh" \
    `endif \
    `ifdef COVER_B13 \
        `include  "covergroups/B13.svh" \
    `endif \
    `ifdef COVER_B14 \
        `include  "covergroups/B14.svh" \
    `endif \
    `ifdef COVER_B15 \
        `include  "covergroups/B15.svh" \
    `endif \
    `ifdef COVER_B16 \
        `include  "covergroups/B16.svh" \
    `endif \
    `ifdef COVER_B17 \
        `include  "covergroups/B17.svh" \
    `endif \
    `ifdef COVER_B18 \
        `include  "covergroups/B18.svh" \
    `endif \
    `ifdef COVER_B19 \
        `include  "covergroups/B19.svh" \
    `endif \
    `ifdef COVER_B20 \
        `include  "covergroups/B20.svh" \
    `endif \
    `ifdef COVER_B21 \
        `include  "covergroups/B21.svh" \
    `endif \
    `ifdef COVER_B22 \
        `include  "covergroups/B22.svh" \
    `endif \
    `ifdef COVER_B23 \
        `include  "covergroups/B23.svh" \
    `endif \
    `ifdef COVER_B24 \
        `include  "covergroups/B24.svh" \
    `endif \
    `ifdef COVER_B25 \
        `include  "covergroups/B25.svh" \
    `endif \
    `ifdef COVER_B26 \
        `include  "covergroups/B26.svh" \
    `endif \
    `ifdef COVER_B27 \
        `include  "covergroups/B27.svh" \
    `endif \
    `ifdef COVER_B28 \
        `include  "covergroups/B28.svh" \
    `endif \
    `ifdef COVER_B29 \
        `include  "covergroups/B29.svh" \
    `endif \


`define INIT_CGS \
    `ifdef COVER_B1 \
        B1_cg = new(CFI); \
    `endif \
    `ifdef COVER_B2 \
        B2_cg = new(CFI); \
    `endif \
    `ifdef COVER_B3 \
        B3_cg = new(CFI); \
    `endif \
    `ifdef COVER_B4 \
        B4_cg = new(CFI); \
    `endif \
    `ifdef COVER_B5 \
        B5_cg = new(CFI); \
    `endif \
    `ifdef COVER_B6 \
        B6_cg = new(CFI); \
    `endif \
    `ifdef COVER_B7 \
        B7_cg = new(CFI); \
    `endif \
    `ifdef COVER_B8 \
        B8_cg = new(CFI); \
    `endif \
    `ifdef COVER_B9 \
        B9_cg = new(CFI); \
    `endif \
    `ifdef COVER_B10 \
        B10_cg = new(CFI); \
    `endif \
    `ifdef COVER_B11 \
        B11_cg = new(CFI); \
    `endif \
    `ifdef COVER_B12 \
        B12_cg = new(CFI); \
    `endif \
    `ifdef COVER_B13 \
        B13_cg = new(CFI); \
    `endif \
    `ifdef COVER_B14 \
        B14_cg = new(CFI); \
    `endif \
    `ifdef COVER_B15 \
        B15_cg = new(CFI); \
    `endif \
    `ifdef COVER_B16 \
        B16_cg = new(CFI); \
    `endif \
    `ifdef COVER_B17 \
        B17_cg = new(CFI); \
    `endif \
    `ifdef COVER_B18 \
        B18_cg = new(CFI); \
    `endif \
    `ifdef COVER_B19 \
        B19_cg = new(CFI); \
    `endif \
    `ifdef COVER_B20 \
        B20_cg = new(CFI); \
    `endif \
    `ifdef COVER_B21 \
        B21_cg = new(CFI); \
    `endif \
    `ifdef COVER_B22 \
        B22_cg = new(CFI); \
    `endif \
    `ifdef COVER_B23 \
        B23_cg = new(CFI); \
    `endif \
    `ifdef COVER_B24 \
        B24_cg = new(CFI); \
    `endif \
    `ifdef COVER_B25 \
        B25_cg = new(CFI); \
    `endif \
    `ifdef COVER_B26 \
        B26_cg = new(CFI); \
    `endif \
    `ifdef COVER_B27 \
        B27_cg = new(CFI); \
    `endif \
    `ifdef COVER_B28 \
        B28_cg = new(CFI); \
    `endif \
    `ifdef COVER_B29 \
        B29_cg = new(CFI); \
    `endif \


`define SAMPLE_CGS \
    `ifdef COVER_B1 \
        B1_cg.sample(); \
    `endif \
    `ifdef COVER_B2 \
        B2_cg.sample(); \
    `endif \
    `ifdef COVER_B3 \
        B3_cg.sample(); \
    `endif \
    `ifdef COVER_B4 \
        B4_cg.sample(); \
    `endif \
    `ifdef COVER_B5 \
        B5_cg.sample(); \
    `endif \
    `ifdef COVER_B6 \
        B6_cg.sample(); \
    `endif \
    `ifdef COVER_B7 \
        B7_cg.sample(); \
    `endif \
    `ifdef COVER_B8 \
        B8_cg.sample(); \
    `endif \
    `ifdef COVER_B9 \
        B9_cg.sample(); \
    `endif \
    `ifdef COVER_B10 \
        B10_cg.sample(); \
    `endif \
    `ifdef COVER_B11 \
        B11_cg.sample(); \
    `endif \
    `ifdef COVER_B12 \
        B12_cg.sample(); \
    `endif \
    `ifdef COVER_B13 \
        B13_cg.sample(); \
    `endif \
    `ifdef COVER_B14 \
        B14_cg.sample(); \
    `endif \
    `ifdef COVER_B15 \
        B15_cg.sample(); \
    `endif \
    `ifdef COVER_B16 \
        B16_cg.sample(); \
    `endif \
    `ifdef COVER_B17 \
        B17_cg.sample(); \
    `endif \
    `ifdef COVER_B18 \
        B18_cg.sample(); \
    `endif \
    `ifdef COVER_B19 \
        B19_cg.sample(); \
    `endif \
    `ifdef COVER_B20 \
        B20_cg.sample(); \
    `endif \
    `ifdef COVER_B21 \
        B21_cg.sample(); \
    `endif \
    `ifdef COVER_B22 \
        B22_cg.sample(); \
    `endif \
    `ifdef COVER_B23 \
        B23_cg.sample(); \
    `endif \
    `ifdef COVER_B24 \
        B24_cg.sample(); \
    `endif \
    `ifdef COVER_B25 \
        B25_cg.sample(); \
    `endif \
    `ifdef COVER_B26 \
        B26_cg.sample(); \
    `endif \
    `ifdef COVER_B27 \
        B27_cg.sample(); \
    `endif \
    `ifdef COVER_B28 \
        B28_cg.sample(); \
    `endif \
    `ifdef COVER_B29 \
        B29_cg.sample(); \
    `endif \


`define SCAN_COVERVECTOR_FILES \
    `ifdef COVER_B1 \
        fd = $fopen("../tests/covervectors/B1_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B2 \
        fd = $fopen("../tests/covervectors/B2_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B3 \
        fd = $fopen("../tests/covervectors/B3_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B4 \
        fd = $fopen("../tests/covervectors/B4_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B5 \
        fd = $fopen("../tests/covervectors/B5_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B6 \
        fd = $fopen("../tests/covervectors/B6_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B7 \
        fd = $fopen("../tests/covervectors/B7_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B8 \
        fd = $fopen("../tests/covervectors/B8_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B9 \
        fd = $fopen("../tests/covervectors/B9_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B10 \
        fd = $fopen("../tests/covervectors/B10_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B11 \
        fd = $fopen("../tests/covervectors/B11_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B12 \
        fd = $fopen("../tests/covervectors/B12_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B13 \
        fd = $fopen("../tests/covervectors/B13_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B14 \
        fd = $fopen("../tests/covervectors/B14_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B15 \
        fd = $fopen("../tests/covervectors/B15_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B16 \
        fd = $fopen("../tests/covervectors/B16_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B17 \
        fd = $fopen("../tests/covervectors/B17_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B18 \
        fd = $fopen("../tests/covervectors/B18_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B19 \
        fd = $fopen("../tests/covervectors/B19_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B20 \
        fd = $fopen("../tests/covervectors/B20_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B21 \
        fd = $fopen("../tests/covervectors/B21_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B22 \
        fd = $fopen("../tests/covervectors/B22_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B23 \
        fd = $fopen("../tests/covervectors/B23_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B24 \
        fd = $fopen("../tests/covervectors/B24_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B25 \
        fd = $fopen("../tests/covervectors/B25_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B26 \
        fd = $fopen("../tests/covervectors/B26_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B27 \
        fd = $fopen("../tests/covervectors/B27_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B28 \
        fd = $fopen("../tests/covervectors/B28_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
 \
    `ifdef COVER_B29 \
        fd = $fopen("../tests/covervectors/B29_cv.txt", "r"); \
        while ($fscanf(fd, "%h", covervectors) == 1) begin \
            @(posedge clk); \
        end \
        @(negedge clk); \
        $fclose(fd); \
    `endif \
