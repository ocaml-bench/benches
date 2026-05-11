#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/evolutionary_algorithm_multicore-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

opam install domainslib -y

dune build --root "${BENCH_DIR}" --profile release evolutionary_algorithm_multicore.exe
cp "${BENCH_DIR}/_build/default/evolutionary_algorithm_multicore.exe" "${OUT}"
chmod +x "${OUT}"
