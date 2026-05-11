#!/usr/bin/env bash
# test_decompress.build.sh — builds test_decompress benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/test_decompress-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install decompress bigstringaf checkseum -y
# --- Build test_decompress ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release test_decompress.exe
cp "${BENCH_DIR}/_build/default/test_decompress.exe" "${OUT}"
chmod +x "${OUT}"
