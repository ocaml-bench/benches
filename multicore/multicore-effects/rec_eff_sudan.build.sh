#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/rec_eff_sudan-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release rec_eff_sudan.exe
cp "${BENCH_DIR}/_build/default/rec_eff_sudan.exe" "${OUT}"
chmod +x "${OUT}"
