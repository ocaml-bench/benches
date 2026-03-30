#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/rec_seq_ack-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release rec_seq_ack.exe
cp "${BENCH_DIR}/_build/default/rec_seq_ack.exe" "${OUT}"
chmod +x "${OUT}"
