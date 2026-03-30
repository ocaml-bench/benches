#!/usr/bin/env bash
# ydump.build.sh — builds ydump benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/ydump-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install yojson camlp-streams -y
# --- Build ydump ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release ydump.exe
cp "${BENCH_DIR}/_build/default/ydump.exe" "${OUT}"
chmod +x "${OUT}"
