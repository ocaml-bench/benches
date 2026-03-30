# Benchmark Incompatibilities Across OCaml Versions

Tested runtimes (as of 2026-03-17):
- **OCaml 4.14.3** — last pre-multicore release
- **OCaml 5.1.0** — early OCaml 5
- **OCaml 5.4.1** — latest stable
- **OCaml trunk** — 5.6.0+dev (commit `02ee646`)
- **OxCaml trunk** — Jane Street fork (commit `068b255`)

101 sequential/multicore benchmarks across 10 suites, plus 12 macrobenchmarks
across 6 suites (counting each (benchmark, arg-set) pair).

Note: compatibility matrix below reflects the state as of 2026-03-17 (81
benchmarks). The 20 newly ported stdlib/ and simple-tests/ benchmarks have
been verified to build on OCaml 5.4.1 but have not yet been swept across all
5 runtimes.

## Compatibility Matrix

| Runtime | Builds OK | Expected failures | Notes |
|---|---|---|---|
| OCaml 4.14.3 | 35/35 | 42 skipped | Multicore + OxCaml suites require OCaml >= 5 |
| OCaml 5.1.0 | 75/77 | 2 | graph500par, mandelbrot6_multicore (see below) |
| OCaml 5.4.1 | 76/77 | 1 | oxcaml_prefetch (OxCaml-only) |
| OCaml trunk | 76/77 | 1 | oxcaml_prefetch (OxCaml-only) |
| OxCaml trunk | 72/77 | 5 | Locality type errors (see below) |

---

## OxCaml Incompatibilities (5 benchmarks)

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

### ydump (sandmark-with-packages) — yojson

The `yojson` library's `write_intlit` function gets an OxCaml locality type error:

```
Error: This expression has type Buffer.t @ local -> string @ local -> unit
       but an expression was expected of type Buffer.t -> string -> unit
```

Fix requires patching yojson upstream or maintaining an OxCaml fork.

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

## Package / System Dependency Issues (2 benchmarks)

### owl_gc (sandmark-with-packages) — system dependencies

The `owl` opam package requires `libopenblas-dev` and `liblapacke-dev` system
packages. Without root access, `opam install owl` aborts at the depext check.
Install them manually before building:

```
sudo apt-get install -y libopenblas-dev liblapacke-dev
```

Note: the original sandmark port incorrectly used `owl-base` (pure OCaml subset)
in both the dune file and build script, but the benchmark source uses
`Owl_dense_matrix_d` and `Owl_dense_ndarray_d` which are only in the full `owl`
package. This has been corrected.

### contrast (sandmark-with-packages) — camlimages build failure on OCaml 5.4

`camlimages 5.0.5` fails to compile on OCaml 5.4.x:

```
[ERROR] The compilation of camlimages.5.0.5 failed at "dune build -p camlimages -j 31 @install"
```

This is an upstream issue — `camlimages` has not been updated for OCaml 5.
May work on older OCaml versions (4.14, 5.1).

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

## Infrastructure Workarounds (Legacy)

> **Note (2026-03-25):** The workarounds below applied to the old
> `opam_auto_install.sh`-based build approach which created ext-switches with
> virtual packages. This has been replaced by `opam-compiler`, which creates
> proper opam switches per runtime. The issues documented here no longer affect
> new builds but are kept for historical reference.

Issues in the old build infrastructure (`lib/opam_auto_install.sh`) that required
fixes to support multiple OCaml versions.

### opam sandbox can't find ext-switch compilers

**Affects:** All ext-switches (any compiler not installed via opam)

For external compilers, opam creates "ext-switches" with virtual `ocaml-system`
packages. opam's build sandbox doesn't have the external compiler on PATH, so
Makefile-based packages (like `num`) that invoke bare `ocamlc`/`ocamlopt` fail
silently — opam records them as installed but no library files are produced.
Dune-based packages work fine because dune finds the compiler through switch config.

**Fix:** `_build_num_for_switch()` builds `num` from source using dune with the
correct compiler on PATH. Uses `cp -rL` to dereference dune's install-tree symlinks.
`num` is filtered from regular `opam install` for ext-switches.

### opam upgrades the compiler in ext-switches

