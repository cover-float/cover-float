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

import multiprocessing
from concurrent.futures import Future, ProcessPoolExecutor, as_completed

from rich import print as rprint
from rich.progress import BarColumn, MofNCompleteColumn, Progress, TextColumn, TimeElapsedColumn

import cover_float.common.log as log
import cover_float.testgen as tg
from cover_float.common.config import Config
from cover_float.common.util import SingleThreadedExecutor


def generate(config: Config) -> bool:
    tg.discover_and_import_models()

    single_thread = config.single_thread or (config.models is not None and len(config.models) < 2)
    if single_thread:
        executor = SingleThreadedExecutor()
    else:
        initializer = None
        if multiprocessing.get_start_method() != "fork":  # Default on linux for python < 3.14
            initializer = tg.discover_and_import_models
        executor = ProcessPoolExecutor(max_workers=config.jobs, initializer=initializer)

    with log.StatusReporter(config, disable=config.quiet) as logger, executor:
        futures: list[Future[bool]] = []

        if config.models is None:
            for model in tg.GLOBAL_MODELS:
                future = tg.GLOBAL_MODELS[model](config, logger, executor)
                if future is not None:
                    futures.append(future)
        else:
            for model in config.models:
                if model in tg.GLOBAL_MODELS:
                    future = tg.GLOBAL_MODELS[model](config, logger, executor)
                    if future is not None:
                        futures.append(future)

        if len(futures) == 0:
            if not config.silent:
                display_name = "cover-float" if not config.models else ", ".join(config.models)
                rprint(f"[bold green]✓ No work to be done for {display_name} [/]")
            return True

        success = True
        if config.quiet and not config.silent:
            with Progress(
                TextColumn("{task.description}"),
                BarColumn(),
                MofNCompleteColumn(),
                TimeElapsedColumn(),
                transient=True,
            ) as progress:
                for future in progress.track(
                    as_completed(futures), total=len(futures), description="[cyan]Generating Cover-Float Tests"
                ):
                    success &= future.result()
            rprint(f"[bold green]✓ Generated {len(futures)} cover-float model(s)[/]")
        else:
            for future in as_completed(futures):
                success &= future.result()

        return success
