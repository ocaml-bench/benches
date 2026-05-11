#!/usr/bin/env bash
# graph500seq.build.sh — builds the kernel1_run benchmark binary.
#
# Also invokes graph500seq.build.deps.sh to generate edges.data if it does not
# exist yet.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/graph500seq-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
# --- Generate edges.data if needed (runtime-independent, generated once) ---
"${BENCH_DIR}/graph500seq.build.deps.sh"

# --- Build kernel1_run -----------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release kernel1_run.exe
cp "${BENCH_DIR}/_build/default/kernel1_run.exe" "${OUT}"
chmod +x "${OUT}"
