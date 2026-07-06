// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A test that configures and runs an instance of sha3_ctrl_intr_test_vseq

class sha3_ctrl_intr_test_test extends sha3_ctrl_base_test;

  `uvm_component_utils(sha3_ctrl_intr_test_test)

  extern function new(string name, uvm_component parent);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual function void configure_sequence(uvm_sequence_base seq);

  // Called when reset is asserted and will notify m_current_sequence (from dv_base_test) if that is
  // not null.
  extern local function void on_reset();
endclass

function sha3_ctrl_intr_test_test::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

task sha3_ctrl_intr_test_test::run_phase(uvm_phase phase);
  fork
    super.run_phase(phase);
    forever begin
      wait(cfg.under_reset);
      on_reset();
      wait(!cfg.under_reset);
    end
  join
endtask

function void sha3_ctrl_intr_test_test::configure_sequence(uvm_sequence_base seq);
  sha3_ctrl_intr_test_vseq vseq;

  // Note that we don't call super.configure_sequence() here: the base class expects the sequence
  // to be of type sha3_ctrl_base_vseq and sha3_ctrl_intr_test_vseq doesn't work like that.

  if (!$cast(vseq, seq)) begin
    `uvm_fatal(get_full_name(), "Test expects to run instances of sha3_ctrl_intr_test_vseq.")
  end

  vseq.set_vif(cfg.m_kmac_intr_vif);
  vseq.add_reg_triple(cfg.ral.kmac_core.INTR_ENABLE,
                      cfg.ral.kmac_core.INTR_STATE,
                      cfg.ral.kmac_core.INTR_TEST);
endfunction

function void sha3_ctrl_intr_test_test::on_reset();
  sha3_ctrl_intr_test_vseq vseq;

  if (m_current_sequence == null) return;

  // This cast should be guaranteed to work, otherwise we would have failed in configure_sequence.
  if (!$cast(vseq, m_current_sequence)) begin
    `uvm_fatal(get_full_name(), "Failed to cast m_current_sequence to sha3_ctrl_intr_test_vseq.")
  end

  vseq.report_reset();
endfunction
