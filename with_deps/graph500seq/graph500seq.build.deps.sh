#!/usr/bin/env bash
# edges.data is independent of the OCaml runtime, so it is generated once and shared by every runtime build.
set -euo pipefail

BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
EDGES_DATA="${BENCH_DIR}/edges.data"

if [[ -f "${EDGES_DATA}" ]]; then
  echo "edges.data already exists at ${EDGES_DATA}; skipping generation." >&2
  exit 0
fi
dune build --root "${BENCH_DIR}" --profile release gen.exe

GEN="${BENCH_DIR}/_build/default/gen.exe"
echo "Generating edges.data (scale=21, edgefactor=16)..." >&2
"${GEN}" -scale 21 -edgefactor 16 "${EDGES_DATA}"
echo "Generated ${EDGES_DATA}" >&2
