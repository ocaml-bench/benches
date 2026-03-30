#!/usr/bin/env bash
# benchmarksgame.build.deps.sh — generates FASTA input files using fasta3.exe.
#
# Called by each benchmark's build script when input data does not yet exist.
# Both input files are independent of the OCaml runtime version, so they are
# generated once and shared across all runtime builds.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
INPUT_25M="${BENCH_DIR}/input25000000.txt"
INPUT_5M="${BENCH_DIR}/input5000000.txt"

if [[ -f "${INPUT_25M}" && -f "${INPUT_5M}" ]]; then
  echo "Input files already exist; skipping generation." >&2
  exit 0
fi
dune build --root "${BENCH_DIR}" --profile release fasta3.exe

FASTA3="${BENCH_DIR}/_build/default/fasta3.exe"

if [[ ! -f "${INPUT_25M}" ]]; then
  echo "Generating input25000000.txt (25M nucleotides)..." >&2
  "${FASTA3}" 25000000 > "${INPUT_25M}"
  echo "Generated ${INPUT_25M}" >&2
fi

if [[ ! -f "${INPUT_5M}" ]]; then
  echo "Generating input5000000.txt (5M nucleotides)..." >&2
  "${FASTA3}" 5000000 > "${INPUT_5M}"
  echo "Generated ${INPUT_5M}" >&2
fi
