#!/usr/bin/env bash
# pidigits5.build.sh — builds pidigits5 benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/pidigits5-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install zarith -y
# --- Build pidigits5 ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release pidigits5.exe
cp "${BENCH_DIR}/_build/default/pidigits5.exe" "${OUT}"
chmod +x "${OUT}"
