#!/usr/bin/env python3
"""Check the single-owner invariant across this repo's compile.yml files.

Background — what compile.yml files are
---------------------------------------
The simulation build is driven by a tree of `compile.yml` descriptors
scattered through the source tree (one per logical module/library, under
`<module>/config/compile.yml`). Each descriptor is a YAML stream of one or
more documents; each document is a *provider* with three things that matter
here:

  * `provides: [<name>]`  — a globally unique name other providers can refer
                            to. The build's active set is computed by
                            transitively closing this graph from a chosen
                            root (e.g. a top-level `tb` provider).
  * `requires: [...]`     — names of other providers this one depends on.
                            Forms the DAG the build walks.
  * `targets: { <tgt>: { files: [...], directories: [...], options: [...] }}`
                          — per-target source lists. Common targets are
                            `rtl`, `tb`, and `dpi_compile`; a build of a
                            given target flattens the union of every
                            reachable provider's matching target into one
                            tool invocation (xrun, vcs, ...).

(The schema is internal/undocumented — there's no public name or spec for
it; treat the above as a working description, not a contract.)

Single ownership as a design pattern
------------------------------------
Nothing in the descriptor format *requires* a given source path to be
claimed by only one provider — the build will accept the same path in
multiple providers' `files:` lists and figure out something to do with it.
This script enforces a stricter convention we've chosen to adopt for this
repo: each concrete source path lives in the `files:` list of exactly one
provider. (Listing the same path in multiple targets of that same provider
— e.g. under both `rtl` and `tb` so it builds in either flow — is a
routing choice within one owner, not a duplicate, and is fine.)

The pattern is worth enforcing because it makes several things that are
otherwise easy to get wrong impossible by construction:

  1. No duplicate compilation. When the build flattens reachable providers
     into one tool invocation, a doubly-claimed file gets compiled twice.
     xcelium emits `*W,RECOME` ("recompiling already-compiled module") and
     other tools react variably; at best it's noise in the log, at worst
     it masks real recompile bugs.
  2. Unambiguous build options per file. `options:` and `directories:`
     attach to the provider, not the file. With one owner, the set of
     `+define+...` and include paths a file sees is a property of the DAG.
     With multiple owners disagreeing, what actually applies depends on
     build-list ordering — a fragile, silent failure mode.
  3. Predictable refactors. Single ownership means "drop this provider"
     has a knowable blast radius: exactly the files it owns leave the
     build. Shared ownership turns every removal into a manual audit of
     who else was claiming what.
  4. Drift detection. New duplicates usually signal that a refactor
     copy-pasted a file list instead of wiring up a `requires:` edge, or
     that two pieces of work independently vendored the same external
     sources. Catching that at lint time is far cheaper than at
     integration time.

The script is the mechanism that keeps the convention honest — without it,
the pattern erodes silently as the tree grows.

Classification of violations
----------------------------
  hard          All claimants live in the same project (the parent repo,
                or a single submodule). A real RECOME hazard in any build
                that pulls that project in. Fails the script (exit 1).
  informational Claimants span project boundaries (parent vs. submodule,
                or two different submodules). Each project declares its
                own copy so it can build standalone; only one is active
                when co-instantiated. Printed but does not fail
                (unless --strict).

Flags
-----
  --strict          treat informational duplicates as hard failures
  --single-project  skip submodules entirely; useful for gating only the
                    parent repo's hygiene independent of submodule state

Usage:
    check_compile_yml_ownership.py [--strict] [--single-project] [REPO_ROOT]
"""
from __future__ import annotations

import argparse
import os
import sys
from collections import defaultdict
from pathlib import Path

import yaml
from tabulate import tabulate

Entry = tuple[str, Path, str]  # (provider, compile_yml, target)


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument(
        "--strict",
        action="store_true",
        help="treat informational (cross-project) duplicates as hard failures",
    )
    ap.add_argument(
        "--single-project",
        action="store_true",
        help="only scan the parent project; skip submodules/ entirely",
    )
    ap.add_argument(
        "repo_root",
        nargs="?",
        default=None,
        help="repo root (default: two dirs above this script)",
    )
    return ap.parse_args()


def expand_vars(path: str, compile_root: Path, repo_root: Path) -> str:
    """Resolve $COMPILE_ROOT and $CALIPTRA_ROOT/$MSFT_REPO_ROOT against the
    repo. Other env vars (Avery, UVM, Questa) point at external trees we
    can't normalize; leave them as-is so they at least compare textually."""
    s = path
    s = s.replace("$COMPILE_ROOT", str(compile_root))
    s = s.replace("$CALIPTRA_ROOT", str(repo_root))
    s = s.replace("$MSFT_REPO_ROOT", str(repo_root))
    return os.path.normpath(s)


