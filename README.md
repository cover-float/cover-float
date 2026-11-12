# cover-float
An implementation of the IBM floating point test suite, written by Aharoni et. al, found [here](https://web.archive.org/web/20210701231302/https://www.research.ibm.com/haifa/projects/verification/fpgen/papers/ieee-test-suite-v2.pdf). We provide functional coverage written in SystemVerilog and Python test generators for each of the 29 models listed in the paper. In addition, we provide python bindings for a modified version of softfloat that allows us to extract intermediate information from floating point operations, such as the pre-rounding intermediate and the multiplication result of a fused multiply-add operation.

The project has SystemVerilog coverage in `coverage`, Python test generation in `src/cover_float`, and softfloat bindings in `src/cpp`. The modified softfloat source is kept in the Spike submodule at `src/dependencies/softfloat/spike`; CMake fetches an unmodified version for comparison. Clone the repository with `--recurse-submodules` to fetch the modified source.

Python generation depends on `uv` as a build system for the softfloat bindings and as a runner. Test generation can be invoked through `make all` or simply `make`. To generate a specific model, e.g. B4, run `make B4`. Coverage is invoked through `make coverage`, and can be used with either QuestaSim or Verilator depending on the `COVERAGE_SIMULATOR` switch. See the makefile for more configuration options.

## Releases

Wheels are built with [cibuildwheel](https://cibuildwheel.pypa.io) for Linux (glibc and musl, x86_64 and aarch64) and macOS (arm64), for CPython 3.10 and later. To make a release:

1. Set the new version with `uv version <version>` (for example, `uv version 0.2.0`), and merge that change.
2. Create a GitHub release with the tag `v<version>` (for example, `v0.2.0`).

The `Release` workflow checks that the tag matches the version in `pyproject.toml`. Then it builds the sdist and all wheels, and publishes them to PyPI with trusted publishing. The publish job runs in the protected `pypi` environment.
