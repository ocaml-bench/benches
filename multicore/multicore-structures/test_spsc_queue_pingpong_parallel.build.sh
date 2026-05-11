#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/test_spsc_queue_pingpong_parallel-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release test_spsc_queue_pingpong_parallel.exe
cp "${BENCH_DIR}/_build/default/test_spsc_queue_pingpong_parallel.exe" "${OUT}"
chmod +x "${OUT}"
