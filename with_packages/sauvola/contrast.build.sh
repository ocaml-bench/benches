#!/usr/bin/env bash
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/contrast-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

opam install camlimages -y
dune build --root "${BENCH_DIR}" --profile release contrast.exe
cp "${BENCH_DIR}/_build/default/contrast.exe" "${OUT}"
chmod +x "${OUT}"
