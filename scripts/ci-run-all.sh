#!/usr/bin/env bash
# ci-run-all.sh: run every program in manifest.yml once, with its manifest args,
# from a scratch cwd. A correctness gate, not a measurement. Runs everything
# before failing; exits 1 if any program exited non-zero or timed out.
#
# Environment:
#   RUNNING_OCAML_RUNTIME_NAME  runtime tag, matching the build (default: ci)
#   RUNTIME_KIND                ocaml (default) | oxcaml
#   LOG_DIR                     where to write per-program logs
#   LOG_TAIL_BYTES              bytes of output kept per program (default 65536)
#   ONLY                        space-separated program names (default: all)
#   SUITE                       restrict to one manifest suite
set -uo pipefail

BENCH_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUNTIME_TAG="${RUNNING_OCAML_RUNTIME_NAME:-ci}"
RUNTIME_KIND="${RUNTIME_KIND:-ocaml}"
LOG_DIR="${LOG_DIR:-${BENCH_DIR}/ci-logs/run/${RUNTIME_TAG}}"
ONLY="${ONLY:-}"
SUITE="${SUITE:-}"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "${SCRATCH}"' EXIT

mkdir -p "${LOG_DIR}"

echo "=== Running all benchmarks once (runtime tag: ${RUNTIME_TAG}) ==="
echo "scratch cwd: ${SCRATCH}"
echo ""

failed=0
count=0
results=()

while IFS=$'\t' read -r name path _script timeout_s args; do
  [ -n "${name}" ] || continue

  exe="${BENCH_DIR}/${path}/${name}-${RUNTIME_TAG}"
  log="${LOG_DIR}/${name}.log"
  count=$((count + 1))

  printf '%-34s ' "${name}"

  if [ ! -x "${exe}" ]; then
    printf 'SKIPPED (not built)\n'
    results+=("FAILED|${name}|0|not built")
    failed=$((failed + 1))
    continue
  fi

  cwd="${SCRATCH}/${name}"
  mkdir -p "${cwd}"

  # Manifest args are plain paths and numbers; word splitting is intended.
  read -ra argv <<< "${args}"

  start=${SECONDS}
  # Keep only the tail: fasta3/fasta6/revcomp2 write ~243 MB to stdout each.
  # `tail -c`, not `head -c`: head would SIGPIPE the benchmark and change the
  # exit code being checked (PIPESTATUS[0]).
  ( cd "${cwd}" && timeout --kill-after=30s "${timeout_s}" "${exe}" "${argv[@]}" ) 2>&1 \
    | tail -c "${LOG_TAIL_BYTES:-65536}" > "${log}"
  rc=${PIPESTATUS[0]}
  elapsed=$((SECONDS - start))

  # 124 = GNU timeout expired, 137 = SIGKILL from --kill-after. uutils timeout
  # returns 125 with --kill-after, but 125 also means "timeout itself failed",
  # so disambiguate by whether the clock ran out.
  timed_out=0
  case ${rc} in
    124|137) timed_out=1 ;;
    125) [ ${elapsed} -ge "${timeout_s}" ] && timed_out=1 ;;
  esac

  if [ ${rc} -eq 0 ]; then
    printf 'ok      %4ds\n' "${elapsed}"
    results+=("ok|${name}|${elapsed}|")
  elif [ ${timed_out} -eq 1 ]; then
    printf 'TIMEOUT %4ds  (limit %ss)\n' "${elapsed}" "${timeout_s}"
    results+=("TIMEOUT|${name}|${elapsed}|exceeded ${timeout_s}s limit")
    failed=$((failed + 1))
  else
    printf 'FAILED  %4ds  (exit %d, see %s)\n' "${elapsed}" "${rc}" "${log#"${BENCH_DIR}/"}"
    # `|` is the field separator for the summary rows, so strip it from log text.
    results+=("FAILED|${name}|${elapsed}|exit ${rc}: $(tail -3 "${log}" | tr '\n|' ' /' | cut -c1-160)")
    failed=$((failed + 1))
  fi
done < <(python3 "${BENCH_DIR}/scripts/ci-manifest.py" list \
           --only "${ONLY}" --suite "${SUITE}" --runtime-kind "${RUNTIME_KIND}")

echo ""
echo "=== ${count} programs, $((count - failed)) ran clean, ${failed} failed ==="

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "## Run once (${RUNTIME_TAG}) — $((count - failed))/${count} programs"
    echo ""
    echo "| program | result | wall | detail |"
    echo "|---|---|---:|---|"
    for r in "${results[@]}"; do
      IFS='|' read -r status name elapsed detail <<< "${r}"
      icon=$([ "${status}" = "ok" ] && echo ":white_check_mark:" || echo ":x:")
      echo "| \`${name}\` | ${icon} ${status} | ${elapsed}s | ${detail} |"
    done
    echo ""
    echo "_Wall times are from a shared runner — indicative only, not measurements._"
  } >> "${GITHUB_STEP_SUMMARY}"
fi

[ ${failed} -eq 0 ] || exit 1
