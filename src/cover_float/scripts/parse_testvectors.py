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

"""
Angela Zheng

February 25, 2026

Converts hex-encoded test vectors into readable format like:
b32+ =0 -1.016A3DP101 +1.7CEE72P95 -> -1.7AED06P100 x

Currently supports
- Rounding mode: Round to Nearest Even
- Operations: add, sub, mul, div, fmadd, fmsub, fnmadd, fnmsub, sqrt, rem,
            cfi, cff, cif, class, feq, flt, fle, min, max, csn, fsgnj, fsgnjn, fsgnjx
- Flags: 'x' if a flag is raised and '' if none
"""

import logging
import time
from pathlib import Path
from typing import Any, Optional, cast

import cover_float.common.log as log
from cover_float.reference import run_test_vector_unmodified, verify_test_vector

FMT_SPECS: dict[str, dict[str, Any]] = {
    "00": {"name": "f16", "type": "float", "exp_bits": 5, "man_bits": 10, "bias": 15, "total_bits": 16},
    "01": {"name": "f32", "type": "float", "exp_bits": 8, "man_bits": 23, "bias": 127, "total_bits": 32},
    "02": {"name": "f64", "type": "float", "exp_bits": 11, "man_bits": 52, "bias": 1023, "total_bits": 64},
    "03": {"name": "f128", "type": "float", "exp_bits": 15, "man_bits": 112, "bias": 16383, "total_bits": 128},
    "04": {"name": "bf16", "type": "float", "exp_bits": 8, "man_bits": 7, "bias": 127, "total_bits": 16},
    "81": {"name": "int", "type": "int", "signed": True, "total_bits": 32},
    "c1": {"name": "uint", "type": "int", "signed": False, "total_bits": 32},
    "82": {"name": "long", "type": "int", "signed": True, "total_bits": 64},
    "c2": {"name": "ulong", "type": "int", "signed": False, "total_bits": 64},
}

OP_NAMES: dict[str, str] = {
    "00000010": "add",
    "00000020": "sub",
    "00000030": "mul",
    "00000040": "div",
    "00000051": "fmadd",
    "00000052": "fmsub",
    "00000053": "fnmadd",
    "00000054": "fnmsub",
    "00000060": "sqrt",
    "00000070": "rem",
    "00000080": "cfi",
    "00000090": "cff",
    "000000A0": "cif",
    "000000B1": "feq",
    "000000C1": "flt",
    "000000C2": "fle",
    "000000D0": "class",
    "000000E0": "min",
    "000000F0": "max",
    "00000100": "csn",
    "00000101": "fsgnj",
    "00000102": "fsgnjn",
    "00000103": "fsgnjx",
}

ROUND_NAMES: dict[str, str] = {"00": "=0"}


def hex_to_binary(hex_str: str, bits: int) -> str:
    return bin(int(hex_str, 16))[2:].zfill(bits)


def parse_int_value(hex_val: str, spec: dict[str, Any]) -> dict[str, Any]:
    bits: int = spec["total_bits"]
    unsigned: int = int(hex_val, 16)
    if spec.get("signed"):
        sign_bit: int = 1 << (bits - 1)
        value: int = unsigned - (1 << bits) if (unsigned & sign_bit) else unsigned
    else:
        value: int = unsigned
    return {"value": value, "signed": spec.get("signed", False), "raw": hex_val}


def parse_fp_value(hex_val: str, fmt_code: str) -> Optional[dict[str, Any]]:
    spec = FMT_SPECS.get(fmt_code)
    if not spec:
        return None

    total_bits: int = spec["total_bits"]
    val: int = int(hex_val, 16)

    sign: int = (val >> (total_bits - 1)) & 1
    exp_bits: int = spec["exp_bits"]
    man_bits: int = spec["man_bits"]

    biased_exp: int = (val >> man_bits) & ((1 << exp_bits) - 1)
    mantissa: int = val & ((1 << man_bits) - 1)

    is_zero: bool = biased_exp == 0 and mantissa == 0
    is_inf: bool = biased_exp == ((1 << exp_bits) - 1) and mantissa == 0
    is_nan: bool = biased_exp == ((1 << exp_bits) - 1) and mantissa != 0
    is_subnormal: bool = biased_exp == 0 and mantissa != 0

    actual_exp: int = (1 - spec["bias"]) if (is_zero or is_subnormal) else (biased_exp - spec["bias"])

    return {
        "sign": sign,
        "exp": actual_exp,
        "mantissa": mantissa,
        "man_bits": man_bits,
        "is_zero": is_zero,
        "is_inf": is_inf,
        "is_nan": is_nan,
        "is_subnormal": is_subnormal,
    }


