#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/matrix_multiplication-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release matrix_multiplication.exe
cp "${BENCH_DIR}/_build/default/matrix_multiplication.exe" "${OUT}"
chmod +x "${OUT}"
