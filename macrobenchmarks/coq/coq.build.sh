#!/usr/bin/env bash
# coq.build.sh — installs coq and copies the coqc binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/coqc-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

opam install coq -y

COQC="$(command -v coqc)" || { echo "coqc not found after install" >&2; exit 1; }
cp "${COQC}" "${OUT}"
chmod +x "${OUT}"
