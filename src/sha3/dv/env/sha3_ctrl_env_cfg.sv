// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class sha3_ctrl_env_cfg extends dv_base_env_cfg #(.RAL_T(sha3_ctrl_dv_reg));

  virtual reset_if             m_reset_vif;
  virtual ahb_if               m_ahb_vif;
  virtual sha3_intr_if         m_intr_vif;
  virtual kmac_intr_if         m_kmac_intr_vif;
  virtual pins_if #(.Width(1)) m_busy_vif;

  // Masked KMAC is the default configuration
  bit enable_masking = 1;

  // For the unmasked KMAC, the software key is not masked by default.
  bit sw_key_masked = 0;

  // Disable scb cycle accurate check ("status" and "intr_state" registers).
  bit do_cycle_accurate_check = 1;

  // Skip read check for some error test case
  bit skip_read_check = 0;

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

    // Configure CFG_SHADOWED by calling set_is_shadowed(), which will cause its predict functions
    // to do the correct thing and need a double UVM_PREDICT_WRITE before the value changes.
    ral.kmac_core.CFG_SHADOWED.set_is_shadowed();

    ral.kmac_core.INTR_STATE.add_path_slice("u_intr_state_kmac_done.q",  0, 1, BkdrRegPathRtl);
    ral.kmac_core.INTR_STATE.add_path_slice("u_intr_state_fifo_empty.q", 1, 1, BkdrRegPathRtl);
    ral.kmac_core.INTR_STATE.add_path_slice("u_intr_state_kmac_err.q",   2, 1, BkdrRegPathRtl);

    ral.kmac_core.INTR_ENABLE.add_path_slice("u_intr_enable_kmac_done.q",  0, 1, BkdrRegPathRtl);
    ral.kmac_core.INTR_ENABLE.add_path_slice("u_intr_enable_fifo_empty.q", 1, 1, BkdrRegPathRtl);
    ral.kmac_core.INTR_ENABLE.add_path_slice("u_intr_enable_kmac_err.q",   2, 1, BkdrRegPathRtl);

    ral.kmac_core.INTR_TEST.add_path_slice("u_intr_test_kmac_done.q",  0, 1, BkdrRegPathRtl);
    ral.kmac_core.INTR_TEST.add_path_slice("u_intr_test_fifo_empty.q", 1, 1, BkdrRegPathRtl);
    ral.kmac_core.INTR_TEST.add_path_slice("u_intr_test_kmac_err.q",   2, 1, BkdrRegPathRtl);

    // Note: Not connecting up ALERT_TEST, on the basis that Caliptra doesn't use the OpenTitan
    //       alert mechanism and it's probably more helpful to get an error than have the sequence
    //       do nothing.

    ral.kmac_core.CFG_REGWEN.add_path_slice("u_cfg_regwen.qs", 0, 1, BkdrRegPathRtl);

    ral.kmac_core.CFG_SHADOWED.add_prim_subreg_shadow_slices("u_cfg_shadowed_kstrength",
                                                             1, 3);
    ral.kmac_core.CFG_SHADOWED.add_prim_subreg_shadow_slices("u_cfg_shadowed_mode",
                                                             4, 2);
    ral.kmac_core.CFG_SHADOWED.add_prim_subreg_shadow_slices("u_cfg_shadowed_msg_endianness",
                                                             8, 1);
    ral.kmac_core.CFG_SHADOWED.add_prim_subreg_shadow_slices("u_cfg_shadowed_state_endianness",
                                                             9, 1);

    ral.kmac_core.CMD.add_path_slice("u_cmd_cmd.qs", 0, 6, BkdrRegPathRtl);
    ral.kmac_core.CMD.add_path_slice("u_cmd_err_processed.qs", 10, 1, BkdrRegPathRtl);

    ral.kmac_core.STATUS.add_path_slice("u_status_sha3_idle.qs",         0,  1, BkdrRegPathRtl);
    ral.kmac_core.STATUS.add_path_slice("u_status_sha3_absorb.qs",       1,  1, BkdrRegPathRtl);
    ral.kmac_core.STATUS.add_path_slice("u_status_sha3_squeeze.qs",      2,  1, BkdrRegPathRtl);
    ral.kmac_core.STATUS.add_path_slice("u_status_fifo_depth.qs",        8,  5, BkdrRegPathRtl);
    ral.kmac_core.STATUS.add_path_slice("u_status_fifo_empty.qs",        14, 1, BkdrRegPathRtl);
    ral.kmac_core.STATUS.add_path_slice("u_status_fifo_full.qs",         15, 1, BkdrRegPathRtl);
    ral.kmac_core.STATUS.add_path_slice("u_status_alert_fatal_fault.qs", 16, 1, BkdrRegPathRtl);
    ral.kmac_core.STATUS.add_path_slice("u_status_alert_recov_ctrl_update_err.qs",
                                        17, 1, BkdrRegPathRtl);

    for (int unsigned idx = 0; idx < 11; idx++) begin
      string      reg_name = $sformatf("PREFIX_%0d", idx);
      uvm_reg     pfx_reg = ral.kmac_core.get_reg_by_name(reg_name);
      dv_base_reg dv_pfx_reg;

      if (pfx_reg == null) begin
        `uvm_fatal(get_full_name(), $sformatf("Cannot get prefix register %0s.", reg_name))
      end
      if (!$cast(dv_pfx_reg, pfx_reg)) begin
        `uvm_fatal(get_full_name(), $sformatf("Cannot consider register %0s as a dv_base_reg.",
                                              reg_name))
      end

      dv_pfx_reg.add_path_slice($sformatf("u_prefix_%0d.q", idx), 0, 32, BkdrRegPathRtl);
    end

    ral.kmac_core.ERR_CODE.add_path_slice("u_err_code.q", 0, 32, BkdrRegPathRtl);
  endfunction

  // Provide the HDL path for the sha3_ctrl instance.
  function void set_hdl_path(string hdl_path);
    bkdr_reg_path_e std_kind = BkdrRegPathRtl;
    bkdr_reg_path_e shadow_kind = BkdrRegPathRtlShadow;

    ral.kmac_core.set_hdl_path_root({hdl_path, ".u_sha_inst.u_reg"}, std_kind.name());
    ral.kmac_core.set_hdl_path_root({hdl_path, ".u_sha_inst.u_reg"}, shadow_kind.name());

    ral.kmac_core.set_default_hdl_path(std_kind.name());
  endfunction

endclass
