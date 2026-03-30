#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/rec_eff_evenodd-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release rec_eff_evenodd.exe
cp "${BENCH_DIR}/_build/default/rec_eff_evenodd.exe" "${OUT}"
chmod +x "${OUT}"
