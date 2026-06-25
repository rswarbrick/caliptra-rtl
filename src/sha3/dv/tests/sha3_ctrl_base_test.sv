// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class sha3_ctrl_base_test extends dv_base_test #(
    .CFG_T(sha3_ctrl_env_cfg),
    .ENV_T(sha3_ctrl_env)
  );

  `uvm_component_utils(sha3_ctrl_base_test)
  `uvm_component_new

  // the base class dv_base_test creates the following instances:
  // sha3_ctrl_env_cfg: cfg
  // sha3_ctrl_env:     env

  // the base class also looks up UVM_TEST_SEQ plusarg to create and run that seq in
  // the run_phase; as such, nothing more needs to be done

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'($value$plusargs("enable_masking=%0b", cfg.enable_masking));
  endfunction

  virtual task run_phase(uvm_phase phase);
    fork
      super.run_phase(phase);
      if (cfg.is_active) begin
        env.run_layered_register_vseq();
      end
    join
  endtask

  virtual function void configure_sequence(uvm_sequence_base seq);
    sha3_ctrl_base_vseq vseq;

    super.configure_sequence(seq);

    if (!$cast(vseq, seq)) begin
      `uvm_fatal(get_full_name(), "Test expects to run instances of sha3_ctrl_base_vseq.")
    end

    vseq.set_ahb_sequencer(env.get_ahb_mgr_agent().get_sequencer());
  endfunction

endclass : sha3_ctrl_base_test
