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

from typing import TextIO

import cover_float._reference
import cover_float._unmodified_reference
from cover_float.common.constants import TEST_VECTOR_WIDTH_HEX_WITH_SEPARATORS


def run_and_store_test_vector(test_vector: str, test_file: TextIO, cover_file: TextIO) -> None:
    """Run test_vector through coverfloat and store both the test vector and cover vector"""

    cover_vector = cover_float._reference.run_test_vector(test_vector)

    generated_test_vector = cover_vector[:TEST_VECTOR_WIDTH_HEX_WITH_SEPARATORS]
    test_file.write(generated_test_vector + "\n")
    cover_file.write(cover_vector.strip() + "\n")


def store_cover_vector(cover_vector: str, test_file: TextIO, cover_file: TextIO) -> None:
    generated_test_vector = cover_vector[:TEST_VECTOR_WIDTH_HEX_WITH_SEPARATORS]
    test_file.write(generated_test_vector + "\n")
    cover_file.write(cover_vector.strip() + "\n")


def verify_test_vector(test_vector: str) -> bool:
    output_vector = cover_float._unmodified_reference.run_test_vector(test_vector)

    return output_vector[:TEST_VECTOR_WIDTH_HEX_WITH_SEPARATORS].strip() == test_vector.strip()
