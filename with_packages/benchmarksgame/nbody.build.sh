#!/usr/bin/env bash
# nbody.build.sh — builds nbody benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/nbody-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install zarith -y
# --- Build nbody ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release nbody.exe
cp "${BENCH_DIR}/_build/default/nbody.exe" "${OUT}"
chmod +x "${OUT}"
