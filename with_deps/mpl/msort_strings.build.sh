#!/usr/bin/env bash
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/msort_strings-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

opam install domainslib -y
dune build --root "${BENCH_DIR}" --profile release msort_strings.exe
cp "${BENCH_DIR}/_build/default/msort_strings.exe" "${OUT}"
chmod +x "${OUT}"
