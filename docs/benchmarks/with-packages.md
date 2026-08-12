# with_packages/ — benchmarks needing external opam packages

Benchmarks in `with_packages/` require external opam packages. **No manual
package installation is needed** — each build script runs `opam install <pkg> -y`
to install its dependencies into the active opam switch.

### How package installation works

`running-ng` creates a dedicated opam switch for each runtime via
`opam-compiler` (e.g., `running-ng-ocaml-v5.4`). The switch environment is
activated before invoking the build script, so `opam install` targets the
correct switch automatically. Packages are cached in the switch and reused
across benchmark builds for the same runtime.

### Overriding the opam switch

To force a specific switch, add `build_env` to the suite in the YAML config:

```yaml
sandmark-with-packages:
  type: OCamlBenchmarkSuite
  build_env:
    OPAM_SWITCH: "my-custom-switch"
  programs:
    fasta3: ...
```

`OPAM_SWITCH` takes precedence over all auto-detection.

### benchmarksgame

Seven programs sharing `benches/with_packages/benchmarksgame/`. Each has its own build script; all use dune and link against `zarith`, `str`, and `unix`.

- **binarytrees5** — Args: `21`. Allocates and traverses binary trees of depth 21 using Zarith big integers for node values. GC-intensive short-lived allocation.
- **fasta3** — Args: `25000000`. Generates a DNA sequence of 25M characters using cumulative probability tables. Exercises sequential array access.
- **fasta6** — Args: `25000000`. Alternative fasta generator; same input size, different internal algorithm.
- **mandelbrot6** — Args: `16000`. Renders a 16000×16000 Mandelbrot set image in PBM format. Pure floating-point; no GC pressure.
- **nbody_benchmarksgame** — Args: `50000000`. (Built by `nbody.build.sh`; named to keep it distinct from `multicore-numerical`'s own `nbody`.) N-body planetary simulation (5 bodies, 50M steps). Pure floating-point; tests float unboxing.
- **pidigits5** — Args: `10000`. Computes 10000 digits of π using the Stern-Brocot tree algorithm via Zarith arbitrary-precision integers.
- **spectralnorm2** — Args: `5500`. Approximates the spectral norm of an infinite matrix. Dense floating-point; exercises float arrays.

### zarith

Three programs sharing `with_packages/zarith/`. Each has its own build script; all use dune.

- **zarith_fact** — Args: `40 1000000`. Computes factorial of 40, repeated 1M times. Exercises Zarith multiplication. Needs `zarith`.
- **zarith_fib** — Args: `Z 40`. Fibonacci of 40 using Zarith big integers. Exercises Zarith addition. Needs `zarith`, `num`.
- **zarith_tak** — Args: `Z 2500`. Tak function with n=2500 using Zarith integers. Exercises recursive calls with big-integer arithmetic. Needs `zarith`, `num`.

### chameneos_redux_lwt

- **Source:** sandmark `benchmarks/chameneos/`
- **Build:** dune + `lwt.unix`
- **Args:** `<meetings>` — number of colour-changing meetings; config uses `600000`
- **Description:** Simulates chameneos creatures meeting in a waiting room and swapping colours, implemented with Lwt lightweight threads. Exercises Lwt cooperative scheduling and mvar synchronisation.

### thread_ring_lwt_mvar / thread_ring_lwt_stream

Both in `benches/with_packages/thread-lwt/`; shared dune file.

- **Source:** sandmark `benchmarks/thread-lwt/`
- **Build:** dune + `lwt`, `lwt.unix`
- **Args:** `<N>` — number of ring-pass iterations; config uses `20000`
- **thread_ring_lwt_mvar** — Token passed around a ring of 503 Lwt threads via `Lwt_mvar`. Exercises mvar hand-off latency.
- **thread_ring_lwt_stream** — Same ring, but using `Lwt_stream` channels. Slightly higher allocation than the mvar variant.



### test_sched

- **Source:** sandmark `benchmarks/multicore-effects/ms_sched.ml` + `test_sched.ml` (adapted)
- **Build:** ocamlfind + `saturn_lockfree`
- **Args:** `<num_domains> <tasks_to_spawn> <list_length>`
- **Description:** Microbenchmark for a concurrent round-robin effects-based scheduler (`ms_sched.ml`). Spawns `<tasks_to_spawn>` tasks per run, each allocating a list of length `<list_length>`. The scheduler uses a Saturn Michael–Scott queue as its run queue and `Domain.spawn` to run workers across `<num_domains>` domains. Exercises effect handler dispatch, continuation enqueuing, and domain coordination.
- **Note:** In `with_packages/` (not `multicore/`) because it depends on `saturn_lockfree`. See `SANDMARK_ADAPTATIONS.md` for the porting changes from the sandmark original.

### test_lwt (valet)

- **Source:** sandmark `benchmarks/valet/` (4 files: `valet_core.ml`, `valet_react.ml`, `test_lib.ml`, `test_lwt.ml`)
- **Build:** dune + `uuidm`, `ocplib-endian`, `react`, `lwt`
- **Args:** `<n>` — number of users/readers/doors; each of n persons swipes n times → O(n²) events
- **Description:** Reactive access-control simulation. n people each hold a UUID-backed QR code; n QR readers feed into a controller (via `react` event streams) that maps codes to users, which doors then act on. All persons run concurrently via `Lwt.join` with `Lwt.pause ()` yields between each swipe. Exercises Lwt cooperative scheduling, `react` event propagation, and UUID/map allocation.
- **OxCaml:** incompatible (lwt.unix locality error, same as `chameneos_redux_lwt`)

### contrast — **disabled**

Not in the run set: `camlimages` 5.0.5 does not build on OCaml ≥ 5.4
(`/usr/bin/ld: final link failed: bad value`, verified on 5.5.0 and trunk
`c0f8c8ce`). It is listed under `disabled:` in `manifest.yml` and commented out
of running-ng's `micro_base.yml`; the source stays here. Re-enable both when a
camlimages that links is available — it is the only image-processing workload in
the suite.

- **Source:** sandmark `benchmarks/sauvola/contrast.ml`
- **Build:** dune + `camlimages` (`camlimages.all_formats` sub-library)
- **Args:** `<input.ppm> <output_prefix>` — config uses the bundled `example2_small.ppm` (absolute path); output goes to `/tmp/sauvola_out__*.ppm`
- **Description:** Applies 8 image binarisation algorithms (adaptive contrast spreading, Niblack global/local, Sauvola global/local) to a PPM image. Each algorithm creates a new `rgb24` image and iterates over all pixels, exercising OO-style image allocation and GC-heavy pixel-by-pixel access patterns.


## Moved to `macro-benches`

`test_decompress`, `ydump`, `owl_gc` and `zarith_pi` used to live here. They now
live in [macro-benches](https://github.com/ocaml-bench/macro-benches), built from
vendored, version-pinned sources and with a small/default/large input-size ladder
each. The copies here `opam install`ed whatever the solver happened to pick for
the switch, so the library under test changed with the compiler under test — the
exact confound macro-benches exists to remove. Use those instead.
