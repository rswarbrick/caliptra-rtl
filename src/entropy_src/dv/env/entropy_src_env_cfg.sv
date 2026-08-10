// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`include "dv_mubi_macros.svh"

class entropy_src_env_cfg extends dv_base_env_cfg #(.RAL_T(entropy_src_uvm::entropy_src));

  `uvm_object_utils(entropy_src_env_cfg)
  `uvm_object_new

  // Ext component cfgs
  rand push_pull_agent_cfg#(.HostDataWidth(RNG_BUS_WIDTH))
       m_rng_agent_cfg;
  rand push_pull_agent_cfg#(.HostDataWidth(FIPS_CSRNG_BUS_WIDTH))
       m_csrng_agent_cfg;
  rand push_pull_agent_cfg#(.HostDataWidth(0))
       m_aes_halt_agent_cfg;

  // Additional reset interface for the csrng.
  virtual clk_rst_if    csrng_rst_vif;
  virtual reset_if      m_reset_vif;
  virtual pins_if#(8)   otp_en_es_fw_read_vif;
  virtual pins_if#(8)   otp_en_es_fw_over_vif;

  // The AHB interface (with entropy_src as a subordinate)
  virtual ahb_if m_ahb_vif;

  // An interface through which sequences can enable/disable a particular set of assertions
  virtual entropy_src_assertion_if m_assertion_vif;

  // Configuration for DUT CSRs (held in a separate object for easy re-randomization)
  entropy_src_dut_cfg dut_cfg;

  // handle to entropy_src path interface
  virtual entropy_src_path_if   entropy_src_path_vif;

  // Pointer to the preconditioning and bypass fifo exception interfaces.
  // (For tracking errors during FW_OV mode)
  virtual entropy_subsys_fifo_exception_if#(1) precon_fifo_vif;
  virtual entropy_subsys_fifo_exception_if#(1) bypass_fifo_vif;

  // Pointer to the FSM state tracking interface.
  // (Coverage completion requires earlier notice of following state).
  virtual entropy_src_fsm_cov_if fsm_tracking_vif;

  // The subordinate index of entropy_src on the AHB bus. This is used to constrain HSEL when
  // sending AHB sequence items.
  //
  // This must be configured by the testbench (and is initialised to a known-bad default value to
  // check this happens).
  int unsigned m_subordinate_idx = ~0;

  // Variables for controlling test duration.  Depending on the test there are two options:
  // fixed duration in time or total number of seeds.
  //
  // When selecting fixed duration, the total simulated duration of the test is approximately
  // equal to cfg.sim_duration
  //
  // sim_duration_ms is used as a random value to set sim_duration in post_randomize().
  realtime sim_duration;
  rand int unsigned sim_duration_ms;

  // Mean time before hard RNG failure
  // Default: Negative, meaning no random reconfigs.
  realtime hard_mtbf = -1;
  // Mean time before "soft" RNG failure (still functions but less entropy per bit)
  // Default: Negative, meaning no random reconfigs.
  realtime soft_mtbf = -1;

  // Mean time between unexpected configuration update events
  // Default: Negative, meaning no random reconfigs
  realtime mean_rand_reconfig_time = -1;

  // Mean time ERR_CODE_TEST CSR-driven alert events
  // Default: Negative, meaning no random reconfigs
  realtime mean_rand_csr_alert_time = -1;

  // Maximum time to wait for non-seed generating DUT configurations
  realtime max_silent_reconfig_time = -1;

  // Time to pause between register configs.
  realtime configuration_pause_time = 0ns;

  int      seed_cnt;

  // The AST/RNG does not pay attention to the entropy_src `ready` backpressure signal on the RNG
  // entropy_src interface.  We mimic this behavior in the RNG and FW_OV tests, which expect random
  // RNG data.  For other tests (which rely on fixed RNG sequences) we leave handshaking enabled.
  bit      rng_ignores_backpressure = 0;

  // The number of seeds that are consumed via the CSRNG interface or the entopy_data register are
  // recorded by the scoreboard.
  int      total_seeds_consumed = 0;

  /////////////////////
  // Knobs & Weights //
  /////////////////////

  // Knob to inject entropy even if the DUT is configured to not accept it
  uint          spurious_inject_entropy_pct;

  // Constraint knobs for OTP-driven inputs
  uint          otp_en_es_fw_read_pct, otp_en_es_fw_read_inval_pct,
                otp_en_es_fw_over_pct, otp_en_es_fw_over_inval_pct;

  // Behavioral constrint knob: dictates how often each sequence
  // performs a survey of the health test diagnostics.
  // (100% corresponds to a full diagnostic chack after every HT alert,
  // If less than 100%, this full-diagnostic is skipped after some alerts)
  uint          do_check_ht_diag_pct;

  // Constraint knob to limit how often the RNG vseq forces a yet-unseen FSM transition
  uint          induce_targeted_transition_pct;

  /////////////////////////////////////////////////////////////////
  // Implementation-specific constants related to the DUT        //
  // (Needed for accurate prediction, no randomization required) //
  /////////////////////////////////////////////////////////////////

  // Number of clock cycles between a TLUL disable signal, and deassertion
  // of enable on the RNG bus.

  int tlul_to_rng_disable_delay = 0;
  int tlul_to_fifo_clr_delay    = 5;

  // When expecting an alert, the cip scoreboarding routines expect a to see the
  // alert within alert_max_delay clock cycles.
  int      alert_max_delay;

  // host_delay_max value for the RNG agent. This can be overwritten using a plusarg.
  int rng_max_delay = 12;

  ///////////////////////
  // Randomized fields //
  ///////////////////////

  // OTP variables.
  rand logic [7:0]              otp_en_es_fw_read, otp_en_es_fw_over;

  rand bit                      spurious_inject_entropy;

  // Random values for interrupt, alert and error tests
  rand fatal_err_e      which_fatal_err;
  rand err_code_e       which_err_code;
  rand which_fifo_e     which_fifo;
  rand which_fifo_err_e which_fifo_err;
  rand ht_fail_e        which_ht_fail;
  rand cntr_e           which_cntr;
  rand which_ht_e       which_ht;
  rand state_e          which_ht_state;

  rand uint  which_cntr_replicate;

  rand uint  which_bin;

  rand bit   induce_targeted_transition;
  // Read the entropy over the entropy_data register if this is set.
  rand mubi4_t es_route_sw;

  // fw_ov_rd_cnt is the number of words read from the observe FIFO.
  rand int   fw_ov_rd_cnt;

  /////////////////
  // Constraints //
  /////////////////
  constraint sim_duration_ms_c {
    7 <= sim_duration_ms && sim_duration_ms <= 20;
  }

  constraint which_ht_state_c {
    which_ht_state dist {
      BootHTRunning :/ 25,
      BootPhaseDone :/ 25,
      StartupFail1  :/ 25,
      ContHTRunning :/ 25
    };
  }

  constraint otp_en_es_fw_read_c {
    `DV_MUBI8_DIST(otp_en_es_fw_read, otp_en_es_fw_read_pct,
                                      100 - otp_en_es_fw_read_pct - otp_en_es_fw_read_inval_pct,
                                      otp_en_es_fw_read_inval_pct)
  }

  constraint otp_en_es_fw_over_c {
    `DV_MUBI8_DIST(otp_en_es_fw_over, otp_en_es_fw_over_pct,
                                      100 - otp_en_es_fw_over_pct - otp_en_es_fw_over_inval_pct,
                                      otp_en_es_fw_over_inval_pct)
  }

  constraint spurious_inject_entropy_c {spurious_inject_entropy dist {
      1                         :/ spurious_inject_entropy_pct,
      0                         :/ (100 - spurious_inject_entropy_pct) };}

  // Scale the frequency of each error code with the number of sub cover points (number of counters
  // etc)
  // Let the RNG test manage the CSR-driven errors
  constraint which_err_code_c {
    which_err_code dist {
      sfifo_esrng_err   :/ 2,
      sfifo_distr_err   :/ 2,
      sfifo_observe_err :/ 2,
      sfifo_esfinal_err :/ 2,
      es_ack_sm_err     :/ 2,
      es_main_sm_err    :/ 2,
      es_cntr_err       :/ 60,
      fifo_read_err     :/ 4,
      fifo_state_err    :/ 4,
      fifo_cntr_err     :/ 4};}

  constraint which_cntr_replicate_c {which_cntr_replicate inside {[0:RNG_BUS_WIDTH-1]};}
  int        num_bins = 2**RNG_BUS_WIDTH;
  constraint which_bin_c {which_bin inside {[0:num_bins-1]};}

  // Choose the counter to probe by the number of bins or channels with each counter
  constraint which_cntr_c {which_cntr dist {
    window_cntr     :/ 1,
    repcnt_ht_cntr  :/ 4,
    repcnts_ht_cntr :/ 1,
    adaptp_ht_cntr  :/ 4,
    bucket_ht_cntr  :/ 16,
    markov_ht_cntr  :/ 4};}

  // Write errors no longer apply to the esfinal or esrng fifos
  // so exclude those combinations when targetting a specific fifo or error condition
  constraint which_fifo_err_c {
    which_err_code inside {sfifo_esrng_err, sfifo_distr_err, sfifo_esfinal_err} ->
      which_fifo_err inside {read, state};
    which_err_code == fifo_read_err -> which_fifo_err == read;
    which_err_code inside {fifo_state_err, fifo_cntr_err} -> which_fifo_err == state;
  }

  constraint which_fifo_c {
    which_err_code == sfifo_observe_err -> which_fifo == sfifo_observe;
    which_err_code == sfifo_esrng_err -> which_fifo == sfifo_esrng;
    which_err_code == sfifo_distr_err -> which_fifo == sfifo_distr;
    which_err_code == sfifo_esfinal_err -> which_fifo == sfifo_esfinal;
    which_err_code == fifo_cntr_err -> which_fifo inside {sfifo_observe, sfifo_esrng, sfifo_distr,
                                                          sfifo_esfinal};
  }

  constraint induce_targeted_transition_c {induce_targeted_transition dist {
    1                         :/ induce_targeted_transition_pct,
    0                         :/ (100 - induce_targeted_transition_pct) };}

  constraint es_route_sw_c {es_route_sw inside {MuBi4False, MuBi4True};}

  // We need to make sure that we can read out 1024 contiguous symbols, that's why
  // we set the probability for 128 seeds to 40 pct (this is exactly 1024 symbols
  // when using all 4 lanes).
  constraint fw_ov_rd_cnt_c {fw_ov_rd_cnt dist {
    1                         :/ 40,
    [2:127]                   :/ 20,
    128                       :/ 40 };}

  ///////////////
  // Functions //
  ///////////////

  virtual function void initialize(bit [31:0] csr_base_addr = '1);
    // dv_base_env_cfg requires ral_type_name to be set explicitly before initialize_ral (see the
    // comment on dv_base_env_cfg::ral_type_name). Provide the PeakRDL-uvm class name.
    ral_type_name = "entropy_src";

    // Initialisation of the register model will depend on sizes configured in the AHB interface.
    // Make sure that they are available.
    if (m_ahb_vif == null) begin
      `uvm_fatal("no_ahb_if", "Cannot call initialize with no AHB interface.")
    end

    // The address and data width are constrained by the AHB interface with which the block gets
    // accessed. This is visible in m_ahb_vif, from which we can extract addr_width and data_width.
    // The byte-enable width should be zero: there is no wstrb value on the interface.
    initialize_ral(m_ahb_vif.addr_width, m_ahb_vif.data_width, 0);

    ral.INTERRUPT_STATE.add_path_slice("u_intr_state_es_entropy_valid.q",
                                       0, 1, BkdrRegPathRtl);
    ral.INTERRUPT_STATE.add_path_slice("u_intr_state_es_health_test_failed.q",
                                       1, 1, BkdrRegPathRtl);
    ral.INTERRUPT_STATE.add_path_slice("u_intr_state_es_observe_fifo_ready.q",
                                       2, 1, BkdrRegPathRtl);
    ral.INTERRUPT_STATE.add_path_slice("u_intr_state_es_fatal_err.q",
                                       3, 1, BkdrRegPathRtl);

    ral.INTERRUPT_ENABLE.add_path_slice("u_intr_enable_es_entropy_valid.q",
                                        0, 1, BkdrRegPathRtl);
    ral.INTERRUPT_ENABLE.add_path_slice("u_intr_enable_es_health_test_failed.q",
                                        1, 1, BkdrRegPathRtl);
    ral.INTERRUPT_ENABLE.add_path_slice("u_intr_enable_es_observe_fifo_ready.q",
                                        2, 1, BkdrRegPathRtl);
    ral.INTERRUPT_ENABLE.add_path_slice("u_intr_enable_es_fatal_err.q",
                                        3, 1, BkdrRegPathRtl);

    ral.INTERRUPT_TEST.add_path_slice("u_intr_test_es_entropy_valid.q",
                                      0, 1, BkdrRegPathRtl);
    ral.INTERRUPT_TEST.add_path_slice("u_intr_test_es_health_test_failed.q",
                                      1, 1, BkdrRegPathRtl);
    ral.INTERRUPT_TEST.add_path_slice("u_intr_test_es_observe_fifo_ready.q",
                                      2, 1, BkdrRegPathRtl);
    ral.INTERRUPT_TEST.add_path_slice("u_intr_test_es_fatal_err.q",
                                      3, 1, BkdrRegPathRtl);

    // Note: Not connecting up ALERT_TEST, on the basis that Caliptra doesn't use the OpenTitan
    //       alert mechanism and it's probably more helpful to get an error than have the sequence
    //       do nothing.

    ral.ME_REGWEN.add_path_slice("u_me_regwen.q", 0, 1, BkdrRegPathRtl);
    ral.SW_REGUPD.add_path_slice("u_sw_regupd.q", 0, 1, BkdrRegPathRtl);
    ral.REGWEN.add_path_slice("u_regwen.q", 0, 1, BkdrRegPathRtl);
    ral.MODULE_ENABLE.add_path_slice("u_module_enable.q", 0, 4, BkdrRegPathRtl);

    ral.CONF.add_path_slice("u_conf_fips_enable.q", 0, 4, BkdrRegPathRtl);
    ral.CONF.add_path_slice("u_conf_fips_flag.q", 4, 4, BkdrRegPathRtl);
    ral.CONF.add_path_slice("u_conf_rng_fips.q", 8, 4, BkdrRegPathRtl);
    ral.CONF.add_path_slice("u_conf_rng_bit_enable.q", 12, 4, BkdrRegPathRtl);
    ral.CONF.add_path_slice("u_conf_threshold_scope.q", 16, 4, BkdrRegPathRtl);
    ral.CONF.add_path_slice("u_conf_entropy_data_reg_enable.q", 20, 4, BkdrRegPathRtl);
    ral.CONF.add_path_slice("u_conf_rng_bit_sel.q", 24, 8, BkdrRegPathRtl);

    ral.ENTROPY_CONTROL.add_path_slice("u_entropy_control_es_route.q", 0, 4, BkdrRegPathRtl);
    ral.ENTROPY_CONTROL.add_path_slice("u_entropy_control_es_type.q", 4, 4, BkdrRegPathRtl);

    ral.ENTROPY_DATA.add_path_slice("u_entropy_data.qs", 0, 32, BkdrRegPathRtl);

    ral.HEALTH_TEST_WINDOWS.add_path_slice("u_health_test_windows_fips_window.q",
                                           0, 16, BkdrRegPathRtl);
    ral.HEALTH_TEST_WINDOWS.add_path_slice("u_health_test_windows_bypass_window.q",
                                           16, 16, BkdrRegPathRtl);

    add_threshold_slices(ral.REPCNT_THRESHOLDS, "u_repcnt_thresholds");
    add_watermark_slices(ral.REPCNT_HI_WATERMARKS, "u_repcnt_hi_watermarks");
    ral.REPCNT_TOTAL_FAILS.add_path_slice("u_repcnt_total_fails.qs", 0, 32, BkdrRegPathRtl);

    add_threshold_slices(ral.REPCNTS_THRESHOLDS, "u_repcnts_thresholds");
    add_watermark_slices(ral.REPCNTS_HI_WATERMARKS, "u_repcnts_hi_watermarks");
    ral.REPCNTS_TOTAL_FAILS.add_path_slice("u_repcnts_total_fails.qs", 0, 32, BkdrRegPathRtl);

    add_slices_for_test_regs(ral.ADAPTP_HI_THRESHOLDS,
                             ral.ADAPTP_HI_WATERMARKS,
                             ral.ADAPTP_HI_TOTAL_FAILS,
                             "u_adaptp_hi");

    add_slices_for_test_regs(ral.ADAPTP_LO_THRESHOLDS,
                             ral.ADAPTP_LO_WATERMARKS,
                             ral.ADAPTP_LO_TOTAL_FAILS,
                             "u_adaptp_lo");

    add_threshold_slices(ral.BUCKET_THRESHOLDS, "u_bucket_thresholds");
    add_watermark_slices(ral.BUCKET_HI_WATERMARKS, "u_bucket_hi_watermarks");
    ral.REPCNTS_TOTAL_FAILS.add_path_slice("u_bucket_total_fails.qs", 0, 32, BkdrRegPathRtl);

    add_slices_for_test_regs(ral.MARKOV_HI_THRESHOLDS,
                             ral.MARKOV_HI_WATERMARKS,
                             ral.MARKOV_HI_TOTAL_FAILS,
                             "u_markov_hi");
    add_slices_for_test_regs(ral.MARKOV_LO_THRESHOLDS,
                             ral.MARKOV_LO_WATERMARKS,
                             ral.MARKOV_LO_TOTAL_FAILS,
                             "u_markov_lo");
    add_slices_for_test_regs(ral.EXTHT_HI_THRESHOLDS,
                             ral.EXTHT_HI_WATERMARKS,
                             ral.EXTHT_HI_TOTAL_FAILS,
                             "u_extht_hi");
    add_slices_for_test_regs(ral.EXTHT_LO_THRESHOLDS,
                             ral.EXTHT_LO_WATERMARKS,
                             ral.EXTHT_LO_TOTAL_FAILS,
                             "u_extht_lo");

    ral.ALERT_THRESHOLD.add_path_slice("u_alert_threshold_alert_threshold.q",
                                       0, 16, BkdrRegPathRtl);
    ral.ALERT_THRESHOLD.add_path_slice("u_alert_threshold_alert_threshold_inv.q",
                                       16, 16, BkdrRegPathRtl);

    ral.ALERT_SUMMARY_FAIL_COUNTS.add_path_slice("u_alert_summary_fail_counts.qs",
                                                 0, 16, BkdrRegPathRtl);

    ral.ALERT_FAIL_COUNTS.add_path_slice("u_alert_fail_counts_repcnt_fail_count.qs",
                                         4, 4, BkdrRegPathRtl);
    ral.ALERT_FAIL_COUNTS.add_path_slice("u_alert_fail_counts_adaptp_hi_fail_count.qs",
                                         8, 4, BkdrRegPathRtl);
    ral.ALERT_FAIL_COUNTS.add_path_slice("u_alert_fail_counts_adaptp_lo_fail_count.qs",
                                         12, 4, BkdrRegPathRtl);
    ral.ALERT_FAIL_COUNTS.add_path_slice("u_alert_fail_counts_bucket_fail_count.qs",
                                         16, 4, BkdrRegPathRtl);
    ral.ALERT_FAIL_COUNTS.add_path_slice("u_alert_fail_counts_markov_hi_fail_count.qs",
                                         20, 4, BkdrRegPathRtl);
    ral.ALERT_FAIL_COUNTS.add_path_slice("u_alert_fail_counts_markov_lo_fail_count.qs",
                                         24, 4, BkdrRegPathRtl);
    ral.ALERT_FAIL_COUNTS.add_path_slice("u_alert_fail_counts_repcnts_fail_count.qs",
                                         28, 4, BkdrRegPathRtl);

    ral.EXTHT_FAIL_COUNTS.add_path_slice("u_extht_fail_counts_extht_hi_fail_count.qs",
                                         0, 4, BkdrRegPathRtl);
    ral.EXTHT_FAIL_COUNTS.add_path_slice("u_extht_fail_counts_extht_lo_fail_count.qs",
                                         4, 4, BkdrRegPathRtl);

    ral.FW_OV_CONTROL.add_path_slice("u_fw_ov_control_fw_ov_mode.qs",
                                     0, 4, BkdrRegPathRtl);
    ral.FW_OV_CONTROL.add_path_slice("u_fw_ov_control_fw_ov_entropy_insert.qs",
                                     4, 4, BkdrRegPathRtl);

    ral.FW_OV_SHA3_START.add_path_slice("u_fw_ov_sha3_start.q", 0, 4, BkdrRegPathRtl);

    ral.FW_OV_WR_FIFO_FULL.add_path_slice("u_fw_ov_wr_fifo_full.qs", 0, 1, BkdrRegPathRtl);
    ral.FW_OV_RD_FIFO_OVERFLOW.add_path_slice("u_fw_ov_rd_fifo_overflow.qs", 0, 1, BkdrRegPathRtl);

    ral.FW_OV_RD_DATA.add_path_slice("u_fw_ov_rd_data.q", 0, 32, BkdrRegPathRtl);
    ral.FW_OV_WR_DATA.add_path_slice("u_fw_ov_wr_data.q", 0, 32, BkdrRegPathRtl);

    ral.OBSERVE_FIFO_THRESH.add_path_slice("u_observe_fifo_thresh.qs", 0, 6, BkdrRegPathRtl);

    ral.OBSERVE_FIFO_DEPTH.add_path_slice("u_observe_fifo_depth.qs", 0, 6, BkdrRegPathRtl);

    ral.DEBUG_STATUS.add_path_slice("u_debug_status_entropy_fifo_depth.qs", 0, 2, BkdrRegPathRtl);
    ral.DEBUG_STATUS.add_path_slice("u_debug_status_sha3_fsm.qs", 3, 3, BkdrRegPathRtl);
    ral.DEBUG_STATUS.add_path_slice("u_debug_status_sha3_block_pr.qs", 6, 1, BkdrRegPathRtl);
    ral.DEBUG_STATUS.add_path_slice("u_debug_status_sha3_squeezing.qs", 7, 1, BkdrRegPathRtl);
    ral.DEBUG_STATUS.add_path_slice("u_debug_status_sha3_absorbed.qs", 8, 1, BkdrRegPathRtl);
    ral.DEBUG_STATUS.add_path_slice("u_debug_status_sha3_err.qs", 9, 1, BkdrRegPathRtl);
    ral.DEBUG_STATUS.add_path_slice("u_debug_status_main_sm_idle.qs", 16, 1, BkdrRegPathRtl);
    ral.DEBUG_STATUS.add_path_slice("u_debug_status_main_sm_boot_done.qs", 17, 1, BkdrRegPathRtl);

    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_fips_enable_field_alert.qs",
                                       0, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_entropy_data_reg_en_field_alert.qs",
                                       1, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_module_enable_field_alert.qs",
                                       2, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_threshold_scope_field_alert.qs",
                                       3, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_rng_bit_enable_field_alert.qs",
                                       5, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_fw_ov_sha3_start_field_alert.qs",
                                       7, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_fw_ov_mode_field_alert.qs",
                                       8, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_fw_ov_entropy_insert_field_alert.qs",
                                       9, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_es_route_field_alert.qs",
                                       10, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_es_type_field_alert.qs",
                                       11, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_es_main_sm_alert.qs",
                                       12, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_es_bus_cmp_alert.qs",
                                       13, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_es_thresh_cfg_alert.qs",
                                       14, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_es_fw_ov_wr_alert.qs",
                                       15, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_es_fw_ov_disable_alert.qs",
                                       16, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_fips_flag_field_alert.qs",
                                       17, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_rng_fips_field_alert.qs",
                                       18, 1, BkdrRegPathRtl);
    ral.RECOV_ALERT_STS.add_path_slice("u_recov_alert_sts_postht_entropy_drop_alert.qs",
                                       31, 1, BkdrRegPathRtl);

    ral.ERR_CODE.add_path_slice("u_err_code_sfifo_esrng_err.qs", 0, 1, BkdrRegPathRtl);
    ral.ERR_CODE.add_path_slice("u_err_code_sfifo_distr_err.qs", 1, 1, BkdrRegPathRtl);
    ral.ERR_CODE.add_path_slice("u_err_code_sfifo_observe_err.qs", 2, 1, BkdrRegPathRtl);
    ral.ERR_CODE.add_path_slice("u_err_code_sfifo_esfinal_err.qs", 3, 1, BkdrRegPathRtl);
    ral.ERR_CODE.add_path_slice("u_err_code_es_ack_sm_err.qs", 20, 1, BkdrRegPathRtl);
    ral.ERR_CODE.add_path_slice("u_err_code_es_main_sm_err.qs", 21, 1, BkdrRegPathRtl);
    ral.ERR_CODE.add_path_slice("u_err_code_es_cntr_err.qs", 22, 1, BkdrRegPathRtl);
    ral.ERR_CODE.add_path_slice("u_err_code_sha3_state_err.qs", 23, 1, BkdrRegPathRtl);
    ral.ERR_CODE.add_path_slice("u_err_code_sha3_rst_storage_err.qs", 24, 1, BkdrRegPathRtl);
    ral.ERR_CODE.add_path_slice("u_err_code_fifo_write_err.qs", 28, 1, BkdrRegPathRtl);
    ral.ERR_CODE.add_path_slice("u_err_code_fifo_read_err.qs", 29, 1, BkdrRegPathRtl);
    ral.ERR_CODE.add_path_slice("u_err_code_fifo_state_err.qs", 30, 1, BkdrRegPathRtl);

    ral.ERR_CODE_TEST.add_path_slice("u_err_code_test.q", 0, 5, BkdrRegPathRtl);

    ral.MAIN_SM_STATE.add_path_slice("u_main_sm_state.q", 0, 9, BkdrRegPathRtl);

    dut_cfg = entropy_src_dut_cfg::type_id::create("dut_cfg");

    // create agent config objs
    m_rng_agent_cfg       = push_pull_agent_cfg#(.HostDataWidth(RNG_BUS_WIDTH))::
                            type_id::create("m_rng_agent_cfg");
    m_csrng_agent_cfg     = push_pull_agent_cfg#(.HostDataWidth(FIPS_CSRNG_BUS_WIDTH))::
                            type_id::create("m_csrng_agent_cfg");
    m_aes_halt_agent_cfg  = push_pull_agent_cfg#(.HostDataWidth(0))::
                            type_id::create("m_aes_halt_agent_cfg");
  endfunction

  // Add path slices for the two 16-bit fields in a thresholds register
  //
  // The name_root string is an HDL path, relative to u_reg, for the root of the prim_subreg_ext
  // instance names for the register. For example, if name_root is "u_repcnt_thresholds" then this
  // will point at u_repcnt_thresholds_fips_thresh and u_repcnt_thresholds_bypass_thresh.
  local function void add_threshold_slices(dv_base_reg register,
                                           string      name_root);
    register.add_path_slice({name_root, "_fips_thresh.qs"}, 0, 16, BkdrRegPathRtl);
    register.add_path_slice({name_root, "_bypass_thresh.qs"}, 16, 16, BkdrRegPathRtl);
  endfunction

  // Add path slices for the two 16-bit fields in a watermarks register
  //
  // The name_root string is an HDL path, relative to u_reg, for the root of the prim_subreg_ext
  // instance names for the register. For example, if name_root is "u_repcnt_hi_watermarks" then
  // this will point at u_repcnt_hi_watermarks_fips_watermark and
  // u_repcnt_hi_watermarks_bypass_watermark.
  local function void add_watermark_slices(dv_base_reg register,
                                           string      name_root);
    register.add_path_slice({name_root, "_fips_watermark.qs"}, 0, 16, BkdrRegPathRtl);
    register.add_path_slice({name_root, "_bypass_watermark.qs"}, 16, 16, BkdrRegPathRtl);
  endfunction

  // Add path slices for the three types of register associated with a health test. The name root is
  // the base of the names of the caliptra_prim_subreg_ext instances. For example, if name_root is
  // "u_repnt" then this will point at instances including u_repcnt_thresholds_fips_thresh.
  local function void add_slices_for_test_regs(dv_base_reg thresholds_reg,
                                               dv_base_reg watermarks_reg,
                                               dv_base_reg total_fails_reg,
                                               string      name_root);
    add_threshold_slices(thresholds_reg, {name_root, "_thresholds"});
    add_watermark_slices(watermarks_reg, {name_root, "_watermarks"});
    total_fails_reg.add_path_slice({name_root, "_total_fails.qs"}, 0, 32, BkdrRegPathRtl);
  endfunction

  virtual function string convert2string();
    string str = "";
    str = {str, "\n"};
    str = {str, "\n\t |**************** entropy_src_env_cfg *****************| \t"};

    str = {
        str,
        $sformatf("\n\t |***** otp_en_es_fw_read           :         'h%02h *****| \t",
                  otp_en_es_fw_read),
        $sformatf("\n\t |***** otp_en_es_fw_over           :         'h%02h *****| \t",
                  otp_en_es_fw_over),
        $sformatf("\n\t |***** seed_cnt                    : %12d *****| \t",
                  seed_cnt),
        $sformatf("\n\t |***** sim_duration                : %9.2f ms *****| \t",
                  sim_duration/1ms)
    };

    str = {str, "\n\t |----------------- knobs ------------------------------| \t"};

    str = {
        str,
        $sformatf("\n\t |***** otp_en_es_fw_read_pct       : %12d *****| \t",
                  otp_en_es_fw_read_pct),
        $sformatf("\n\t |***** otp_en_es_fw_read_inval_pct : %12d *****| \t",
                  otp_en_es_fw_read_inval_pct),
        $sformatf("\n\t |***** otp_en_es_fw_over_pct       : %12d *****| \t",
                  otp_en_es_fw_over_pct),
        $sformatf("\n\t |***** otp_en_es_fw_over_inval_pct : %12d *****| \t",
                  otp_en_es_fw_over_inval_pct)
    };

    str = {str, "\n\t |******************************************************| \t"};
    str = {str, dut_cfg.convert2string()};

    return str;
  endfunction

  function void post_randomize();
    void'(dut_cfg.randomize());
    super.post_randomize();
    sim_duration = sim_duration_ms * 1ms;
  endfunction

  function void pre_randomize();
    check_knob_vals();
    super.pre_randomize();
  endfunction

  function void check_knob_vals();
    `DV_CHECK(spurious_inject_entropy_pct <= 100);
    `DV_CHECK(otp_en_es_fw_read_pct <= 100);
    `DV_CHECK(otp_en_es_fw_read_inval_pct <= 100);
    `DV_CHECK((otp_en_es_fw_read_pct + otp_en_es_fw_read_inval_pct) <= 100);
    `DV_CHECK(otp_en_es_fw_over_inval_pct <= 100);
    `DV_CHECK((otp_en_es_fw_over_pct + otp_en_es_fw_over_inval_pct) <= 100);
    `DV_CHECK(otp_en_es_fw_over_pct <= 100);
    `DV_CHECK(do_check_ht_diag_pct <= 100);
    `DV_CHECK(induce_targeted_transition_pct <= 100);
  endfunction

  // Some combinations of environment and DUT configurations do not generate seeds. This function
  // helps vseqs identify these inactive configurations to more quickly prompt a reconfiguration
  // to get more coverage in a given run.
  function bit generates_seeds(mubi4_t route_software, mubi4_t entropy_data_reg_enable);
    if (route_software == MuBi4True) begin
      return (otp_en_es_fw_read == MuBi8True) && (entropy_data_reg_enable == MuBi4True);
    end
    return 1;
  endfunction

  // Similar to generates_seeds(), returns true if a configuration should be able to
  // generate observe_data
  function bit generates_observe_data(mubi4_t fw_read_enable);
     return (otp_en_es_fw_over == MuBi8True) && (fw_read_enable == MuBi4True);
  endfunction

  // Provide the HDL path for the entropy_src instance.
  function void set_hdl_path(string hdl_path);
    import dv_base_reg_pkg::bkdr_reg_path_e, dv_base_reg_pkg::BkdrRegPathRtl;

    bkdr_reg_path_e std_kind = BkdrRegPathRtl;

    ral.set_hdl_path_root({hdl_path, ".u_reg"}, std_kind.name());
    ral.set_default_hdl_path(std_kind.name());
  endfunction

endclass
