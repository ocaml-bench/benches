# multicore/ — OCaml 5 domains and effects

Benchmarks that require OCaml 5.x and the `Effect` module. Source is in `multicore/`; the flat layout mirrors `simple/` (each benchmark in its own subfolder, with an optional `build.deps.sh` for generated data).

Use `OCamlMulticoreBenchmarkSuite` (instead of `OCamlBenchmarkSuite`) in running-ng configs. This suite type enforces OCaml >= 5 at build/run time and raises a clear error if you attempt to sweep with an older compiler.

### multicore/multicore-effects

Single-file effect benchmarks compiled with `ocamlopt`. Adapted from sandmark `benchmarks/multicore-effects/` for the OCaml 5.2+ `Effect` module API (sandmark's originals use the pre-5.2 `effect` keyword syntax, which is not accepted by OCaml 5.2+).

#### algorithmic_differentiation

- **Source:** sandmark `benchmarks/multicore-effects/algorithmic_differentiation.ml` (adapted)
- **Build:** ocamlopt (stdlib only)
- **Args:** `<iterations>` — default 100
- **Description:** Reverse-mode automatic differentiation using deep effect handlers (`Add` and `Mult` effects). Exercises deep effect handler dispatch, continuation resumption, and float array allocation.

#### rec_eff_fib / rec_seq_fib

- **Source:** sandmark `benchmarks/multicore-effects/rec_eff_{fib,seq_fib}.ml` (adapted)
- **Build:** ocamlopt (stdlib only)
- **Args:** `<iters> <n>` — default `4 40` (expected output per iter: 102334155)
- **Description:** Recursive Fibonacci. `rec_eff_fib` installs a `try_with` effect handler at each recursive call site (handler is never triggered; effect `E` is never performed) — tests the overhead of handler installation compared to the pure-recursive `rec_seq_fib` baseline.

#### rec_eff_tak / rec_seq_tak

- **Source:** sandmark `benchmarks/multicore-effects/rec_eff_{tak,seq_tak}.ml` (adapted)
- **Build:** ocamlopt (stdlib only)
- **Args:** `<iters> <x> <y> <z>` — default `1 40 20 11` (expected output per iter: 12)
- **Description:** Takeuchi function. Same handler-overhead comparison pattern as rec_{eff,seq}_fib; three handler installations per recursive call.

#### rec_eff_ack / rec_seq_ack

- **Source:** sandmark `benchmarks/multicore-effects/rec_eff_{ack,seq_ack}.ml` (adapted)
- **Build:** ocamlopt (stdlib only)
- **Args:** `<iters> <m> <n>` — default `2 3 11` (expected output per iter: 16381)
- **Description:** Ackermann function. Same pattern; tests effect handler overhead on a deeply recursive, stack-intensive computation.

#### effect_throughput_val

- **Source:** sandmark `benchmarks/multicore-effects/effect_throughput_val.ml` (adapted)
- **Build:** ocamlopt (stdlib only)
- **Args:** `<n_iter>` — default `1_000_000`
- **Description:** Measures the throughput of an effect handler block where `perform` is never called and a value is returned directly. The `E : unit Effect.t` handler is installed but never triggered; cost is purely the handler frame setup and teardown (stack allocation, context switch in/out, deallocation).

#### effect_throughput_perform

- **Source:** sandmark `benchmarks/multicore-effects/effect_throughput_perform.ml` (adapted)
- **Build:** ocamlopt (stdlib only)
- **Args:** `<n_iter>` — default `1_000_000`
- **Description:** Measures the throughput of a full perform–resume cycle. `E : int -> int Effect.t` is performed once per iteration and the continuation is immediately resumed with the same value. Cost includes the perform (stack switch to handler), the `continue k x` call (stack switch back), and frame deallocation.

#### effect_throughput_perform_drop

- **Source:** sandmark `benchmarks/multicore-effects/effect_throughput_perform_drop.ml` (adapted)
- **Build:** ocamlopt (stdlib only)
- **Args:** `<n_iter>` — default `1_000_000`
- **Description:** Like `effect_throughput_perform` but the continuation is abandoned (not resumed). Measures the perform overhead plus the cost of GC-collecting a dropped continuation.

#### rec_eff_evenodd / rec_seq_evenodd

- **Source:** sandmark `benchmarks/multicore-effects/rec_eff_evenodd.ml` / `rec_seq_evenodd.ml` (adapted / verbatim)
- **Build:** ocamlopt (stdlib only)
- **Args:** `<iters> <n>`; defaults `2 500_000_000`
- **Description:** Even-odd mutual recursion benchmark. `rec_eff_evenodd` installs a dummy effect handler at each `odd` call; `rec_seq_evenodd` is the plain baseline. Measures effect handler call overhead on a tight mutual recursion loop.

#### rec_eff_motzkin / rec_seq_motzkin

- **Source:** sandmark `benchmarks/multicore-effects/rec_eff_motzkin.ml` / `rec_seq_motzkin.ml` (adapted / verbatim)
- **Build:** ocamlopt (stdlib only)
- **Args:** `<iters> <n>`; defaults `4 21`
- **Description:** Computes the n'th Motzkin number (number of ways to draw non-intersecting chords between n circle points). `rec_eff_motzkin` wraps each recursive call in a dummy `try_with`; `rec_seq_motzkin` is the baseline. n=21 yields 142547559.

#### rec_eff_sudan / rec_seq_sudan

- **Source:** sandmark `benchmarks/multicore-effects/rec_eff_sudan.ml` / `rec_seq_sudan.ml` (adapted / verbatim)
- **Build:** ocamlopt (stdlib only)
- **Args:** `<iters> <n> <x> <y>`; defaults `10_000_000 2 2 2`
- **Description:** Computes the Sudan function (recursive but not primitive recursive). `rec_eff_sudan` wraps the inner recursive call in a dummy `try_with`; `rec_seq_sudan` is the baseline. Defaults yield 15569256417.

#### eratosthenes

- **Source:** sandmark `benchmarks/multicore-effects/eratosthenes.ml` (adapted)
- **Build:** ocamlopt (stdlib only)
- **Args:** `<n>` — generate primes up to `n`; default `101`
- **Description:** Message-passing Sieve of Eratosthenes implemented entirely with effects. Uses four effects (`Spawn`, `Yield`, `Send`, `Recv`) and two layered handlers: `run` (round-robin scheduler handling `Spawn`/`Yield`) and `mailbox` (per-pid message queue handling `Send`/`Recv`). The outer `mailbox` handler catches `Send`/`Recv` that bubble through `run`'s handler. Exercises effect handler chaining, continuation queuing, and a Map-backed mailbox.

### multicore/multicore-structures

Lock-free concurrent data structures implemented with OCaml 5 stdlib `Atomic`. No external packages required — the sandmark originals referenced `kcas`, but all atomic operations (`Atomic.t`, `Atomic.get`, `Atomic.set`, `Atomic.compare_and_set`) are available in the stdlib since OCaml 5.0. Each test program is compiled together with its data-structure module using `ocamlfind -package unix`.

**Data structure modules** (in the benchmark directory, compiled alongside each test):
- `ms_queue.ml` — Michael–Scott lock-free MPMC queue using `Atomic.t` and CAS loops.
- `treiber_stack.ml` — Treiber lock-free LIFO stack using `Atomic.t`.
- `spsc_queue.ml` — Wait-free bounded SPSC queue with cache-line padding.

#### test_queue_sequential

- **Source:** sandmark `benchmarks/multicore-structures/test_queue_sequential.ml`
- **Build:** ocamlfind + unix (stdlib Atomic, no domainslib)
- **Args:** `<items>` — number of items to enqueue/dequeue
- **Description:** Sequentially enqueues then dequeues `<items>` integers through the MS queue. Checks that no items are lost and reports throughput (items/ms).

#### test_queue_parallel

- **Source:** sandmark `benchmarks/multicore-structures/test_queue_parallel.ml`
- **Build:** ocamlfind + unix
- **Args:** `<items>`
- **Description:** One domain enqueues `<items>` integers while a second domain concurrently dequeues. Exercises the MS queue's CAS-based enqueue/dequeue paths under concurrent access.

#### test_stack_sequential

- **Source:** sandmark `benchmarks/multicore-structures/test_stack_sequential.ml`
- **Build:** ocamlfind + unix
- **Args:** `<items>`
- **Description:** Sequential push/pop stress test on the Treiber stack.

#### test_stack_parallel

- **Source:** sandmark `benchmarks/multicore-structures/test_stack_parallel.ml`
- **Build:** ocamlfind + unix
- **Args:** `<items>`
- **Description:** Concurrent push (one domain) / pop (another domain) on the Treiber stack.

#### test_spsc_queue_sequential

- **Source:** sandmark `benchmarks/multicore-structures/test_spsc_queue_sequential.ml`
- **Build:** ocamlfind + unix
- **Args:** `<items>` — items per run; repeats 1000 times
- **Description:** Sequential enqueue/dequeue cycle on the SPSC queue. Reports ns/item throughput.

#### test_spsc_queue_parallel

- **Source:** sandmark `benchmarks/multicore-structures/test_spsc_queue_parallel.ml`
- **Build:** ocamlfind + unix
- **Args:** `<items>`
- **Description:** One domain enqueues while another dequeues via the SPSC queue. Exercises the wait-free fast path.

#### test_spsc_queue_pingpong_parallel

- **Source:** sandmark `benchmarks/multicore-structures/test_spsc_queue_pingpong_parallel.ml`
- **Build:** ocamlfind + unix
- **Args:** `<num_threads> <num_messages>`
- **Description:** Creates a ring of `<num_threads>` domains, each connected to the next by an SPSC queue. `Ping` messages circulate until a `Bye` terminates each thread. Measures inter-domain message-passing latency through a chain of SPSC queues.

### multicore/multicore-numerical

Parallel versions of classic numerical benchmarks using `domainslib`. Each multicore benchmark has a corresponding sequential baseline. All compiled with `ocamlfind -package domainslib` (or stdlib-only for sequentials). First argument is always `<num_domains>`.

#### mandelbrot6_multicore

- **Source:** sandmark `benchmarks/multicore-numerical/mandelbrot6_multicore.ml`
- **Build:** ocamlfind + domainslib
- **Args:** `<num_domains> <width>` — default `1 200`
- **Description:** Parallel Mandelbrot set renderer. Uses `Task.parallel_for` over rows; each domain computes a horizontal strip. Outputs PBM binary format to stdout. Based on benchmarksgame Mandelbrot #6.

#### nbody_multicore / nbody

- **Source:** sandmark `benchmarks/multicore-numerical/{nbody_multicore,nbody}.ml`
- **Build:** ocamlfind + domainslib (multicore); ocamlopt stdlib (sequential)
- **Args:** `<num_domains> <n> <num_bodies>` — default `1 500 1024`; sequential: `<n> <num_bodies>` — default `500 1024`
- **Description:** N-body gravitational simulation. Parallel version uses `Task.parallel_for` for the velocity-update inner loop and `Task.parallel_for_reduce` for energy computation.

#### floyd_warshall_multicore / floyd_warshall

- **Source:** sandmark `benchmarks/multicore-numerical/{floyd_warshall_multicore,floyd_warshall}.ml`
- **Build:** ocamlfind + domainslib; stdlib
- **Args:** `<num_domains> <n>` — default `1 4`; sequential: `<n>` — default `4`
- **Description:** All-pairs shortest path (Floyd–Warshall). The outer `k` loop is sequential (dependency), inner `i` loop parallelised with `Task.parallel_for`. Uses an algebraic `edge` type (`Value of int | Infinity`).

#### game_of_life_multicore / game_of_life

- **Source:** sandmark `benchmarks/multicore-numerical/{game_of_life_multicore,game_of_life}.ml`
- **Build:** ocamlfind + domainslib; stdlib
- **Args:** `<num_domains> <n_times> <board_size>` — default `1 2 1024`; sequential: `<n_times> <board_size>` — default `2 1024`
- **Description:** Conway's Game of Life on a `board_size × board_size` grid, iterated `n_times` steps. Row updates parallelised with `Task.parallel_for`.

#### binarytrees5_multicore

- **Source:** sandmark `benchmarks/multicore-numerical/binarytrees5_multicore.ml`
- **Build:** ocamlfind + domainslib
- **Args:** `<num_domains> <max_depth>` — default `1 10`
- **Description:** Binary tree construction and checksum benchmark (benchmarksgame binary-trees #5). Uses `Task.async`/`Task.await` to parallelise tree checks across depths and domains. Exercises GC allocation and domain-local work stealing.

#### spectralnorm2_multicore

- **Source:** sandmark `benchmarks/multicore-numerical/spectralnorm2_multicore.ml`
- **Build:** ocamlfind + domainslib
- **Args:** `<num_domains> <n>` — default `1 2000`
- **Description:** Spectral norm of the infinite matrix A where `A[i,j] = 1/((i+j)*(i+j+1)/2+i+1)`. Power iteration using `Task.parallel_for` for matrix-vector products. Based on benchmarksgame spectral-norm #2.

#### fannkuchredux_multicore

- **Source:** sandmark `benchmarks/multicore-numerical/fannkuchredux_multicore.ml`
- **Build:** ocamlfind + domainslib
- **Args:** `<workers> <n>` — default `10 7`
- **Description:** Fannkuch-redux (permutation counting). Divides the factorial permutation space into `workers` chunks and uses `Task.parallel_for` to count flip operations in parallel.

#### quicksort_multicore / quicksort

- **Source:** sandmark `benchmarks/multicore-numerical/{quicksort_multicore,quicksort}.ml`
- **Build:** ocamlfind + domainslib; stdlib
- **Args:** `<num_domains> <n>` — default `1 2000`; sequential: `<n>` — default `2000`
- **Description:** Parallel quicksort using `Task.async`/`Task.await` to spawn recursive subproblems. Depth-bounded spawning (halves remaining depth budget at each partition).

#### mergesort_multicore / mergesort

- **Source:** sandmark `benchmarks/multicore-numerical/{mergesort_multicore,mergesort}.ml`
- **Build:** ocamlfind + domainslib; stdlib
- **Args:** `<num_domains> <n>` — default `1 1024`; sequential: `<n>` — default `1024`
- **Description:** Parallel merge sort using `Task.async`/`Task.await`. Falls back to bubble sort below threshold (32 elements). Uses an in-place double-buffer merge strategy.

#### matrix_multiplication_multicore / matrix_multiplication

- **Source:** sandmark `benchmarks/multicore-numerical/{matrix_multiplication_multicore,matrix_multiplication}.ml`
- **Build:** ocamlfind + domainslib; stdlib
- **Args:** `<num_domains> <size>` — default `1 1024`; sequential: `<size>` — default `1024`
- **Description:** Dense integer matrix multiplication. Row-parallel using `Task.parallel_for` over the output rows.

#### matrix_multiplication_tiling_multicore

- **Source:** sandmark `benchmarks/multicore-numerical/matrix_multiplication_tiling_multicore.ml`
- **Build:** ocamlfind + domainslib
- **Args:** `<num_domains> <size>` — default `1 1024`
- **Description:** Tiled matrix multiplication using explicit `Domainslib.Chan`-based task distribution rather than `parallel_for`. Tile size is 64. The channel-based dispatch is chosen because the loop has decreasing work per iteration, which makes static `parallel_for` chunking suboptimal.

#### LU_decomposition_multicore / LU_decomposition

- **Source:** sandmark `benchmarks/multicore-numerical/{LU_decomposition_multicore,LU_decomposition}.ml`
- **Build:** ocamlfind + domainslib; stdlib
- **Args:** `<num_domains> <mat_size>` — default `1 1200`; sequential: `<mat_size>` — default `1200`
- **Description:** In-place LU decomposition of a random float matrix. Uses `Task.parallel_for` for row elimination and `Domain.DLS` for domain-local random state. Stores L and U in packed form.

#### nqueens_multicore / nqueens

- **Source:** sandmark `benchmarks/multicore-numerical/{nqueens_multicore,nqueens}.ml`
- **Build:** ocamlfind + domainslib; stdlib
- **Args:** `<num_domains> <board_size>` — default `2 13`; sequential: `<board_size>` — default `13`
- **Description:** N-queens solver. Parallel version spawns a `Task.async` for each valid queen placement at each row, aggregating results with `Task.await`.

#### evolutionary_algorithm_multicore / evolutionary_algorithm

- **Source:** sandmark `benchmarks/multicore-numerical/{evolutionary_algorithm_multicore,evolutionary_algorithm}.ml`
- **Build:** ocamlfind + domainslib; stdlib
- **Args:** `<num_domains> <n> <lambda>` — default `4 1000 1000`; sequential: `<n> <lambda>` — default `1000 1000`
- **Description:** Minimal genetic algorithm optimising the Onemax fitness function. Parallel version uses `Task.parallel_for` to evaluate and mutate the population in each generation. Uses `Domain.DLS` for domain-local random state.

### multicore/multicore-grammatrix

Gram matrix benchmark from the Yamanishi laboratory. Compiled with `ocamlfind`; requires a `data/` subdirectory with CSV input files (bundled). The benchmark reads feature vectors from a CSV (space-separated floats) and computes the symmetric Gram matrix via dot products. Default input is `data/tox21_nrar_ligands_std_rand_01.csv` (7026 samples).

A shared helper module `utls.ml` is compiled alongside the main benchmark in each build.

#### grammatrix

- **Source:** sandmark `benchmarks/multicore-grammatrix/grammatrix.ml` + `utls/utls.ml`
- **Build:** ocamlfind + unix (sequential)
- **Args:** `<ncores> <input_file>` — default `1 data/tox21_nrar_ligands_std_rand_01.csv`
- **Description:** Sequential Gram matrix computation. Reads feature vectors, computes the full N×N symmetric matrix in O(N²) dot products, then prints a corner summary. The `ncores` argument is accepted but ignored (present for interface parity with the multicore version).

#### grammatrix_multicore

- **Source:** sandmark `benchmarks/multicore-grammatrix/grammatrix_multicore.ml` + `utls/utls.ml`
- **Build:** ocamlfind + domainslib + unix
- **Args:** `<num_domains> <chunk_size> <input_file>` — default `4 16 data/tox21_nrar_ligands_std_rand_01.csv`
- **Description:** Parallel Gram matrix computation using explicit `Domainslib.Chan`-based task distribution. Work chunks of `<chunk_size>` rows are sent through a bounded channel; each domain fetches and processes chunks until a `Quit` message is received. Channel-based dispatch is preferred over `parallel_for` here because earlier rows have more work (triangular iteration), so pre-computing and queuing chunks in decreasing-work order improves load balance. **Note:** the benchmark must be run from the `multicore-grammatrix/` directory so that the `data/` relative path resolves correctly.

### multicore/oxcaml-prefetch (OxCaml only)

Multicore GC stress test using OxCaml-specific APIs. **Requires an OxCaml compiler** (Jane Street's OCaml fork) — will not compile with stock OCaml.

#### oxcaml_prefetch

- **Source:** custom benchmark (not from sandmark)
- **Build:** ocamlopt (stdlib only)
- **Args:** _(none)_
- **Description:** Spawns 8 domains using `Domain.Safe.spawn` (OxCaml API), each building a large binary tree of depth 28 with 10-byte string leaves. After all domains have built their trees, the main domain runs 10 `Gc.full_major` cycles. Exercises concurrent major GC marking across multiple domains with a large shared live set. Uses `Sys.poll_actions` for cooperative domain coordination and `Atomic` for synchronisation.
- **OxCaml APIs used:** `Domain.Safe.spawn`, `Sys.poll_actions`
- **Suite type:** `OCamlOxcamlBenchmarkSuite` — fails with an error if the runtime is not `type: OxCaml`.

### multicore/multicore-minilight

Parallel global illumination renderer (MiniLight 1.5.2). A Monte Carlo path tracer with an octree spatial index. All nine source modules are compiled together in dependency order using `ocamlfind -package domainslib`. Only the parallel entry point (`minilight_multicore`) is provided; the sequential variant is omitted because its `camera.ml` has a different API signature.

Compilation order: `vector3f → triangle → surfacePoint → spatialIndex → scene → image → rayTracer → camera → minilight_multicore`

#### minilight_multicore

- **Source:** sandmark `benchmarks/multicore-minilight/parallel/` (all modules)
- **Build:** ocamlfind + domainslib (9-module compilation)
- **Args:** `<scene_file>` — path to a MiniLight scene description (e.g. `roomfront.ml.txt`, bundled)
- **Description:** Parallel path tracer. Each frame's pixel rows are distributed across domains using `Task.parallel_for` inside `Camera.frame`. Uses `Domain.DLS` for per-domain `Random.State` to avoid contention. Renders progressively, printing progress to stderr and saving PPM output to `<scene_file>.ppm`. **Note:** the renderer runs until interrupted; for benchmarking, wrap with a timeout or limit iterations in the scene file.

### multicore/graph500par

Parallel Graph500 Kronecker graph generator and BFS kernel. Two executables are built from shared library modules; `gen` must be run first to produce an edge-list data file that `kernel1_run_multicore` then reads.

Compilation order for both executables: `graphTypes → sparseGraph → generate → [gen | kernel1Par → kernel1_run_multicore]`

#### gen

- **Source:** sandmark `benchmarks/graph500par/gen.ml` (+ `generate.ml`, `sparseGraph.ml`, `graphTypes.ml`)
- **Build:** ocamlfind + domainslib + unix
- **Args:** `[-scale SCALE] [-edgefactor EDGE_FACTOR] [-ndomains NUM_DOMAINS] OUTPUT_FILE` — defaults `scale=12 edgefactor=16 ndomains=1`
- **Description:** Kronecker graph generator implementing the Graph500 specification. Generates `2^scale` vertices and `edgefactor * 2^scale` edges using a probabilistic bit-setting algorithm with random permutations. Edge generation uses `Task.parallel_for`. Writes the edge list to `OUTPUT_FILE` via `Marshal`.

#### kernel1_run_multicore

- **Source:** sandmark `benchmarks/graph500par/kernel1_run_multicore.ml` (+ `kernel1Par.ml`, `generate.ml`, `sparseGraph.ml`, `graphTypes.ml`)
- **Build:** ocamlfind + domainslib + unix
- **Args:** `[-ndomains NUM_DOMAINS] EDGE_LIST_FILE`
- **Description:** Graph500 Kernel 1 — parallel construction of a sparse adjacency-list representation. Reads the pre-generated edge list from `EDGE_LIST_FILE`, removes self-loops, finds the maximum vertex label using `Task.parallel_for_reduce`, and builds the sparse graph using `Task.parallel_for` with lock-free `Atomic.t`-based adjacency lists. Reports I/O and construction time.

---

## multicore/alloc_multicore

### alloc_multicore

- **Source:** sandmark `benchmarks/simple-tests/alloc_multicore.ml`
- **Build:** ocamlopt (stdlib only — uses `Domain.spawn`/`Domain.join`)
- **Args:** `<num_domains> <iterations>`; config uses `2 200_000`
- **Description:** Parallel minor-heap allocation benchmark. Each domain allocates small mutable records `{ an_int; a_string; a_float }` in a tight loop. Measures allocation throughput under parallel GC pressure.

---

## multicore/pingpong_multicore

### pingpong_multicore

- **Source:** sandmark `benchmarks/simple-tests/pingpong_multicore.ml`
- **Build:** ocamlfind + domainslib (auto-installed)
- **Args:** `<num_domains> <chan_size> <total_messages>`; config uses `3 1 1000000`
- **Description:** Multi-domain channel ping-pong benchmark using `Domainslib.Chan`. A producer sends messages through a pipeline of worker domains, each incrementing a counter before forwarding. Measures channel throughput and domain synchronisation overhead.

