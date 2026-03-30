#!/usr/bin/env bash
# contrast.build.sh — builds contrast benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/contrast-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install camlimages -y
# --- Build contrast ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release contrast.exe
cp "${BENCH_DIR}/_build/default/contrast.exe" "${OUT}"
chmod +x "${OUT}"
