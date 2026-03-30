#!/usr/bin/env bash
# fasta6.build.sh — builds fasta6 benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/fasta6-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install zarith -y
# --- Build fasta6 ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release fasta6.exe
cp "${BENCH_DIR}/_build/default/fasta6.exe" "${OUT}"
chmod +x "${OUT}"
