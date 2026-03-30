#!/usr/bin/env bash
# raytracer.build.sh — builds the mpl/raytracer benchmark binary.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/raytracer-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

# --- Install domainslib ---------------------------------------------------
opam install domainslib -y
# --- Build raytracer ---------------------------------------------------------
dune build --root "${BENCH_DIR}" --profile release raytracer.exe
cp "${BENCH_DIR}/_build/default/raytracer.exe" "${OUT}"
chmod +x "${OUT}"
