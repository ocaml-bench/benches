#!/usr/bin/env bash
# zarith_pi.build.sh — builds zarith_pi benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/zarith_pi-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install zarith num -y
# --- Build zarith_pi ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release zarith_pi.exe
cp "${BENCH_DIR}/_build/default/zarith_pi.exe" "${OUT}"
chmod +x "${OUT}"
