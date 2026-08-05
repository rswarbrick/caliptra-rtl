// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// An extension of sha3_ctrl_base_test that runs sha3_ctrl_csr_mem_rw_with_rand_reset_vseq.

class sha3_ctrl_csr_mem_rw_with_rand_reset_test extends sha3_ctrl_base_test;
  `uvm_component_utils(sha3_ctrl_csr_mem_rw_with_rand_reset_test)

  extern function new(string name, uvm_component parent);
  extern function void configure_sequence(uvm_sequence_base seq);
endclass

function sha3_ctrl_csr_mem_rw_with_rand_reset_test::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

function void sha3_ctrl_csr_mem_rw_with_rand_reset_test::configure_sequence(uvm_sequence_base seq);
  sha3_ctrl_csr_mem_rw_with_rand_reset_vseq vseq;
  ahb_agent_pkg::ahb_mgr_agent              mgr_agent;
  ahb_agent_pkg::sub_addr_range_t           subordinate_ranges[$];

  super.configure_sequence(seq);

  if (!$cast(vseq, seq)) begin
    `uvm_fatal(get_full_name(), "Test expects to run sha3_ctrl_csr_mem_rw_with_rand_reset_vseq.")
  end

  mgr_agent = env.get_ahb_mgr_agent();
  mgr_agent.get_subordinate_ranges(subordinate_ranges);

  vseq.set_reset_sequencer(env.get_reset_agent().get_sequencer());
  vseq.set_reset_event(env.get_reset_agent().get_event());
  vseq.set_subordinates(subordinate_ranges);
endfunction
