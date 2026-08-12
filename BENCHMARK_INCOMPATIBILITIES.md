# Benchmark Incompatibilities Across OCaml Versions

Which benchmarks fail, on which compilers, and why. Source-level changes made
during the sandmark port live in `SANDMARK_ADAPTATIONS.md` instead — those are
deliberate edits, these are things that don't work.

## Verified: OCaml 5.5.0 and trunk `c0f8c8ce` (2026-08-10)

Full build **and run** of all 195 enabled programs on both compilers, via
`bash scripts/test-runtimes.sh 5.5.0 trunk-c0f8c8ce`:

| Runtime | Builds | Runs clean |
|---|---|---|
| OCaml 5.5.0 | 195/195 | 195/195 |
| OCaml trunk `c0f8c8ce` | 195/195 | 195/195 |

Nothing in the enabled set fails on either compiler, and the two agree
program-for-program. Two programs are excluded from that set by configuration
rather than by failing:

| Program | Why it is excluded |
|---|---|
| `contrast` | `camlimages` 5.0.5 does not build on OCaml ≥ 5.4 — see below. Listed under `disabled:` in `manifest.yml` and commented out of running-ng's `micro_base.yml`. |
| `oxcaml_prefetch` | OxCaml-only by design (`requires: oxcaml`). |

**This is the first run in which the whole suite passed.** The sweep that
produced these numbers started at 190/196, and the five failures it exposed had
each been failing on *every* runtime since the port — a sweep reports a crashed
benchmark as a missing data point, which reads as noise. They are fixed:

| Program | Was | Fix |
|---|---|---|
| `fannkuchredux` | `Invalid_argument("index out of bounds")` for every `n` | `Perm.next` was called once past the last permutation; sandmark hid it with `-unsafe`. See `SANDMARK_ADAPTATIONS.md`. Now returns the reference values for `n = 11`. |
| `fannkuchredux_multicore` | same | same |
| `quicksort_multicore` | `Effect.Unhandled(Domainslib__Task.Wait)` | top-level call now wrapped in `T.run pool`, like every sibling |
| `test_sched` | `Invalid_argument("index out of bounds")` | config passed 2 args; the program reads `Sys.argv.(3)`. Now `2 1000000 1000` |
| `rec_eff_evenodd` | 120 s timeout every run | no args in the config, so it took its built-in default of 2 × 500M effect installs. Now `2 5000000`, matching `rec_seq_evenodd` |

Re-verify with `scripts/test-runtimes.sh`, not by eye.

## Older runtimes (as of 2026-03-17, not re-verified since)

- **OCaml 4.14.3** — last pre-multicore release
- **OCaml 5.1.0** — early OCaml 5
- **OCaml 5.4.1** — then-latest stable
- **OxCaml trunk** — Jane Street fork (commit `068b255`)

These predate the 2026-08-10 sweep and the fixes above, and were taken over a
smaller program set. Treat the OxCaml and 4.14/5.1 sections below as the
still-current explanation of *why* those runtimes fail, and the counts as
historical.

| Runtime | Builds OK | Expected failures | Notes |
|---|---|---|---|
| OCaml 4.14.3 | 35/35 | 42 skipped | Multicore + OxCaml suites require OCaml >= 5 |
| OCaml 5.1.0 | 75/77 | 2 | graph500par, mandelbrot6_multicore (see below) |
| OCaml 5.4.1 | 76/77 | 1 | oxcaml_prefetch (OxCaml-only) |
| OxCaml trunk | 72/77 | 5 | Locality type errors (see below) |

---

## OxCaml Incompatibilities

(`ydump` was also on this list; it now lives in `~/macro-benches`.)

OxCaml's extended type system adds locality mode annotations (`@ local`) to standard
library functions and propagates them through type inference. Some upstream packages
and benchmark sources are incompatible.

### mandelbrot6_multicore (multicore-numerical) — benchmark source

OxCaml's `output_bytes` has signature `out_channel -> bytes @ local -> unit`.
The `@ local` annotation makes it incompatible with `Array.iter`'s expected
callback type `'a -> unit`. Stock OCaml's `output_bytes` has no locality annotation.

```
Error: This expression has type out_channel -> bytes @ local -> unit
       but an expression was expected of type 'a -> unit
```

Fix would require modifying the source, which would break stock OCaml builds.

### chameneos_redux_lwt, thread_ring_lwt_mvar, thread_ring_lwt_stream (sandmark-with-packages) — lwt_unix

