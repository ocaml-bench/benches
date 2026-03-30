#!/usr/bin/env bash
# zarith_fact.build.sh — builds zarith_fact benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/zarith_fact-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install zarith num -y
# --- Build zarith_fact ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release zarith_fact.exe
cp "${BENCH_DIR}/_build/default/zarith_fact.exe" "${OUT}"
chmod +x "${OUT}"
