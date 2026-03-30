#!/usr/bin/env bash
# alt_ergo.build.sh — installs alt-ergo and copies the binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/alt_ergo-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

opam install alt-ergo.2.4.3 -y

ALT_ERGO="$(command -v alt-ergo)" || { echo "alt-ergo not found after install" >&2; exit 1; }
cp "${ALT_ERGO}" "${OUT}"
chmod +x "${OUT}"
