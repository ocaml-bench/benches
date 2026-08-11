# Benchmark reference

One page per group. Each entry gives the sandmark source it came from, how it is
built, what arguments it takes, and what it is meant to stress.

The authoritative *(program, path, build script, arguments)* list is
[`../../manifest.yml`](../../manifest.yml) — these pages explain the benchmarks,
the manifest defines them. When the two disagree, the manifest is right and the
page needs fixing.

| Page | Programs |
|---|--:|
| [simple.md](simple.md) — stdlib-only sequential benchmarks | 24 |
| [stdlib.md](stdlib.md) — stdlib data-structure microbenchmarks | 69 |
| [simple-tests.md](simple-tests.md) — allocation, laziness, weak refs, finalisers | 25 |
| [with-deps.md](with-deps.md) — generated input or multi-library builds | 10 |
| [with-packages.md](with-packages.md) — external opam packages | 12 |
| [multicore.md](multicore.md) — OCaml 5 domains and effects | 56 |
