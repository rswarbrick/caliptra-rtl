// Copyright lowRISC contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

package reset_agent_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "reset_edge_item.svh"
  `include "reset_monitor.svh"

  `include "reset_drive_item.svh"
  `include "reset_driver.svh"

  typedef uvm_sequencer #(reset_drive_item, reset_edge_item) reset_sequencer_t;

  `include "seq_lib/reset_seq.svh"
  `include "seq_lib/reset_now_seq.svh"
  `include "seq_lib/random_reset_seq.svh"

  `include "reset_agent.svh"
endpackage
