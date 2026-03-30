#!/usr/bin/env bash
# fasta3.build.sh — builds fasta3 benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/fasta3-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install zarith -y
# --- Build fasta3 ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release fasta3.exe
cp "${BENCH_DIR}/_build/default/fasta3.exe" "${OUT}"
chmod +x "${OUT}"
