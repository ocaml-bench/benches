#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/qr_decomposition-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release qr_decomposition.exe
cp "${BENCH_DIR}/_build/default/qr_decomposition.exe" "${OUT}"
chmod +x "${OUT}"
