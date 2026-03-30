#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/evolutionary_algorithm-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release evolutionary_algorithm.exe
cp "${BENCH_DIR}/_build/default/evolutionary_algorithm.exe" "${OUT}"
chmod +x "${OUT}"
