#!/usr/bin/env bash
# zarith_tak.build.sh — builds zarith_tak benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/zarith_tak-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install zarith num -y
# --- Build zarith_tak ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release zarith_tak.exe
cp "${BENCH_DIR}/_build/default/zarith_tak.exe" "${OUT}"
chmod +x "${OUT}"
