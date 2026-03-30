#!/usr/bin/env bash
# binarytrees5.build.sh — builds binarytrees5 benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/binarytrees5-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install zarith -y
# --- Build binarytrees5 ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release binarytrees5.exe
cp "${BENCH_DIR}/_build/default/binarytrees5.exe" "${OUT}"
chmod +x "${OUT}"
