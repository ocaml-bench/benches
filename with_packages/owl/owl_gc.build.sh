#!/usr/bin/env bash
# owl_gc.build.sh — builds owl_gc benchmark binary.
#
# System dependencies: libopenblas-dev liblapacke-dev
#   (install via: sudo apt-get install -y libopenblas-dev liblapacke-dev)
#   opam will install them automatically if run with sudo/root access.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/owl_gc-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
# owl (not owl-base) is needed: the benchmark uses Owl_dense_matrix_d and
# Owl_dense_ndarray_d which are only in the full owl package.
opam install owl -y
# --- Build owl_gc ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release owl_gc.exe
cp "${BENCH_DIR}/_build/default/owl_gc.exe" "${OUT}"
chmod +x "${OUT}"
