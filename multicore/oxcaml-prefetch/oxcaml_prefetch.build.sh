#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/oxcaml_prefetch-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release oxcaml_prefetch.exe
cp "${BENCH_DIR}/_build/default/oxcaml_prefetch.exe" "${OUT}"
chmod +x "${OUT}"
