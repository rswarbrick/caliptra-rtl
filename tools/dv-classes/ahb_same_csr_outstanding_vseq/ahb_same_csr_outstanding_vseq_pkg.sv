// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

package ahb_same_csr_outstanding_vseq_pkg;
  import uvm_pkg::*;

  import dv_base_reg_pkg::dv_base_reg;
  import dv_base_reg_pkg::dv_base_reg_block;
  import ahb_agent_pkg::ahb_txn_request_item;
  import ahb_agent_pkg::ahb_status_item;
  import ahb_agent_pkg::sub_addr_range_t;
  import ahb_agent_pkg::ahb_txn_sequencer_t;
  import ahb_agent_pkg::ahb_read_write_seq;

  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  `include "ahb_one_csr_outstanding_vseq.svh"
  `include "ahb_same_csr_outstanding_vseq.svh"
endpackage
