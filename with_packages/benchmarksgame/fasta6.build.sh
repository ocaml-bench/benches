#!/usr/bin/env bash
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/fasta6-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

opam install zarith -y
dune build --root "${BENCH_DIR}" --profile release fasta6.exe
cp "${BENCH_DIR}/_build/default/fasta6.exe" "${OUT}"
chmod +x "${OUT}"
