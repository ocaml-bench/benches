#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/weak_htbl-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release weak_htbl.exe
cp "${BENCH_DIR}/_build/default/weak_htbl.exe" "${OUT}"
chmod +x "${OUT}"