**Affects:** OCaml 5.1.0 (and any version where transitive deps need newer OCaml)

When installing packages with transitive dependencies that need a newer OCaml
(e.g., `domainslib 0.5.2` → `saturn >= 1.0.0` → OCaml >= 5.2), opam's solver
would silently upgrade the `ocaml` meta-package from the default repo
(e.g., 5.1.0 → 5.3.0), then compile packages against the wrong compiler version.
The external 5.1.0 compiler would refuse the `.cmi` files: "seems to be for a
newer version of OCaml."

**Fix:** Two-part:
1. Virtual `ocaml-system` package declares `conflicts: ["ocaml-base-compiler"]`
2. All `opam install` calls for ext-switches include an explicit `"ocaml.${vnum}"`
   constraint, forcing opam to keep the compiler version pinned. This causes opam
   to select older compatible package versions (e.g., domainslib 0.5.1 instead of 0.5.2).

### num 1.5 incompatible with OCaml >= 5.2

**Affects:** OCaml 5.4.1, trunk (any OCaml >= 5.2)

`num 1.5`'s `num_top.ml` uses the `Longident.t` type from `compiler-libs`, which
changed in OCaml 5.2: `Ldot` and `Lapply` constructors now require `Location.loc`-wrapped
arguments instead of bare values.

**Fix:** `_build_num_for_switch()` uses `num 1.6`, which avoids the `Longident`
API entirely (uses `eval_string` in `num_top.ml`).

### OxCaml stubs shadow real packages in ext-compiler-repo

**Affects:** All ext-switches (OxCaml and stock OCaml)

OxCaml requires stub packages (ocamlfind, dune, csexp, dune-configurator) in the
ext-compiler-repo because OxCaml's locality modes break their build. These stubs
shadow the real packages for ALL ext-switches, including stock OCaml, resulting in
missing binaries/libraries.

**Fix:** Both OxCaml and stock OCaml ext-switch code paths build from source:
- **ocamlfind**: built with stock OCaml, `findlib.conf` patched to target compiler's stdlib
- **dune**: symlinked from a stock opam switch
- **csexp + dune-configurator**: built with the target compiler using dune

### test_decompress API change (fixed)

Was failing due to decompress 1.5.3 API changes (not version-specific):
- `Higher.compress`/`uncompress`: `~i`/`~o` labels removed, now positional args
- `~w` parameter: `De.window` → `De.Lz77.window`
- `Higher.uncompress` return type: now `(unit, error) result`

Fixed in `test_decompress.ml`. Works with all runtimes.

---

## Macrobenchmark Incompatibilities

Macrobenchmarks (`macrobenchmarks/`) install real-world tools via opam. Some tools
have upper-bound OCaml version constraints in their dependency trees, preventing
installation on newer compilers.

Tested across 5 runtimes (OCaml 4.14.3, 5.1.0, 5.4.1, trunk 5.6.0+dev, OxCaml trunk):

| Tool | 4.14.3 | 5.1.0 | 5.4.1 | trunk | OxCaml | Blocker |
|---|---|---|---|---|---|---|
| alt-ergo | FAIL | FAIL | FAIL | OK | FAIL | ocamlbuild sandbox (4.14/5.x); OxCaml locality types |
| coq | OK | OK | OK | OK | FAIL | OxCaml: ocamlfind `ignore` locality type |
| cpdf | OK | OK | OK | OK | FAIL | OxCaml: ocamlfind `ignore` locality type |
| cubicle | FAIL | FAIL | FAIL | FAIL | FAIL | `cubicle → ocaml < 5.0.0`; autotools fails in sandbox on 4.14 |
| frama-c | FAIL | FAIL | FAIL | FAIL | FAIL | `why3 → ocaml < 5.5`; depext `graphviz` on 4.14/5.x |
| menhir | OK | OK | OK | OK | FAIL | OxCaml: ocamlfind `ignore` locality type |

Incompatible benchmarks fail at the opam install step and are skipped automatically
by `running-ng` (warning logged, empty log file produced).

### Failure details

