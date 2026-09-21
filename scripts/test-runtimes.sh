#!/usr/bin/env bash
# test-runtimes.sh: build and run the whole suite under several OCaml runtimes.
# A build/run correctness gate, not a measurement (one invocation, no perf, no olly).
#
# Usage: bash scripts/test-runtimes.sh [NAME...]   (default: 5.5.0 + newest trunk switch)
#   NAME is a running-ng runtime suffix: it selects opam switch running-ng-ocaml-NAME
#   and tags binaries <program>-ocaml-NAME, matching what running-ng produces.
# Environment:
#   SWITCH_PREFIX  opam switch name prefix (default: running-ng-ocaml-)
#   SKIP_RUN       set to skip the run phase
#   ONLY / SUITE   forwarded to ci-build-all.sh and ci-run-all.sh
#   LOG_ROOT       where per-runtime logs go (default: ci-logs)
set -uo pipefail

BENCH_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SWITCH_PREFIX="${SWITCH_PREFIX:-running-ng-ocaml-}"
LOG_ROOT="${LOG_ROOT:-${BENCH_DIR}/ci-logs}"

if [ $# -eq 0 ]; then
  newest_trunk="$(opam switch list --short 2>/dev/null \
    | grep "^${SWITCH_PREFIX}trunk-" \
    | while read -r sw; do
        printf '%s\t%s\n' "$(stat -c %Y "$(opam var prefix --switch="$sw" 2>/dev/null)" 2>/dev/null || echo 0)" "$sw"
      done | sort -n | tail -1 | cut -f2)"
  set -- 5.5.0 "${newest_trunk#"${SWITCH_PREFIX}"}"
  echo "No runtimes given; defaulting to: $*"
  echo ""
fi

echo "=== manifest check ==="
python3 "${BENCH_DIR}/scripts/ci-manifest.py" check || exit 1
echo ""

overall=0
summary=()

for name in "$@"; do
  [ -n "${name}" ] || continue
  tag="ocaml-${name}"
  switch="${SWITCH_PREFIX}${name}"

  echo ""
  echo "############################################################"
  echo "# ${tag}   (opam switch: ${switch})"
  echo "############################################################"

  if ! opam switch list --short 2>/dev/null | grep -qFx "${switch}"; then
    echo "SKIPPED: no such opam switch '${switch}'."
    echo "  Create it with: opam compiler create ocaml/ocaml:${name}   (needs the opam-compiler plugin)"
    echo "  running-ng provisions these automatically; this script never creates one,"
    echo "  because silently building a compiler is not what you asked for."
    summary+=("${tag}|SKIPPED|no switch|-")
    overall=1
    continue
  fi

  # Same `opam env --set-switch` as running-ng (compiler and pinned dune both come
  # from the switch); subshell so it cannot leak into the next runtime.
  (
    eval "$(opam env --switch="${switch}" --set-switch)"
    echo "compiler: $(ocamlopt -version)   dune: $(dune --version)"
    echo ""

    export RUNNING_OCAML_RUNTIME_NAME="${tag}"
    export LOG_DIR="${LOG_ROOT}/build/${tag}"
    bash "${BENCH_DIR}/scripts/ci-build-all.sh"
    build_rc=$?

    run_rc=0
    if [ -z "${SKIP_RUN:-}" ]; then
      echo ""
      LOG_DIR="${LOG_ROOT}/run/${tag}" bash "${BENCH_DIR}/scripts/ci-run-all.sh"
      run_rc=$?
    fi

    # Exit status bits: 1 = build broke, 2 = run broke.
    exit $(( (build_rc != 0 ? 1 : 0) + (run_rc != 0 ? 2 : 0) ))
  )
  rc=$?

  case ${rc} in
    0) summary+=("${tag}|ok|build ok|run ok") ;;
    1) summary+=("${tag}|FAILED|build FAILED|run ok"); overall=1 ;;
    2) summary+=("${tag}|FAILED|build ok|run FAILED"); overall=1 ;;
    3) summary+=("${tag}|FAILED|build FAILED|run FAILED"); overall=1 ;;
    *) summary+=("${tag}|FAILED|driver exit ${rc}|-"); overall=1 ;;
  esac
done

echo ""
echo "############################################################"
echo "# Summary"
echo "############################################################"
printf '%-28s %-9s %-16s %s\n' runtime result build run
for s in "${summary[@]}"; do
  IFS='|' read -r a b c d <<< "${s}"
  printf '%-28s %-9s %-16s %s\n' "${a}" "${b}" "${c}" "${d}"
done
echo ""
echo "Logs: ${LOG_ROOT#"${BENCH_DIR}/"}/{build,run}/<runtime>/<program>.log"

exit ${overall}