The lwt dependency chain resolves (dune-configurator is built from source), but
`lwt_unix` itself fails to compile due to OxCaml locality annotations on the
`Unix` module:

```
File "src/unix/lwt_unix.cppo.ml", line 1552, characters 51-60:
Error: This expression has type
         "Unix.file_descr -> Bytes.t -> int -> int -> Unix.msg_flag list -> int"
       but an expression was expected of type
         "Unix.file_descr -> bytes @ local -> int -> int -> Unix.msg_flag list @ local -> int"
```

Fix requires patching lwt upstream or maintaining an OxCaml fork.


### oxcaml_prefetch — OxCaml-only by design

`OCamlOxcamlBenchmarkSuite` requires a `type: OxCaml` runtime. Fails for all 4
stock OCaml runtimes (expected, not a bug).

---

## OCaml 5.1.0 Incompatibilities (2 benchmarks)

### graph500par/kernel1_run_multicore

With the compiler version lock (see infrastructure section below), opam selects
`domainslib 0.5.1` instead of `0.5.2` for OCaml 5.1.0. graph500par may use
domainslib APIs that changed between 0.5.1 and 0.5.2 (needs investigation).

### mandelbrot6_multicore

Fails on 5.1.0 for a similar reason to OxCaml — `output_bytes` signature
differences in early OCaml 5 stdlib.

---

## Package / System Dependency Issues


### contrast (sandmark-with-packages) — camlimages build failure on OCaml 5.4

`camlimages 5.0.5` fails to compile on OCaml 5.4.x:

```
[ERROR] The compilation of camlimages.5.0.5 failed at "dune build -p camlimages -j 31 @install"
```

Re-verified 2026-08-10 on both 5.5.0 and trunk `c0f8c8ce`; the failure is now at
link time:

```
/usr/bin/ld: final link failed: bad value
collect2: error: ld returned 1 exit status
```

This is an upstream issue — `camlimages` has not been updated for OCaml 5. Since
it fails on every compiler we care about, `contrast` is now **disabled** rather
than left to fail a build slot in every sweep: it is under `disabled:` in
`manifest.yml` and commented out of running-ng's `micro_base.yml`. The source
stays in the tree; re-enable both when a camlimages that links is available.

---

## OCaml 4.14.3 — Multicore Suites Skipped (42 benchmarks)

`OCamlMulticoreBenchmarkSuite` enforces OCaml >= 5. All 41 multicore benchmarks
plus `oxcaml_prefetch` are skipped for 4.14.3. This is by design.

The sequential baselines in `multicore-numerical` (nbody, floyd_warshall,
game_of_life, quicksort, mergesort, matrix_multiplication, LU_decomposition,
nqueens, evolutionary_algorithm) don't use Domain/Effect but are in a multicore
suite, so they can't be tested with 4.14 through the framework without moving
them to a non-multicore suite or changing the suite type.

---

## Infrastructure workarounds (removed)

This file used to carry ~90 lines of workarounds for the old
`lib/opam_auto_install.sh` ext-switch build (opam sandbox not finding external
compilers, opam silently upgrading the compiler inside an ext-switch, `num` 1.5
vs OCaml ≥ 5.2, OxCaml stubs shadowing real packages, autotools `configure`
truncating long compiler paths, `dllzarith.so` under the sandbox). That build
approach was replaced by `opam-compiler`, which creates a real switch per
runtime, and none of it applies any more. It is in git history if you need it.

## Macrobenchmarks

The `macrobenchmarks/` directory that used to live here — alt-ergo, coq, cpdf,
cubicle, frama-c, menhir, installed via `opam install` and benchmarked as
installed binaries — is gone. Real-world programs are now
[macro-benches](https://github.com/ocaml-bench/macro-benches), which builds them
from vendored, version-pinned source instead, so the tool under test no longer
changes with the compiler under test. Its per-tool pages carry the current
version constraints.

## Key files

- `manifest.yml` — the program list; `disabled:` records what is switched off and why
- `scripts/test-runtimes.sh` — how the table at the top of this file is produced
- `SANDMARK_ADAPTATIONS.md` — source changes made during the port
- `~/running-ng/src/running/config/base/ocaml/micro_base.yml` — the suite definition sweeps run from
- `~/running-ng/src/running/config/experiments/e2e_micro_5.5.0_vs_trunk.yml` — full-suite 5.5.0 vs trunk
