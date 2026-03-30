#!/usr/bin/env bash
# cpdf.build.sh — installs cpdf and copies the binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/cpdf-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

opam install cpdf -y

CPDF="$(command -v cpdf)" || { echo "cpdf not found after install" >&2; exit 1; }
cp "${CPDF}" "${OUT}"
chmod +x "${OUT}"
