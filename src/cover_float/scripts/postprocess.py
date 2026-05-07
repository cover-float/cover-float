# Copyright (C) 2025-26 Harvey Mudd College
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, any work distributed under the
# License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific language governing permissions
# and limitations under the License.

# Test Vector Post-Processing
# Ryan Wolk (rwolk@g.hmc.edu)

from __future__ import annotations

import csv
import logging
import pathlib
import time
from dataclasses import dataclass
from typing import TextIO, cast

import cover_float.common.log as log
from cover_float.common import constants
from cover_float.common.util import unpack_test_vector
from cover_float.reference import run_test_vector_unmodified, verify_test_vector
from cover_float.scripts.parse_testvectors import format_output, parse_test_vector


@dataclass
class OperationType:
    sources: list[str]
    dest: str


@dataclass
class OperationInfo:
    name: str
    type: OperationType


COMMON_OUTPUTS = ["fflags"]
FR_TYPE = OperationType(sources=["fs1val", "fs2val"], dest="fdval")  # add, sub, div, mul, fsgnj, cff, fmin, fmax
FR1_TYPE = OperationType(["fs1val"], dest="fdval")  # sqrt, rfi
FR4_TYPE = OperationType(["fs1val", "fs2val", "fs3val"], dest="fdval")  # fma
F2INT_TYPE = OperationType(["fs1val"], dest="rdval")  # cfi
INT2F_TYPE = OperationType(["rs1val"], dest="fdval")  # cif
FCLASS_TYPE = OperationType(["fs1val"], dest="rdval")  # fclass
FCMP_TYPE = OperationType(["fs1val", "fs2val"], dest="rdval")  # feq, flt, fle


OP_TO_INSTRUCTION_INFO = {
    constants.OP_ADD: OperationInfo("fadd", FR_TYPE),
    constants.OP_SUB: OperationInfo("fsub", FR_TYPE),
    constants.OP_MUL: OperationInfo("fmul", FR_TYPE),
    constants.OP_DIV: OperationInfo("fdiv", FR_TYPE),
    constants.OP_FMADD: OperationInfo("fmadd", FR4_TYPE),
    constants.OP_FMSUB: OperationInfo("fmsub", FR4_TYPE),
    constants.OP_FNMADD: OperationInfo("fnmadd", FR4_TYPE),
    constants.OP_FNMSUB: OperationInfo("fnmsub", FR4_TYPE),
    constants.OP_SQRT: OperationInfo("fsqrt", FR1_TYPE),
    constants.OP_CFI: OperationInfo("fcvt", F2INT_TYPE),
    constants.OP_CFF: OperationInfo("fcvt", FR_TYPE),
    constants.OP_CIF: OperationInfo("fcvt", INT2F_TYPE),
    constants.OP_FEQ: OperationInfo("feq", FCMP_TYPE),
    constants.OP_FLT: OperationInfo("flt", FCMP_TYPE),
    constants.OP_FLE: OperationInfo("fle", FCMP_TYPE),
    constants.OP_CLASS: OperationInfo("fclass", FCLASS_TYPE),
    constants.OP_MIN: OperationInfo("fmin", FR_TYPE),
    constants.OP_MAX: OperationInfo("fmax", FR_TYPE),
    constants.OP_FSGNJ: OperationInfo("fsgnj", FR_TYPE),
    constants.OP_FSGNJN: OperationInfo("fsgnjn", FR_TYPE),
    constants.OP_FSGNJX: OperationInfo("fsgnjx", FR_TYPE),
    constants.OP_RFI: OperationInfo("froundnx", FR1_TYPE),
}

RISCV_FMT_CODES = {
    constants.FMT_BF16: "bf16",
    constants.FMT_HALF: "h",
    constants.FMT_SINGLE: "s",
    constants.FMT_DOUBLE: "d",
    constants.FMT_QUAD: "q",
    constants.FMT_INT: "w",
    constants.FMT_UINT: "wu",
    constants.FMT_LONG: "l",
    constants.FMT_ULONG: "lu",
}

