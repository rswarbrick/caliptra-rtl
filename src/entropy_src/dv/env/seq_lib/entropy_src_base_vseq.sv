// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class entropy_src_base_vseq extends dv_base_vseq #(
    .RAL_T               (entropy_src_uvm::entropy_src),
    .CFG_T               (entropy_src_env_cfg),
    .COV_T               (entropy_src_env_cov),
    .VIRTUAL_SEQUENCER_T (entropy_src_virtual_sequencer)
  );
  `uvm_object_utils(entropy_src_base_vseq)

  rand bit [3:0]                     rng_val;
  rand bit [NumEntropySrcIntr - 1:0] en_intr;
  rand bit  do_check_ht_diag;

  // various knobs to enable certain routines
  bit  do_entropy_src_init = 1'b1;
  bit  do_interrupt        = 1'b1;

  bit init_successful      = 1'b0;

  bit [15:0] path_err_val;

  virtual entropy_src_cov_if   cov_vif;

  // A sequencer for the reset interface.
  //
  // If a sequence will need to inject a reset, this sequencer must be confgured by the test by
  // calling set_reset_sequencer() before running the sequence.
  protected reset_sequencer_t m_reset_sequencer;


  constraint do_check_ht_diag_c {
    do_check_ht_diag dist {
      0 :/ cfg.do_check_ht_diag_pct,
      1 :/ 100 - cfg.do_check_ht_diag_pct
    };
  }

  `uvm_object_new

  task pre_start();
    bit old_do_apply_reset = do_apply_reset;

    cfg.otp_en_es_fw_read_vif.drive(.val(cfg.otp_en_es_fw_read));
    cfg.otp_en_es_fw_over_vif.drive(.val(cfg.otp_en_es_fw_over));

    if (!uvm_config_db#(virtual entropy_src_cov_if)::get
        (null, "*.env" , "entropy_src_cov_if", cov_vif)) begin
      `uvm_fatal(`gfn, $sformatf("Failed to get entropy_src_cov_if from uvm_config_db"))
    end

    // Override do_apply_reset to be false when starting a sequence: the test should have just
    // injected a reset.
    do_apply_reset = 0;

    super.pre_start();

    do_apply_reset = old_do_apply_reset;
  endtask

  // Provide a sequencer that connects to the reset agent.
  function void set_reset_sequencer(reset_sequencer_t sequencer);
    m_reset_sequencer = sequencer;
  endfunction

  virtual task dut_init(string reset_kind = "HARD");
    int regwen;

    super.dut_init(.reset_kind(reset_kind));

    // Don't loop here trying to reconfigure (in case the configuration fails)
    // leave that to any derived tests that allow for configuration failures.
    if (do_entropy_src_init) begin
      entropy_src_init(.newcfg(cfg.dut_cfg), .completed(init_successful), .regwen(regwen));
    end
  endtask

  //
  // Most of the health check diagnostics are hard to read during the normal test.
  //
  // Since there is a delay between when data is received at the RNG interface and when
  // the health check completes, checking these registers during the usual test body can lead
  // to spurious scoreboarding errors.   We let the scoreboard check these all at the end of
  // the test instead.
  //
  task check_ht_diagnostics();
    int val;
    uvm_reg stat_regs[] = '{ral.REPCNT_HI_WATERMARKS, ral.REPCNTS_HI_WATERMARKS,
                            ral.ADAPTP_HI_WATERMARKS, ral.ADAPTP_LO_WATERMARKS,
                            ral.EXTHT_HI_WATERMARKS, ral.EXTHT_LO_WATERMARKS,
                            ral.MARKOV_HI_WATERMARKS, ral.MARKOV_LO_WATERMARKS,
                            ral.MARKOV_HI_TOTAL_FAILS, ral.MARKOV_LO_TOTAL_FAILS,
                            ral.REPCNT_TOTAL_FAILS, ral.REPCNTS_TOTAL_FAILS,
                            ral.ADAPTP_HI_TOTAL_FAILS, ral.ADAPTP_LO_TOTAL_FAILS,
                            ral.BUCKET_HI_WATERMARKS, ral.BUCKET_TOTAL_FAILS,
                            ral.EXTHT_HI_TOTAL_FAILS, ral.EXTHT_LO_TOTAL_FAILS,
                            ral.ALERT_SUMMARY_FAIL_COUNTS,
                            ral.ALERT_FAIL_COUNTS, ral.EXTHT_FAIL_COUNTS};
    foreach (stat_regs[i]) begin
      uvm_status_e txn_status;
      stat_regs[i].mirror(txn_status);

      if (cfg.under_reset) return;
      if (txn_status != UVM_IS_OK) begin
        `uvm_error(get_full_name(), $sformatf("Failed to mirror %0s", stat_regs[i].get_name()))
      end
    end
  endtask

  // A replacement for dv_base_vseq::apply_reset("HARD"). This uses the reset agent to inject the
  // reset a bit more cleanly (and will fail at runtime if the test hasn't provided a reset
  // sequencer).
  protected task apply_hard_dut_reset();
    import reset_agent_pkg::reset_seq;
    reset_seq seq = reset_seq::type_id::create("seq");

    if (m_reset_sequencer == null) begin
      `uvm_fatal(get_full_name(), "Cannot apply reset because m_reset_sequencer is null.")
    end

    // This is constrained so that it doesn't necessarily land on a clock edge, but doesn't take
    // very long. Since we don't know the clock frequency here, let's just pick 1ns as an upper
    // bound: even with a 1GHz clock, that is still only one cycle.
    if (!seq.randomize() with { m_item.m_delay_ps < 1000; }) begin
      `uvm_fatal(get_full_name(), "Failed to randomise reset sequence.")
    end

    // Note that this won't really behave as expected if there is already a sequence running on
    // m_reset_sequencer: this reset will be queued and wait after the one that's currently
    // running.
    seq.start(m_reset_sequencer);    
  endtask

  virtual task apply_reset(string kind = "HARD");
    if (kind == "CSRNG_ONLY") begin
      cfg.csrng_rst_vif.apply_reset();
    end else if (kind == "HARD_DUT_ONLY") begin
      apply_hard_dut_reset();
    end else begin
      fork
        apply_hard_dut_reset();
        cfg.csrng_rst_vif.apply_reset();
      join
    end
  endtask

  virtual task dut_shutdown();
    bit bundles_found;
    // check for pending entropy_src operations and wait for them to complete
    `uvm_info(`gfn, "Shutting down", UVM_LOW)

    `uvm_info(`gfn, "Disabling DUT", UVM_MEDIUM)
    disable_dut();

    `uvm_info(`gfn, "Checking diagnostics", UVM_MEDIUM)
    check_ht_diagnostics();
    `uvm_info(`gfn, "Clearing Alerts", UVM_MEDIUM)
    ral.RECOV_ALERT_STS.ES_MAIN_SM_ALERT.set(1'b0);
    csr_update(.csr(ral.RECOV_ALERT_STS));

    super.dut_shutdown();
  endtask

  // Abstract the method of enabling the dut, to potentially allow for
  // callbacks to be applied in the derived classes
  virtual task enable_dut();
    `uvm_info(`gfn, "Enabling DUT", UVM_MEDIUM)
    csr_wr(.ptr(ral.MODULE_ENABLE.MODULE_ENABLE), .value(prim_mubi_pkg::MuBi4True));
  endtask

  task disable_dut();
    uvm_status_e txn_status;

    ral.MODULE_ENABLE.MODULE_ENABLE.set(MuBi4False);
    ral.MODULE_ENABLE.update(txn_status);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to update MODULE_ENABLE.")

    // Disabling the module will clear the error state,
    // as well as the observe and entropy_data FIFOs
    // Clear all interupts here
    ral.INTERRUPT_STATE.write(txn_status, 32'hf);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to write INTERRUPT_STATE.")

    // Check, but do not clear alert_sts, as the handlers for those conditions may need to see them.
    ral.RECOV_ALERT_STS.mirror(txn_status);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to mirror RECOV_ALERT_STS.")

    `DV_CHECK_MEMBER_RANDOMIZE_FATAL(do_check_ht_diag)
    if (do_check_ht_diag) begin
      // read all health check values
      `uvm_info(`gfn, "Checking_ht_values", UVM_HIGH)
      check_ht_diagnostics();
      `uvm_info(`gfn, "HT value check complete", UVM_HIGH)
    end
  endtask

  // Helper function to entropy_src_init. Tries to apply the new configuration
  // Does not check for invalid MuBi or threshold alert values
  virtual task try_apply_base_configuration(entropy_src_dut_cfg newcfg, realtime pause,
                                            output bit completed);

    completed = 0;

    // Controls
    ral.ENTROPY_CONTROL.ES_TYPE.set(newcfg.type_bypass);
    ral.ENTROPY_CONTROL.ES_ROUTE.set(newcfg.route_software);
    csr_update(.csr(ral.ENTROPY_CONTROL));
    #(pause);

    ral.HEALTH_TEST_WINDOWS.FIPS_WINDOW.set(newcfg.fips_window_size/RNG_BUS_WIDTH);
    ral.HEALTH_TEST_WINDOWS.BYPASS_WINDOW.set(newcfg.bypass_window_size/RNG_BUS_WIDTH);
    csr_update(.csr(ral.HEALTH_TEST_WINDOWS));
    #(pause);

    // Thresholds for the continuous health checks:
    // REPCNT and REPCNTS

    if (!newcfg.default_ht_thresholds) begin
      ral.REPCNT_THRESHOLDS.BYPASS_THRESH.set(newcfg.repcnt_thresh_bypass);
      ral.REPCNT_THRESHOLDS.FIPS_THRESH.set(newcfg.repcnt_thresh_fips);
      csr_update(.csr(ral.REPCNT_THRESHOLDS));

      ral.REPCNTS_THRESHOLDS.BYPASS_THRESH.set(newcfg.repcnts_thresh_bypass);
      ral.REPCNTS_THRESHOLDS.FIPS_THRESH.set(newcfg.repcnts_thresh_fips);
      csr_update(.csr(ral.REPCNTS_THRESHOLDS));
    end
    #(pause);

    // Windowed health test thresholds managed in derived vseq classes

    // FW_OV registers
    ral.FW_OV_CONTROL.FW_OV_MODE.set(newcfg.fw_read_enable);
    ral.FW_OV_CONTROL.FW_OV_ENTROPY_INSERT.set(newcfg.fw_over_enable);
    csr_update(.csr(ral.FW_OV_CONTROL));
    #(pause);

    ral.FW_OV_SHA3_START.FW_OV_INSERT_START.set(newcfg.fw_ov_insert_start);
    csr_update(.csr(ral.FW_OV_SHA3_START));
    #(pause);

    ral.ALERT_THRESHOLD.ALERT_THRESHOLD.set(newcfg.alert_threshold);
    ral.ALERT_THRESHOLD.ALERT_THRESHOLD_INV.set(newcfg.alert_threshold_inv);
    csr_update(.csr(ral.ALERT_THRESHOLD));
    #(pause);

    ral.OBSERVE_FIFO_THRESH.OBSERVE_FIFO_THRESH.set(newcfg.observe_fifo_thresh);
    csr_update(ral.OBSERVE_FIFO_THRESH);
    #(pause);

    ral.CONF.FIPS_ENABLE.set(newcfg.fips_enable);
    ral.CONF.ENTROPY_DATA_REG_ENABLE.set(newcfg.entropy_data_reg_enable);
    ral.CONF.FIPS_FLAG.set(newcfg.fips_flag);
    ral.CONF.RNG_FIPS.set(newcfg.rng_fips);
    ral.CONF.RNG_BIT_ENABLE.set(newcfg.rng_bit_enable);
    ral.CONF.RNG_BIT_SEL.set(newcfg.rng_bit_sel);
    ral.CONF.THRESHOLD_SCOPE.set(newcfg.ht_threshold_scope);
    csr_update(.csr(ral.CONF));
    #(pause);

    // Register write enable lock is on be default
    // Setting this to zero will lock future writes
    csr_wr(.ptr(ral.SW_REGUPD), .value(newcfg.sw_regupd));
    #(pause);

    // Module_enables (should be done last)
    if (newcfg.module_enable == MuBi4True) begin
      // Use the enable method to invoke any callbacks.
      enable_dut();
    end else if (newcfg.module_enable == MuBi4False) begin
      disable_dut();
    end else begin
      // Explicitly write the invalid enable value
      // to the module_enable register.
      ral.MODULE_ENABLE.set(newcfg.module_enable);
      csr_update(.csr(ral.MODULE_ENABLE));
    end
    #(pause);

    ral.ME_REGWEN.set(newcfg.me_regwen);
    csr_update(.csr(ral.ME_REGWEN));
    #(pause);

    if (do_interrupt) begin
      ral.INTERRUPT_ENABLE.set(newcfg.en_intr);
      csr_update(ral.INTERRUPT_ENABLE);
    end

    cfg.clk_rst_vif.wait_clks(2);
    `uvm_info(`gfn, "Configuration Complete", UVM_MEDIUM)

    completed = 1;
  endtask

  // Repeatedly read the given register until its value matches desired_value when both are masked.
  //
  // Exits early on reset.
  protected task masked_spinwait_register(uvm_reg        register,
                                          uvm_reg_data_t desired_value,
                                          uvm_reg_data_t mask);
    forever begin
      uvm_status_e   txn_status;
      uvm_reg_data_t reg_value;

      register.read(txn_status, reg_value);
      if (cfg.under_reset) return;
      if (txn_status != UVM_IS_OK) begin
        `uvm_error(get_full_name(), $sformatf("Failed to read %0s register.", register.get_name()))
      end

      if (~|((reg_value ^ desired_value) & mask)) break;
    end
  endtask

  // Wait until the REGWEN register becomes 1 (meaning that writes are enabled)
  protected task spinwait_regwen();
    masked_spinwait_register(ral.REGWEN, 1, 1);
  endtask

  // Setup basic entropy_src features, halting if a recoverable alert is detected
  //
  // If disable==1, explicitly clear module_enable before configuring
  // to remove the write_lock
  //
  // Outputs REGWEN = 0, if the device coniguration was attempted when most registers
  // were locked. (Likely intentionally)
  virtual task entropy_src_init(entropy_src_dut_cfg newcfg=cfg.dut_cfg,
                                realtime pause=cfg.configuration_pause_time,
                                output bit completed,
                                output bit regwen);
    uvm_status_e txn_status;

    completed = 0;

    if (newcfg.preconfig_disable) begin
      disable_dut();
      `uvm_info(`gfn, "DUT Disabled", UVM_MEDIUM)
      if (ral.SW_REGUPD.SW_REGUPD.get()) begin
        `uvm_info(`gfn, "Waiting for REGWEN", UVM_HIGH)

        spinwait_regwen();
        if (cfg.under_reset) return;

        `uvm_info(`gfn, "REGWEN Detected", UVM_HIGH)
      end
    end

    ral.REGWEN.read(txn_status, regwen);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to read REGWEN.")

    wait_no_outstanding_access();

    `uvm_info(`gfn, "Applying configuration", UVM_MEDIUM)

    try_apply_base_configuration(newcfg, pause, completed);
    if (cfg.under_reset) return;

    if (!completed) begin
      bit [31:0] value;
      `uvm_info(`gfn, "Detected recoverable alert", UVM_LOW)

      `uvm_info(`gfn, "Falling back on safe config", UVM_LOW)

      // Set all fields with redundancy to safe values
      entropy_src_safe_config();
      // Read the alert sts register, let the scoreboard validate the value (if enabled)
      csr_rd(.ptr(ral.RECOV_ALERT_STS), .value(value));
      `uvm_info(`gfn, $sformatf("RECOV_ALERT_STS (pre): %08x", value), UVM_MEDIUM)
      // clear the alert status register.
      csr_wr(.ptr(ral.RECOV_ALERT_STS), .value('h0));
      // Re-read the alert_status register to confirm that it has been cleared.
      csr_rd(.ptr(ral.RECOV_ALERT_STS), .value(value));
      `uvm_info(`gfn, $sformatf("RECOV_ALERT_STS: %08x", value), UVM_MEDIUM)
    end

    `uvm_info(`gfn, $sformatf("Exiting configuration, status %d", completed) , UVM_MEDIUM)

  endtask

  // helper task to clear any invalid configurations
  task entropy_src_safe_config();

    `uvm_info(`gfn, "Moving DUT into a safe configuration", UVM_MEDIUM)
    // explicitly clear module_enable to allow module writes
    disable_dut();

    // Clear all interrupts
    csr_wr(.ptr(ral.INTERRUPT_STATE), .value(32'hf));

    ral.ENTROPY_CONTROL.ES_TYPE.set(MuBi4False);
    ral.ENTROPY_CONTROL.ES_ROUTE.set(MuBi4False);
    csr_update(.csr(ral.ENTROPY_CONTROL));

    ral.CONF.FIPS_ENABLE.set(MuBi4False);
    ral.CONF.ENTROPY_DATA_REG_ENABLE.set(MuBi4False);
    ral.CONF.FIPS_FLAG.set(MuBi4False);
    ral.CONF.RNG_FIPS.set(MuBi4False);
    ral.CONF.RNG_BIT_ENABLE.set(MuBi4False);
    ral.CONF.THRESHOLD_SCOPE.set(MuBi4False);
    csr_update(.csr(ral.CONF));

    ral.FW_OV_CONTROL.FW_OV_MODE.set(MuBi4False);
    ral.FW_OV_CONTROL.FW_OV_ENTROPY_INSERT.set(MuBi4False);
    csr_update(.csr(ral.FW_OV_CONTROL));

    ral.FW_OV_SHA3_START.FW_OV_INSERT_START.set(MuBi4False);
    csr_update(.csr(ral.FW_OV_SHA3_START));

    csr_wr(.ptr(ral.ALERT_THRESHOLD), .value(ral.ALERT_THRESHOLD.get_reset()));

    `uvm_info(`gfn, "Safe configuration", UVM_MEDIUM)

  endtask

  typedef enum int {
    TlSrcEntropyDataReg,
    TlSrcObserveFIFO
  } tl_data_source_e;

  // Poll the relevant interrupt bit for accessing either the ENTROPY_DATA or FW_OV_RD_DATA
  // register
  task poll(tl_data_source_e source = TlSrcEntropyDataReg, int spinwait_delay_ns = 0);

    uvm_reg_field intr_field;

    case (source)
      TlSrcEntropyDataReg: begin
        intr_field = ral.INTERRUPT_STATE.ES_ENTROPY_VALID;
      end
      TlSrcObserveFIFO: begin
        intr_field = ral.INTERRUPT_STATE.ES_OBSERVE_FIFO_READY;
      end
      default: begin
        `uvm_fatal(`gfn, "Invalid source for accessing TL entropy (environment error)")
      end
    endcase

    csr_spinwait(.ptr(intr_field), .exp_data(1'b1), .spinwait_delay_ns(spinwait_delay_ns));
  endtask


  // Read all data in ENTROPY_DATA or FW_OV_RD_DATA up to a certain ammount
  //
  // Data is read in bundles, where the size of a bundle depends on the data
  // source.
  //
  // For the entropy_data register a bundle consists of CSRNG_BUS_WIDTH (=384) bits
  // and this it takes CSRNG_BUS_WIDTH/32 (=12) reads to fetch a whole bundle.
  //
  // When accessing the observe_fifo via the FW_OV_RD_DATA register the bundle size is
  // programmable and set to be equal to the value set in the OBSERVE_FIFO_DEPTH register
  // TODO(#18837): What happens if the depth is zero?
  //
  // a. max_bundles bundles have been read
  // b. The INTERRUPT_STATE register indicates no more data in entropy_data
  //
  // If max_bundles < 0, simply reads all available bundles.
  //
  // If source is TlSrcObserveFIFO and check_overflow is set to 1, this task checks whether
  // overflows occured or not. This is done to make sure that the data read from the observe
  // FIFO is contiguous.
  task do_entropy_data_read(tl_data_source_e source = TlSrcEntropyDataReg,
                            int max_bundles = -1,
                            bit check_overflow = 0,
                            output int bundles_found);
    bit intr_status;
    bit done;
    int cnt_per_interrupt;
    uvm_reg_field intr_field;
    uvm_reg       data_reg;

    bundles_found = 0;

    case (source)
      TlSrcEntropyDataReg: begin
        intr_field        = ral.INTERRUPT_STATE.ES_ENTROPY_VALID;
        data_reg          = ral.ENTROPY_DATA;
        cnt_per_interrupt = entropy_src_pkg::CSRNG_BUS_WIDTH / 32;
      end
      TlSrcObserveFIFO: begin
        intr_field        = ral.INTERRUPT_STATE.ES_OBSERVE_FIFO_READY;
        data_reg          = ral.FW_OV_RD_DATA;
        csr_rd(.ptr(ral.OBSERVE_FIFO_THRESH), .value(cnt_per_interrupt));
      end
      default: begin
        `uvm_fatal(`gfn, "Invalid source for accessing TL entropy (environment error)")
      end
    endcase
    `DV_SPINWAIT(
      do begin
        `uvm_info(`gfn, "READING INTERRUPT STS", UVM_DEBUG)
        csr_rd(.ptr(intr_field), .value(intr_status));
        if (intr_status) begin
          // Check that the Observe FIFO hasn't overflown yet.
          // By checking for overflows before and after reading the observe FIFO we can make sure,
          // that the data we are reading is contiguous.
          if (check_overflow && (source == TlSrcObserveFIFO)) begin
            csr_rd_check(.ptr(ral.FW_OV_RD_FIFO_OVERFLOW.FW_OV_RD_FIFO_OVERFLOW),
                        .compare_value('0));
          end
          // Read and check entropy
          `uvm_info(`gfn, $sformatf("Reading %d words", cnt_per_interrupt), UVM_HIGH)
          for (int i = 0; i < cnt_per_interrupt; i++) begin
            bit [31:0] entropy_tlul;
            csr_rd(.ptr(data_reg), .value(entropy_tlul), .blocking(1'b1));
          end
          if (check_overflow && (source == TlSrcObserveFIFO)) begin
            // Check whether no overflow occured while reading the observe FIFO and we are
            // still reading out contiguous data.
            csr_rd_check(.ptr(ral.FW_OV_RD_FIFO_OVERFLOW.FW_OV_RD_FIFO_OVERFLOW),
                        .compare_value('0));
          end
          // Clear the appropriate interrupt bit
          `uvm_info(`gfn, "CLEARING FIFO INTERRUPT", UVM_DEBUG)
          csr_wr(.ptr(intr_field), .value(1'b1), .blocking(1'b1));
          bundles_found++;
        end
        done = (max_bundles >= 0) && (bundles_found >= max_bundles);
      end while (intr_status && !done);, // do begin
    $sformatf("Timeout encountered while reading %s", source.name()), 250us/1ns)
  endtask

  task run_rng_host_seq(push_pull_host_seq#(entropy_src_pkg::RNG_BUS_WIDTH) m_rng_push_seq);
    for (int i = 0; i < m_rng_push_seq.num_trans; i++) begin
      rng_val =  i % 16;
      cfg.m_rng_agent_cfg.add_h_user_data(rng_val);
    end
    m_rng_push_seq.start(p_sequencer.rng_sequencer_h);
  endtask // run_rng_host_seq

  task repcnt_ht_fail_seq(push_pull_host_seq#(entropy_src_pkg::RNG_BUS_WIDTH) m_rng_push_seq,
                          int num_trans = m_rng_push_seq.num_trans);
    // Set rng_val
    // Use randomly generated but fixed rng_val through the test to cause the repcnt health test
    // to fail
    `DV_CHECK_STD_RANDOMIZE_FATAL(rng_val)
    for (int i = 0; i < num_trans; i++) begin
      cfg.m_rng_agent_cfg.add_h_user_data(rng_val);
    end
  endtask // repcnt_ht_fail_seq

  task adaptp_ht_fail_seq(push_pull_host_seq#(entropy_src_pkg::RNG_BUS_WIDTH) m_rng_push_seq,
                          bit[15:0] fips_lo_thresh, bit[15:0] fips_hi_thresh,
                          bit[15:0] bypass_lo_thresh, bit[15:0] bypass_hi_thresh,
                          int num_trans = m_rng_push_seq.num_trans);
    ral.ADAPTP_HI_THRESHOLDS.FIPS_THRESH.set(fips_hi_thresh);
    ral.ADAPTP_HI_THRESHOLDS.BYPASS_THRESH.set(bypass_hi_thresh);
    csr_update(.csr(ral.ADAPTP_HI_THRESHOLDS));
    ral.ADAPTP_LO_THRESHOLDS.FIPS_THRESH.set(fips_lo_thresh);
    ral.ADAPTP_LO_THRESHOLDS.BYPASS_THRESH.set(bypass_lo_thresh);
    csr_update(.csr(ral.ADAPTP_LO_THRESHOLDS));
    // Turn on module_enable
    enable_dut();
    // Set rng_val
    for (int i = 0; i < num_trans; i++) begin
      rng_val = (i % 16 == 0 ? (cfg.which_ht == high_test ? 0 : 1) :
                               (cfg.which_ht == high_test ? 1 : 0));
      cfg.m_rng_agent_cfg.add_h_user_data(rng_val);
    end
  endtask // adaptp_ht_fail_seq

  task bucket_ht_fail_seq(push_pull_host_seq#(entropy_src_pkg::RNG_BUS_WIDTH) m_rng_push_seq,
                          bit[15:0] fips_thresh, bit[15:0] bypass_thresh,
                          int num_trans = m_rng_push_seq.num_trans);
    ral.BUCKET_THRESHOLDS.FIPS_THRESH.set(fips_thresh);
    ral.BUCKET_THRESHOLDS.BYPASS_THRESH.set(bypass_thresh);
    csr_update(.csr(ral.BUCKET_THRESHOLDS));
    // Turn on module_enable
    enable_dut();
    // Set rng_val
    for (int i = 0; i < num_trans; i++) begin
      rng_val = (i % 2 == 0 ? 5 : 10);
      cfg.m_rng_agent_cfg.add_h_user_data(rng_val);
    end
  endtask // bucket_ht_fail_seq

  task markov_ht_fail_seq(push_pull_host_seq#(entropy_src_pkg::RNG_BUS_WIDTH) m_rng_push_seq,
                          bit[15:0] fips_lo_thresh, bit[15:0] fips_hi_thresh,
                          bit[15:0] bypass_lo_thresh, bit[15:0] bypass_hi_thresh,
                          int num_trans = m_rng_push_seq.num_trans);
    ral.MARKOV_HI_THRESHOLDS.FIPS_THRESH.set(fips_hi_thresh);
    ral.MARKOV_HI_THRESHOLDS.BYPASS_THRESH.set(bypass_hi_thresh);
    csr_update(.csr(ral.MARKOV_HI_THRESHOLDS));
    ral.MARKOV_LO_THRESHOLDS.FIPS_THRESH.set(fips_lo_thresh);
    ral.MARKOV_LO_THRESHOLDS.BYPASS_THRESH.set(bypass_lo_thresh);
    csr_update(.csr(ral.MARKOV_LO_THRESHOLDS));
    // Turn on module_enable
    enable_dut();
    // Set rng_val
    for (int i = 0; i < num_trans; i++) begin
      rng_val = (i % 2 == 0 ? (cfg.which_ht == high_test ? 0 : 1) :
                              (cfg.which_ht == high_test ? 1 : 0));
      cfg.m_rng_agent_cfg.add_h_user_data(rng_val);
    end
  endtask // markov_ht_fail_seq

  task force_fifo_err(string path1, string path2, bit value1, bit value2,
                      uvm_reg_field reg_field, bit exp_data);
    if (!uvm_hdl_check_path(path1)) begin
      `uvm_fatal(`gfn, $sformatf("\n\t ----| PATH NOT FOUND"))
    end else begin
      `DV_CHECK(uvm_hdl_force(path1, value1));
    end
    if (!uvm_hdl_check_path(path2)) begin
      `uvm_fatal(`gfn, $sformatf("\n\t ----| PATH NOT FOUND"))
    end else begin
      `DV_CHECK(uvm_hdl_force(path2, value2));
    end
    cfg.clk_rst_vif.wait_clks(50);
    // Check register value
    csr_spinwait(.ptr(reg_field), .exp_data(exp_data));
    `DV_CHECK(uvm_hdl_release(path1));
    `DV_CHECK(uvm_hdl_release(path2));
  endtask // force_fifo_err

  task force_fifo_err_exception(string paths [4], bit values [4],
                                uvm_reg_field reg_field, bit exp_data);
    string data_path = "tb.dut.u_entropy_src_core.sfifo_esrng_rdata";
    foreach (paths[i]) begin
      if (!uvm_hdl_check_path(paths[i])) begin
        `uvm_fatal(`gfn, $sformatf("\n\t ----| PATH NOT FOUND"))
      end else begin
        `DV_CHECK(uvm_hdl_force(paths[i], values[i]));
      end
    end
    if (!uvm_hdl_check_path(data_path)) begin
      `uvm_fatal(`gfn, $sformatf("\n\t ----| PATH NOT FOUND"))
    end else begin
      `DV_CHECK(uvm_hdl_force(data_path, '0));
    end
    cfg.clk_rst_vif.wait_clks(50);
    // Check register value
    csr_spinwait(.ptr(reg_field), .exp_data(exp_data));
    foreach (paths[i]) begin
      `DV_CHECK(uvm_hdl_release(paths[i]));
    end
  endtask // force_fifo_err_exception

  task force_path_err(string path, bit [15:0] value, uvm_reg_field reg_field, bit exp_data);
    if (!uvm_hdl_check_path(path)) begin
      `uvm_fatal(`gfn, $sformatf("\n\t ----| PATH NOT FOUND"))
    end else begin
      `DV_CHECK(uvm_hdl_force(path, value));
      cfg.clk_rst_vif.wait_clks(50);
      `DV_CHECK(uvm_hdl_release(path));
      cfg.clk_rst_vif.wait_clks(50);
      // Check err_code register
      csr_rd_check(.ptr(reg_field), .compare_value(exp_data));
    end
  endtask // force_path_err

  task window_cntr_err_test(uvm_reg_field reg_field);
    string path = cfg.entropy_src_path_vif.cntr_err_path("window", cfg.which_cntr_replicate);
    `DV_CHECK_STD_RANDOMIZE_FATAL(path_err_val)
    // Force the path (cnt_q[1]) to stuck at a different value from cnt_q[0] to trigger
    // the counter error
    force_path_err(path, path_err_val, reg_field, 1'b1);
  endtask // window_cntr_err_test

  task repcnt_ht_cntr_test(push_pull_host_seq#(entropy_src_pkg::RNG_BUS_WIDTH) m_rng_push_seq,
                           uvm_reg_field reg_field);
    string path;
    `DV_CHECK_STD_RANDOMIZE_FATAL(path_err_val)
    // Set a low threshold to introduce ht fails
    ral.REPCNT_THRESHOLDS.FIPS_THRESH.set(16'h0008);
    ral.REPCNT_THRESHOLDS.BYPASS_THRESH.set(16'h0008);
    csr_update(.csr(ral.REPCNT_THRESHOLDS));
    repcnt_ht_fail_seq(m_rng_push_seq);
    m_rng_push_seq.start(p_sequencer.rng_sequencer_h);
    cfg.clk_rst_vif.wait_clks(100);
    // Force repcnt ht counter err
    path = cfg.entropy_src_path_vif.cntr_err_path("repcnt_ht", cfg.which_cntr_replicate);
    // Force the path (cnt_q[1]) to stuck at a different value from cnt_q[0] to trigger
    // the counter error
    force_path_err(path, path_err_val, reg_field, 1'b1);
    // Write the threshold back to a high value
    ral.REPCNT_THRESHOLDS.FIPS_THRESH.set(16'hfffe);
    ral.REPCNT_THRESHOLDS.BYPASS_THRESH.set(16'hfffe);
    csr_update(.csr(ral.REPCNT_THRESHOLDS));
  endtask // repcnt_ht_cntr_test

  task repcnts_ht_cntr_test(push_pull_host_seq#(entropy_src_pkg::RNG_BUS_WIDTH) m_rng_push_seq,
                            uvm_reg_field reg_field);
    string path;
    `DV_CHECK_STD_RANDOMIZE_FATAL(path_err_val)
    // Set a low threshold to introduce ht fails
    ral.REPCNTS_THRESHOLDS.FIPS_THRESH.set(16'h0008);
    ral.REPCNTS_THRESHOLDS.BYPASS_THRESH.set(16'h0008);
    csr_update(.csr(ral.REPCNTS_THRESHOLDS));
    repcnt_ht_fail_seq(m_rng_push_seq);
    m_rng_push_seq.start(p_sequencer.rng_sequencer_h);
    cfg.clk_rst_vif.wait_clks(100);
    // Force repcnts ht counter err
    path = cfg.entropy_src_path_vif.cntr_err_path("repcnts_ht", cfg.which_cntr_replicate);
    // Force the path (cnt_q[1]) to stuck at a different value from cnt_q[0] to trigger
    // the counter error
    force_path_err(path, path_err_val, reg_field, 1'b1);
    // Write the threshold back to a high value
    ral.REPCNTS_THRESHOLDS.FIPS_THRESH.set(16'hfffe);
    ral.REPCNTS_THRESHOLDS.BYPASS_THRESH.set(16'hfffe);
    csr_update(.csr(ral.REPCNTS_THRESHOLDS));
  endtask // repcnts_ht_cntr_test

  task adaptp_ht_cntr_test(push_pull_host_seq#(entropy_src_pkg::RNG_BUS_WIDTH) m_rng_push_seq,
                           uvm_reg_field reg_field);
    string path;
    bit [15:0] fips_thresh = 16'h0008;
    bit [15:0] bypass_thresh = 16'h0008;
    `DV_CHECK_STD_RANDOMIZE_FATAL(path_err_val)
    adaptp_ht_fail_seq(m_rng_push_seq, fips_thresh, fips_thresh, bypass_thresh, bypass_thresh);
    // Start the sequence
    m_rng_push_seq.start(p_sequencer.rng_sequencer_h);
    cfg.clk_rst_vif.wait_clks(100);
    // Force adaptp ht counter err
    path = cfg.entropy_src_path_vif.cntr_err_path("adaptp_ht", cfg.which_cntr_replicate);
    // Force the path (cnt_q[1]) to stuck at a different value from cnt_q[0] to trigger
    // the counter error
    force_path_err(path, path_err_val, reg_field, 1'b1);
    // Write the threshold back to a high value
    ral.ADAPTP_HI_THRESHOLDS.FIPS_THRESH.set(16'hfffe);
    ral.ADAPTP_HI_THRESHOLDS.BYPASS_THRESH.set(16'hfffe);
    csr_update(.csr(ral.ADAPTP_HI_THRESHOLDS));
    ral.ADAPTP_LO_THRESHOLDS.FIPS_THRESH.set(16'hfffe);
    ral.ADAPTP_LO_THRESHOLDS.BYPASS_THRESH.set(16'hfffe);
    csr_update(.csr(ral.ADAPTP_LO_THRESHOLDS));
  endtask // adaptp_ht_cntr_test

  task bucket_ht_cntr_test(push_pull_host_seq#(entropy_src_pkg::RNG_BUS_WIDTH) m_rng_push_seq,
                           uvm_reg_field reg_field);
    string path;
    bit [15:0] fips_thresh = 16'h0008;
    bit [15:0] bypass_thresh = 16'h0008;
    `DV_CHECK_STD_RANDOMIZE_FATAL(path_err_val)
    fips_thresh = 16'h0008;
    bypass_thresh = 16'h0008;
    bucket_ht_fail_seq(m_rng_push_seq, fips_thresh, bypass_thresh);
    m_rng_push_seq.start(p_sequencer.rng_sequencer_h);
    cfg.clk_rst_vif.wait_clks(100);
    // Force bucket ht counter err
    path = cfg.entropy_src_path_vif.cntr_err_path("bucket_ht", cfg.which_bin);
    // Force the path (cnt_q[1]) to stuck at a different value from cnt_q[0] to trigger
    // the counter error
    force_path_err(path, path_err_val, reg_field, 1'b1);
    // Write the threshold back to a high value
    ral.BUCKET_THRESHOLDS.FIPS_THRESH.set(16'hfffe);
    ral.BUCKET_THRESHOLDS.BYPASS_THRESH.set(16'hfffe);
    csr_update(.csr(ral.BUCKET_THRESHOLDS));
  endtask // bucket_ht_cntr_test

  task markov_ht_cntr_test(push_pull_host_seq#(entropy_src_pkg::RNG_BUS_WIDTH) m_rng_push_seq,
                           uvm_reg_field reg_field);
    string path;
    bit [15:0] fips_thresh = 16'h0008;
    bit [15:0] bypass_thresh = 16'h0008;
    `DV_CHECK_STD_RANDOMIZE_FATAL(path_err_val)

    fips_thresh = 16'h0008;
    bypass_thresh = 16'h0008;
    markov_ht_fail_seq(m_rng_push_seq, fips_thresh, fips_thresh, bypass_thresh, bypass_thresh);
    // Start the sequence
    m_rng_push_seq.start(p_sequencer.rng_sequencer_h);
    cfg.clk_rst_vif.wait_clks(100);
    // Force markov ht counter err
    path = cfg.entropy_src_path_vif.cntr_err_path("markov_ht", cfg.which_cntr_replicate);
    // Force the path (cnt_q[1]) to stuck at a different value from cnt_q[0] to trigger
    // the counter error
    force_path_err(path, path_err_val, reg_field, 1'b1);
    // Write the threshold back to a high value
    ral.MARKOV_HI_THRESHOLDS.FIPS_THRESH.set(16'hfffe);
    ral.MARKOV_HI_THRESHOLDS.BYPASS_THRESH.set(16'hfffe);
    csr_update(.csr(ral.MARKOV_HI_THRESHOLDS));
    ral.MARKOV_LO_THRESHOLDS.FIPS_THRESH.set(16'hfffe);
    ral.MARKOV_LO_THRESHOLDS.BYPASS_THRESH.set(16'hfffe);
    csr_update(.csr(ral.MARKOV_LO_THRESHOLDS));
  endtask // markov_ht_cntr_test

  // Find the first or last index in the original string that the target character appears
  function automatic int find_index (string target, string original_str, string which_index);
    int        index;
    case (which_index)
      "first": begin
        for (int i = original_str.len(); i > 0; i--) begin
          if (original_str[i] == target) index = i;
        end
      end
      "last": begin
        for (int i = 0; i < original_str.len(); i++) begin
          if (original_str[i] == target) index = i;
        end
      end
      default: begin
        `uvm_fatal(`gfn, "Invalid index!")
      end
    endcase // case (which_index)
    return index;
  endfunction // find_index

  // Check that the selected interrupts have the expected values, possibly clearing them afterwards.
  //
  // Note that this does *not* check any interrupt pins: in caliptra-rtl, the entropy_src block is
  // only used for its interrupt register state.
  //
  //  interrupts    A bit mask of interrupts (in the format of INTERRUPT_ENABLE) which specifies the
  //                interrupts that should be checked by the function.
  //
  //  check_set     If this is false, the task checks that all of the interrupts are low. If it
  //                is true, the task checks that the interrupts are low exactly when they are
  //                enabled. In either case, this check is done by looking at intr_vif and also
  //                doing a front-door read of INTERRUPT_STATE.
  //
  //  clear         If true and any interrupts have been asserted then write to INTERRUPT_STATE to
  //                clear those interrupts.
  protected task check_interrupts(bit [31:0] interrupts,
                                  bit        check_set,
                                  bit [31:0] clear = '1);
    uvm_reg    csr_intr_state, csr_intr_enable;
    bit [31:0] exp_intr_state;

    if (cfg.under_reset) return;

    if (check_set) begin
      csr_intr_enable = ral.get_dv_base_reg_by_name("INTERRUPT_ENABLE");
      exp_intr_state = interrupts;
    end else begin
      exp_intr_state = ~interrupts;
    end

    csr_intr_state = ral.get_dv_base_reg_by_name("INTERRUPT_STATE");
    csr_rd_check(.ptr(csr_intr_state), .compare_value(exp_intr_state), .compare_mask(interrupts));

    if (check_set && |(interrupts & clear)) begin
      csr_wr(.ptr(csr_intr_state), .value(interrupts & clear));
    end
  endtask

endclass : entropy_src_base_vseq
