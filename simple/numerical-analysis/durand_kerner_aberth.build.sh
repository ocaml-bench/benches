#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/durand_kerner_aberth-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release durand_kerner_aberth.exe
cp "${BENCH_DIR}/_build/default/durand_kerner_aberth.exe" "${OUT}"
chmod +x "${OUT}"
