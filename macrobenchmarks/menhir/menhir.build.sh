#!/usr/bin/env bash
# menhir.build.sh — installs menhir and copies the binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/menhir-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

opam install menhir -y

MENHIR="$(command -v menhir)" || { echo "menhir not found after install" >&2; exit 1; }
cp "${MENHIR}" "${OUT}"
chmod +x "${OUT}"