def iter_files(doc) -> list[tuple[str, str]]:
    """Yield (target_name, file_path) for every file under any target."""
    out: list[tuple[str, str]] = []
    targets = doc.get("targets") or {}
    if not isinstance(targets, dict):
        return out
    for tname, tdef in targets.items():
        if not isinstance(tdef, dict):
            continue
        files = tdef.get("files") or []
        if not isinstance(files, list):
            continue
        for f in files:
            if isinstance(f, str):
                out.append((tname, f))
    return out


def project_of(cy: Path, repo: Path) -> str:
    """Return a stable project identifier for a compile.yml location.

    Files outside `submodules/` belong to the parent project (`<root>`).
    Files inside `submodules/<name>/...` belong to that named submodule, so
    nested submodules and top-level submodules each get their own bucket."""
    try:
        rel = cy.relative_to(repo).parts
    except ValueError:
        return "<external>"
    if len(rel) >= 2 and rel[0] == "submodules":
        return f"submodules/{rel[1]}"
    return "<root>"


def render_violation(
    idx: int,
    total: int,
    path: str,
    entries: list[Entry],
    repo: Path,
) -> None:
    rows = [
        (
            provider,
            tname,
            project_of(cy, repo),
            str(cy.relative_to(repo) if cy.is_relative_to(repo) else cy),
        )
        for provider, cy, tname in entries
    ]
    bar = "=" * 78
    print(bar)
    print(f"[{idx}/{total}] {path}")
    print(bar)
    print(
        tabulate(
            rows,
            headers=("provider", "target", "project", "compile.yml"),
            tablefmt="fancy_grid",
        )
    )
    print()


def main() -> int:
    args = parse_args()
    repo = (
        Path(args.repo_root).resolve()
        if args.repo_root
        else Path(__file__).resolve().parents[2]
    )

    compile_ymls = sorted(
        p
        for p in repo.rglob("compile.yml")
        if "/scratch/" not in str(p)
        and "/.git/" not in str(p)
        and not (args.single_project and project_of(p, repo) != "<root>")
    )

    owners: dict[str, list[Entry]] = defaultdict(list)
    parse_errors: list[tuple[Path, str]] = []

    for cy in compile_ymls:
        compile_root = cy.parent.parent  # config/compile.yml -> module dir
        try:
            docs = list(yaml.safe_load_all(cy.read_text()))
        except yaml.YAMLError as e:
            parse_errors.append((cy, str(e)))
            continue
        for doc in docs:
            if not isinstance(doc, dict):
                continue
            provides = doc.get("provides") or []
            provider = (
                provides[0]
                if isinstance(provides, list) and provides
                else "<unknown>"
            )
            for tname, raw in iter_files(doc):
                resolved = expand_vars(raw, compile_root, repo)
                owners[resolved].append((provider, cy, tname))

    hard: dict[str, list[Entry]] = {}
    informational: dict[str, list[Entry]] = {}
    for path, entries in owners.items():
        if len({e[0] for e in entries}) <= 1:
            continue
        projects = {project_of(cy, repo) for _, cy, _ in entries}
        bucket = hard if len(projects) == 1 else informational
        bucket[path] = entries

    if parse_errors:
        print("YAML parse errors:")
        for cy, err in parse_errors:
            print(f"  {cy}: {err}")
        print()

    if not hard and not informational:
        print(
            f"OK: scanned {len(compile_ymls)} compile.yml files, "
            f"{len(owners)} unique source paths, no single-owner violations."
        )
        return 0

    if hard:
        total = len(hard)
        print(f"HARD violations ({total}) — same-project duplicate ownership:\n")
        for i, (path, entries) in enumerate(sorted(hard.items()), start=1):
            render_violation(i, total, path, entries, repo)

    if informational:
        total = len(informational)
        label = "promoted to HARD by --strict" if args.strict else "informational"
        print(
            f"Cross-project duplicates ({total}) — {label}. "
            "These are intentional mirrors when a submodule needs to build "
            "standalone; only one wins at integration.\n"
        )
        for i, (path, entries) in enumerate(sorted(informational.items()), start=1):
            render_violation(i, total, path, entries, repo)

    failed = bool(hard) or (args.strict and bool(informational))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
