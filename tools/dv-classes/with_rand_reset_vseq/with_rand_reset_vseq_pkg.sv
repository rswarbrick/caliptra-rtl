// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

package with_rand_reset_vseq_pkg;
  import uvm_pkg::*;

  import reset_agent_pkg::reset_sequencer_t;
  import reset_agent_pkg::random_reset_seq;

  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  `include "with_rand_reset_vseq.svh"
endpackage
