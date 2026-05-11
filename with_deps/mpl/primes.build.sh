#!/usr/bin/env bash
# primes.build.sh — builds the mpl/primes benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/primes-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install domainslib ---------------------------------------------------
opam install domainslib -y
# --- Build primes ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release primes.exe
cp "${BENCH_DIR}/_build/default/primes.exe" "${OUT}"
chmod +x "${OUT}"
