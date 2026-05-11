#!/usr/bin/env bash
# kernel1_run_multicore.build.sh — requires domainslib + unix
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/kernel1_run_multicore-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

opam install domainslib -y

# --- Generate edges.data if needed (runtime-independent, generated once) ---
"${BENCH_DIR}/graph500par.build.deps.sh"

dune build --root "${BENCH_DIR}" --profile release kernel1_run_multicore.exe
cp "${BENCH_DIR}/_build/default/kernel1_run_multicore.exe" "${OUT}"
chmod +x "${OUT}"
