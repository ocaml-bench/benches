#!/usr/bin/env bash
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/graph500seq-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
"${BENCH_DIR}/graph500seq.build.deps.sh"

dune build --root "${BENCH_DIR}" --profile release kernel1_run.exe
cp "${BENCH_DIR}/_build/default/kernel1_run.exe" "${OUT}"
chmod +x "${OUT}"