def format_mantissa(parsed: dict[str, Any]) -> str:
    mantissa: int = parsed["mantissa"]
    man_bits: int = parsed["man_bits"]
    lead_bit: str = "0" if parsed["is_subnormal"] else "1"

    if mantissa == 0:
        return f"{lead_bit}.0"

    hex_digits: int = (man_bits + 3) // 4
    hex_str: str = f"{mantissa:0{hex_digits}X}"
    return f"{lead_bit}.{hex_str}"


def decode_class_mask(val: int) -> str:
    """Decodes fclass bitmask."""
    masks: dict[int, str] = {
        0: "NegInf",
        1: "NegNormal",
        2: "NegSubnormal",
        3: "NegZero",
        4: "PosZero",
        5: "PosSubnormal",
        6: "PosNormal",
        7: "PosInf",
        8: "sNaN",
        9: "qNaN",
    }
    active = [name for bit, name in masks.items() if (val >> bit) & 1]
    return "|".join(active) if active else hex(val)


def value_to_string(parsed: Optional[dict[str, Any]], fmt_code: str, is_class: bool = False) -> str:
    if parsed is None:
        return "None"

    spec = FMT_SPECS.get(fmt_code, {})

    if is_class:
        return decode_class_mask(parsed["value"])

    if spec.get("type") == "int":
        val: int = parsed["value"]
        return str(val) if parsed.get("signed") else hex(val)

    if parsed["is_nan"]:
        return "NaN"
    if parsed["is_inf"]:
        return f"{'-' if parsed['sign'] else '+'}Inf"
    if parsed["is_zero"]:
        return f"{'-' if parsed['sign'] else '+'}0.0P0"

    sign_char: str = "-" if parsed["sign"] else "+"
    return f"{sign_char}{format_mantissa(parsed)}P{parsed['exp']}"


