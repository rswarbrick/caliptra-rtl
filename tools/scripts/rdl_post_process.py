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

"""Post-processing scrubs for ``peakrdl-regblock`` SystemVerilog output.

Every transform in this module is a workaround for a specific
peakrdl-regblock quirk: the generated RTL is *almost* what Caliptra
needs, but a handful of structural choices have to be patched up
before downstream tools (Verilator, Cadence xmvlog, lint, synthesis)
accept them.

Generic improvements that are *not* upstream workarounds (e.g. the
``CALIPTRA_ASSERT_KNOWN`` injection on ``hwif_in``) live in their own
modules - see :mod:`inject_hwif_assertion`.

Two entry points are exposed and consumed by ``tools/scripts/reg_gen.py``
(and the adams-bridge submodule's equivalent):

* :func:`scrub_line_by_line` - applied to ``{module}.sv`` and
  ``{module}_pkg.sv``.  Runs each callable in :data:`FIXES` against
  every declaration line.
* :func:`strip_trailing_whitespace` - applied to all three generated
  file types (``.sv``, ``_pkg.sv``, ``_uvm.sv``) as defence in depth
  against template/whitespace regressions.

Each upstream-quirk fix is implemented as a standalone callable in
:data:`FIXES` with a docstring stating *what* the generator emits,
*why* it must be rewritten, and *the condition under which the fix
can be deleted* (typically: a future peakrdl-regblock release).  If
upstream lands the fix, drop the corresponding entry from
:data:`FIXES` (and delete its function).

Currently targets peakrdl-regblock 1.3.1.
"""

import os
import re
import sys
from typing import Callable, List, Union

PathLike = Union[str, os.PathLike]


# ---------------------------------------------------------------------------
# Whitespace scrub (not tied to a specific peakrdl-regblock bug)
# ---------------------------------------------------------------------------

def strip_trailing_whitespace(fname: PathLike) -> None:
    """Strip trailing whitespace from every line of *fname*, in place.

    Safe to keep indefinitely; not a workaround for any upstream bug.
    """
    with open(fname, 'r') as f:
        lines = f.readlines()
    stripped = [line.rstrip() + '\n' for line in lines]
    with open(fname, 'w') as f:
        f.writelines(stripped)


# ---------------------------------------------------------------------------
# Per-line upstream-quirk fixes
#
# Each function takes a single source line and returns the (possibly
# rewritten) line.  Functions are pure transforms and do not need
# cross-line state; cross-line state (e.g. reset-signal capture, end-
# of-module assertion insertion) is handled separately below.
#
# Each fix is independently removable: when the corresponding
# upstream behaviour is fixed, delete the function and remove its
# entry from FIXES.
# ---------------------------------------------------------------------------

# Matches `struct` optionally followed by `unpacked`.
_STRUCT_RE = re.compile(r'\bstruct\b\s*(?:unpacked)?')

# Matches a constant unpacked dimension, e.g. `[2]`.
_UNPACKED_DIM_RE = re.compile(r'\[\d+\]')

# Peels:
#   (whitespace)(existing packed dims)(identifier)(already-rewritten unpacked dims)[N]
# and folds the trailing [N] into a packed [N-1:0] on the left of the identifier.
_UNPACKED_TO_PACKED_RE = re.compile(
    r'(\s*)(\[[\w-]+:0\])*(\s*\w+)\s*(\[\d+\])*\[(\d+)\]'
)


def fix_unpacked_struct(line: str) -> str:
    """Force ``struct`` declarations to be packed.

    peakrdl-regblock emits bare ``struct { ... }`` declarations.  In
    SystemVerilog a bare ``struct`` is **unpacked by default**, which
    means it cannot be bit-sliced, used as a port, or assigned with
    bitwise operators - none of which Caliptra's downstream flows
    tolerate.  Rewrite both ``struct`` and the (rarer) explicit
    ``struct unpacked`` to ``struct packed``.

    Remove when: peakrdl-regblock emits ``struct packed`` directly
    (or exposes a knob to do so).  As of 1.3.1 this still fires
    thousands of times per regeneration, so the fix is load-bearing.
    """
    if _STRUCT_RE.search(line) is None:
        return line
    return _STRUCT_RE.sub(r'struct packed', line)


def fix_unpacked_array_dim(line: str) -> str:
    """Convert unpacked array dimensions on declarations to packed.

    peakrdl-regblock writes signal/struct declarations as e.g.::

        logic NAME[2];

    which is an *unpacked* array.  Caliptra's tools require these to
    be packed::

        logic [2-1:0]NAME;

    The regex peels any existing packed dimensions, the identifier,
    and any already-rewritten unpacked dimensions, then folds the
    trailing ``[N]`` into a packed ``[N-1:0]`` on the left of the
    identifier.  A loop handles multi-dimensional cases.

    **Declarations only.**  Procedural single-bit selects such as::

        readback_data_var[0] = field_storage.CTRL0.ENDIAN_SWAP.value;

    must *not* be rewritten - doing so produces malformed
    declarations with initialisers and trips xmvlog's ``VARIST``
    warning.

    Known limitation: arrays whose identifier and dimensions are on
    separate lines are not detected.

    Remove when: peakrdl-regblock emits packed dimensions directly
    (or exposes a knob to do so).
    """
    if _UNPACKED_DIM_RE.search(line) is None:
        return line
    while _UNPACKED_DIM_RE.search(line) is not None:
        line = _UNPACKED_TO_PACKED_RE.sub(r'\1[\5-1:0]\2\3\4', line)
    return line


# The ordered list of per-line fixes applied to declaration lines.
# Drop entries from here as upstream issues are fixed.
FIXES: List[Callable[[str], str]] = [
    fix_unpacked_struct,
    fix_unpacked_array_dim,
]


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

def scrub_line_by_line(fname: PathLike) -> None:
    """Apply every per-line peakrdl-regblock workaround to *fname* in place.

    Runs each callable in :data:`FIXES` against every *declaration*
    line (lines without an ``=`` operator); procedural assignments are
    passed through untouched - see :func:`fix_unpacked_array_dim`.
    """
    with open(fname, 'r') as f:
        lines = f.readlines()

    out: List[str] = []
    for line in lines:
        if '=' not in line:
            for fix in FIXES:
                line = fix(line)
        out.append(line)

    with open(fname, 'w') as f:
        f.writelines(out)


if __name__ == "__main__":
    if len(sys.argv) == 1:
        print(f"{os.path.basename(sys.argv[0])} requires an argument to specify target file!")
        sys.exit(1)
    fname = sys.argv[1]
    print(f"file name to modify is {fname}")
    scrub_line_by_line(fname)
