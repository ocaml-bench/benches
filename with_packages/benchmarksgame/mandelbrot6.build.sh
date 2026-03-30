#!/usr/bin/env bash
# mandelbrot6.build.sh — builds mandelbrot6 benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/mandelbrot6-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install zarith -y
# --- Build mandelbrot6 ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release mandelbrot6.exe
cp "${BENCH_DIR}/_build/default/mandelbrot6.exe" "${OUT}"
chmod +x "${OUT}"
