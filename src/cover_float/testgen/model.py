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

import concurrent.futures
import logging
import logging.handlers
from pathlib import Path
from queue import Queue
from typing import Any, Callable, TextIO

from rich.progress import TaskID

import cover_float.common.log as log
from cover_float.scripts.postprocess import postprocess_testvectors

GLOBAL_MODELS: dict[
    str, Callable[[Path, log.StatusReporter, concurrent.futures.Executor], concurrent.futures.Future[None]]
] = {}
GLOBAL_MODEL_FUNCTIONS: dict[str, Callable[[TextIO, TextIO], None]] = {}


class MPLoggingHandler(logging.Handler):
    def __init__(self, queue: Queue[Any], task_id: TaskID) -> None:
        super().__init__()
        self.queue = queue
        self.task_id = task_id

    def emit(self, record: logging.LogRecord) -> None:
        self.queue.put(
            {
                "action": "update",
                "args": [self.task_id],
                "kwargs": {
                    "status": record.msg,
                },
            }
        )


def _run_model_by_name(
    model_name: str,
    output_dir: Path,
    task_id: TaskID,
    logging_queue: Queue[Any],
    post_process: bool,
) -> None:
    tv_path = output_dir / "testvectors" / f"{model_name}_tv.txt"
    cv_path = output_dir / "covervectors" / f"{model_name}_cv.txt"

    model_logger = logging.getLogger(model_name)

    if isinstance(model_logger, log.ModelLogger):
        model_logger.task_id = task_id
        model_logger.msg_queue = logging_queue

    model_logger.handlers = []
    model_logger.propagate = False

    # Handle Status Updates
    handler = MPLoggingHandler(logging_queue, task_id)
    handler.addFilter(log.OnlyStatusFilter())
    model_logger.addHandler(handler)

    # Handle Other Updates
    general_handler = logging.handlers.QueueHandler(logging_queue)
    general_handler.addFilter(log.ExcludeStatusFilter())
    model_logger.addHandler(general_handler)

    try:
        with tv_path.open("w") as test_f, cv_path.open("w") as cover_f:
            GLOBAL_MODEL_FUNCTIONS[model_name](test_f, cover_f)

        if post_process:
            test_vectors_dir = output_dir / "testvectors"
            readable_vectors_dir = output_dir / "readable"
            processed_vectors_dir = output_dir / "processed"
            postprocess_testvectors(model_name, test_vectors_dir, processed_vectors_dir, readable_vectors_dir)
    except Exception as e:
        logger = logging.getLogger(model_name)
        logger.exception(f"[bold red]Fatal Error in {model_name}[/] ", exc_info=e, extra={"markup": True})


def register_model(
    model_name: str,
) -> Callable[
    [Callable[[TextIO, TextIO], None]],
    Callable[[Path, log.StatusReporter, concurrent.futures.Executor], concurrent.futures.Future[None]],
]:
    def inner(
        fn: Callable[[TextIO, TextIO], None],
    ) -> Callable[[Path, log.StatusReporter, concurrent.futures.Executor], concurrent.futures.Future[None]]:
        # Store the function in a global dict so it can be accessed by the worker process
        GLOBAL_MODEL_FUNCTIONS[model_name] = fn

        def wrapper(
            output_dir: Path,
            status_reporter: log.StatusReporter,
            executor: concurrent.futures.Executor,
            post_process: bool = True,
        ) -> concurrent.futures.Future[None]:
            task_id = status_reporter.start_model(model_name)

            future = executor.submit(
                _run_model_by_name,
                model_name,
                output_dir,
                task_id,
                status_reporter.logging_queue,
                post_process,
            )
            future.add_done_callback(lambda _: status_reporter.stop_model(model_name))
            return future

        GLOBAL_MODELS[model_name] = wrapper
        return wrapper

    return inner
