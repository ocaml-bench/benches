#!/usr/bin/env bash
# tokens.build.sh — builds the mpl/tokens benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/tokens-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install domainslib ---------------------------------------------------
opam install domainslib -y
# --- Build tokens ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release tokens.exe
cp "${BENCH_DIR}/_build/default/tokens.exe" "${OUT}"
chmod +x "${OUT}"
