#!/usr/bin/env bash
# spectralnorm2.build.sh — builds spectralnorm2 benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/spectralnorm2-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install zarith -y
# --- Build spectralnorm2 ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release spectralnorm2.exe
cp "${BENCH_DIR}/_build/default/spectralnorm2.exe" "${OUT}"
chmod +x "${OUT}"
