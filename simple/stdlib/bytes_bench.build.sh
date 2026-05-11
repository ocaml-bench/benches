#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/bytes_bench-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release bytes_bench.exe
cp "${BENCH_DIR}/_build/default/bytes_bench.exe" "${OUT}"
chmod +x "${OUT}"
