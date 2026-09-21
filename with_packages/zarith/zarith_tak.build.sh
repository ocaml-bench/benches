#!/usr/bin/env bash
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/zarith_tak-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

opam install zarith num -y
dune build --root "${BENCH_DIR}" --profile release zarith_tak.exe
cp "${BENCH_DIR}/_build/default/zarith_tak.exe" "${OUT}"
chmod +x "${OUT}"
