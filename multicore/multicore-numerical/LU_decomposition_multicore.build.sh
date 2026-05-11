#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/LU_decomposition_multicore-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

opam install domainslib -y

dune build --root "${BENCH_DIR}" --profile release LU_decomposition_multicore.exe
cp "${BENCH_DIR}/_build/default/LU_decomposition_multicore.exe" "${OUT}"
chmod +x "${OUT}"
