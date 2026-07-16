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

from importlib import import_module
from pathlib import Path


def discover_and_import_models() -> None:
    model_dir = Path(__file__).parent

    for py_file in model_dir.glob("*.py"):
        if py_file.stem.startswith("B"):
            import_module(f"cover_float.testgen.{py_file.stem}")
