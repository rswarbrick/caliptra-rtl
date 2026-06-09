#!/usr/bin/env python3
"""Check that each ``*.vf`` filelist matches the transitive closure of the
matching provider in the ``compile.yml`` graph.

Why this script exists
----------------------
The simulation build has two parallel descriptions of the source tree:

  * Hand-curated ``+f``-style filelists at ``src/<block>/config/<name>.vf``.
    These are the canonical compilation target for VCS / Verilator / UVMF
    benches today; the Makefiles and READMEs all point at them. The .vf
    files are flat — one list of ``+incdir+...`` lines followed by source
    paths, all anchored at ``$CALIPTRA_ROOT``.
  * A DAG of ``compile.yml`` providers (one per logical module under
    ``src/<block>/config/compile.yml``). Each provider declares a unique
    ``provides:`` slug, a ``requires:`` edge list, and one or more
    ``targets:`` (typically ``rtl`` and ``tb``) listing ``files:`` and
    ``directories:`` anchored at ``$COMPILE_ROOT`` (= the module dir).

Both descriptions are maintained by hand — see CONTRIBUTING.md, which lists
``*.vf file lists`` and ``compile.yml`` as separate things contributors edit.
That means they can (and do) drift. This script flags the drift.

Naming convention that makes the check possible
-----------------------------------------------
Every ``.vf`` file we want to verify has a same-named ``provides:`` entry
somewhere in the ``compile.yml`` tree. The basename of the .vf without the
extension is the provider slug:

    src/soc_ifc/config/soc_ifc_tb.vf           <->  provides: [soc_ifc_tb]
    src/soc_ifc/config/soc_ifc_top.vf          <->  provides: [soc_ifc_top]
    src/soc_ifc/config/soc_ifc_pkg.vf          <->  provides: [soc_ifc_pkg]
    src/integration/config/caliptra_top_tb.vf  <->  provides: [caliptra_top_tb]

Not every provider has a .vf — many are internal fragments (e.g.
``soc_ifc_coverage``) meant to be pulled in transitively via ``requires:``.
That asymmetry is fine: a .vf without a provider is a real gap, a provider
without a .vf is just an intermediate node in the graph.

Checking algorithm
------------------
For each ``*.vf`` file:

  1. Look up the provider whose ``provides:`` slug matches the .vf basename.
     (Built once into a global index.) If none, skip with a warning.
  2. Walk ``requires:`` transitively across all ``compile.yml`` files to
     collect the reachable provider set.
  3. Decide which ``targets:`` to union. The .vf basename tells us:
       * ``*_tb``, ``*_tb_*``, ``*_uvm_pkg``, ``*_coverage``  -> rtl + tb
       * everything else                                       -> rtl only
     This mirrors what happens when the build flattens reachable providers
     into a single tool invocation — a tb root pulls both the testbench
     sources and the RTL it exercises, while an rtl root pulls only rtl.
  4. From each reachable provider, collect ``files:`` and ``directories:``
     under the chosen targets. Normalize ``$COMPILE_ROOT`` -> the
     provider's module dir and ``$CALIPTRA_ROOT`` / ``$MSFT_REPO_ROOT`` ->
     the repo root, producing absolute paths.
  5. Parse the .vf into two sets: incdir paths (from ``+incdir+...``) and
     file paths. Resolve ``${CALIPTRA_ROOT}`` likewise.
  6. Set-compare files and incdirs. Report files-only-in-vf,
     files-only-in-compile-yml, and the same for incdirs.

Caveats
-------
  * Set equality, not order equality. SystemVerilog package-before-use
    means compile order matters; this check will pass two filelists with
    the same contents in different orders even though one may fail to
    compile. Catching order bugs is a separate (and harder) lint.
  * Cross-target leakage. Some .vf files (notably hand-tuned ones in
    submodules / UVMF template output) intentionally include or exclude
    things that don't fit the simple "tb pulls rtl+tb, rtl pulls rtl"
    rule. Expect a few of these to need explicit per-file overrides or to
    be added to the skip list below.
  * Non-modeled artifacts. .vf files sometimes reference files
    ``compile.yml`` doesn't yet describe (waiver lists, ``+define+``-only
    lines, ``.vlt`` Verilator config). These show up as "only in .vf".
    Treat the first run's output as a punch list to either add to
    ``compile.yml`` or whitelist here.
  * Environment-variable paths into external trees (``$AVERY_HOME``,
    ``$UVM_HOME``, ``$QUESTA_HOME``, ...) are left unresolved and compared
    textually — they at least catch typos and stale references.
  * Submodules. Each submodule has its own ``compile.yml`` tree;
    cross-project ``requires:`` edges have to resolve against the unified
    index. ``check_compile_yml_ownership.py`` already walks the same set
    of files; this script reuses the same discovery rules.

Longer term
-----------
The right answer is not to check equivalence but to eliminate one source
of truth. The ``compile.yml`` graph is strictly richer (it carries
``requires:`` edges, per-target options, and provider names), so the
``.vf`` files should ideally be *generated* from it at build time — e.g.
``tools/scripts/gen_vf.py --provider soc_ifc_tb > src/soc_ifc/config/soc_ifc_tb.vf``
run from a pre-commit hook or CI. At that point this checker collapses
into a regeneration diff (``git diff --exit-code`` after running the
generator). Until that lands, this script keeps the two views honest.

Usage
-----
    check_vf_compile_yml_equivalence.py [REPO_ROOT] [--vf PATH] [-v]

    --vf PATH     check a single .vf file (otherwise: every .vf in the tree)
    -v            print matching entries as well as mismatches

Exit code is non-zero iff any checked .vf has a mismatch against its
provider's transitive closure.
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

import yaml


# .vf basenames whose contents we don't expect to match compile.yml — either
# because compile.yml doesn't model them yet, or because they're hand-tuned
# variants (UVMF template output, vendor IP filelists) where the equivalence
# rule doesn't apply. Populate from the first-run output.
SKIP_VFS: set[str] = set()

# Suffixes that mean "this .vf is a tb-style root" -> union rtl + tb targets
# from each reachable provider. Everything else -> rtl only.
TB_SUFFIX_RE = re.compile(r"(_tb|_tb_[a-z0-9_]+|_uvm_pkg|_coverage)$")


def submodule_root_map(repo: Path) -> dict[str, str]:
    """Map env vars used in .vf / compile.yml files to repo-relative roots.

    These vars anchor paths into vendored or submodule trees. Without this
    map the same file shows up as ``$ADAMSBRIDGE_ROOT/.../foo.sv`` on the
    .vf side and ``<repo>/submodules/adams-bridge/.../foo.sv`` on the
    compile.yml side (where ``$COMPILE_ROOT`` already resolved). Pin both
    onto absolute paths so set comparison works.

    ``$CALIPTRA_PRIM_ROOT`` defaults to ``src/caliptra_prim_generic`` per
    ``tools/scripts/Makefile``; a different impl can be selected at build
    time but for the static-equivalence check we use the default.
    """
    return {
        "ADAMSBRIDGE_ROOT": str(repo / "submodules" / "adams-bridge"),
        "CALIPTRA_PRIM_ROOT": str(repo / "src" / "caliptra_prim_generic"),
        # Token, not a path: the impl prefix that selects which prim
        # variant to compile (generic vs. an ASIC-vendor lib). Default
        # per tools/scripts/Makefile.
        "CALIPTRA_PRIM_MODULE_PREFIX": "caliptra_prim_generic",
    }


@dataclass
class Provider:
    name: str
    compile_yml: Path
    compile_root: Path  # = compile_yml.parent.parent (the module dir)
    requires: list[str] = field(default_factory=list)
    targets: dict[str, dict] = field(default_factory=dict)  # tname -> tdef


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("repo_root", nargs="?", default=None,
                    help="repo root (default: two dirs above this script)")
    ap.add_argument("--vf", default=None,
                    help="check a single .vf file (path, absolute or relative)")
    ap.add_argument("-v", "--verbose", action="store_true",
                    help="print matches as well as mismatches")
    return ap.parse_args()


def find_repo_root(arg: str | None) -> Path:
    if arg:
        return Path(arg).resolve()
    return Path(__file__).resolve().parents[2]


def discover_compile_ymls(repo: Path) -> list[Path]:
    """Same discovery rule as check_compile_yml_ownership.py: every
    ``*/config/compile.yml`` under the tree, excluding .git."""
    out: list[Path] = []
    for p in repo.rglob("config/compile.yml"):
        if ".git" in p.parts:
            continue
        out.append(p)
    return sorted(out)


def discover_vfs(repo: Path) -> list[Path]:
    out: list[Path] = []
    for p in repo.rglob("config/*.vf"):
        if ".git" in p.parts:
            continue
        out.append(p)
    return sorted(out)


def build_provider_index(compile_ymls: list[Path]) -> dict[str, Provider]:
    """Return slug -> Provider. Last-write wins on duplicate ``provides:``
    (which is a single-ownership violation flagged separately by
    check_compile_yml_ownership.py — not this script's job)."""
    idx: dict[str, Provider] = {}
    for cy in compile_ymls:
        compile_root = cy.parent.parent
        try:
            with open(cy) as f:
                docs = list(yaml.safe_load_all(f))
        except yaml.YAMLError as e:
            print(f"warning: failed to parse {cy}: {e}", file=sys.stderr)
            continue
        for doc in docs:
            if not isinstance(doc, dict):
                continue
            provides = doc.get("provides") or []
            requires = doc.get("requires") or []
            targets = doc.get("targets") or {}
            if not isinstance(provides, list) or not isinstance(targets, dict):
                continue
            for slug in provides:
                if not isinstance(slug, str):
                    continue
                idx[slug] = Provider(
                    name=slug,
                    compile_yml=cy,
                    compile_root=compile_root,
                    requires=[r for r in requires if isinstance(r, str)],
                    targets=targets,
                )
    return idx


def expand(path: str, compile_root: Path, repo: Path,
           extra: dict[str, str] | None = None) -> str:
    """Resolve $COMPILE_ROOT / $CALIPTRA_ROOT / $MSFT_REPO_ROOT and any
    ``extra`` env vars (submodule roots) to absolute paths. Handles both
    ``$FOO`` and ``${FOO}`` forms. Leaves unknown env vars untouched so
    they at least compare textually."""
    subs = {
        "COMPILE_ROOT": str(compile_root),
        "CALIPTRA_ROOT": str(repo),
        "MSFT_REPO_ROOT": str(repo),
    }
    if extra:
        subs.update(extra)
    s = path
    for var, val in subs.items():
        s = s.replace(f"${{{var}}}", val).replace(f"${var}", val)
    return os.path.normpath(s)


def transitive_providers(root: str, idx: dict[str, Provider]) -> list[Provider]:
    """DFS over requires: edges. Returns reachable providers including root.
    Missing edges are silently skipped (they'd typically point at external
    cores like uvm_lib that aren't in this index)."""
    seen: set[str] = set()
    order: list[Provider] = []

    def visit(slug: str) -> None:
        if slug in seen or slug not in idx:
            return
        seen.add(slug)
        p = idx[slug]
        order.append(p)
        for r in p.requires:
            visit(r)

    visit(root)
    return order


def collect_from_providers(
    providers: list[Provider], target_names: set[str], repo: Path,
    extra: dict[str, str],
) -> tuple[set[str], set[str]]:
    """Return (files, incdirs) as absolute-path sets, unioned across the
    given providers' matching targets."""
    files: set[str] = set()
    incdirs: set[str] = set()
    for p in providers:
        for tname, tdef in p.targets.items():
            if tname not in target_names:
                continue
            if not isinstance(tdef, dict):
                continue
            for f in tdef.get("files") or []:
                if isinstance(f, str):
                    files.add(expand(f, p.compile_root, repo, extra))
            for d in tdef.get("directories") or []:
                if isinstance(d, str):
                    incdirs.add(expand(d, p.compile_root, repo, extra))
    return files, incdirs


def parse_vf(vf: Path, repo: Path, extra: dict[str, str]) -> tuple[set[str], set[str]]:
    """Return (files, incdirs) from a .vf, with $CALIPTRA_ROOT resolved.

    Ignores blank lines, ``//`` and ``#`` comments, and ``+define+`` /
    ``-`` switches. ``+incdir+PATH`` -> incdirs, everything else that
    looks like a path -> files."""
    files: set[str] = set()
    incdirs: set[str] = set()
    # .vf has no $COMPILE_ROOT; pass repo as compile_root (won't be used).
    for raw in vf.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("//") or line.startswith("#"):
            continue
        if line.startswith("+incdir+"):
            for token in line[len("+incdir+"):].split("+"):
                if token:
                    incdirs.add(expand(token, repo, repo, extra))
            continue
        if line.startswith("+") or line.startswith("-"):
            # +define+..., -f ..., other tool switches: ignored.
            continue
        files.add(expand(line, repo, repo, extra))
    return files, incdirs


def target_set_for(vf_name: str) -> set[str]:
    if TB_SUFFIX_RE.search(vf_name):
        return {"rtl", "tb"}
    return {"rtl"}


def rel(p: str | Path, repo: Path) -> str:
    """Relativize to repo root for readable CI output. Leave alone if the
    path is outside the repo (e.g. unresolved ``$UVMF_HOME/...``)."""
    s = str(p)
    root = str(repo) + os.sep
    if s.startswith(root):
        return s[len(root):]
    return s


# Use GitHub Actions inline annotations if running under GHA, so each
# failure shows up on the PR review with a link to the offending file.
# Detected via the standard env var set on every runner.
GHA = os.environ.get("GITHUB_ACTIONS") == "true"


def gha_error(vf_path: Path, repo: Path, message: str) -> None:
    if not GHA:
        return
    # See: https://docs.github.com/actions/reference/workflow-commands-for-github-actions
    print(f"::error file={rel(vf_path, repo)}::{message}")


HEADER = "=" * 72
SUBHEADER = "-" * 72


def diff_report(
    label: str, vf_set: set[str], yml_set: set[str], repo: Path
) -> tuple[int, list[str]]:
    only_vf = sorted(vf_set - yml_set)
    only_yml = sorted(yml_set - vf_set)
    if not only_vf and not only_yml:
        return 0, []
    lines: list[str] = []
    if only_vf:
        lines.append(f"  {label} only in .vf (missing from compile.yml closure):")
        for f in only_vf:
            lines.append(f"    - {rel(f, repo)}")
    if only_yml:
        lines.append(f"  {label} only in compile.yml (missing from .vf):")
        for f in only_yml:
            lines.append(f"    - {rel(f, repo)}")
    return len(only_vf) + len(only_yml), lines


def check_vf(vf: Path, idx: dict[str, Provider], repo: Path,
             extra: dict[str, str], verbose: bool) -> bool:
    """Return True on pass, False on fail. Prints a CI-friendly block on fail."""
    slug = vf.stem
    vf_rel = rel(vf, repo)
    if slug in SKIP_VFS:
        if verbose:
            print(f"SKIP {vf_rel}  (in SKIP_VFS)")
        return True
    if slug not in idx:
        # A .vf without a same-named provider is a parity violation: the
        # build has two stories for what this thing is. Treat as failure;
        # add to SKIP_VFS with justification if intentional.
        print(HEADER)
        print(f"FAIL: {vf_rel}")
        print(f"  no compile.yml provider named '{slug}'")
        print(f"  fix: add a provider with `provides: [{slug}]` to a compile.yml,")
        print(f"       or add '{slug}' to SKIP_VFS in this script with a reason.")
        gha_error(vf, repo,
                  f"No compile.yml provider named '{slug}' for this .vf filelist")
        return False

    providers = transitive_providers(slug, idx)
    targets = target_set_for(slug)
    yml_files, yml_incdirs = collect_from_providers(providers, targets, repo, extra)
    vf_files, vf_incdirs = parse_vf(vf, repo, extra)

    n_files,   file_lines   = diff_report("files",   vf_files,   yml_files,   repo)
    n_incdirs, incdir_lines = diff_report("incdirs", vf_incdirs, yml_incdirs, repo)
    total = n_files + n_incdirs

    if total == 0:
        if verbose:
            print(f"PASS {vf_rel}  ({len(vf_files)} files, "
                  f"{len(vf_incdirs)} incdirs)")
        return True

    root_provider = idx[slug]
    cy_rel = rel(root_provider.compile_yml, repo)
    print(HEADER)
    print(f"FAIL: {vf_rel}")
    print(f"  provider:    {slug}  ({len(providers)} provider(s) in "
          f"transitive closure)")
    print(f"  compile.yml: {cy_rel}")
    print(f"  targets:     {', '.join(sorted(targets))}")
    print(SUBHEADER)
    for line in file_lines:
        print(line)
    if file_lines and incdir_lines:
        print()
    for line in incdir_lines:
        print(line)
    gha_error(vf, repo,
              f"{vf_rel} diverges from compile.yml provider '{slug}' "
              f"({total} mismatched entr{'y' if total == 1 else 'ies'}). "
              f"Edit {vf_rel} or {cy_rel} to restore parity; see job log.")
    return False


def main() -> int:
    args = parse_args()
    repo = find_repo_root(args.repo_root)
    compile_ymls = discover_compile_ymls(repo)
    idx = build_provider_index(compile_ymls)
    extra = submodule_root_map(repo)

    if args.vf:
        vfs = [Path(args.vf).resolve()]
    else:
        vfs = discover_vfs(repo)

    failures = 0
    for vf in vfs:
        if not check_vf(vf, idx, repo, extra, args.verbose):
            failures += 1

    passes = len(vfs) - failures
    print()
    print(HEADER)
    if failures:
        print(f"FAIL: {failures} of {len(vfs)} .vf file(s) diverge from their "
              f"compile.yml providers ({passes} pass).")
        print()
        print("Each FAIL block above lists the .vf and the compile.yml that "
              "describe the same")
        print("logical unit. To fix: edit one of them so the file/incdir sets "
              "match. The two")
        print("must stay in sync until .vf files are generated from "
              "compile.yml — see this")
        print("script's module docstring for the longer-term plan.")
        print(HEADER)
        return 1
    print(f"PASS: all {len(vfs)} .vf file(s) match their compile.yml providers "
          f"({len(idx)} provider(s) across {len(compile_ymls)} compile.yml "
          f"file(s)).")
    print(HEADER)
    return 0


if __name__ == "__main__":
    sys.exit(main())
