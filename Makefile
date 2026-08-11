.PHONY: check build run test clean clean-dune clean-data

# --- checks and test runs ---------------------------------------------------

check:  ## manifest vs. tree vs. running-ng's micro_base.yml
	@python3 scripts/ci-manifest.py check --running-ng

build:  ## build every program with the compiler currently on PATH
	@bash scripts/ci-build-all.sh

run:    ## run every built program once
	@bash scripts/ci-run-all.sh

test:   ## build + run everything under 5.5.0 and the newest local trunk switch
	@bash scripts/test-runtimes.sh

# --- cleaning ---------------------------------------------------------------

clean: clean-dune clean-data
	@echo "Cleaning benchmark binaries and object files under $(CURDIR)"
	@find . -type f \
		-not -path "./.git/*" \
		\( \
			-name "*.o" -o \
			-name "*.obj" -o \
			-name "*.a" -o \
			-name "*.so" -o \
			-name "*.cmi" -o \
			-name "*.cmo" -o \
			-name "*.cmx" -o \
			-name "*.cmxa" -o \
			-name "*.cma" -o \
			-name "*.cmt" -o \
			-name "*.cmti" -o \
			-name "*.annot" -o \
			-name "*.opt" -o \
			-name "*-ocaml-*" -o \
			-name "*-oxcaml-*" -o \
			-name "*-mmtk*" \
		\) -delete
	@rm -rf ci-logs

clean-dune:
	@echo "Cleaning dune build directories under $(CURDIR)"
	@find . -type d \( -name "_build" -o -name "_build-running" \) -prune -exec rm -rf {} +

# Generated input data produced by the *.build.deps.sh scripts. Runtime-version
# independent, so it is generated once and shared across every runtime in a
# sweep — which is also why `clean` regenerating it costs real time.
clean-data:
	@echo "Cleaning generated input data under $(CURDIR)"
	@rm -f with_deps/graph500seq/edges.data
	@rm -f with_deps/benchmarksgame/input*.txt
	@rm -f multicore/graph500par/edges.data
	@rm -f simple/minilight/*.ppm
