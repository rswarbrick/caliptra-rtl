// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

package ahb_csr_mem_rw_vseq_pkg;
  import uvm_pkg::*;

  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  import dv_base_reg_pkg::dv_base_reg_block;

  import ahb_agent_pkg::ahb_txn_sequencer_t;
  import ahb_agent_pkg::sub_addr_range_t;

  import csr_utils_pkg::csr_rw_seq;

  import ahb_mem_rw_seq_pkg::ahb_mem_rw_seq;

  `include "ahb_csr_mem_rw_vseq.svh"
endpackage