def parse_test_vector(line: str) -> Optional[dict[str, Any]]:
    line = line.strip()
    if not line or line.startswith("//"):
        return None

    parts = line.split("_")
    if len(parts) < 8:
        return None

    op_code, rnd_code, a_val, b_val, c_val, op_fmt, result_val, result_fmt = parts[:8]
    flags: str = parts[8] if len(parts) > 8 else "00"

    one_op_names = ("sqrt", "cfi", "cff", "cif", "class")
    three_op_names = ("fmadd", "fmsub", "fnmadd", "fnmsub")

    op_name: str = OP_NAMES.get(op_code.upper(), "UNK")
    rnd_name: str = ROUND_NAMES.get(rnd_code, "?")
    op_spec, res_spec = FMT_SPECS.get(op_fmt), FMT_SPECS.get(result_fmt)

    if not op_spec or not res_spec:
        return None

    def fixwidth(val: str, width: int) -> str:
        return val[-width:] if len(val) >= width else val.zfill(width)

    op_hex_chars: int = op_spec["total_bits"] // 4
    res_hex_chars: int = res_spec["total_bits"] // 4

    a_parsed = (
        parse_fp_value(fixwidth(a_val, op_hex_chars), op_fmt)
        if op_spec["type"] == "float"
        else parse_int_value(fixwidth(a_val, op_hex_chars), op_spec)
    )

    b_parsed = None
    if op_name not in one_op_names:
        b_parsed = (
            parse_fp_value(fixwidth(b_val, op_hex_chars), op_fmt)
            if op_spec["type"] == "float"
            else parse_int_value(fixwidth(b_val, op_hex_chars), op_spec)
        )

    c_parsed = parse_fp_value(fixwidth(c_val, op_hex_chars), op_fmt) if op_name in three_op_names else None

    if op_name in ("class", "feq", "flt", "fle"):
        result_parsed = parse_int_value(fixwidth(result_val, 8), {"total_bits": 32, "signed": False})
    elif res_spec["type"] == "float":
        result_parsed = parse_fp_value(fixwidth(result_val, res_hex_chars), result_fmt)
    else:
        result_parsed = parse_int_value(fixwidth(result_val, res_hex_chars), res_spec)

    options: dict[str, str] = {
        "add": "+",
        "sub": "-",
        "mul": "*",
        "div": "/",
        "fmadd": "*+",
        "fmsub": "*-",
        "fnmadd": "-*+",
        "fnmsub": "-*-",
        "sqrt": "v-",
        "rem": "rem",
        "cfi": "cfi",
        "cff": "cff",
        "cif": "cif",
        "class": "cls",
        "feq": "==",
        "flt": "<",
        "fle": "<=",
        "min": "min",
        "max": "max",
        "csn": "csn",
        "fsgnj": "sj",
        "fsgnjn": "sjn",
        "fsgnjx": "sjx",
    }

    effective_res_fmt: str = "c1" if op_name in ("class", "feq", "flt", "fle") else result_fmt

    return {
        "format": f"{op_spec['name']}{options.get(op_name, 'UNK')}",
        "round": rnd_name,
        "op_a": value_to_string(a_parsed, op_fmt),
        "op_b": value_to_string(b_parsed, op_fmt) if b_parsed else None,
        "op_c": value_to_string(c_parsed, op_fmt) if c_parsed else None,
        "result": value_to_string(result_parsed, effective_res_fmt, is_class=(op_name == "class")),
        "flags": "x" if flags != "00" else "",
        "res_fmt_name": res_spec["name"],
    }


def format_output(parsed: dict[str, Any]) -> str:
    """Format parsed test vector to output string based on operand count."""
    flags: str = f" {parsed['flags']}" if parsed["flags"] else ""
    op: str = parsed["format"]
    rnd: str = parsed["round"]
    a: str = parsed["op_a"]
    b: Optional[str] = parsed.get("op_b")
    c: Optional[str] = parsed.get("op_c")

    if "v-" in op or any(x in op for x in ["cfi", "cff", "cif", "cls"]):
        base = f"{op} {rnd} {a}"
    elif c:
        base = f"{op} {rnd} {a} {b} {c}"
    else:
        base = f"{op} {rnd} {a} {b}"

    return f"{base} -> {parsed['result']} ({parsed['res_fmt_name']}){flags}"


def auto_parse(model_name: str, output_dir: str) -> None:
    logger: log.ModelLogger = cast(log.ModelLogger, logging.getLogger(model_name))

    input_path = Path(output_dir) / "testvectors" / f"{model_name}_tv.txt"
    output_path = Path(output_dir) / "readable" / f"{model_name}_parsed.txt"

    output_path.parent.mkdir(parents=True, exist_ok=True)

    count = 0
    with input_path.open("r") as infile, output_path.open("w") as outfile:
        input_size = input_path.stat().st_size

        last_update = time.monotonic()
        update_size = 0

        with logger.progress_bar("Post Processing", total=input_size) as bar:
            for line in infile:
                parsed = parse_test_vector(line)

                if parsed:
                    outfile.write(format_output(parsed) + "\n")
                    count += 1

                    if not verify_test_vector(line):
                        logger.exception(
                            f"Covervector Failed Verification: {line}, Expected: {run_test_vector_unmodified(line)}"
                        )

                now = time.monotonic()
                update_size += len(line)
                if now - last_update >= 0.1:
                    bar.advance(update_size)
                    last_update = now
                    update_size = 0

    logger.info(f"Parsed {count} {model_name} vectors to {output_path}")
