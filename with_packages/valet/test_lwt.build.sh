#!/usr/bin/env bash
# test_lwt.build.sh — builds test_lwt benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/test_lwt-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install uuidm ocplib-endian react lwt -y
# --- Build test_lwt ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release test_lwt.exe
cp "${BENCH_DIR}/_build/default/test_lwt.exe" "${OUT}"
chmod +x "${OUT}"
