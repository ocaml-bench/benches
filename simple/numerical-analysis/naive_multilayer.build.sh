#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/naive_multilayer-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release naive_multilayer.exe
cp "${BENCH_DIR}/_build/default/naive_multilayer.exe" "${OUT}"
chmod +x "${OUT}"
