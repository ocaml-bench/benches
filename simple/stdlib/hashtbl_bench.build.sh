#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/hashtbl_bench-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release hashtbl_bench.exe
cp "${BENCH_DIR}/_build/default/hashtbl_bench.exe" "${OUT}"
chmod +x "${OUT}"
