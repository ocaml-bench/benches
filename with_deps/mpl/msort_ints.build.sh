#!/usr/bin/env bash
# msort_ints.build.sh — builds the mpl/msort_ints benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/msort_ints-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install domainslib ---------------------------------------------------
opam install domainslib -y
# --- Build msort_ints ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release msort_ints.exe
cp "${BENCH_DIR}/_build/default/msort_ints.exe" "${OUT}"
chmod +x "${OUT}"
