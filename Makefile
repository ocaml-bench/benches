.PHONY: clean clean-dune clean-with-deps clean-macrobenchmarks

clean: clean-dune clean-with-deps clean-macrobenchmarks
	@echo "Cleaning benchmark build artifacts under $(CURDIR)"
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
			-name "*-oxcaml-*" \
		\) -delete

clean-dune:
	@echo "Cleaning dune build directories under $(CURDIR)"
	@find . -type d \( -name "_build" -o -name "_build-running" \) -prune -exec rm -rf {} +

# Remove generated input data files produced by build.deps.sh scripts.
# These are runtime-version-independent and recreated automatically on next build.
clean-with-deps:
	@echo "Cleaning generated input data under $(CURDIR)/with_deps"
	@rm -f with_deps/graph500seq/edges.data
	@rm -f with_deps/benchmarksgame/input*.txt
	@rm -f multicore/graph500par/edges.data

# Remove generated output files from macrobenchmark runs.
clean-macrobenchmarks:
	@echo "Cleaning generated macrobenchmark outputs under $(CURDIR)/macrobenchmarks"
	@rm -f macrobenchmarks/menhir/sysver.automaton
	@rm -f macrobenchmarks/menhir/sysver.conflicts
	@rm -f macrobenchmarks/menhir/sysver.ml
	@rm -f macrobenchmarks/coq/*.glob
	@rm -f macrobenchmarks/coq/.*.aux
