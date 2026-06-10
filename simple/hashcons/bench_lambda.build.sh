#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/bench_lambda-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"
dune build --root "${BENCH_DIR}" --profile release bench_lambda.exe
cp "${BENCH_DIR}/_build/default/bench_lambda.exe" "${OUT}"
chmod +x "${OUT}"
# Note: bench_lambda reads its data file from $QUICKSORT_TERM (absolute path);
# the running-ng config must point it at ${BENCH_DIR}/quicksort.term since the
# run cwd is a temp dir.
