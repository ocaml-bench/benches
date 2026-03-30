#!/usr/bin/env bash
# frama_c.build.sh — installs frama-c and copies the binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/frama_c-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

opam install frama-c -y

FRAMA_C="$(command -v frama-c)" || { echo "frama-c not found after install" >&2; exit 1; }
cp "${FRAMA_C}" "${OUT}"
chmod +x "${OUT}"
