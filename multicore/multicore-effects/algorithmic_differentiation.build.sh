#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/algorithmic_differentiation-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release algorithmic_differentiation.exe
cp "${BENCH_DIR}/_build/default/algorithmic_differentiation.exe" "${OUT}"
chmod +x "${OUT}"