**alt-ergo on 4.14.3 / 5.1.0 / 5.4.1:** Multiple autotools-based transitive deps
fail in ext-switches. `ocamlbuild` (required by `logs → hmap → dolmen`) is now
built from source (stub in ext-compiler-repo + `_build_ocamlbuild_for_switch`),
but `ocplib-simplex 0.4.1` (required by `alt-ergo-lib`) has a broken `configure`
that truncates long compiler paths into invalid Makefile lines (`missing separator`
error). On trunk (5.6+), opam resolves alt-ergo 2.4.3 which avoids these deps
entirely. Pinning to `alt-ergo.2.4.3` on older OCaml still hits `ocplib-simplex`.
The sandbox is now disabled for ext-switch installs (`wrap-build-commands=[]`),
which helps ocamlbuild but not the configure path-truncation bug.

**cubicle on 4.14.3:** Even though cubicle's opam constraint allows 4.14, its
`autotools`/`m4` build fails in the sandbox (`autom4te: error: m4 failed`).
On 5.x+: hard `ocaml < 5.0.0` constraint.

**frama-c on all runtimes:** On trunk/5.x: `why3 1.8.2 → ocaml < 5.5` and
`ppxlib → ocaml < 5.5.0`. On 4.14.3: version constraints are satisfied, but
`ocplib-simplex 0.4.1` (via `alt-ergo-free`) and `why3 1.8.2` both have broken
autotools `configure` scripts that truncate long compiler paths into invalid
Makefile lines. System deps (`graphviz`, `libgtksourceview-3.0-dev`) are handled
by `--assume-depexts`.

**OxCaml (all tools):** `ocamlfind`'s `topfind.ml` uses `ignore` which is
incompatible with OxCaml's `string @ local -> unit` locality annotation.
Ocamlfind fails to build, blocking all subsequent opam installs.

### Autotools configure truncates long compiler paths

**Affects:** alt-ergo (ocplib-simplex), frama-c (why3, ocplib-simplex) on all runtimes

Autotools-based packages generate `Makefile` via `./configure`.  When the OCaml
compiler lives in a long path like `/tmp/running-ng-ocaml-toolchains/commit-.../
install/lib/ocaml`, the generated `OCAMLLIB` variable gets split across lines,
producing `Makefile:32: *** missing separator` errors.  This affects
`ocplib-simplex 0.4.1` (Makefile-based, no dune) and `why3 1.8.2` (also
Makefile-based for its `byte` target).

**Workaround:** None yet.  A possible fix would be to symlink the toolchain to a
shorter path (e.g. `/tmp/rng-tc/<hash>`) before building.

### ocamlfind native code (findlib_dynload.cmxa)

**Affects:** coq (rocq-runtime) in ext-switches

`rocq-runtime` links against `findlib_dynload.cmxa` (native-code findlib). The
`_build_ocamlfind_for_switch()` helper in `opam_auto_install.sh` originally only
ran `make all` (bytecode), producing `.cma` but not `.cmxa` files.

**Fix:** Added `make opt` step to build native-code archives.

### csexp permission denied in ext-switches

**Affects:** alt-ergo (and any tool needing csexp) in ext-switches

`_build_dune_configurator_for_switch()` copies csexp files from dune's build
output, which has read-only permissions. When opam later tries to install the
csexp stub package, it can't overwrite the read-only files.

**Fix:** Added `chmod u+w` after copying dune-built files (csexp, dune-configurator, num).

### dllzarith.so not found in opam sandbox (bytecode linking)

**Affects:** coq (rocq-runtime builds rocqworker.bc which needs dllzarith.so)

opam's build sandbox clears `CAML_LD_LIBRARY_PATH`. The bytecode linker
(`ocamlc`) falls back to the compiler's `ld.conf` to find stub libraries, but
the ext-switch compiler's `ld.conf` only has relative paths (`./stublibs`, `.`)
which don't resolve inside the sandbox.

**Fix:** During ext-switch creation, append the switch's absolute stublibs path
(`$OPAMROOT/$switch/lib/stublibs`) to the compiler's `ld.conf`.

---

## Key Files

- `lib/opam_auto_install.sh` — legacy ext-switch setup (no longer used by new build scripts)
- `~/running-ng/src/running/config/gc_sweep_all_versions.yml` — sweep config for all 5 runtimes
- `~/running-ng/src/running/config/ocaml_gc_sweep_example.yml` — default sweep config
