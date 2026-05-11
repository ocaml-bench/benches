#!/usr/bin/env bash
# graph500seq.build.deps.sh — generates edges.data using gen.exe.
#
# Called by graph500seq.build.sh when edges.data does not yet exist.
# edges.data is independent of the OCaml runtime version, so it is generated
# once and shared across all runtime builds.
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
