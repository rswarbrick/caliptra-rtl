// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A test that configures and runs an instance of ahb_same_csr_outstanding_vseq

class sha3_ctrl_same_csr_outstanding_test extends sha3_ctrl_base_test;
  `uvm_component_utils(sha3_ctrl_same_csr_outstanding_test)

  extern function new(string name, uvm_component parent);
  extern virtual function void configure_sequence(uvm_sequence_base seq);
endclass

function sha3_ctrl_same_csr_outstanding_test::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

function void sha3_ctrl_same_csr_outstanding_test::configure_sequence(uvm_sequence_base seq);
  import ahb_same_csr_outstanding_vseq_pkg::ahb_same_csr_outstanding_vseq;

  ahb_same_csr_outstanding_vseq   vseq;
  ahb_agent_pkg::ahb_mgr_agent    mgr_agent;
  ahb_agent_pkg::sub_addr_range_t subordinate_ranges[$];

  // Note that we don't call super.configure_sequence() here: the base class expects the sequence to
  // be of type sha3_ctrl_base_vseq and sha3_ctrl_same_csr_outstanding_vseq doesn't work like that.

  if (!$cast(vseq, seq)) begin
    `uvm_fatal(get_full_name(), "Test expects to run instances of ahb_same_csr_outstanding_vseq.")
  end

  mgr_agent = env.get_ahb_mgr_agent();
  mgr_agent.get_subordinate_ranges(subordinate_ranges);

  // Because caliptra-rtl uses AHB-lite, there is no wstrb signal on the interface and we shouldn't
  // allow the sequence to pick wstrb values that can't be represented.
  vseq.set_use_full_wstrb();

  // TODO: The sha3_ctrl environment doesn't yet support partial accesses for CSRs.
  vseq.set_only_full_accesses();

  vseq.set_ral(cfg.ral.kmac_core);
  vseq.set_subordinates(subordinate_ranges);
  vseq.set_sequencer(mgr_agent.get_sequencer());
endfunction
