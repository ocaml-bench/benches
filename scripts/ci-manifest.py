#!/usr/bin/env python3
"""Read manifest.yml for the build/run scripts.

Modes:

  ci-manifest.py list          one TAB-separated row per program:
                                    name  path  build_script  timeout  args
                                  (${RUNNING_BENCH_DIR} already expanded)

                                  `args` is last on purpose: bash treats TAB as
                                  whitespace-IFS, so an empty field in the middle
                                  of a row would collapse and shift every later
                                  column.

  ci-manifest.py check         verify the manifest against the tree:
                                    - every program's dir and build script exist
                                    - every build script in the tree is claimed
                                      by a program or listed under `disabled`
                                    - every in-tree input path in `args` exists
                                    - every program names a declared suite
                                  Reads nothing outside this repo. This is what
                                  `make check` and CI run.

                                  --running-ng [<micro_base.yml>] additionally
                                  diffs the program set and every `args` string
                                  against running-ng's sweep config. Opt-in, and
                                  the ONLY thing in this repo that looks outside
                                  it: benches builds, runs and tests itself
                                  standalone, so never fold this into `check`.

Filters (list only):
  --only "a b c"     restrict to these program names
  --suite NAME       restrict to one suite
  --runtime-kind K   drop programs whose `requires:` does not match K
                     (default "ocaml"; use "oxcaml" for an OxCaml runtime)

Kept deliberately small: the shell scripts do the work, this only parses.
"""

import argparse
import os
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("error: PyYAML not found — install it with `python3 -m pip install pyyaml`")

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "manifest.yml"
# Benchmarks live two levels down: <group>/<benchmark-dir>/<name>.build.sh
SCRIPT_GLOB = "*/*/*.build.sh"


def load():
    with MANIFEST.open() as f:
        return yaml.safe_load(f)


def expand(s):
    # The manifest uses running-ng's ${RUNNING_BENCH_DIR} spelling so the two
    # arg lists can be diffed mechanically.
    return (s or "").replace("${RUNNING_BENCH_DIR}", str(ROOT))


def script_of(name, prog):
    return prog.get("build_script") or f"{name}.build.sh"


def timeout_of(m, prog):
    suite = m.get("suites", {}).get(prog.get("suite"), {})
    return suite.get("timeout") or m.get("default_timeout", 120)


def cmd_list(args):
    m = load()
    only = set(args.only.split()) if args.only else None
    for name, p in (m.get("programs") or {}).items():
        if only is not None and name not in only:
            continue
        if args.suite and p.get("suite") != args.suite:
            continue
        requires = p.get("requires")
        if requires and requires != args.runtime_kind:
            continue
        print(
            "\t".join(
                [
                    name,
                    p["path"],
                    script_of(name, p),
                    str(timeout_of(m, p)),
                    expand(p.get("args", "")),
                ]
            )
        )


def cmd_check(args):
    m = load()
    programs = m.get("programs") or {}
    suites = m.get("suites") or {}
    disabled = m.get("disabled") or {}
    problems = []

    claimed = set()
    for name, p in programs.items():
        d = ROOT / p["path"]
        s = d / script_of(name, p)
        if p.get("suite") not in suites:
            problems.append(f"{name}: suite {p.get('suite')!r} is not declared")
        if not d.is_dir():
            problems.append(f"{name}: no such directory {p['path']}")
            continue
        if not s.exists():
            problems.append(f"{name}: no build script {s.relative_to(ROOT)}")
            continue
        claimed.add(str(s.relative_to(ROOT)))
        # Args carrying an in-tree path (input data) must actually resolve.
        for tok in (p.get("args") or "").split():
            if "${RUNNING_BENCH_DIR}" in tok and not Path(expand(tok)).exists():
                problems.append(f"{name}: args reference a missing file {tok}")

    for name, d in disabled.items():
        s = ROOT / d["path"] / d["build_script"]
        if not s.exists():
            problems.append(f"disabled/{name}: no build script {s.relative_to(ROOT)}")
        else:
            claimed.add(str(s.relative_to(ROOT)))

    in_tree = {str(p.relative_to(ROOT)) for p in ROOT.glob(SCRIPT_GLOB)}
    for orphan in sorted(in_tree - claimed):
        problems.append(f"build script claimed by no program and not disabled: {orphan}")

    n_compared = f"{len(programs)} programs, {len(in_tree)} build scripts"

    if args.running_ng:
        problems += check_running_ng(programs, Path(args.running_ng).expanduser())
        n_compared += ", cross-checked against running-ng"

    print(f"checked {n_compared}")
    if problems:
        print(f"\n{len(problems)} problem(s):", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        sys.exit(1)
    print("ok")


def check_running_ng(programs, config):
    """Diff this manifest against the config that drives real runs."""
    if not config.exists():
        return [f"running-ng config not found: {config}"]
    with config.open() as f:
        cfg = yaml.safe_load(f)

    ng = {}
    for suite, names in (cfg.get("benchmarks") or {}).items():
        for name in names:
            prog = cfg["suites"][suite]["programs"].get(name)
            if prog is not None:
                ng[name] = prog

    problems = []
    for name in sorted(set(ng) - set(programs)):
        problems.append(f"running-ng runs {name!r} but the manifest does not list it")
    for name in sorted(set(programs) - set(ng)):
        problems.append(f"manifest lists {name!r} but running-ng does not run it")
    for name in sorted(set(ng) & set(programs)):
        want, got = ng[name].get("args", ""), programs[name].get("args", "")
        if want != got:
            problems.append(f"{name}: args differ\n      running-ng: {want}\n      manifest:   {got}")
    return problems


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_list = sub.add_parser("list")
    p_list.add_argument("--only", default="")
    p_list.add_argument("--suite", default="")
    p_list.add_argument("--runtime-kind", default="ocaml")
    p_list.set_defaults(fn=cmd_list)

    p_check = sub.add_parser("check")
    p_check.add_argument(
        "--running-ng",
        nargs="?",
        const="~/running-ng/src/running/config/base/ocaml/micro_base.yml",
        default=None,
        help="opt-in: also diff the program list against running-ng's micro_base.yml",
    )
    p_check.set_defaults(fn=cmd_check)

    args = ap.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
