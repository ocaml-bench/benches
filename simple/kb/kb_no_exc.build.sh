#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/kb_no_exc-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release kb_no_exc.exe
cp "${BENCH_DIR}/_build/default/kb_no_exc.exe" "${OUT}"
chmod +x "${OUT}"
