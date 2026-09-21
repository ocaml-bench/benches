#!/usr/bin/env bash
# ci-build-all.sh: build every program in manifest.yml with the compiler on PATH.
# Does not stop at the first failure; prints a result table (also to
# $GITHUB_STEP_SUMMARY under GitHub Actions) and exits 1 if any build failed.
# Programs sharing a build script are each built separately, as running-ng does.
#
# Environment:
#   RUNNING_OCAML_RUNTIME_NAME  runtime tag; binaries are <name>-<tag> (default: ci)
#   RUNTIME_KIND                ocaml (default) | oxcaml; selects programs whose `requires:` matches
#   LOG_DIR                     where to write per-program logs (default ci-logs/build/<tag>)
#   ONLY                        space-separated program names (default: all)
#   SUITE                       restrict to one manifest suite
set -uo pipefail

BENCH_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUNTIME_TAG="${RUNNING_OCAML_RUNTIME_NAME:-ci}"
RUNTIME_KIND="${RUNTIME_KIND:-ocaml}"
LOG_DIR="${LOG_DIR:-${BENCH_DIR}/ci-logs/build/${RUNTIME_TAG}}"
ONLY="${ONLY:-}"
SUITE="${SUITE:-}"

mkdir -p "${LOG_DIR}"

echo "=== Building all benchmarks (runtime tag: ${RUNTIME_TAG}) ==="
echo "benches:  ${BENCH_DIR}"
echo "compiler: $(ocamlopt -version 2>/dev/null || echo '??') ($(command -v ocamlopt || echo 'ocamlopt not on PATH'))"
echo "dune:     $(dune --version 2>/dev/null || echo '??')"
echo "switch:   ${OPAM_SWITCH_PREFIX:-<none>}"
echo ""

failed=0
count=0
results=()

while IFS=$'\t' read -r name path script _timeout _args; do
  [ -n "${name}" ] || continue

  bench_dir="${BENCH_DIR}/${path}"
  out="${bench_dir}/${name}-${RUNTIME_TAG}"
  log="${LOG_DIR}/${name}.log"
  count=$((count + 1))

  # A stale binary from a previous compiler would make a failed build look like a success.
  rm -f "${out}"

  printf '%-34s ' "${name}"
  start=${SECONDS}
  env RUNNING_OCAML_BENCH_DIR="${bench_dir}" \
      RUNNING_OCAML_OUTPUT="${out}" \
      RUNNING_OCAML_RUNTIME_NAME="${RUNTIME_TAG}" \
      bash "${bench_dir}/${script}" > "${log}" 2>&1
  rc=$?
  elapsed=$((SECONDS - start))

  if [ ${rc} -eq 0 ] && [ -x "${out}" ]; then
    printf 'ok      %4ds\n' "${elapsed}"
    results+=("ok|${name}|${elapsed}|")
  elif [ ${rc} -eq 0 ]; then
    printf 'FAILED  %4ds  (script succeeded but produced no executable)\n' "${elapsed}"
    results+=("FAILED|${name}|${elapsed}|no executable produced")
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
echo "=== ${count} programs, $((count - failed)) built, ${failed} failed ==="

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "## Build (${RUNTIME_TAG}) — $((count - failed))/${count} programs"
    echo ""
    echo "| program | result | build time | detail |"
    echo "|---|---|---:|---|"
    for r in "${results[@]}"; do
      IFS='|' read -r status name elapsed detail <<< "${r}"
      icon=$([ "${status}" = "ok" ] && echo ":white_check_mark:" || echo ":x:")
      echo "| \`${name}\` | ${icon} ${status} | ${elapsed}s | ${detail} |"
    done
  } >> "${GITHUB_STEP_SUMMARY}"
fi

[ ${failed} -eq 0 ] || exit 1
