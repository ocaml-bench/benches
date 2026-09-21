#!/usr/bin/env bash
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/regexredux2-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
"${BENCH_DIR}/benchmarksgame.build.deps.sh"

dune build --root "${BENCH_DIR}" --profile release regexredux2.exe
cp "${BENCH_DIR}/_build/default/regexredux2.exe" "${OUT}"
chmod +x "${OUT}"
