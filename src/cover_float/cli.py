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

import argparse
from pathlib import Path

from cover_float import Config, generate


def main() -> None:
    config = parse_args()
    success = generate(config)

    # Code 0 if successful
    exit(not success)


def parse_args() -> Config:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--model",
        "--models",
        dest="models",
        action="extend",
        nargs="+",
        help="Model(s) to generate test vectors for",
    )
    parser.add_argument("--output-dir", type=str, default="tests", help="Directory to save generated test vectors")
    parser.add_argument("--single-thread", action="store_true", help="Run Generation in a Single Thread")
    parser.add_argument("--jobs", type=int, default=None, help="Number of Jobs to Run When Multi-Threaded")
    parser.add_argument(
        "--partial-output", action="store_true", help="Create a Reduced Number of Tests in Test Heavy Models"
    )
    parser.add_argument(
        "--quiet",
        "-q",
        action="count",
        default=0,
        help="Applying Once Condenses Info Logging to a Single Progress Bar, Twice Eliminates all Logging",
    )
    parser.add_argument("--only-processed-vectors", action="store_true", help="Generate Only Processed Test Vectors")
    args = parser.parse_args()

    output_dir = Path(args.output_dir)
    single_thread = args.single_thread or (args.models is not None and len(args.models) < 2)
    jobs = 1 if single_thread else args.jobs

    return Config(
        output_dir=output_dir,
        full_coverage_testgen=not args.partial_output,
        quiet=args.quiet > 0,
        silent=args.quiet > 1,
        release=args.only_processed_vectors,
        jobs=jobs,
        models=args.models,
        single_thread=single_thread,
    )
