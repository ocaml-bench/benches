#!/usr/bin/env bash
# zarith_fib.build.sh — builds zarith_fib benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/zarith_fib-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install zarith num -y
# --- Build zarith_fib ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release zarith_fib.exe
cp "${BENCH_DIR}/_build/default/zarith_fib.exe" "${OUT}"
chmod +x "${OUT}"
