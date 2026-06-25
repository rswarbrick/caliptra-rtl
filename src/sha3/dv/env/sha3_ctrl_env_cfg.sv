// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class sha3_ctrl_env_cfg extends dv_base_env_cfg #(.RAL_T(sha3_ctrl_dv_reg));

  virtual ahb_if               m_ahb_vif;
  virtual sha3_intr_if         m_intr_vif;
  virtual pins_if #(.Width(1)) m_busy_vif;

  // Masked KMAC is the default configuration
  bit enable_masking = 1;

  // For the unmasked KMAC, the software key is not masked by default.
  bit sw_key_masked = 0;

  // Disable scb cycle accurate check ("status" and "intr_state" registers).
  bit do_cycle_accurate_check = 1;

  // Skip read check for some error test case
  bit skip_read_check = 0;

  // Tracks if a test invalidated the sideloading key.
  bit key_invalidated = 0;

  // Tracks if a sha3 sw control error is expected to occur.
  bit expect_sha3_sw_ctrl_err = 0;

  // These values are used by the test vector tests to select the correct vector text files.
  // These are unused by all other tests.
  int sha3_variant;
  int shake_variant;

  // Defines the maximum message size when randomizing the message.
  int unsigned max_msg_size = 10_000;

  // The subordinate index of sha3_ctrl on the AHB bus. This is used to constrain HSEL when sending
  // AHB sequence items.
  //
  // This must be configured by the testbench (and is initialised to a known-bad default value to
  // check this happens).
  int unsigned m_subordinate_idx = ~0;

  `uvm_object_utils_begin(sha3_ctrl_env_cfg)
  `uvm_object_utils_end

  `uvm_object_new

  virtual function void initialize();
    void'($value$plusargs("enable_masking=%0d", enable_masking));
    void'($value$plusargs("sw_key_masked=%0d", sw_key_masked));
    void'($value$plusargs("test_vectors_sha3_variant=%0d", sha3_variant));
    void'($value$plusargs("test_vectors_shake_variant=%0d", shake_variant));

    // dv_base_env_cfg requires ral_type_name to be set explicitly before initialize_ral (see the
    // comment on dv_base_env_cfg::ral_type_name). Provide the PeakRDL-uvm class name.
    ral_type_name = "sha3_ctrl_dv_reg";

    initialize_ral(`UVM_REG_ADDR_WIDTH,
                   `UVM_REG_DATA_WIDTH,
                   `UVM_REG_BYTENABLE_WIDTH);
  endfunction

endclass