ROUNDING_MODE_TO_COMMON = {
    constants.ROUND_NEAR_EVEN: "rne",
    constants.ROUND_MINMAG: "rtz",
    constants.ROUND_MIN: "rdn",
    constants.ROUND_MAX: "rup",
    constants.ROUND_NEAR_MAXMAG: "rmm",
}

NO_ROUNDING_MODE_OPS = ["fclass", "feq", "fle", "flt", "fmax", "fmin", "fsgnj", "fsgnjn", "fsgnjx"]


def postprocess_testvectors(
    model: str,
    test_vector_location: pathlib.Path,
    processed_vectors_dir: pathlib.Path,
    readable_vectors_dir: pathlib.Path,
) -> None:
    logger: log.ModelLogger = cast(log.ModelLogger, logging.getLogger(model))

    test_vector_file = test_vector_location / f"{model}_tv.txt"
    readable_vectors_file = readable_vectors_dir / f"{model}_parsed.txt"
    processed_vectors: dict[str, tuple[csv.DictWriter[str], TextIO]] = {}
    total = 0
    non_riscv = 0

    file_size = test_vector_file.stat().st_size
    readable_vectors_file.parent.mkdir(parents=True, exist_ok=True)

    with (
        test_vector_file.open("r") as test_vectors,
        readable_vectors_file.open("w") as readable_vectors,
        logger.progress_bar("Post Processing", total=file_size) as bar,
    ):
        last_update = time.monotonic()
        update_size = 0

        for line in test_vectors.readlines():
            parsed = parse_test_vector(line)
            if parsed:
                readable_vectors.write(format_output(parsed) + "\n")

                if not verify_test_vector(line):
                    logger.exception(
                        f"Covervector Failed Verification: {line}, Expected: {run_test_vector_unmodified(line)}"
                    )

            try:
                unpacked = unpack_test_vector(line)
            except ValueError:
                continue

            total += 1

            try:
                operation_info = OP_TO_INSTRUCTION_INFO[unpacked.op.upper()]
            except KeyError:
                non_riscv += 1
                continue

            if unpacked.rounding_mode == constants.ROUND_ODD:
                non_riscv += 1
                continue

            operation = operation_info.name

            input_fmt = RISCV_FMT_CODES[unpacked.output_format]

            instruction_code = operation + "." + input_fmt
            if operation == "fcvt":
                output_fmt = RISCV_FMT_CODES[unpacked.input_format]
                instruction_code += "." + output_fmt

            if instruction_code not in processed_vectors:
                processed_vector_path = processed_vectors_dir / instruction_code / f"{model}.csv"
                processed_vector_path.parent.mkdir(parents=True, exist_ok=True)
                file = processed_vector_path.open("w")

                csv_columns = [*operation_info.type.sources, operation_info.type.dest, *COMMON_OUTPUTS]
                if operation_info.name not in NO_ROUNDING_MODE_OPS:
                    csv_columns.append("frm")

                writer = csv.DictWriter(file, csv_columns)

                writer.writeheader()
                processed_vectors[instruction_code] = (writer, file)

            info: dict[str, str | int] = {
                "fflags": unpacked.flags,
            }

            if operation_info.name not in NO_ROUNDING_MODE_OPS:
                info["frm"] = ROUNDING_MODE_TO_COMMON[unpacked.rounding_mode]

            for i, source in enumerate(operation_info.type.sources):
                if i == 0:
                    info[source] = unpacked.input1
                elif i == 1:
                    info[source] = unpacked.input2
                elif i == 2:
                    info[source] = unpacked.input3

            info[operation_info.type.dest] = unpacked.result

            processed_vectors[instruction_code][0].writerow(info)

            now = time.monotonic()
            update_size += len(line)
            if now - last_update >= 0.1:
                bar.advance(update_size)
                last_update = now
                update_size = 0

    for instruction_code in processed_vectors:
        processed_vectors[instruction_code][1].close()

    if non_riscv == 0:
        logger.info(f"Parsed {total} {model} Vectors")
    else:
        logger.info(f"Parsed {total} {model} Vectors, {non_riscv} Tests Were Non-RISC-V Instructions")
