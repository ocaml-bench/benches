#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/effect_throughput_val-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release effect_throughput_val.exe
cp "${BENCH_DIR}/_build/default/effect_throughput_val.exe" "${OUT}"
chmod +x "${OUT}"
