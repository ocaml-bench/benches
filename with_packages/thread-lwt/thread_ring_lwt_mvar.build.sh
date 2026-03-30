#!/usr/bin/env bash
# thread_ring_lwt_mvar.build.sh — builds thread_ring_lwt_mvar benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/thread_ring_lwt_mvar-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install required packages --------------------------------------------
opam install lwt -y
# --- Build thread_ring_lwt_mvar ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release thread_ring_lwt_mvar.exe
cp "${BENCH_DIR}/_build/default/thread_ring_lwt_mvar.exe" "${OUT}"
chmod +x "${OUT}"
