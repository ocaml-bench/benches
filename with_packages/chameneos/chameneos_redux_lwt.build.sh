#!/usr/bin/env bash
# chameneos_redux_lwt.build.sh — builds chameneos_redux_lwt benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/chameneos_redux_lwt-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install lwt -y
# --- Build chameneos_redux_lwt ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release chameneos_redux_lwt.exe
cp "${BENCH_DIR}/_build/default/chameneos_redux_lwt.exe" "${OUT}"
chmod +x "${OUT}"
