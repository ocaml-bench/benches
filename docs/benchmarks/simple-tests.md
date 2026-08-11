# simple/simple-tests — allocation, laziness, weak refs, finalisers

Sandmark's `benchmarks/simple-tests/` suite: small stdlib-only benchmarks covering
allocation, lazy evaluation, stacks, finalizers, and weak/ephemeron tables.

### alloc
- **Source:** sandmark `benchmarks/simple-tests/alloc.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** none
- **Description:** Minor heap allocation rate benchmark: allocates tuples and small lists at high frequency.

### lists
- **Source:** sandmark `benchmarks/simple-tests/lists.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** none
- **Description:** List operations: append, rev, map, filter, fold.

### stress
- **Source:** sandmark `benchmarks/simple-tests/stress.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** none
- **Description:** Allocation stress test; exercises minor and major GC.

### lazylist
- **Source:** sandmark `benchmarks/simple-tests/lazylist.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** none
- **Description:** Lazy list operations via `Lazy.t` suspension.

### lazy_primes
- **Source:** sandmark `benchmarks/simple-tests/lazy_primes.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** none
- **Description:** Lazy sieve of Eratosthenes using `Lazy.t`-deferred streams.

### morestacks
- **Source:** sandmark `benchmarks/simple-tests/morestacks.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** none
- **Description:** Stack operations on functional and imperative stacks.

### stacks
- **Source:** sandmark `benchmarks/simple-tests/stacks.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** none
- **Description:** Stdlib `Stack` module push/pop under various patterns.

### finalise
- **Source:** sandmark `benchmarks/simple-tests/finalise.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** none
- **Description:** GC finalizer registration and invocation throughput (`Gc.finalise`).

### weakretain
- **Source:** sandmark `benchmarks/simple-tests/weakretain.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** none
- **Description:** Weak pointer retention: allocates objects and checks how many survive GC through a `Weak.t` array.

### weak_htbl
- **Source:** sandmark `benchmarks/simple-tests/weak_htbl.ml`
- **Build:** ocamlopt (stdlib only); OCaml 5.x adaptation (see `SANDMARK_ADAPTATIONS.md`)
- **Args:** `<N>` — table size
- **Description:** Correctness and performance test for ephemeron-based hash tables (`Ephemeron.K{1,2,n}.Make`) versus regular `Hashtbl` and `Map`-backed tables. Note: `iter` was removed from Ephemeron modules in OCaml 5.x; the correctness assertions for weak tables now pass vacuously.

