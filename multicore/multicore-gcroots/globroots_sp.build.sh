#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/globroots_sp-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

opam install domainslib -y

dune build --root "${BENCH_DIR}" --profile release globroots_sp.exe
cp "${BENCH_DIR}/_build/default/globroots_sp.exe" "${OUT}"
chmod +x "${OUT}"
