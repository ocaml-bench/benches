#!/usr/bin/env bash
# cubicle.build.sh — installs cubicle and copies the binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/cubicle-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

opam install cubicle -y

CUBICLE="$(command -v cubicle)" || { echo "cubicle not found after install" >&2; exit 1; }
cp "${CUBICLE}" "${OUT}"
chmod +x "${OUT}"
