# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Generate SystemVerilog register blocks and UVM RAL models from a SystemRDL source file.

For each RDL file this script produces:
  - ``{addrmap_name}.sv``       — synthesisable register block (via peakrdl-regblock)
  - ``{addrmap_name}_pkg.sv``   — SV package with register types and an address-width localparam
  - ``{rdl_file_stem}_uvm.sv``  — UVM RAL model (via peakrdl-uvm)

RTL outputs ({addrmap_name}.sv, {addrmap_name}_pkg.sv) are written to ``--rtl-output``
(default: same directory as the RDL file).  The UVM RAL model ({rdl_file_stem}_uvm.sv)
is written to ``--dv-output`` (default: same directory as the RDL file).
``$CALIPTRA_ROOT`` must be set; it is used to locate ``src/keyvault/data/kv_def.rdl`` and the UVM Jinja2 templates.

Usage::

    python reg_gen.py <path/to/foo_reg.rdl> [--rtl-output DIR] [--dv-output DIR]
                      [--param NAME=VALUE ...] [--cov]

The ``--cov`` flag additionally emits ``{rdl_file_stem}_covergroups.svh`` and
``{rdl_file_stem}_sample.svh`` to ``--dv-output`` as hand-edit starting points for
functional coverage.
"""

from systemrdl import RDLCompiler, RDLCompileError, RDLWalker
from systemrdl import RDLListener, rdltypes
from systemrdl.node import FieldNode, AddrmapNode, RootNode
from peakrdl_regblock import RegblockExporter
from peakrdl_uvm import UVMExporter
from peakrdl_html import HTMLExporter
from peakrdl_regblock.udps import ALL_UDPS
from peakrdl_regblock.cpuif.passthrough import PassthroughCpuif
from math import log, ceil, floor
from pathlib import Path
from typing import Union
import sys
import os
import re
import rdl_post_process
import inject_hwif_assertion
import argparse


class SVPkgAppendingListener(RDLListener):
    """RDL walker listener that appends an address-width localparam to a
    generated register package.

    ``RegblockExporter`` emits ``{addrmap_name}_pkg.sv`` but does not
    include the total address-map size as a parameter.  This listener
    walks the elaborated model and rewrites that file in-place, inserting:

        localparam {ADDRMAP_NAME}_ADDR_WIDTH = 32'd<N>;

    where ``<N>`` is ``floor(log2(addrmap.total_size)) + 1``.

    The listener assumes ``RegblockExporter`` has already written
    ``{addrmap_name}_pkg.sv`` into *file_path* before the walk begins.
    """

    def __init__(self, file_path: Path) -> None:
        """
        Args:
            file_path: Directory containing the previously generated
                ``*_pkg.sv`` file, and into which the rewritten file
                will be saved.
        """
        self.file_path = file_path
        self.orig_file = ""

    def enter_Addrmap(self, node: AddrmapNode) -> None:
        """Read the existing pkg file, strip the closing ``endpackage``,
        and rewrite it with the address-width localparam appended.

        The file handle is left open for :meth:`exit_Addrmap` to close
        after writing the ``endpackage`` terminator.
        """
        # Only the top-level addrmap gets `{name}_pkg.sv` and `{name}.sv` emitted by
        # peakrdl-regblock; nested sub-addrmaps don't (peakrdl-regblock either inlines them or,
        # if marked `external`, skips them entirely with the RTL provided externally). Identify
        # the top by parent type — `node.external` is True for the top-level too, so we can't
        # use that.
        # Only touch ``self.file`` for the top-level addrmap.  Nested addrmaps (e.g. an
        # ``external`` sub-addrmap) re-enter this listener; without this guard they would
        # overwrite ``self.file`` to ``None`` and ``exit_Addrmap`` of the top-level would
        # then skip writing the closing ``endpackage`` terminator.
        if not isinstance(node.parent, RootNode):
            return
        self.regfile_name = self.file_path / node.inst_name
        pkg_file_path = self.file_path / f"{node.inst_name}_pkg.sv"
        self.file = open(pkg_file_path, 'r')
        for line in self.file.readlines():
            if (re.search(r'\bendpackage\b', line) is None):
                self.orig_file += line
        self.file.close()
        self.file = open(pkg_file_path, 'w')
        self.file.write(self.orig_file)
        self.file.write("\n    localparam " + node.inst_name.upper() + "_ADDR_WIDTH = " + "32'd" + str(int(floor(log(node.total_size, 2)) + 1)) + ";")

    def exit_Addrmap(self, node: AddrmapNode) -> None:
        """Write the closing ``endpackage`` keyword and close the file."""
        # Mirror the guard in ``enter_Addrmap``: only the top-level addrmap owns ``self.file``.
        if not isinstance(node.parent, RootNode):
            return
        self.file.write("\n\nendpackage")
        self.file.close()

    def get_regfile_name(self) -> Path:
        """Return the stem path of the generated register file.

        Returns:
            Path of the form ``{file_path}/{addrmap_inst_name}`` with no
            extension.  Append ``.sv`` or ``_pkg.sv`` to obtain the
            actual output file paths.
        """
        return self.regfile_name


def parse_params(param_args: list[str]) -> dict[str, Union[bool, int]]:
    """Parse ``NAME=VALUE`` strings into a typed dictionary.

    Supports three value types, tested in order:

    - **Boolean**: ``'true'`` or ``'false'`` (case-insensitive) → ``bool``
    - **Hexadecimal**: ``'0x'``-prefixed strings → ``int``
    - **Decimal integer**: digit strings, optionally negative → ``int``

    Values that do not match any of the above patterns are silently
    ignored and excluded from the returned dictionary.

    Args:
        param_args: List of ``'NAME=VALUE'`` strings, typically from
            argparse with ``action='append'``.

    Returns:
        Dictionary mapping parameter names to their typed values.
        Exits with code 1 if a string lacks ``'='`` or contains an
        invalid hex literal.
    """
    parameters: dict[str, Union[bool, int]] = {}
    for param in param_args:
        if '=' not in param:
            print(f"Error: Invalid parameter format '{param}'. Use NAME=VALUE")
            sys.exit(1)
        name, value = param.split('=', 1)

        if value.lower() in ['true', 'false']:
            parameters[name] = value.lower() == 'true'
        elif value.startswith('0x'):
            try:
                parameters[name] = int(value, 16)
            except ValueError:
                print(f"Error: Invalid hex value '{value}'")
                sys.exit(1)
        elif value.isdigit() or (value.startswith('-') and value[1:].isdigit()):
            parameters[name] = int(value)

    return parameters


def compile_and_elaborate(
    rdlc: RDLCompiler,
    repo_root: Path,
    rdl_file: Path,
    parameters: dict[str, Union[bool, int]],
) -> RootNode:
    """Compile SystemRDL sources and return the elaborated root node.

    Always compiles ``src/keyvault/data/kv_def.rdl`` from *repo_root*
    before the target file, so that any RDL using key-vault controls
    has the required type definitions in scope.  This dependency is
    unconditional: every register block is compiled against
    ``kv_def.rdl`` regardless of whether it references key-vault types.

    Args:
        rdlc: A configured ``RDLCompiler`` instance with all required
            UDPs already registered.
        repo_root: Absolute path to the Caliptra repository root
            (value of ``$CALIPTRA_ROOT``).
        rdl_file: Path to the target ``.rdl`` file to compile.
        parameters: Elaboration-time parameter overrides as produced
            by :func:`parse_params`.  Pass an empty dict for defaults.

    Returns:
        Elaborated root node of the register model.
        Exits with code 1 on any ``RDLCompileError``.
    """
    # Both compile_file and elaborate can raise RDLCompileError (syntax errors and semantic violations respectively).
    try:
        rdlc.compile_file(repo_root / "src/keyvault/data/kv_def.rdl")
        rdlc.compile_file(rdl_file)
        return rdlc.elaborate(parameters=parameters if parameters else None)
    except RDLCompileError:
        sys.exit(1)


def export(
    root: RootNode,
    repo_root: Path,
    rdl_file: Path,
    rtl_output_dir: Path,
    dv_output_dir: Path,
    build_cov: bool,
    dv_only: bool = False,
    rtl_only: bool = False,
) -> None:
    """Export all generated artefacts from an elaborated register model.

    **RTL (always)**
        ``RegblockExporter`` writes ``{addrmap_name}.sv`` and
        ``{addrmap_name}_pkg.sv`` to *rtl_output_dir*, where *addrmap_name*
        is the elaborated addrmap's ``inst_name`` — not necessarily the stem
        of *rdl_file*.  Both files are then modified in-place by
        :func:`rdl_post_process.scrub_line_by_line` to convert unpacked
        arrays and structs to packed equivalents required by Verilator,
        and the ``.sv`` file additionally has a ``CALIPTRA_ASSERT_KNOWN``
        X-check on ``hwif_in`` injected by
        :class:`inject_hwif_assertion.HwifAssertionListener` during the
        same RDL walker pass that drives :class:`SVPkgAppendingListener`.

    **UVM RAL model (always)**
        ``{rdl_file.stem}_uvm.sv`` is written to *dv_output_dir* using the
        Jinja2 templates at ``repo_root/tools/templates/rdl/uvm``.

    **Coverage scaffolding (only when build_cov is True)**
        ``{rdl_file.stem}_covergroups.svh`` and
        ``{rdl_file.stem}_sample.svh`` are generated to *dv_output_dir* from
        templates at ``repo_root/tools/templates/rdl/cov`` and
        ``repo_root/tools/templates/rdl/smp`` respectively.  These files are
        *starting points* that must be hand-edited after generation; they are
        not produced in the normal CI flow.

    Args:
        root: Elaborated root node as returned by
            :func:`compile_and_elaborate`.
        repo_root: Absolute path to the Caliptra repository root,
            used to locate the UVM and coverage Jinja2 templates.
        rdl_file: Path to the source ``.rdl`` file; its stem names the
            UVM and coverage output files.
        rtl_output_dir: Directory for synthesisable RTL outputs
            ({addrmap_name}.sv and {addrmap_name}_pkg.sv).
        dv_output_dir: Directory for DV outputs ({stem}_uvm.sv and,
            when --cov is given, the coverage scaffolding files).
        build_cov: When ``True``, also emit the coverage scaffolding
            files.
    """
    # Emit synthesisable register block RTL (unless this is a DV-only composite
    # whose sub-addrmaps are already implemented as standalone regblocks).
    if not dv_only:
        exporter = RegblockExporter()
        exporter.export(
            root, rtl_output_dir,
            cpuif_cls=PassthroughCpuif,
            retime_read_response=False
        )

    # Emit UVM RAL model (unless this is an RTL-only run for a regblock whose RAL is
    # produced from a separate composite RDL).
    if not rtl_only:
        uvm_out = dv_output_dir / f"{rdl_file.stem}_uvm.sv"
        exporter = UVMExporter(user_template_dir=repo_root / "tools/templates/rdl/uvm")
        exporter.export(root, str(uvm_out), use_uvm_factory=True)
        rdl_post_process.strip_trailing_whitespace(uvm_out)

        if build_cov:
            exporter = UVMExporter(user_template_dir=repo_root / "tools/templates/rdl/cov")
            exporter.export(root, str(dv_output_dir / f"{rdl_file.stem}_covergroups.svh"))
            exporter = UVMExporter(user_template_dir=repo_root / "tools/templates/rdl/smp")
            exporter.export(root, str(dv_output_dir / f"{rdl_file.stem}_sample.svh"))

    if dv_only:
        return

    # Traverse the register model with two listeners:
    #   * SVPkgAppendingListener — append the address-width localparam to the pkg
    #   * HwifAssertionListener  — inject CALIPTRA_ASSERT_KNOWN(hwif_in) into the module
    walker = RDLWalker(unroll=True)
    pkglistener = SVPkgAppendingListener(rtl_output_dir)
    hwif_listener = inject_hwif_assertion.HwifAssertionListener(rtl_output_dir)
    walker.walk(root, pkglistener, hwif_listener)

    # Post-process RTL:
    #   1. rdl_post_process — fixes for peakrdl-regblock quirks (unpacked
    #      structs/arrays etc.) needed for Verilator/xmvlog/lint compatibility.
    #   2. strip_trailing_whitespace — defence-in-depth cleanup of
    #      trailing whitespace emitted by upstream Jinja rendering.
    # TODO: replace (1) with a custom exporter template to avoid the scrub step.
    regfile_name = pkglistener.get_regfile_name()
    rtl_sv = regfile_name.with_suffix('.sv')
    rtl_pkg = regfile_name.with_name(regfile_name.name + '_pkg.sv')
    rdl_post_process.scrub_line_by_line(rtl_sv)
    rdl_post_process.scrub_line_by_line(rtl_pkg)
    rdl_post_process.strip_trailing_whitespace(rtl_sv)
    rdl_post_process.strip_trailing_whitespace(rtl_pkg)


def main() -> None:
    """Parse arguments, compile/elaborate the RDL sources, and export all artefacts."""
    parser = argparse.ArgumentParser(description='Generate SystemVerilog registers from RDL files')
    parser.add_argument('rdl_file', help='RDL input file')
    parser.add_argument('--cov', action='store_true', help='Generate coverage files')
    parser.add_argument('--param', '-p', action='append', default=[],
                        help='Set RDL parameter (format: NAME=VALUE). Can be used multiple times.')
    parser.add_argument('--rtl-output', default=None,
                        help='Output directory for synthesisable RTL files '
                             '({addrmap}.sv, {addrmap}_pkg.sv). '
                             'Defaults to the directory containing the RDL file.')
    parser.add_argument('--dv-output', default=None,
                        help='Output directory for DV files ({stem}_uvm.sv and coverage '
                             'scaffolding). Defaults to the directory containing the RDL file.')
    parser.add_argument('--dv-only', action='store_true',
                        help='Emit only the UVM RAL model (skip the synthesisable regblock RTL). '
                             'Use for composite addrmaps whose sub-blocks are already implemented '
                             'as standalone regblocks elsewhere.')
    parser.add_argument('--rtl-only', action='store_true',
                        help='Emit only the synthesisable regblock RTL (skip the UVM RAL and '
                             'coverage scaffolding). Use when the RAL is produced from a '
                             'separate composite RDL.')
    args = parser.parse_args()
    if args.dv_only and args.rtl_only:
        print("Error: --dv-only and --rtl-only are mutually exclusive.")
        sys.exit(1)

    rdl_file = Path(args.rdl_file)
    default_output_dir = rdl_file.resolve().parent
    rtl_output_dir = Path(args.rtl_output) if args.rtl_output else default_output_dir
    dv_output_dir = Path(args.dv_output) if args.dv_output else default_output_dir

    rtl_output_dir.mkdir(parents=True, exist_ok=True)
    dv_output_dir.mkdir(parents=True, exist_ok=True)

    _repo_root_str = os.environ.get('CALIPTRA_ROOT')
    if not _repo_root_str:
        print("CALIPTRA_ROOT environment variable is not defined.")
        sys.exit(1)
    repo_root = Path(_repo_root_str)

    parameters = parse_params(args.param)

    rdlc = RDLCompiler()
    for udp in ALL_UDPS:
        rdlc.register_udp(udp)

    root = compile_and_elaborate(rdlc, repo_root, rdl_file, parameters)
    export(root, repo_root, rdl_file, rtl_output_dir, dv_output_dir, args.cov,
           dv_only=args.dv_only, rtl_only=args.rtl_only)


if __name__ == '__main__':
    main()
