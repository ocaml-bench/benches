#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/grammatrix_multicore-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

opam install domainslib -y

dune build --root "${BENCH_DIR}" --profile release grammatrix_multicore.exe
cp "${BENCH_DIR}/_build/default/grammatrix_multicore.exe" "${OUT}"
chmod +x "${OUT}"
