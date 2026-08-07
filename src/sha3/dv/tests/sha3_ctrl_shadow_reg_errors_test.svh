// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A test that configures and runs an instance of shadow_reg_errors_vseq

class sha3_ctrl_shadow_reg_errors_test extends sha3_ctrl_base_test;
  `uvm_component_utils(sha3_ctrl_shadow_reg_errors_test)

  extern function new(string name, uvm_component parent);
  extern virtual function void configure_sequence(uvm_sequence_base seq);
endclass

function sha3_ctrl_shadow_reg_errors_test::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

function void sha3_ctrl_shadow_reg_errors_test::configure_sequence(uvm_sequence_base seq);
  shadow_reg_errors_vseq vseq;

  // Note that we don't call super.configure_sequence() here: the base class expects the sequence
  // to be of type sha3_ctrl_base_vseq and shadow_reg_errors_vseq is not.

  if (!$cast(vseq, seq)) begin
    `uvm_fatal(get_full_name(), "Test expects to run instances of shadow_reg_errors_vseq.")
  end

  vseq.add_update_error_field(cfg.ral.kmac_core.STATUS.ALERT_RECOV_CTRL_UPDATE_ERR, 1);
  vseq.add_storage_error_field(cfg.ral.kmac_core.STATUS.ALERT_FATAL_FAULT, 1);
  vseq.add_storage_error_field(cfg.ral.kmac_core.CFG_REGWEN.en, 0);
  vseq.add_storage_error_field(cfg.ral.kmac_core.STATUS.sha3_idle, 0);

  vseq.add_reg_block(cfg.ral.kmac_core);

  vseq.set_reset_event(env.get_reset_agent().get_event());
endfunction
