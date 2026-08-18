# benches

A suite of OCaml **micro-benchmarks**, ported from
[sandmark](https://github.com/ocaml-bench/sandmark), for comparing one OCaml
runtime against another on small, sharply-focused workloads: allocation rate,
mark and sweep throughput, effect-handler dispatch, weak-table and finaliser
behaviour, domain synchronisation, the OCaml→C calling convention.

Where its sibling [macro-benches](https://github.com/ocaml-bench/macro-benches)
answers *"is the compiler faster on real programs?"*, this repo answers *"which
part of the runtime moved?"*. When a macro-benchmark regresses, these are the
benchmarks that tell you where to look — and because each one is a single small
binary with no vendored dependency tree, they build in seconds and are cheap to
sweep across dozens of GC configurations.

Each benchmark is its own binary, built by its own `<name>.build.sh` honouring a
small, documented contract. You can use it two ways:

- **Standalone.** Activate any opam switch with `dune` on `PATH`, run a
  benchmark's build script, and run the binary yourself.
- **Orchestrated.** Point [running-ng](https://github.com/udesou/running-ng) at
  the repo and let it manage per-runtime opam switches and drive cross-runtime,
  frame-pointer, flambda, or GC-parameter sweeps.

## The benchmarks

196 programs built from 117 build scripts, 195 of which run on stock OCaml
(`oxcaml_prefetch` needs OxCaml). Many programs share a script and differ only
in arguments — one `stdlib/string_bench.build.sh` backs twelve
`string_bench_*` programs, one `capi.build.sh` backs six. The authoritative list
of *(program, script, arguments)* is [`manifest.yml`](manifest.yml).

| Group | Programs | What's in it | Needs |
|---|--:|---|---|
| [`simple/`](docs/benchmarks/simple.md) | 24 | The classic sandmark sequential set: `almabench`, `bdd`, `kb`, `zdd`, `minilight`, `markbench`, six numerical-analysis kernels, and the six `capi` OCaml→C calling-convention probes | stdlib, unix, one C stub |
| [`simple/stdlib`](docs/benchmarks/stdlib.md) | 69 | Data-structure microbenchmarks over `Array`, `Bytes`, `String`, `Map`, `Set`, `Stack`, `Hashtbl`, `Bigarray`, `Str` and the polymorphic compare/equal path | stdlib, str |
| [`simple/simple-tests`](docs/benchmarks/simple-tests.md) | 25 | GC-facing probes: raw allocation rate, list and stack shapes, laziness, `Gc.finalise`, weak arrays, ephemeron tables | stdlib |
| [`with_deps/`](docs/benchmarks/with-deps.md) | 10 | Benchmarks needing a multi-library build or a generated input: `graph500seq`, four benchmarksgame FASTA/k-nucleotide programs, five parallel `mpl` programs | dune, generated data |
| [`with_packages/`](docs/benchmarks/with-packages.md) | 12 | Benchmarks over external opam packages: seven benchmarksgame programs, three zarith kernels, and two Lwt scheduling benchmarks (`test_lwt`, `test_sched`) | `opam install` at build time |
| [`multicore/`](docs/benchmarks/multicore.md) | 56 | OCaml 5 only: 17 effect benchmarks, 7 lock-free structures, 22 domainslib numerical kernels, gcroots, grammatrix, parallel minilight and graph500 | OCaml ≥ 5, domainslib, saturn |

Each linked page lists every program with its source, build, arguments, and what
it is meant to stress.

Four benchmarks that used to live in `with_packages/` — `test_decompress`,
`ydump`, `owl_gc` and `zarith_pi` — now live in **macro-benches** instead, where
they are built from vendored, version-pinned sources and have proper input-size
ladders. The copies here `opam install`ed whatever the solver picked for each
switch, so the library under test changed along with the compiler under test.

## Quick start

### Prerequisites

opam 2.3+, and a switch with `dune` and `ocamlfind`. `with_packages/` benchmarks
install their own opam dependencies at build time, so a handful of system
libraries need to be present first:

```bash
sudo apt install build-essential m4 pkg-config libgmp-dev zlib1g-dev
```

### Build and run one benchmark by hand

```bash
eval $(opam env --switch=running-ng-ocaml-5.5.0 --set-switch)

bash simple/almabench/almabench.build.sh      # writes simple/almabench/almabench-runtime
./simple/almabench/almabench-runtime
```

The build script assumes the switch is already active and writes its binary to
`$RUNNING_OCAML_OUTPUT` (defaulting to `<name>-<runtime>` in the benchmark's own
directory). See [§Build-script contract](#build-script-contract).

Arguments matter — several benchmarks take an input size or an input file, and
running one bare gives you a different benchmark than the sweep runs. Ask the
manifest:

```bash
python3 scripts/ci-manifest.py list --only "zdd markbench string_bench_map"
```

### Build and run everything

Across one or more runtimes, with a summary at the end:

```bash
bash scripts/test-runtimes.sh                        # 5.5.0 + newest local trunk switch
bash scripts/test-runtimes.sh 5.5.0 trunk-c0f8c8ce   # explicit
SKIP_RUN=1 bash scripts/test-runtimes.sh             # build phase only
ONLY="almabench bdd fft" bash scripts/test-runtimes.sh
```

Each `NAME` argument selects the opam switch `running-ng-ocaml-NAME` and tags
binaries `<program>-ocaml-NAME` — the same names running-ng uses, so a tree this
script leaves behind is the tree a sweep would find. It never creates a switch;
if one is missing it says so and moves on.

The two phases can also be driven separately — this is exactly what CI does:

```bash
make check                                          # manifest vs. tree
RUNNING_OCAML_RUNTIME_NAME=ocaml-5.5.0 bash scripts/ci-build-all.sh
RUNNING_OCAML_RUNTIME_NAME=ocaml-5.5.0 bash scripts/ci-run-all.sh
```

None of that needs anything outside this repo — an opam switch with `dune` is
the whole prerequisite.

Neither is a measurement: one invocation, no perf, no olly, no core pinning,
wall time printed only so an obvious blow-up is visible. They are build/run
correctness gates. Real numbers come from running-ng on quiet hardware.

Per-program logs land in `ci-logs/{build,run}/<runtime>/<program>.log`, capped at
the last 64 KB of output — `fasta3`, `fasta6` and `revcomp2` each write ~243 MB
of FASTA to stdout. Raise it with `LOG_TAIL_BYTES`.

### CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs the three steps above
on every PR into `master` and on every push to it, against OCaml 5.5.0 (gating)
and `ocaml/ocaml` trunk (informational). It runs **every** program, not a subset:
the whole suite builds in ~21s and runs in ~4.5 min.

As of 2026-08-10 all 195 enabled programs build and run clean on both OCaml
5.5.0 and trunk `c0f8c8ce`; see
[BENCHMARK_INCOMPATIBILITIES.md](BENCHMARK_INCOMPATIBILITIES.md).

### Run sweeps

For cross-runtime, frame-pointer, flambda or GC-parameter sweeps you want
running-ng to manage the per-runtime switches:

```bash
cd ~/running-ng
RUNNING_BENCH_DIR=~/benches \
CONFIG_FILE=src/running/config/examples/ocaml_gc_sweep_example.yml \
  bash build_ocaml_binaries_gc_sweep.sh    # build only
  bash run_ocaml_bench_gc_sweep.sh         # build + run + measure
```

Two ready-made configs point at this repo:

| Config | What it does |
|---|---|
| `examples/smoke_micro_550.yml` | six benchmarks, 5.5.0 vs trunk, 1 invocation — a plumbing check, ~1 min |
| `experiments/e2e_micro_5.5.0_vs_trunk.yml` | the whole suite, 5.5.0 vs trunk, 1 invocation |

running-ng keeps its own copy of the program list in
`src/running/config/base/ocaml/micro_base.yml`. If you maintain both, `make
check-running-ng` diffs it against `manifest.yml` program for program and
argument for argument. That check is opt-in on purpose: this repo builds, runs
and tests itself without running-ng, and neither `make check` nor CI will ever
ask you for a running-ng checkout.

### Clean

```bash
make clean        # binaries, dune _build dirs, and generated input data
```

### Make targets

| Target | What it does |
|---|---|
| `make check` | manifest vs. tree — needs nothing outside this repo |
| `make build` / `make run` | build / run every program with the compiler on `PATH` |
| `make test` | both, across 5.5.0 and the newest local trunk switch |
| `make check-running-ng` | *opt-in*: also diff the program list against running-ng's `micro_base.yml` |
| `make clean` | binaries, `_build` dirs, generated input data, `ci-logs/` |

## Build-script contract

A `<name>.build.sh` is called with the runtime's opam switch already activated,
so the compiler, `dune`, and any installed packages are on `PATH`. It reads:

| Variable | Meaning |
|---|---|
| `RUNNING_OCAML_BENCH_DIR` | the benchmark's own directory |
| `RUNNING_OCAML_OUTPUT` | where to write the binary (absolute) |
| `RUNNING_OCAML_RUNTIME_NAME` | runtime tag, e.g. `ocaml-5.5.0` |
| `RUNNING_OCAML_SWITCH` | the active opam switch (exported for parity with macro-benches; no script here needs it) |

and must leave an executable at `RUNNING_OCAML_OUTPUT`. Most scripts are four
lines: `dune build --root "$BENCH_DIR" --profile release <target>.exe`, then copy
the result. A benchmark needing runtime-independent generated input (a graph edge
list, a FASTA file) puts it in a companion `<name>.build.deps.sh` that the build
script calls first and that skips itself if the data already exists — so the data
is generated once and shared across every runtime in a sweep.

[macro-benches uses the same
contract](https://github.com/ocaml-bench/macro-benches#build-script-contract) —
same variable names, same "leave an executable at `RUNNING_OCAML_OUTPUT`" — with
two additions its benchmarks need and these don't: `RUNNING_OCAML_SWITCH_PREFIX`
(for the three benchmarks that run the runtime's own compiler as the workload),
and dispatch on the output filename when one script backs several programs.
Change one side of the contract, check the other.

## Layout

```text
simple/<bench>/         stdlib/unix only — <name>.build.sh + dune + sources
with_deps/<bench>/      multi-library builds or generated input data
with_packages/<bench>/  external opam packages; the build script installs them
multicore/<bench>/      OCaml >= 5 — domains, effects, domainslib, saturn
docs/benchmarks/        one page per group: what each program runs
scripts/                ci-manifest.py, ci-build-all.sh, ci-run-all.sh, test-runtimes.sh
.github/workflows/      CI: build + run every program on 5.5.0 and trunk
manifest.yml            the program list: name, path, script, args   (committed)
ci-logs/                per-program build and run logs      (generated, gitignored)
```

## More documentation

- [docs/benchmarks/](docs/benchmarks) — a page per group, with every program.
- [SANDMARK_ADAPTATIONS.md](SANDMARK_ADAPTATIONS.md) — every source change made
  when porting from sandmark, and why.
- [BENCHMARK_INCOMPATIBILITIES.md](BENCHMARK_INCOMPATIBILITIES.md) — which
  benchmarks fail on which compiler versions.
- [CLAUDE.md](CLAUDE.md) — the operational detail: known-broken benchmarks, the
  gotchas worth knowing before you touch the build, and the backlog.
