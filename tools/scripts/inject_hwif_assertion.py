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

"""Inject a ``CALIPTRA_ASSERT_KNOWN`` X-check on ``hwif_in`` into a module.

This is a Caliptra-specific *addition* to generated register-block
RTL, not a workaround for any specific generator's bugs.  It is
deliberately kept separate from :mod:`rdl_post_process`, which only
hosts fixes for upstream peakrdl-regblock quirks.

Implemented as an ``RDLListener`` so the disable-condition signal is
recovered from the elaborated RDL model rather than text-scanning the
generated SystemVerilog for ``negedge`` clauses.  Every reset in the
RDL is declared as ``signal {activelow; async;} <name>;`` and fields
reference it via ``resetsignal = <name>;``; we walk those declarations
to pick the preferred disable condition (see
:meth:`HwifAssertionListener._pick_reset`).

Consumed by ``tools/scripts/reg_gen.py``; runs against the same
``RDLWalker`` pass that drives :class:`SVPkgAppendingListener`.
"""

import re
from pathlib import Path
from typing import Optional

from systemrdl import RDLListener
from systemrdl.node import AddrmapNode, FieldNode, SignalNode

# Signal-name fragments that identify a "hard" reset.  hard_reset_b,
# error_reset_b and cptra_pwrgood are used interchangeably across the
# generated blocks; any of them is preferred over a soft reset for
# the X-check assertion's disable condition.
_HARD_RESET_RE = re.compile(r'hard_reset|pwrgood|error_reset')

# Matches a top-level `endmodule` keyword.
_ENDMODULE_RE = re.compile(r'\bendmodule\b')


class HwifAssertionListener(RDLListener):
    """RDL walker listener that injects a ``CALIPTRA_ASSERT_KNOWN`` on
    the module's ``hwif_in`` struct.

    ``RegblockExporter`` emits ``{addrmap_name}.sv`` but does not
    include an X-check assertion on the input ``hwif_in`` struct.
    This listener walks the elaborated model and rewrites that file
    in-place to insert, just before ``endmodule``::

        `include "caliptra_prim_assert.sv"
        `CALIPTRA_ASSERT_KNOWN(ERR_HWIF_IN, hwif_in, clk, !<reset>)

    where ``<reset>`` is the addrmap's preferred reset signal name
    (active-low; hence the ``!``).  The ``caliptra_prim_assert.sv``
    include is required for the macro to resolve during synthesis
    (#1181).

    The listener assumes ``RegblockExporter`` has already written
    ``{addrmap_name}.sv`` into *file_path* before the walk begins.
    """

    def __init__(self, file_path: Path) -> None:
        """
        Args:
            file_path: Directory containing the previously generated
                ``*.sv`` file, into which the rewritten file will be
                saved.
        """
        self.file_path = file_path

    @staticmethod
    def _pick_reset(node: AddrmapNode) -> str:
        """Return the reset signal name to use as the disable condition.

        Prefers a "hard" reset (see :data:`_HARD_RESET_RE`) - hmac,
        for example, declares both ``reset_b`` and ``error_reset_b``;
        peakrdl-regblock emits ``always_ff`` blocks for both, and we
        want the X-check disabled during the harder of the two.

        Strategy: collect the set of distinct signals referenced by
        every field's ``resetsignal`` property (via
        :class:`RDLWalker`-style traversal of the addrmap's
        descendants), then pick the first hard reset by name pattern;
        fall back to any reset referenced if none are "hard".

        Falling back further to ``node.signals()`` would let an
        otherwise-unused signal declaration leak in - we deliberately
        only consider signals actually wired to a field.
        """
        referenced: list[str] = []
        for child in node.descendants():
            if isinstance(child, FieldNode):
                rs = child.get_property('resetsignal')
                if isinstance(rs, SignalNode) and rs.inst_name not in referenced:
                    referenced.append(rs.inst_name)
        if not referenced:
            raise RuntimeError(
                f"addrmap {node.inst_name!r} has no fields with a resetsignal; "
                "cannot derive disable condition for CALIPTRA_ASSERT_KNOWN"
            )
        for name in referenced:
            if _HARD_RESET_RE.search(name):
                return name
        return referenced[0]

    def enter_Addrmap(self, node: AddrmapNode) -> None:
        """Rewrite ``{addrmap_name}.sv`` with the assertion block prepended
        to its ``endmodule`` line.
        """
        # Only the top-level addrmap is emitted as `{name}.sv` by peakrdl-regblock; nested
        # sub-addrmaps either inline (no separate file) or are marked external (RTL provided
        # elsewhere). Skip non-top nodes.
        from systemrdl.node import RootNode
        if not isinstance(node.parent, RootNode):
            return
        sv_path = self.file_path / f"{node.inst_name}.sv"
        reset_name = self._pick_reset(node)
        # Resets enter the module through the `hwif_in` input struct, so
        # the assertion must reference them via that hierarchical path -
        # the bare SignalNode.inst_name is not a visible identifier
        # inside the module.
        block = (
            '\n'
            '`include "caliptra_prim_assert.sv"\n'
            f'`CALIPTRA_ASSERT_KNOWN(ERR_HWIF_IN, hwif_in, clk, !hwif_in.{reset_name})\n'
            '\n'
        )
        with open(sv_path, 'r') as f:
            lines = f.readlines()
        out = []
        injected = False
        for line in lines:
            if not injected and _ENDMODULE_RE.search(line) is not None:
                out.append(block)
                injected = True
            out.append(line)
        if not injected:
            raise RuntimeError(f"no `endmodule` found in {sv_path}")
        with open(sv_path, 'w') as f:
            f.writelines(out)
