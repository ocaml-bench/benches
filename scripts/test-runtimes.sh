#!/usr/bin/env bash
# test-runtimes.sh — build and run the whole suite under several OCaml runtimes.
#
# The gate you want before trusting a sweep: it answers "does every benchmark in
# this tree still build and still run, on each compiler I care about?" — and,
# because it runs the same set on each, "did anything change between them?"
#
# For each runtime it activates that runtime's opam switch (the same
# `opam env --set-switch` running-ng does, so the compiler *and* the pinned dune
# come from the switch), then runs scripts/ci-build-all.sh and scripts/ci-run-all.sh.
# Nothing here measures performance: one invocation, no perf, no olly, no core
# pinning. It is a build/run correctness gate.
#
# Usage:
#   bash scripts/test-runtimes.sh                    # 5.5.0 + newest trunk switch
#   bash scripts/test-runtimes.sh 5.5.0 trunk-c0f8c8ce
#   SKIP_RUN=1 bash scripts/test-runtimes.sh         # build phase only
#   ONLY="almabench bdd" bash scripts/test-runtimes.sh
#
# Each argument NAME is a running-ng runtime suffix: it selects the opam switch
# `running-ng-ocaml-NAME` and tags binaries `<program>-ocaml-NAME`, matching what
# running-ng itself produces — so a tree left behind by this script is exactly
# the tree a sweep would find, and vice versa.
#
# Environment:
#   SWITCH_PREFIX  opam switch name prefix (default: running-ng-ocaml-)
#   SKIP_RUN       set to skip the run phase
#   ONLY / SUITE   forwarded to ci-build-all.sh and ci-run-all.sh
#   LOG_ROOT       where per-runtime logs go (default: ci-logs)
set -uo pipefail

BENCH_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SWITCH_PREFIX="${SWITCH_PREFIX:-running-ng-ocaml-}"
LOG_ROOT="${LOG_ROOT:-${BENCH_DIR}/ci-logs}"

# Default: the 5.5.0 release plus whichever trunk switch is newest on this
# machine, which is what "5.5.0 vs latest trunk" means in practice here.
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

  # Same activation running-ng performs: compiler and pinned dune both come from
  # the runtime switch. Done in a subshell so one runtime cannot leak into the next.
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

    # Fold both phases into one exit status the parent can read: 0 clean,
    # 1 build broke, 2 run broke, 3 both.
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
