# CLAUDE.md — working notes for agents & contributors on `benches`

Auto-loaded context for Claude Code (and a quick orientation for humans). Keep it
short and current.

## What this is

- Standalone OCaml **micro-benchmarks** ported from
  [sandmark](https://github.com/ocaml-bench/sandmark), each built as its own binary.
- Driven by `~/running-ng` (suite types `OCamlBenchmarkSuite` /
  `OCamlMulticoreBenchmarkSuite`): for each (benchmark, runtime) it activates the
  runtime's opam switch and runs the benchmark's `<name>.build.sh`.

## Hard rules (do not violate)

- No "Claude"/Anthropic/Co-Authored-By: Claude in further commit messages.
- **Remote is `origin = github.com/ocaml-bench/benches`** — a *shared org* repo, not a
  personal fork. Commit/push only when asked. Current work branch:
  `add-hashcons-benchmarks`.
- **Build-script contract:** a `<name>.build.sh` assumes the opam switch is already
  activated (compiler + `dune` on PATH) and must produce the binary at
  `RUNNING_OCAML_OUTPUT` (named `<name>-<runtime>`). Do **not** reference the legacy
  `OCAML_EXECUTABLE` / `OCAML_HOME` env vars (pre-opam-compiler; gone).
- **Don't commit built binaries** (`*-<runtime>`) or generated data.
- Keep documentation files (eg. README.md) consistent with every commit. 


## Where things live (read first)

- `simple/` — stdlib/unix-only, single-file (compile with `ocamlopt`, no deps).
- `with_deps/` — dune multi-lib or generated data (dune only).
- `with_packages/` — external opam packages (zarith, lwt, decompress, yojson, owl…);
  the build script `opam install`s deps into the active switch first.
- `multicore/` — OCaml ≥ 5 (domains/effects; `domainslib`, `saturn_lockfree`).
- Each benchmark dir: `<name>.build.sh` (+ optional `<name>.build.deps.sh` for
  runtime-independent cached data) + a `dune` file.
- Docs: `README.md`, `SANDMARK_ADAPTATIONS.md` (source changes from sandmark),
  `BENCHMARK_INCOMPATIBILITIES.md` (per-version failure matrix).

## Build / run

- running-ng calls `<name>.build.sh` with: `RUNNING_OCAML_OUTPUT`,
  `RUNNING_OCAML_BENCH_DIR`, `RUNNING_OCAML_RUNTIME_NAME`, `RUNNING_OCAML_SWITCH`.
  Most scripts do `dune build --root . --profile release` then copy the exe to
  `RUNNING_OCAML_OUTPUT`.
- Drive via `~/running-ng`: `RUNNING_BENCH_DIR=~/benches CONFIG_FILE=… bash
  build_ocaml_binaries_gc_sweep.sh` (build) / `run_ocaml_bench_gc_sweep.sh` (run).
- `dune` itself comes from the running-ng *tools switch* on PATH; the compiler comes
  from the runtime switch.

## Gotchas (hard-won — don't rediscover)

- **Known non-building benches** (pre-existing, not regressions): `owl_gc` needs
  system `libopenblas-dev`/`liblapacke-dev`; `contrast` needs `camlimages` (incompatible
  with OCaml ≥ 5.4); `oxcaml_prefetch` only builds under OxCaml; a couple of
  `multicore/` (`graph500par`, `mandelbrot6`) fail on some versions. See
  `BENCHMARK_INCOMPATIBILITIES.md`.
- **Effect/Domain API drift**: ports from sandmark were adapted to the 5.x Effect API
  — record any further source change in `SANDMARK_ADAPTATIONS.md`.
- **Under ocaml-mmtk**: micro-benches build/run via running-ng's `OCamlMMTk` runtime,
  which auto-injects `setarch -R` (ASLR off, MMTk mmap flake) — no wrapper needed.

## Per-session workflow

1. New/edited benchmark → add/keep its `<name>.build.sh` + `dune`; mirror the build
   contract above.
2. Validate by building through running-ng (don't hand-roll compiler invocations).
3. Record source adaptations in `SANDMARK_ADAPTATIONS.md`, incompatibilities in
   `BENCHMARK_INCOMPATIBILITIES.md`; commit only when asked; `Co-Authored-By: Claude` is fine.
