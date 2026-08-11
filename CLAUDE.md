# CLAUDE.md — working notes for agents & contributors on `benches`

Auto-loaded context for Claude Code (and a reference for contributors). The
human-facing docs are `README.md` and the per-group pages under
`docs/benchmarks/`. This file holds the operational detail that doesn't belong in
either: the build-script contract, the known-broken table, the gotchas, and the
backlog.

## What this is

- Standalone OCaml **micro-benchmarks** ported from
  [sandmark](https://github.com/ocaml-bench/sandmark), each built as its own
  binary by its own `<name>.build.sh`. 196 programs from 117 build scripts,
  in `simple/`, `with_deps/`, `with_packages/` and `multicore/`.
- Its sibling is `~/macro-benches` (real-world programs, vendored deps,
  input-size ladders). Same build-script contract, same env-var names,
  deliberately: a script here and a script there are interchangeable to
  running-ng. The split is by *what is being measured* — macro-benches asks
  whether real programs got faster, this repo asks which part of the runtime
  moved.
- Driven by `~/running-ng` (suite types `OCamlBenchmarkSuite` /
  `OCamlMulticoreBenchmarkSuite`): for each (benchmark, runtime) it activates the
  runtime's opam switch and runs the benchmark's `<name>.build.sh`.
- `manifest.yml` is **the program list** — name → path, build script, args. It
  exists because 196 programs come from 117 scripts (twelve `string_bench_*`
  programs share one script and differ only in arguments), so the scripts alone
  don't tell you what programs exist or how to run them. Before it existed, that
  list lived only in running-ng and this repo could not test itself.

## Hard rules (do not violate)

- **Do not comment on PRs, or add to PRs, unless explicitly asked to.**
- No "Claude"/Anthropic/Co-Authored-By: Claude in further commit messages.
- **Remote is `origin = github.com/ocaml-bench/benches`** — a *shared org* repo,
  not a personal fork. Commit/push only when asked.
- **Build-script contract:** a `<name>.build.sh` assumes the opam switch is
  already activated (compiler + `dune` on PATH) and must produce the binary at
  `RUNNING_OCAML_OUTPUT` (named `<name>-<runtime>`). Do **not** reference the
  legacy `OCAML_EXECUTABLE` / `OCAML_HOME` env vars (pre-opam-compiler; gone).
- **`manifest.yml` and running-ng's `micro_base.yml` must agree.** Add a
  benchmark to both in the same commit; `ci-manifest.py check --running-ng`
  diffs them program-for-program and argument-for-argument, and is the cheapest
  check in the repo. A program in only one of them is a benchmark that silently
  never runs, or a sweep entry that fails every time.
- **Don't commit built binaries** (`*-<runtime>`), `ci-logs/`, or generated data.
- Keep documentation consistent with every commit: `README.md`, the relevant
  `docs/benchmarks/<group>.md`, and this file.

## Where things live (read first)

- `simple/` — stdlib/unix-only. Mostly single-file; `capi/` has C stubs.
- `with_deps/` — dune multi-lib or generated input data (dune only, no opam).
- `with_packages/` — external opam packages; the build script `opam install`s
  its deps into the *active* switch first.
- `multicore/` — OCaml ≥ 5 (domains/effects; `domainslib`, `saturn_lockfree`).
- Each benchmark dir: `<name>.build.sh` (+ optional `<name>.build.deps.sh` for
  runtime-independent cached data) + a `dune` file.
- `manifest.yml` — the program list. `scripts/` — the tooling that reads it.
- `.github/workflows/ci.yml` — PR + post-merge build-and-run gate (see §CI).
- `docs/benchmarks/<group>.md` — human-facing page per group.
- Docs: `README.md`, `SANDMARK_ADAPTATIONS.md` (source changes from sandmark),
  `BENCHMARK_INCOMPATIBILITIES.md` (per-version failure matrix).

## Build / run

running-ng calls `<name>.build.sh` with `RUNNING_OCAML_OUTPUT`,
`RUNNING_OCAML_BENCH_DIR`, `RUNNING_OCAML_RUNTIME_NAME`, `RUNNING_OCAML_SWITCH`.
Most scripts do `dune build --root . --profile release` then copy the exe to
`RUNNING_OCAML_OUTPUT`.

Both the compiler **and** `dune` come from the runtime switch — running-ng pins
`dune` per switch (`OCaml.DUNE_VERSION`, currently 3.24.0) precisely so the two
sides of a comparison aren't built by different dune versions. The old "dune from
the tools switch" fallback is gone; don't reintroduce it.

Three ways in, cheapest first:

```bash
python3 scripts/ci-manifest.py check --running-ng     # seconds
python3 scripts/ci-manifest.py list --only "zdd fft"  # what a program actually runs

RUNNING_OCAML_RUNTIME_NAME=ocaml-5.5.0 bash scripts/ci-build-all.sh   # one switch, must be active
RUNNING_OCAML_RUNTIME_NAME=ocaml-5.5.0 bash scripts/ci-run-all.sh

bash scripts/test-runtimes.sh 5.5.0 trunk-c0f8c8ce       # activates switches itself
```

`test-runtimes.sh NAME…` maps each `NAME` to the opam switch
`running-ng-ocaml-NAME` and the binary tag `ocaml-NAME`, which is exactly what
running-ng produces — so the two leave interchangeable trees. It never creates a
switch; a missing one is reported and skipped.

`ci-build-all.sh` deletes the output binary before each build. Without that, a
stale binary from the previous compiler makes a build failure look like a pass
(and makes running-ng skip the rebuild).

Or drive running-ng directly: `RUNNING_BENCH_DIR=~/benches CONFIG_FILE=… bash
build_ocaml_binaries_gc_sweep.sh` (build) / `run_ocaml_bench_gc_sweep.sh` (run).
Configs pointing here: `examples/smoke_micro_550.yml` (six benchmarks, ~1 min)
and `experiments/e2e_micro_5.5.0_vs_trunk.yml` (whole suite). Pass
`RUNNING_REUSE_SWITCHES=1` unless you actually want both compilers rebuilt from
source — running-ng deletes and rebuilds a pre-existing switch by default.

Neither `ci-run-all.sh` nor `test-runtimes.sh` measures anything: one invocation, no
perf, no olly, no pinning. They are build/run correctness gates.

## Known broken (verified 2026-08-10, OCaml 5.5.0 and trunk `c0f8c8ce`)

Full build+run of all 195 enabled programs on both runtimes:
**195/195 build, 195/195 run clean** on each — the first time the whole suite
has passed. Anything not listed here builds and runs on both.

| Program | Symptom | Status |
|---|---|---|
| `contrast` | `camlimages` 5.0.5 fails to build: `/usr/bin/ld: final link failed: bad value` | Pre-existing, both runtimes. Removed from running-ng's selection — the source stays, the sweep no longer wastes a build slot failing. Needs a camlimages that works on ≥ 5.4. |
| `oxcaml_prefetch` | Uses OxCaml-only intrinsics | By design. `requires: oxcaml` in the manifest; skipped unless `RUNTIME_KIND=oxcaml`. |

Fixed as part of the 2026-08-10 sweep — each had **never** run successfully, on
any runtime, and had been failing silently inside every sweep:

- `fannkuchredux` / `fannkuchredux_multicore` —
  `Invalid_argument("index out of bounds")` for every `n`. `fr` calls
  `Perm.next` once more than there are permutations, so the last worker chunk
  (`hi = n!`) walks off the end of `c`. Sandmark hides this by compiling with
  `-unsafe`; the dune port here doesn't, so the latent out-of-bounds read became
  a hard failure. Fixed by not advancing past the final permutation — the
  discarded `next` never contributed to the result.
- `test_sched` — reads `Sys.argv.(3)` (`list_length`) but the config passed only
  two arguments. Now `2 1000000 1000` (~1.7s); the old `2 1000` would have been
  ~0s of work even if it had run.
- `quicksort_multicore` — `Effect.Unhandled(Domainslib__Task.Wait)`: an
  `await`/`parallel` outside the `Task.run` scope.
- `rec_eff_evenodd` — no args in the config, so it took its built-in default of
  2 × 500M effect installs and hit the suite's 120s timeout every time. Now given
  explicit args.

**When you touch any of these, re-verify with `scripts/test-runtimes.sh`, not by
eye.** The reason they survived so long is that a sweep reports a failed
benchmark as a missing data point, which looks like noise.

## CI

`.github/workflows/ci.yml` runs on **pull requests into `master`** and on
**pushes to `master`** (plus a weekly cron and `workflow_dispatch`); nothing runs
on other branch pushes. Two legs — `stable` (5.5.0, gates) and `trunk`
(`continue-on-error`, tracks a moving compiler). Three steps that matter:
`ci-manifest.py check`, then `ci-build-all.sh`, then `ci-run-all.sh`, with
`RUNNING_OCAML_RUNTIME_NAME: ci` so binaries land as `<program>-ci`.

**CI runs every program, not a subset.** macro-benches flags a `ci_run:` subset
because its large rungs don't fit a hosted runner; here the whole suite runs in
**~4.5 min** of wall time (263s for 195 programs, measured 2026-08-10 with
`_build` warm) and builds in ~21s, so there is nothing to gain by choosing
favourites and a whole class of "the benchmark CI skipped was the broken one" to
lose. If you are tempted to add `ci_run:`, measure first — the cost here is the
cold `opam install` for `with_packages/`, which caching addresses, not the run.

The `check` step deliberately omits `--running-ng`: that cross-checks against a
running-ng checkout, which CI does not have. Keeping the two in step stays a
local and reviewer responsibility.

The weekly cron uses its own cache scope so it starts cold. Unlike
macro-benches' cold run, this one genuinely *is* a drift check: nothing here is
version-pinned (the `with_packages/` scripts `opam install` whatever the solver
picks), so the cron is the only thing that notices when a new zarith, lwt or
domainslib stops working.

## The running-ng boundary (shared with macro-benches)

Both benchmark repos present the *same* interface to running-ng. Verified
2026-08-10; when you change one side, check the other.

**Consistent — do not diverge:**

| | benches | macro-benches |
|---|---|---|
| build-script env vars | `RUNNING_OCAML_{BENCH_DIR,OUTPUT,RUNTIME_NAME}` | same, plus `RUNNING_OCAML_SWITCH{,_PREFIX}` |
| output binary | `<program>-<runtime>` in the benchmark dir | same |
| suite type | `OCamlBenchmarkSuite` (+ `Multicore`/`Oxcaml` variants) | `OCamlBenchmarkSuite` |
| program list | `manifest.yml` | `benchmarks/manifest.yml` |
| repo-side tooling | `scripts/ci-{manifest.py,build-all.sh,run-all.sh}` | same names |
| running-ng config | `base/ocaml/micro_base.yml` | `base/ocaml/macro_base.yml` |

macro-benches reading two extra env vars is a superset, not a divergence: only
`ocamlc-self-compile` and `jsoo` need them, because they run the runtime's *own*
compiler as the workload. running-ng always exports all five.

**Deliberately different — and why:**

- **`RUNNING_BENCH_DIR` vs `RUNNING_MACRO_BENCH_DIR`.** Two names for the same
  thing; running-ng's launch scripts export both as synonyms. Historical, and
  not worth a flag day — but note the two entry points disagreed until
  2026-08-10 (`build_ocaml_binaries_gc_sweep.sh` read only the first, and
  resolved its `../benches` fallback eagerly under `set -e`, so a macro-only
  *build* aborted if `~/benches` was absent). Fixed; keep them symmetric.
- **Manifest location and per-program fields.** `benchmarks/manifest.yml` with
  `tool:` there, root `manifest.yml` with `path:` here — because this repo has
  no single `benchmarks/` directory, its groups are top-level. macro-benches has
  `ci_run:` and `expected_exit:`; this repo has `suite:`, `requires:` and a
  `suites:` block carrying per-suite timeouts (macro-benches puts the timeout on
  the program). Each fits its own layout. If a benchmark here ever needs a
  non-zero success exit, spell the field `expected_exit:` and give it exact-
  equality semantics, matching macro-benches and running-ng.
- **No `make setup` here.** macro-benches has a vendoring phase; this repo has
  nothing to vendor.

## Gotchas (hard-won — don't rediscover)

- **`timeout` on this machine is uutils coreutils, not GNU.** With
  `--kill-after` set, uutils 0.2.2 returns **125** on a timeout where GNU
  returns 124 — and 125 otherwise means "timeout itself failed". `ci-run-all.sh`
  disambiguates on elapsed time; don't "simplify" that back to a bare
  `124|137)` case or every timeout gets reported as an ordinary crash (which is
  how `rec_eff_evenodd`'s timeout first showed up as "exit 125").
- **Several benchmarks write their result to stdout in bulk** — `fasta3`,
  `fasta6` and `revcomp2` emit ~243 MB of FASTA each, `mandelbrot6` a 31 MB PBM.
  Capturing that whole is 776 MB of logs *per runtime*, so `ci-run-all.sh` keeps
  only the last `LOG_TAIL_BYTES` (64 KB) via `tail -c`. It must be `tail`, not
  `head`: truncating from the front closes the pipe early and SIGPIPEs the
  benchmark, changing the exit code the script is there to check.
- **A benchmark that "has always been in the config" is not evidence it runs.**
  Five of them didn't. `ci-run-all.sh` exists because building is not running.
- **Arguments live in the config, not in the benchmark.** Many benchmarks have
  built-in defaults far larger or far smaller than what the sweep passes
  (`rec_eff_evenodd` defaults to 500M iterations). Running a binary bare is a
  different benchmark from what the sweep runs — always check `ci-manifest.py
  list --only <name>`.
- **`with_packages/` is not hermetic** — each build script `opam install`s into
  the active switch, so the library version is a function of the switch, not of
  the repo. That is why `decompress`, `yojson`, `owl` and `zarith_pi` moved to
  `~/macro-benches` (vendored, pinned). Prefer not to grow this directory; if a
  benchmark's *library* is what you want to measure, it belongs in macro-benches.
- **Benchmark names must be unique across suites.** `nbody` used to name two
  different programs (benchmarksgame's 5-planet integrator in `with_packages/`
  and multicore-numerical's 1024-body one), so results from any run covering both
  collided. The first is now `nbody_benchmarksgame` (build script still
  `nbody.build.sh`). `manifest.yml` is keyed by program name, so this class of
  bug now fails `check` instead of silently corrupting results.
- **Effect/Domain API drift**: ports from sandmark were adapted to the 5.x Effect
  API (sandmark's originals use the pre-5.2 `effect` keyword) — record any
  further source change in `SANDMARK_ADAPTATIONS.md`.
- **`-unsafe` is load-bearing in sandmark.** Several benchmarksgame programs
  index past the end by design and rely on `-unsafe` to make it harmless. The
  dune ports here mostly don't pass it, which turns latent out-of-bounds reads
  into hard failures — a good thing, but it means "sandmark runs it fine" is not
  evidence the port will.
- **Under ocaml-mmtk**: micro-benches build/run via running-ng's `OCamlMMTk`
  runtime, which auto-injects `setarch -R` (ASLR off, MMTk mmap flake) — no
  wrapper needed.
- **`dune build --root <benchdir>`** means `_build/` lives inside each benchmark
  directory and is *shared across runtimes* (unlike macro-benches, which uses
  `--build-dir _build-<runtime>`). Building runtime B after runtime A rebuilds
  from scratch. Fine serially; do not run two runtimes concurrently against the
  same tree.

## Per-session workflow

1. New/edited benchmark → add/keep its `<name>.build.sh` + `dune`; mirror the
   build contract above.
2. Add it to `manifest.yml` **and** running-ng's `micro_base.yml` in the same
   commit; `ci-manifest.py check --running-ng` must pass.
3. Validate by building *and running* through `scripts/test-runtimes.sh` (or
   running-ng) — don't hand-roll compiler invocations, and don't call a build
   success a pass.
4. Record source adaptations in `SANDMARK_ADAPTATIONS.md`, incompatibilities in
   `BENCHMARK_INCOMPATIBILITIES.md`; commit only when asked.

## Backlog

### Re-enable `contrast` — filed 2026-08-10

Needs a `camlimages` that links on OCaml ≥ 5.4. It's the only image-processing
workload in the suite, and the only one with that pixel-loop allocation shape.

### Audit the remaining sandmark `-unsafe` ports — filed 2026-08-10

Two of the three out-of-bounds failures found on 2026-08-10 came from the same
root cause (sandmark compiles with `-unsafe`, the dune port doesn't). The rest of
`with_packages/benchmarksgame/` and `multicore/multicore-numerical/` come from
the same source and have not been audited for the same pattern — they run clean
today, which only proves they don't index out of bounds on the *current*
arguments.
