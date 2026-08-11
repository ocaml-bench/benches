# simple/stdlib — stdlib data-structure microbenchmarks

Sandmark's `benchmarks/stdlib/` suite: 10 single-file benchmarks covering core stdlib
data structures. Each takes `<bench_type> [args]` and dispatches to sub-benchmarks.

### array_bench
- **Source:** sandmark `benchmarks/stdlib/array_bench.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** `<bench_type>` — e.g. `make`, `init`, `map`, etc.
- **Description:** Array allocation, initialisation, map, sort, and iteration microbenchmarks.

### bytes_bench
- **Source:** sandmark `benchmarks/stdlib/bytes_bench.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** `<bench_type>`
- **Description:** Bytes buffer operations: blit, fill, sub, compare.

### string_bench
- **Source:** sandmark `benchmarks/stdlib/string_bench.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** `<bench_type>`
- **Description:** String operations: concat, contains, split, compare.

### map_bench
- **Source:** sandmark `benchmarks/stdlib/map_bench.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** `<bench_type>`
- **Description:** Functional map (AVL tree) insert, lookup, fold, merge.

### set_bench
- **Source:** sandmark `benchmarks/stdlib/set_bench.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** `<bench_type>`
- **Description:** Functional set insert, union, inter, diff.

### stack_bench
- **Source:** sandmark `benchmarks/stdlib/stack_bench.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** `<bench_type>`
- **Description:** Stack push/pop operations.

### hashtbl_bench
- **Source:** sandmark `benchmarks/stdlib/hashtbl_bench.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** `<bench_type>`
- **Description:** Hashtable add, find, replace, fold.

### pervasives_bench
- **Source:** sandmark `benchmarks/stdlib/pervasives_bench.ml`
- **Build:** ocamlopt (stdlib only)
- **Args:** `<bench_type>`
- **Description:** Stdlib arithmetic and comparison functions.

### str_bench
- **Source:** sandmark `benchmarks/stdlib/str_bench.ml`
- **Build:** ocamlopt + `str.cmxa` (`-I +str str.cmxa`)
- **Args:** `<bench_type>`
- **Description:** Regular expression operations from the `Str` library.

### big_array_bench
- **Source:** sandmark `benchmarks/stdlib/big_array_bench.ml`
- **Build:** ocamlopt; links `bigarray.cmxa` only on OCaml 4.x (bundled into stdlib on 5.x)
- **Args:** `<bench_type>`
- **Description:** Bigarray allocation and element access patterns.

