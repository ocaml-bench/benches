#!/usr/bin/env bash
set -euo pipefail
BENCH_DIR="${RUNNING_OCAML_BENCH_DIR:-$(pwd)}"
OUT="${RUNNING_OCAML_OUTPUT:-${BENCH_DIR}/test_sched-${RUNNING_OCAML_RUNTIME_NAME:-runtime}}"

opam install saturn_lockfree -y

dune build --root "${BENCH_DIR}" --profile release test_sched.exe
cp "${BENCH_DIR}/_build/default/test_sched.exe" "${OUT}"
chmod +x "${OUT}"
