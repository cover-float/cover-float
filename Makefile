# --- Targets ---

RM_CMD ?= rm -rf
AGGRESSIVENESS ?= 1

COVER_FLOAT_FLAGS =

ifeq ($(AGGRESSIVENESS), 0)
	COVER_FLOAT_FLAGS += --partial-output
endif

MODELS := B1 B2 B3 B5 B6 B7 B8 B9 B10 B11 B12 B13 B14 B15 B16 B18 B20 B21 B25 B26 B27 B29

.PHONY: build clean sim all $(MODELS)

# Notice that we pass --managed-python, we do this so that uv (scikit-build-core)
# will have a python enviornment with Python.h to build with.
all:
	uv run --managed-python cover-float-testgen $(COVER_FLOAT_FLAGS)

# Build target to compile the pybind11 module (if necessary)
build:
	@echo "Building python module"
	uv build --managed-python

sim:
	cd sim && vsim -c -do "do run.do"

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

# --- Include Dependency Files ---
# Include auto-generated dependency files if they exist
# -include $(DEPS)
