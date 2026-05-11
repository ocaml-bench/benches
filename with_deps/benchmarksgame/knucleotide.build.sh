#!/usr/bin/env bash
# knucleotide.build.sh — builds the knucleotide benchmark binary.
#
# Also invokes benchmarksgame.build.deps.sh to generate FASTA input files
# if they do not yet exist.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/knucleotide-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
# --- Generate input data if needed (runtime-independent, generated once) ---
"${BENCH_DIR}/benchmarksgame.build.deps.sh"

# --- Build knucleotide ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release knucleotide.exe
cp "${BENCH_DIR}/_build/default/knucleotide.exe" "${OUT}"
chmod +x "${OUT}"
