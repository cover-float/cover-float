# --- Targets ---

RM_CMD ?= rm -rf
AGGRESSIVENESS ?= 1
PROCESSED_ONLY ?=
SILENT ?=
GREP := grep -E
COVERAGE_SIMULATOR := questa

COVER_FLOAT_FLAGS =

ifeq ($(AGGRESSIVENESS), 0)
	COVER_FLOAT_FLAGS += --partial-output
endif

ifneq ($(PROCESSED_ONLY),)
	COVER_FLOAT_FLAGS += --only-processed-vectors
endif

ifneq ($(SILENT),)
	COVER_FLOAT_FLAGS += -qq
endif

MODELS := B1 B2 B3 B4 B5 B6 B7 B8 B9 B10 B11 B12 B13 B14 B15 B16 B17 B18 B19 B20 B21 B22 B23 B24 B25 B26 B27 B28 B29

.PHONY: build clean all $(MODELS) coverage coverage-questa coverage-verilator

# Notice that we pass --managed-python, we do this so that uv (scikit-build-core)
# will have a python enviornment with Python.h to build with.
all:
	uv run --managed-python cover-float-testgen $(COVER_FLOAT_FLAGS)

processed-tests-only:
	uv run --managed-python cover-float-testgen --partial-output --only-processed-vectors --quiet $(COVER_FLOAT_FLAGS)

# Build target to compile the pybind11 module (if necessary)
build:
	@echo "Building python module"
	uv build --managed-python

coverage-questa:
	cd sim && vsim -c -do "do run.do"

EMPTY_BIN := "\(\s*0/\s*0\)"
coverage-verilator:
	verilator --binary --coverage-user coverage/coverfloat.sv -Icoverage -Icoverage/covergroups/ -Wno-WIDTHEXPAND -j 0 --quiet -O3 --coverage-merge-instances
	cd obj_dir && ./Vcoverfloat
	@echo "Coverage Report:"
	@report=$$(verilator_coverage --report summary obj_dir/coverage.dat) || exit $$?; \
	summary=$$(printf "%s\n" "$$report" | $(GREP) -v -e $(EMPTY_BIN) -e "Coverage Summary:"); \
	printf "%s\n" "$$summary"; \
	if printf "%s\n" "$$summary" | $(GREP) -v -e "100\.0%" | $(GREP) -q . ; then \
		echo "Failing Covergroups:"; \
		verilator_coverage --report hier obj_dir/coverage.dat | $(GREP) -v -e "100\.0%" -e $(EMPTY_BIN) -e "Covergroup Coverage Summary:"; \
		exit 1; \
	fi

update-verilator-report:
	set -o pipefail; \
	$(MAKE) --no-print-directory coverage-verilator | tee >(sed -n '/Coverage Report:/,$$p' > reports/verilator.txt)

ifeq ($(COVERAGE_SIMULATOR), questa)
coverage: coverage-questa
else ifeq ($(COVERAGE_SIMULATOR), verilator)
coverage: coverage-verilator
else
$(error Set COVERAGE_SIMULATOR to either questa or verilator)
endif

$(MODELS):
	uv run --managed-python cover-float-testgen $(COVER_FLOAT_FLAGS) --model $@


# Clean target to remove build artifacts
clean:
	@echo "Cleaning build directory..."
	$(RM_CMD) build/
	$(RM_CMD) dist/
	$(RM_CMD) src/cover_float/__pycache__/
	$(RM_CMD) src/cover_float/testgen/__pycache__/
	$(RM_CMD) sim/coverfloat_worklib/
	$(RM_CMD) sim/transcript
	$(RM_CMD) sim/coverfloat.ucdb
	$(RM_CMD) tests/testvectors/B*_tv.txt
	$(RM_CMD) tests/covervectors/B*_cv.txt
	$(RM_CMD) tests/readable/B*_parsed.txt
	$(RM_CMD) tests/processed/*/B*.csv
	$(RM_CMD) tests/.stamp
	$(RM_CMD) obj_dir

# --- Include Dependency Files ---
# Include auto-generated dependency files if they exist
# -include $(DEPS)
