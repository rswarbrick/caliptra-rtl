// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class entropy_src_scoreboard extends dv_base_scoreboard#(
    .CFG_T(entropy_src_env_cfg),
    .RAL_T(entropy_src_uvm::entropy_src),
    .COV_T(entropy_src_env_cov)
  );

  `uvm_component_utils(entropy_src_scoreboard)

  // An import for AHB transactions.
  uvm_analysis_imp_ahb_txn #(ahb_txn_item, entropy_src_scoreboard) m_ahb_txn_imp;

  // The width of addresses on the monitored AHB interface. This defaults to 64 (full width), but
  // will be configured with a smaller value by the environment to match the size of the actual
  // interface.
  //
  // Monitored AHB transactions (that arrive through m_ahb_txn_imp) will have just that many of the
  // bottom bits of the address. As such, the register block's base address needs truncating in the
  // same way to allow register lookups by address.
  int unsigned m_ahb_addr_width = 64;

  // TODO (Cleanup): Put the DUT-internal constant (`PreCondWidth`) into a package and use it here.
  localparam int SHACondWidth     = 64;
  localparam int ObserveFifoDepth = entropy_src_reg_pkg::ObserveFifoDepth;

  virtual entropy_src_cov_if cov_vif;

  // used by health_test_scoring_thread to predict the FSMs phase
  // when constructing seeds
  int seed_idx             = 0;
  // number of seeds output since enable (or reset)
  int seeds_out            = 0;

  int entropy_data_seeds    = 0;
  int entropy_data_drops    = 0;
  int csrng_seeds           = 0;
  int csrng_drops           = 0;
  int observe_fifo_words    = 0;
  int observe_fifo_drops    = 0;
  bit observe_fifo_overflow = 0;
  int overflow_read_cnt     = 0;

  bit dut_pipeline_enabled = 0;
  bit regwen_pending = 0;
  bit ht_fips_mode = 0;

  // The FW_OV pipeline is controlled by two variables: SHA3_START and MODULE_ENABLE
  // The MODULE_ENABLE signal has different delays when shutting down the FW_OV pipeline
  // so we track it in a separate variable for fw_ov
  bit fw_ov_sha_enabled    = 0;
  bit fw_ov_pipe_enabled   = 0;

  // This scoreboard is not capable of anticipating with single-cycle accuracy whether the observe
  // and entropy data FIFOs are empty.  However, we can note when they have been explicitly cleared
  // and use that to anticipate any alerts that may come about background diable events
  bit fifos_cleared = 1;

  // Queue of RNG data for health testing
  queue_of_rng_val_t               health_test_data_q;

  // Queue of seeds for predicting reads to entropy_data CSR
  bit [CSRNG_BUS_WIDTH - 1:0]      entropy_data_q[$];

  // Queue of 32-bit words for predicting outputs of the observe FIFO
  bit [31:0]                repacked_entropy_release_q[$];
  bit [31:0]                observe_fifo_q[$];
  bit                       overflow_condition = 0;
  bit                       observe_read_incoming = 0;
  bit [31:0]                fw_ov_wr_fifo_full_prediction = '0;
  bit                       precon_fifo_full = 0;
  bit                       precon_fifo_full_q = 0;

  // Queue of 64-bit words for inserting entropy input to the SHA (or raw) pipelines
  bit [SHACondWidth - 1:0]         sha_process_q[$];
  bit [SHACondWidth - 1:0]         raw_process_q[$];

  // Buffer to store SHA entropy when using FW_OV mode
  bit [SHACondWidth - 1:0]         repacked_entropy_fw_ov;
  int                              repack_idx_fw_ov = 0;

  // The most recent candidate seed from entropy_data_q
  // At each TL read the TL data item is compared to the appropriate
  // 32-bit segment of this seed (as determented by seed_tl_read_cnt)
  bit [CSRNG_BUS_WIDTH - 1:0]      tl_best_seed_candidate;

  // The previous output seed (+ fips bit)  We need to track this to determine whether to expect
  // the bus_cmp recov_alert
  bit [CSRNG_BUS_WIDTH : 0]        prev_csrng_seed;

  // Number of 32-bit TL reads to the current (active) seed
  // Ranges from 0 (no data read out) to CSRNG_BUS_WIDTH/32 (seed fully read out)
  int                              seed_tl_read_cnt = 0;

  bit [FIPS_CSRNG_BUS_WIDTH - 1:0] fips_csrng_q[$];

  // TODO: Document Initial Conditions for health check.
  // This should make no practical difference, but it is important for successful verification.
  rng_val_t                        prev_rng_val = '0;
  int                              repcnt      [RNG_BUS_WIDTH];
  int                              repcnt_symbol;

  // Total number of repcnt OR repcnts failures for a particular sample.
  // Some care is required in counting total failures as different
  // types of failures happening in the same sample only get counted once.
  int                              continuous_fail_count;
  bit                              cont_fail_in_last_sample;

  // Predicted value of internal repetition counters.
  bit [15:0] repcnt_event_cnt;
  bit [15:0] repcnts_event_cnt;

  // Ext. HT counters.
  // Like the continuous tests, these failures can in principle happen many times
  // per window, however only one failure per window gets registered toward the
  // total alert count.
  int                              extht_fail_count;
  int                              extht_fail_in_last_sample;

  bit threshold_alert_active = 1'b0;

  // Signal to indicate that the main sm is going into the error state
  bit main_sm_escalates = 0;

  // Bit to signify that the module_enable bit is locked
  bit dut_me_reglocked = 1'b0;

  // TLM agent fifos
  uvm_tlm_analysis_fifo#(push_pull_item#(.HostDataWidth(FIPS_CSRNG_BUS_WIDTH)))
      csrng_fifo;
  uvm_tlm_analysis_fifo#(push_pull_item#(.HostDataWidth(RNG_BUS_WIDTH)))
      rng_fifo;

  // Interrupt Management Variables

  // To track interrupt events we need to identify interupts have
  // been previously observed to be high.
  //
  // An interrupt that was previously high is ignored until
  // it is observed to be high again.
  //
  // Interrupts go high when a new interrupt is observed
  // Interrupts should go low when an interrupt is cleared
  bit [NumEntropySrcIntr - 1:0] known_intr_state = '0;

  bit [NumEntropySrcIntr - 1:0] intr_en_mask = '0;
  bit [NumEntropySrcIntr - 1:0] intr_test = '0;
  bit                           intr_test_active = '0;

  // Indicates that the observe fifo should have data in it.
  // Switches to OBSERVE_FIFO_THRESHOLD when:
  //   A. A new observe fifo interrupt has been received.
  //   B. The interrupt has been cleared, but it persists a cycle later.
  // Decrements by one when the fifo is read.
  // Is cleared on Reset, or Disable, (stays cleared until enable)
  int expected_obsfifo_entries_since_last_intr  = 0;

  // Signal to communicate that TL data has inserted into the FW_OV FIFO at an invalid time.
  // The DUT ignores such inputs and raises an alert.  However in the interest of testing the
  // response to the DUT to all the _ data that comes in, we mimic the DUT and ignore
  // these data points once we notice one of these events.
  bit ignore_fw_ov_data_pulse = 0;

  // Variables used to predict the observe FIFO depth.
  bit observe_push_busy_addr_phase = 0;
  bit observe_push_busy = 0;

  // Variables used to predict whether the precon FIFO is full or not.
  int precon_fifo_cnt = 0;
  bit sha3_msg_ready = 0;
  bit predict_fw_ov_wr_fifo_full = 0;
  string pad_st_path = "tb.dut.u_entropy_src_core.u_sha3.u_pad.st[6:0]";
  string pad_st_d_path = "tb.dut.u_entropy_src_core.u_sha3.u_pad.st_d[6:0]";
  string aes_halt_o_path = "tb.dut.cs_aes_halt_o";

  // This enum type contains the states used for the FSM in sha3pad.sv.
  localparam int StateWidthPad = 7;
  typedef enum logic [StateWidthPad-1:0] {
    StPadIdle = 7'b1000010,
    StPrefix = 7'b0111100,
    StPrefixWait =7'b1001100,
    StMessage = 7'b0100101,
    StMessageWait = 7'b0001111,
    StPad = 7'b1111010,
    StPadRun = 7'b0011001,
    StPad01 = 7'b1101001,
    StPadFlush = 7'b1010111,
    StTerminalError = 7'b0110011
  } pad_st_e;

  // Enabling, disabling and reset all have some effect in clearing the state of the DUT
  // Due to subleties in timing, the DUT resets the Observe FIFO with a unique delay
  typedef enum int {
    HardReset,
    Disable,
    Enable,
    FIFOClr,
    FWOVDisable
  } reset_event_e;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    m_ahb_txn_imp = new("m_ahb_txn_imp", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    rng_fifo   = new("rng_fifo", this);
    csrng_fifo = new("csrng_fifo", this);

    if (!uvm_config_db#(virtual entropy_src_cov_if)::get
       (null, "*.env" , "entropy_src_cov_if", cov_vif)) begin
       `uvm_fatal(`gfn, $sformatf("Failed to get entropy_src_cov_if from uvm_config_db"))
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    // When seeing unexpected alerts during debugging, disable the alert checking.
    //do_alert_check = 0;
    super.run_phase(phase);
    if (cfg.en_scb) begin
      fork
        process_csrng();
        process_fifo_exceptions();
        health_test_scoring_thread();
        predict_fw_ov_wr_full();
      join_none
    end
  endtask

  // Post simulation statistics reporting
  function void report_phase(uvm_phase phase);
    string fmt, msg;

    fmt = "Seeds read from entropy_data:               %0d";
    msg = $sformatf(fmt, entropy_data_seeds);
    `uvm_info(`gfn, msg, UVM_LOW)

    fmt = "Seeds assumed dropped from entropy_data:    %0d";
    msg = $sformatf(fmt, entropy_data_drops);
    `uvm_info(`gfn, msg, UVM_LOW)

    fmt = "Seeds read from csrng interface:            %0d";
    msg = $sformatf(fmt, csrng_seeds);
    `uvm_info(`gfn, msg, UVM_LOW)

    fmt = "Seeds assumed dropped from csrng interface: %0d";
    msg = $sformatf(fmt, csrng_drops);
    `uvm_info(`gfn, msg, UVM_LOW)

    fmt = "Words read from observe fifo:               %0d";
    msg = $sformatf(fmt, observe_fifo_words);
    `uvm_info(`gfn, msg, UVM_LOW)

    fmt = "Words assumed dropped from observe fifo:    %0d";
    msg = $sformatf(fmt, observe_fifo_drops);
    `uvm_info(`gfn, msg, UVM_LOW)
  endfunction

  //
  // Health check test routines
  //

  function void update_repcnts(bit fips_mode, rng_val_t rng_val);
    int           max_repcnt = 0;
    bit           repcnt_fail, repcnt_sym_fail;
    uvm_reg_field alert_summary_field = ral.ALERT_SUMMARY_FAIL_COUNTS.ANY_FAIL_COUNT;
    int           any_fail_count_regval;
    string        fmt;
    bit           rng_bit_en = (`gmv(ral.CONF.RNG_BIT_ENABLE) == MuBi4True);
    int           rng_bit_sel = `gmv(ral.CONF.RNG_BIT_SEL);

    for (int i = 0; i < RNG_BUS_WIDTH; i++) begin
      if (rng_val[i] == prev_rng_val[i]) begin
        repcnt[i]++;
      end else begin
        repcnt[i] = 1;
      end
      max_repcnt = (repcnt[i] > max_repcnt) ? repcnt[i] : max_repcnt;
    end
    // Overwrite max_repcnt with the value of the selected lane if the single lane mode is active.
    if (rng_bit_en) begin
      max_repcnt = repcnt[rng_bit_sel];
    end
    `uvm_info(`gfn, $sformatf("max repcnt %0h", max_repcnt), UVM_DEBUG)
    repcnt_fail = evaluate_repcnt_test(fips_mode, max_repcnt);

    if (rng_val == prev_rng_val) begin
      repcnt_symbol++;
    end else begin
      repcnt_symbol = 1;
    end
    repcnt_sym_fail = evaluate_repcnt_symbol_test(fips_mode, repcnt_symbol);

    cont_fail_in_last_sample = repcnt_fail | repcnt_sym_fail;
    continuous_fail_count += cont_fail_in_last_sample;

    any_fail_count_regval = `gmv(alert_summary_field);
    any_fail_count_regval += cont_fail_in_last_sample;
    `DV_CHECK_FATAL(alert_summary_field.predict(.value(any_fail_count_regval),
                                                .kind(UVM_PREDICT_DIRECT)))

    if(cont_fail_in_last_sample) begin
      fmt = "Predicted alert cnt for all tests: %04h";
      `uvm_info(`gfn, $sformatf(fmt, any_fail_count_regval), UVM_HIGH)
    end

    prev_rng_val = rng_val;
  endfunction

  function int calc_adaptp_test(queue_of_rng_val_t window, output int maxval, output int minval);
    int test_cnt[RNG_BUS_WIDTH];
    int minq[$], maxq[$];
    int result = '0;
    bit rng_bit_en = (`gmv(ral.CONF.RNG_BIT_ENABLE) == MuBi4True);
    int rng_bit_sel = `gmv(ral.CONF.RNG_BIT_SEL);
    for (int i = 0; i < window.size(); i++) begin
      for (int j = 0; j < RNG_BUS_WIDTH; j++) begin
         test_cnt[j] += window[i][j];
      end
    end
    // If the single lane mode is active set the min the max and the return value
    // to the test_cnt of the selected lane.
    if (rng_bit_en) begin
      maxval = test_cnt[rng_bit_sel];
      minval = test_cnt[rng_bit_sel];
      return test_cnt[rng_bit_sel];
    end else begin
      maxq = test_cnt.max();
      maxval = maxq[0];
      minq = test_cnt.min();
      minval = minq[0];
      return test_cnt.sum();
    end
  endfunction

  function int calc_bucket_test(queue_of_rng_val_t window);
    int bin_count = (1 << RNG_BUS_WIDTH);
    int result[$];

    int buckets [] = new [bin_count];

    for (int i = 0; i < window.size(); i++) begin
      int elem = window[i];
      buckets[elem]++;
    end

    for (int i = 0; i < bin_count; i++) begin
      `uvm_info(`gfn, $sformatf("Bucket test. bin: %01h, value: %02h", i, buckets[i]), UVM_DEBUG)
    end

    result = buckets.max();

    `uvm_info(`gfn, $sformatf("Bucket test. max value: %02h", result[0]), UVM_FULL)

    return result[0];
  endfunction

  function int calc_markov_test(queue_of_rng_val_t window, output int maxval, output int minval);
    int pair_cnt[RNG_BUS_WIDTH];
    int minq[$], maxq[$];
    bit rng_bit_en = (`gmv(ral.CONF.RNG_BIT_ENABLE) == MuBi4True);
    int rng_bit_sel = `gmv(ral.CONF.RNG_BIT_SEL);
    for (int i = 0; i < window.size(); i += 2) begin
      for (int j = 0; j < RNG_BUS_WIDTH; j++) begin
        bit different = window[i][j] ^ window[i + 1][j];
        pair_cnt[j] += different;
      end
    end
    // If the single lane mode is active set the min the max and the return value
    // to the pair_cnt of the selected lane.
    if (rng_bit_en) begin
      maxval = pair_cnt[rng_bit_sel];
      minval = pair_cnt[rng_bit_sel];
      return pair_cnt[rng_bit_sel];
    end else begin
      maxq = pair_cnt.max();
      maxval = maxq[0];
      minq = pair_cnt.min();
      minval = minq[0];
      return pair_cnt.sum();
    end
  endfunction

  function int calc_extht_test(queue_of_rng_val_t window);
    // TODO(#16276)
    int result = 0;
    return result;
  endfunction

  //
  // Debug tool: make sure that the following helper functions use proper names for health checks.
  //
  function void validate_test_name(string name);
    bit is_valid;
    is_valid = (name == "adaptp_hi") ||
               (name == "adaptp_lo") ||
               (name == "bucket"   ) ||
               (name == "markov_hi") ||
               (name == "markov_lo") ||
               (name == "extht_hi" ) ||
               (name == "extht_lo" ) ||
               (name == "repcnt"   ) ||
               (name == "repcnts"  );
    `DV_CHECK_EQ(is_valid, 1, $sformatf("invalid test name: %s\n", name))
  endfunction

  function bit is_low_test(string name);
    int len = name.len();
    return (name.substr(len - 3, len - 1) == "_lo");
  endfunction

  // Operate on the watermark for a given test, using the mirrored copy of the corresponding
  // watermark register.
  //
  // If the value exceeds (or is less then) the latest watermark value, then update the prediction.
  //
  // Implements predictions for all registers named <test>_watermarks.
  function void update_watermark(string test, bit fips_mode, int value);
    string        watermark_field_name;
    string        watermark_reg_name;
    uvm_reg       watermark_reg;
    uvm_reg_field watermark_field;
    int           watermark_val;
    bit           low_test;
    string        fmt;

    validate_test_name(test);

    // The watermark registers for repcnt, repcnts and bucket tests deviate from the
    // general convention of suppressing the "_hi" suffix for tests that do not have a low
    // threshold.
    if ((test == "repcnt") || (test == "repcnts") || (test == "bucket")) begin
      test = {test, "_hi"};
    end

    watermark_field_name = fips_mode ? "fips_watermark" : "bypass_watermark";
    watermark_reg_name   = $sformatf("%s_watermarks", test);
    watermark_reg        = ral.get_reg_by_name(watermark_reg_name);
    watermark_field      = watermark_reg.get_field_by_name(watermark_field_name);
    watermark_val        = watermark_field.get_mirrored_value();
    low_test             = is_low_test(test);

    if (low_test) begin : low_watermark_check
      if (value < watermark_val) begin
        fmt = "Predicted LO watermark for \"%s\" test (FIPS? %d): %04h";
        `uvm_info(`gfn, $sformatf(fmt, test, fips_mode, value), UVM_HIGH)
        `DV_CHECK_FATAL(watermark_field.predict(.value(value), .kind(UVM_PREDICT_READ)))
      end else begin
        fmt = "LO watermark unchanged for \"%s\" test (FIPS? %d): %04h";
        `uvm_info(`gfn, $sformatf(fmt, test, fips_mode, watermark_val), UVM_HIGH)
      end
    end else begin : high_watermark_check
      // Update predicted value of internal repetition counter even if the watermark does not
      // increase.
      if (test == "repcnt_hi") begin
        repcnt_event_cnt = value;
      end else if (test == "repcnts_hi") begin
        repcnts_event_cnt = value;
      end
      // Update predicted watermark value if appropriate.
      if (value > watermark_val) begin
        string fmt;
        fmt = "Predicted HI watermark for \"%s\" test (FIPS? %d): %04h";
        `uvm_info(`gfn, $sformatf(fmt, test, fips_mode, value), UVM_HIGH)
        `DV_CHECK_FATAL(watermark_field.predict(.value(value), .kind(UVM_PREDICT_READ)))
      end else begin
        fmt = "HI watermark unchanged for \"%s\" test (FIPS? %d): %04h";
        `uvm_info(`gfn, $sformatf(fmt, test, fips_mode, watermark_val), UVM_HIGH)
      end
    end : high_watermark_check

  endfunction

  // Compare a particular health check value against the corresponding thresholds.
  // If the health check fails, log the failure and update our predictions for the alert registers.
  //
  // Implements predictions for all registers named:
  // <test>_total_fails
  // alert_fail_counts.<test>_fail_count
  // extht_fail_counts.<test>_fail_count
  //
  // Because failing multiple tests for a single test only count as one total alert failure
  // this routine does not update alert_summary_fail_counts
  //

  function void predict_failure_logs(string test);
    string        total_fail_reg_name;
    string        total_fail_field_name;
    string        alert_cnt_reg_name;
    string        alert_cnt_field_name;
    uvm_reg       total_fail_reg;
    uvm_reg       alert_cnt_reg;
    uvm_reg_field total_fail_field;
    uvm_reg_field alert_cnt_field;

    bit [3:0]     alert_cnt;
    int           fail_total;

    string        fmt, msg;

    validate_test_name(test);
    total_fail_reg_name = $sformatf("%s_total_fails", test);
    total_fail_field_name = total_fail_reg_name;

    // Most tests have field in the alert_fail_counts register, except extht_fail_counts
    if (test.substr(0, 5) == "extht_") begin
      alert_cnt_reg_name = "extht_fail_counts";
    end else begin
      alert_cnt_reg_name = "alert_fail_counts";
    end
    alert_cnt_field_name = $sformatf("%s_fail_count", test);

    total_fail_reg   = ral.get_reg_by_name(total_fail_reg_name);
    total_fail_field = total_fail_reg.get_field_by_name(total_fail_field_name);

    alert_cnt_reg    = ral.get_reg_by_name(alert_cnt_reg_name);
    alert_cnt_field  = alert_cnt_reg.get_field_by_name(alert_cnt_field_name);

    fail_total = total_fail_field.get_mirrored_value();
    alert_cnt  =  alert_cnt_field.get_mirrored_value();

    // Update the predicted failure counters, noting that the DUT will not let these overflow
    alert_cnt  += (&alert_cnt)  ? 0 : 1;
    fail_total += (&fail_total) ? 0 : 1;

    fmt = "Previous alert cnt reg: %08h";
    msg = $sformatf(fmt, alert_cnt_reg.get_mirrored_value());
    `uvm_info(`gfn, msg, UVM_DEBUG)

    `DV_CHECK_FATAL(total_fail_field.predict(.value(fail_total), .kind(UVM_PREDICT_DIRECT)))
    `DV_CHECK_FATAL( alert_cnt_field.predict(.value( alert_cnt), .kind(UVM_PREDICT_DIRECT)))

    fmt = "Predicted alert cnt for \"%s\" test: %04h";
    msg = $sformatf(fmt, test, alert_cnt_field.get_mirrored_value());
    `uvm_info(`gfn, msg, UVM_HIGH)

    fmt = "Entire alert cnt reg: %08h";
    msg = $sformatf(fmt, alert_cnt_reg.get_mirrored_value());
    `uvm_info(`gfn, msg, UVM_FULL)

    fmt = "Predicted fail cnt for \"%s\" test: %01h";
    msg = $sformatf(fmt, test, total_fail_field.get_mirrored_value());
    `uvm_info(`gfn, msg, UVM_HIGH)
  endfunction

  function bit check_threshold(string test, bit fips_mode, int value);
    string        threshold_reg_name;
    string        threshold_field_name;
    uvm_reg       threshold_reg;
    uvm_reg_field threshold_field;

    int        threshold_val;
    bit        continuous_test;
    bit        failure;
    bit        low_test;
    string     fmt, msg;

    validate_test_name(test);
    low_test             = is_low_test(test);
    continuous_test      = (test == "repcnt") || (test == "repcnts");

    threshold_field_name = fips_mode ? "fips_thresh" : "bypass_thresh";
    threshold_reg_name  = $sformatf("%s_thresholds", test);

    threshold_reg    = ral.get_reg_by_name(threshold_reg_name);
    threshold_field  = threshold_reg.get_field_by_name(threshold_field_name);

    threshold_val = threshold_field.get_mirrored_value();

    // Continuous tests are more rigorous about holding to the '>=' specified in NIST
    // 800-90B. Meanwhile the windowed tests use "<" or ">" as this allows these tests
    // to be temporarily disabled at boot, by choosing the maximal window size.
    // TODO: Document this
    if (continuous_test) begin
      failure = (low_test && value <= threshold_val) || (!low_test && value >= threshold_val);
    end else begin
      failure = (low_test && value < threshold_val) || (!low_test && value > threshold_val);
    end

    fmt = "Threshold for \"%s\" test (FIPS? %d): %04h";
    `uvm_info(`gfn, $sformatf(fmt, test, fips_mode, threshold_val), UVM_FULL)

    fmt = "Observed value for \"%s\" test (FIPS? %d): %04h, %s";
    `uvm_info(`gfn, $sformatf(fmt, test, fips_mode, value, failure ? "FAIL" : "PASS"), UVM_FULL)

    return failure;

  endfunction


  // Indicates that the health test is active
  // Also indicates whether the sigma value in the dut_cfg is being employed
  function bit ht_is_active();
    bit fw_insert, sigma_applied;

    fw_insert = (ral.FW_OV_CONTROL.FW_OV_MODE.get_mirrored_value() == MuBi4True) &&
                (ral.FW_OV_CONTROL.FW_OV_ENTROPY_INSERT.get_mirrored_value() == MuBi4True);

    // TODO (Priority 3): This use of the dut_cfg depends very much on the vseq being employed.
    sigma_applied = !cfg.dut_cfg.default_ht_thresholds;

    return !fw_insert && sigma_applied;

  endfunction

  function bit evaluate_adaptp_test(queue_of_rng_val_t window, bit fips_mode);
    int value, minval, maxval;
    bit fail_hi, fail_lo;
    bit total_scope;
    int threshold_hi, threshold_lo;
    real sigma_hi, sigma_lo;

    int window_size = fips_mode ? `gmv(ral.HEALTH_TEST_WINDOWS.FIPS_WINDOW) :
                                  `gmv(ral.HEALTH_TEST_WINDOWS.BYPASS_WINDOW);

    // If rng_bit_enable is set to MuBi4True, the window size is 4 times as large.
    // We need the same number of bits but only have a single lane.
    int window_size_scaled = (`gmv(ral.CONF.RNG_BIT_ENABLE) == MuBi4True) ? 4*window_size :
                                                                            window_size;

    threshold_hi = fips_mode ? `gmv(ral.ADAPTP_HI_THRESHOLDS.FIPS_THRESH) :
                               `gmv(ral.ADAPTP_HI_THRESHOLDS.BYPASS_THRESH);

    threshold_lo = fips_mode ? `gmv(ral.ADAPTP_LO_THRESHOLDS.FIPS_THRESH) :
                               `gmv(ral.ADAPTP_LO_THRESHOLDS.BYPASS_THRESH);

    total_scope = (ral.CONF.THRESHOLD_SCOPE.get_mirrored_value() == MuBi4True);

    sigma_hi = ideal_threshold_to_sigma(window_size_scaled, adaptp_ht, !total_scope,
                                        high_test, threshold_hi);
    sigma_lo = ideal_threshold_to_sigma(window_size_scaled, adaptp_ht, !total_scope,
                                        low_test, threshold_lo);

    value = calc_adaptp_test(window, maxval, minval);

    update_watermark("adaptp_lo", fips_mode, total_scope ? value : minval);
    update_watermark("adaptp_hi", fips_mode, total_scope ? value : maxval);

    fail_lo = check_threshold("adaptp_lo", fips_mode, total_scope ? value : minval);
    if (fail_lo) predict_failure_logs("adaptp_lo");

    fail_hi = check_threshold("adaptp_hi", fips_mode, total_scope ? value : maxval);
    if (fail_hi) predict_failure_logs("adaptp_hi");


    if (ht_is_active()) begin
      cov_vif.cg_win_ht_sample(adaptp_ht, high_test, window_size_scaled * RNG_BUS_WIDTH, fail_hi);
      cov_vif.cg_win_ht_sample(adaptp_ht, low_test, window_size_scaled * RNG_BUS_WIDTH, fail_lo);
      cov_vif.cg_win_ht_deep_threshold_sample(adaptp_ht, high_test,
                                              window_size_scaled * RNG_BUS_WIDTH,
                                              !total_scope, sigma_hi, fail_hi);
      cov_vif.cg_win_ht_deep_threshold_sample(adaptp_ht, low_test,
                                              window_size_scaled * RNG_BUS_WIDTH,
                                              !total_scope, sigma_lo, fail_lo);
    end

    return (fail_hi || fail_lo);
  endfunction

  function bit evaluate_bucket_test(queue_of_rng_val_t window, bit fips_mode);
    int value;
    bit fail;
    int threshold;
    real sigma;

    int window_size = fips_mode ? `gmv(ral.HEALTH_TEST_WINDOWS.FIPS_WINDOW) :
                                  `gmv(ral.HEALTH_TEST_WINDOWS.BYPASS_WINDOW);

    // If rng_bit_enable is set to MuBi4True, the window size is 4 times as large.
    // We need the same number of bits but only have a single lane.
    int window_size_scaled = (`gmv(ral.CONF.RNG_BIT_ENABLE) == MuBi4True) ? 4*window_size :
                                                                            window_size;

    threshold = fips_mode ? `gmv(ral.BUCKET_THRESHOLDS.FIPS_THRESH) :
                            `gmv(ral.BUCKET_THRESHOLDS.BYPASS_THRESH);

    sigma = ideal_threshold_to_sigma(window_size_scaled, bucket_ht, 0, high_test, threshold);

    value = calc_bucket_test(window);

    update_watermark("bucket", fips_mode, value);

    fail = check_threshold("bucket", fips_mode, value);
    if (fail) predict_failure_logs("bucket");

    if (ht_is_active()) begin
      cov_vif.cg_win_ht_sample(bucket_ht, high_test, window_size_scaled*RNG_BUS_WIDTH, fail);
      cov_vif.cg_win_ht_deep_threshold_sample(bucket_ht, high_test,
                                              window_size_scaled*RNG_BUS_WIDTH,
                                              1'b0, sigma, fail);
    end

    return fail;
  endfunction

  function bit evaluate_markov_test(queue_of_rng_val_t window, bit fips_mode);
    int value, minval, maxval;
    bit fail_hi, fail_lo;
    bit total_scope;
    int threshold_hi, threshold_lo;
    real sigma_hi, sigma_lo;

    int window_size = fips_mode ? `gmv(ral.HEALTH_TEST_WINDOWS.FIPS_WINDOW) :
                                  `gmv(ral.HEALTH_TEST_WINDOWS.BYPASS_WINDOW);

    // If rng_bit_enable is set to MuBi4True, the window size is 4 times as large.
    // We need the same number of bits but only have a single lane.
    int window_size_scaled = (`gmv(ral.CONF.RNG_BIT_ENABLE) == MuBi4True) ? 4*window_size :
                                                                            window_size;

    threshold_hi = fips_mode ? `gmv(ral.MARKOV_HI_THRESHOLDS.FIPS_THRESH) :
                               `gmv(ral.MARKOV_HI_THRESHOLDS.BYPASS_THRESH);

    threshold_lo = fips_mode ? `gmv(ral.MARKOV_LO_THRESHOLDS.FIPS_THRESH) :
                               `gmv(ral.MARKOV_LO_THRESHOLDS.BYPASS_THRESH);

    total_scope = (ral.CONF.THRESHOLD_SCOPE.get_mirrored_value() == MuBi4True);

    sigma_hi = ideal_threshold_to_sigma(window_size_scaled, markov_ht, !total_scope,
                                        high_test, threshold_hi);
    sigma_lo = ideal_threshold_to_sigma(window_size_scaled, markov_ht, !total_scope,
                                        low_test, threshold_lo);

    value = calc_markov_test(window, maxval, minval);

    update_watermark("markov_lo", fips_mode, total_scope ? value : minval);
    update_watermark("markov_hi", fips_mode, total_scope ? value : maxval);

    fail_lo = check_threshold("markov_lo", fips_mode, total_scope ? value : minval);
    if (fail_lo) predict_failure_logs("markov_lo");

    fail_hi = check_threshold("markov_hi", fips_mode, total_scope ? value : maxval);
    if (fail_hi) predict_failure_logs("markov_hi");

    if (ht_is_active()) begin
      cov_vif.cg_win_ht_sample(markov_ht, high_test, window_size_scaled*RNG_BUS_WIDTH, fail_hi);
      cov_vif.cg_win_ht_sample(markov_ht, low_test, window_size_scaled*RNG_BUS_WIDTH, fail_lo);
      cov_vif.cg_win_ht_deep_threshold_sample(markov_ht, high_test,
                                              window_size_scaled*RNG_BUS_WIDTH,
                                              !total_scope, sigma_hi, fail_hi);
      cov_vif.cg_win_ht_deep_threshold_sample(markov_ht, low_test,
                                              window_size_scaled*RNG_BUS_WIDTH,
                                              !total_scope, sigma_hi, fail_lo);
    end

    return (fail_hi || fail_lo);
  endfunction

  // The repetition counts are always running
  function bit evaluate_repcnt_test(bit fips_mode, int value);
    bit fail;
    bit rng_en = (`gmv(ral.CONF.RNG_BIT_ENABLE) == MuBi4True);

    update_watermark("repcnt", fips_mode, value);

    fail = check_threshold("repcnt", fips_mode, value);
    if (fail) begin
      `uvm_info(`gfn, "repcnt failure detected", UVM_FULL)
      predict_failure_logs("repcnt");
    end

    if (ht_is_active()) begin
      cov_vif.cg_cont_ht_sample(repcnt_ht, fips_mode, rng_en, `gmv(ral.CONF.RNG_BIT_SEL),
                                value, fail);
    end

    return fail;

  endfunction

  function bit evaluate_repcnt_symbol_test(bit fips_mode, int value);
    bit fail;
    bit rng_en = (`gmv(ral.CONF.RNG_BIT_ENABLE) == MuBi4True);

    update_watermark("repcnts", fips_mode, value);

    fail = check_threshold("repcnts", fips_mode, value);
    if (fail) begin
      `uvm_info(`gfn, "repcnts failure detected", UVM_FULL)
      predict_failure_logs("repcnts");
    end

    if (ht_is_active()) begin
      cov_vif.cg_cont_ht_sample(repcnts_ht, fips_mode, rng_en, `gmv(ral.CONF.RNG_BIT_SEL),
                                value, fail);
    end

    return fail;
  endfunction

  function int health_check_rng_data(queue_of_rng_val_t window,
                                     bit fips_mode);
    int           windowed_fail_count;
    int           total_fail_count;
    int           overcount;
    bit           sample_fail_count;
    uvm_reg_field alert_summary_field = ral.ALERT_SUMMARY_FAIL_COUNTS.ANY_FAIL_COUNT;
    int           any_fail_count_regval;
    string        fmt;

    windowed_fail_count = evaluate_adaptp_test(window, fips_mode) +
                          evaluate_bucket_test(window, fips_mode) +
                          evaluate_markov_test(window, fips_mode);

    // Are there any failures this in the last sample (continuous or windowed)?
    // Note: If the last sample in the window has a continuous HT failure, then
    // this sample has already been added to the failure counts
    sample_fail_count = (windowed_fail_count != 0);

    // Add the number of continuous fails (excluding the last sample)
    // to any failure in this sample.
    total_fail_count = sample_fail_count + continuous_fail_count + extht_fail_count;

    // Implementation artifact:
    // Account for the fact that simultaneous failures for windowed, continuous and ExtHT tests
    // only get counted once in the total failure count if they coincidentally occur in the last
    // sample.
    overcount = sample_fail_count + cont_fail_in_last_sample + extht_fail_in_last_sample;
    overcount -= (overcount >= 1);
    total_fail_count -= overcount;

    // To avoid double counting only mark a sample failure if there haven't
    // already been continuous or extht failures at the same time.
    if (sample_fail_count && !(cont_fail_in_last_sample || extht_fail_in_last_sample)) begin
      any_fail_count_regval = `gmv(alert_summary_field);
      // Just add any failure in the last sample as the previous samples
      // were added as they occurred.
      any_fail_count_regval++;
      `DV_CHECK_FATAL(alert_summary_field.predict(.value(any_fail_count_regval),
                                                  .kind(UVM_PREDICT_DIRECT)))
      fmt = "Predicted alert cnt for all tests: %04h";
      `uvm_info(`gfn, $sformatf(fmt, any_fail_count_regval), UVM_HIGH)
    end

    continuous_fail_count = 0;
    extht_fail_count = 0;

    return total_fail_count;
  endfunction

  function void process_failures(int total_fail_count,
                                 bit fw_ov_insert,
                                 entropy_phase_e dut_phase,
                                 int successive_win_fail_count);

    bit failure             = 0;

    uvm_reg       alert_fail_reg      = ral.ALERT_FAIL_COUNTS;
    uvm_reg       extht_fail_reg      = ral.EXTHT_FAIL_COUNTS;
    uvm_reg_field any_fail_count_fld  = ral.ALERT_SUMMARY_FAIL_COUNTS.ANY_FAIL_COUNT;
    string        fmt;
    int           any_fail_count_regval;
    int           alert_threshold;
    bit           main_sm_exp_alert_cond;

    // TODO (#18889): If an alert is anticipated, we should check that (if necessary) this seed is
    // stopped and no others are allowed to progress.
    alert_threshold = `gmv(ral.ALERT_THRESHOLD.ALERT_THRESHOLD);

    fmt = "Predicting alert status with %0d new failures this window";
    `uvm_info(`gfn, $sformatf(fmt, total_fail_count), UVM_FULL)

    any_fail_count_regval = `gmv(any_fail_count_fld);

    failure = (total_fail_count != 0);
    main_sm_exp_alert_cond = (dut_phase == STARTUP) ?
                             (successive_win_fail_count >= 2) :
                             (any_fail_count_regval >= alert_threshold);

    if (failure) begin : test_failure
      if (main_sm_exp_alert_cond) begin
        if (!fw_ov_insert && !threshold_alert_active && !main_sm_escalates) begin
          if (dut_phase == STARTUP) begin
            fmt =  "New alert anticpated with >= 2 failing windows." +
                   "(supercedes count/threshold of %01d/%01d)";
          end else begin
            fmt = "New alert anticpated! Fail count (%01d) >= threshold (%01d)";
          end
          threshold_alert_active = 1;
          `DV_CHECK_FATAL(ral.RECOV_ALERT_STS.ES_MAIN_SM_ALERT.predict(1'b1));

          // The DUT should either set the alert, or crash the sim.
          // If we succeed, sample this alert_threshold as covered successfully.
          cov_vif.cg_alert_cnt_sample(alert_threshold, 1);
        end else if (main_sm_escalates) begin
          fmt = "Main SM in error state, overrides recov alert (Fail cnt: %01d,  thresh: %01d)";
        end else if(threshold_alert_active) begin
          fmt = "Alert already signalled:  Fail count (%01d) >= threshold (%01d)";
        end else begin
          fmt = "FW_OV mode, alerts suppressed:  Fail count (%01d) >= threshold (%01d)";
        end
        `uvm_info(`gfn, $sformatf(fmt, any_fail_count_regval, alert_threshold), UVM_HIGH)
      end else begin
        fmt = "No alert anticpated. fail count (%01d) < threshold (%01d)";
        `uvm_info(`gfn, $sformatf(fmt, any_fail_count_regval, alert_threshold), UVM_HIGH)
      end
    end else begin : no_test_failure
      if (!fw_ov_insert && !threshold_alert_active && !main_sm_escalates) begin
        // Now we know that all tests have passed we can clear the failure counts. In FW_OV mode
        // alerts are suppressed but we keep counting failures. In addition, even in case of a
        // full passing test sequence, counters are not cleared.
        `DV_CHECK_FATAL(alert_fail_reg.predict(.value(32'd0), .kind(UVM_PREDICT_DIRECT)))
        `DV_CHECK_FATAL(extht_fail_reg.predict(.value(32'd0), .kind(UVM_PREDICT_DIRECT)))
        `DV_CHECK_FATAL(any_fail_count_fld.predict(.value('0), .kind(UVM_PREDICT_DIRECT)))
      end else begin
        fmt = "Alert state persists: Fail count (%01d) >= threshold (%01d)";
        `uvm_info(`gfn, $sformatf(fmt, any_fail_count_regval, alert_threshold), UVM_HIGH)
      end
    end : no_test_failure

  endfunction

  //
  // Helper functions for process_entropy_data_csr_access
  //

  function bit try_seed_tl(input bit [CSRNG_BUS_WIDTH - 1:0] new_candidate,
                           input bit [31:0] tl_data,
                           output bit [31:0] tl_prediction);
    bit [CSRNG_BUS_WIDTH - 1:0] mask, new_seed_masked, best_seed_masked;
    bit matches_prev_reads;
    bit matches_tl_data;
    string fmt;

    mask = '0;

    for(int i = 0; i < seed_tl_read_cnt; i++) begin
      mask[i * 32 +: 32] = {32{1'b1}};
    end
    new_seed_masked = (new_candidate & mask);
    best_seed_masked = (tl_best_seed_candidate & mask);
    matches_prev_reads = (best_seed_masked == new_seed_masked);

    if (matches_prev_reads) begin
      // Only log this if the new seed is different from the previous best:
      if (new_candidate != tl_best_seed_candidate) begin
        string fmt = "Found another match candidate after %01d total dropped seeds";
       `uvm_info(`gfn, $sformatf(fmt, entropy_data_drops), UVM_HIGH)
      end
    end else begin
      `uvm_info(`gfn, "New candidate seed does not match previous segments", UVM_HIGH)
      fmt = "New seed: %096h, Best seed: %096h";
      // In the log mask out portions that have not been compared yet, for contrast
      `uvm_info(`gfn, $sformatf(fmt, new_seed_masked, best_seed_masked), UVM_HIGH)
       return 0;
    end

    tl_prediction = new_candidate[32 * seed_tl_read_cnt +: 32];
    matches_tl_data = (tl_prediction == tl_data);

    if (tl_prediction == tl_data) begin
      tl_best_seed_candidate = new_candidate;
      fmt = "Seed matches TL data after %d TL reads";
      `uvm_info(`gfn, $sformatf(fmt, seed_tl_read_cnt+1), UVM_HIGH)
      return 1;
    end else begin
      fmt = "TL DATA (%08h) does not match predicted seed segment (%08h)";
      `uvm_info(`gfn, $sformatf(fmt, tl_data, tl_prediction), UVM_HIGH)
      return 0;
    end

  endfunction

  function void clear_ht_stat_predictions();
    string stat_regs [] = '{
        "repcnt_hi_watermarks", "repcnts_hi_watermarks", "adaptp_hi_watermarks",
        "adaptp_lo_watermarks", "extht_hi_watermarks", "extht_lo_watermarks",
        "bucket_hi_watermarks", "markov_hi_watermarks", "markov_lo_watermarks",
        "repcnt_total_fails", "repcnts_total_fails", "adaptp_hi_total_fails",
        "adaptp_lo_total_fails", "bucket_total_fails", "markov_hi_total_fails",
        "markov_lo_total_fails", "extht_hi_total_fails", "extht_lo_total_fails",
        "alert_summary_fail_counts", "alert_fail_counts", "extht_fail_counts"
    };
    foreach (stat_regs[i]) begin
      uvm_reg csr = ral.get_reg_by_name(stat_regs[i]);
      void'(csr.predict(.value(csr.get_reset()), .kind(UVM_PREDICT_READ)));
    end
  endfunction

  // Clear all relevant prediction variables for
  // Reset, disable, enable and (delayed) FIFOClr reset events.
  function void handle_disable_reset(reset_event_e rst_type);
    bit is_fw_ov = (`gmv(ral.FW_OV_CONTROL.FW_OV_MODE) == MuBi4True) &&
                   (`gmv(ral.FW_OV_CONTROL.FW_OV_ENTROPY_INSERT) == MuBi4True);

    if (rst_type == Enable) begin
      // Stop ignoring alerts as soon as ENTROPY_SRC is turned on.
      clear_ht_stat_predictions();
      seeds_out = 0;
      health_test_data_q.delete();
      // Wait until the precon FIFO is not full anymore and update precon_fifo_full
      // and precon_fifo_cnt for the prediction of fw_ov_wr_fifo_full.
      fork
        begin
          bit [StateWidthPad-1:0] sha3pad_state, sha3pad_state_next;
          bit cs_aes_halt_o;
          // Wait one cycle for the precon FIFO clear signal to go low.
          cfg.clk_rst_vif.wait_clks(1);
          do begin
            // Wait one cycle for the FIFO not full signal to potentially go high.
            cfg.clk_rst_vif.wait_clks(1);
            `DV_CHECK(uvm_hdl_read(pad_st_path, sha3pad_state))
            `DV_CHECK(uvm_hdl_read(pad_st_d_path, sha3pad_state_next))
            `DV_CHECK(uvm_hdl_read(aes_halt_o_path, cs_aes_halt_o))
            sha3_msg_ready = !cs_aes_halt_o && (sha3pad_state == StMessage) &&
                             (sha3pad_state_next == StMessage);
          end while (!sha3_msg_ready);
          precon_fifo_full = 0;
          precon_fifo_cnt = 0;
        end
      join_none
    end

    // Internal CSRNG stores and scoreboard state is cleared on Disable and HardReset events.
    if( rst_type == Disable || rst_type == HardReset ) begin
      fips_csrng_q.delete();
      repacked_entropy_release_q.delete();
      overflow_condition = 0;
      `DV_CHECK_FATAL(ral.OBSERVE_FIFO_DEPTH.OBSERVE_FIFO_DEPTH.predict('b0))
      // fw_ov_wr_fifo_full goes high when the module is disabled.
      precon_fifo_full = 1;
      precon_fifo_cnt = 1;
    end

    // Internal repetition counters and watermark registers are cleared on enable.
    if (rst_type == Enable) begin
      fork
        begin
          // Clear watermark registers (to 0) and internal repetition counters (to 1).
          `DV_CHECK_FATAL(ral.REPCNT_HI_WATERMARKS.FIPS_WATERMARK.predict(16'd0))
          `DV_CHECK_FATAL(ral.REPCNT_HI_WATERMARKS.BYPASS_WATERMARK.predict(16'd0))
          repcnt_event_cnt = 16'd1;
          `DV_CHECK_FATAL(ral.REPCNTS_HI_WATERMARKS.FIPS_WATERMARK.predict(16'd0))
          `DV_CHECK_FATAL(ral.REPCNTS_HI_WATERMARKS.BYPASS_WATERMARK.predict(16'd0))
          repcnts_event_cnt = 16'd1;
          // Wait one clock cycle, then propagate the internal counter to the watermark registers.
          cfg.clk_rst_vif.wait_clks(1);
          propagate_repcnt_to_watermark();
        end
      join_none
    end

    // Internal repetition counters are reset to 0 on reset.
    if (rst_type == HardReset) begin
      repcnt_event_cnt = '0;
      repcnts_event_cnt = '0;
    end

    // The SHA3 engine is the one unit that is not always cleared on
    // disable.
    // It clears itself in on disable in normal RNG mode.
    // However, in FW_OV mode it only clears itself
    // when a digest is output or on hard reset so in this case,
    // we leave the sha_process_q alone to represent the fact
    // that there is still data in the SHA3 state.
    //
    // However any entropy absorbed in raw mode (and stashed in
    // raw_process_q), will always be lost on disable.
    if(rst_type == HardReset) begin
      sha_process_q.delete();
      raw_process_q.delete();
      repack_idx_fw_ov = 0;
      intr_test = '0;
      intr_test_active = 0;
      regwen_pending = 0;
    end

    if (rst_type == Disable) begin
      raw_process_q.delete();
    end

    if (rst_type == FWOVDisable) begin
      // For FW_OV mode the 64 bit packer is also cleared.
      repack_idx_fw_ov = 0;
    end
    // Note: For non-FW_OV mode, the repack_idx_tl and repack_idx_sha counters are stack variables
    // which get reset automatically when the collect entropy task exits.

    if ((rst_type == FIFOClr) || (rst_type == Enable)) begin
      observe_fifo_q.delete();
      entropy_data_q.delete();
      // The overflow condition for the observe FIFO is cleared whenever the observe FIFO
      // gets cleared.
      observe_fifo_overflow = 0;
      overflow_read_cnt = 0;
      // Clear variables used for observe FIFO depth prediction.
      observe_push_busy_addr_phase = 0;
      observe_push_busy = 0;
    end

    // reset all other statistics
    threshold_alert_active = 0;
    main_sm_escalates = 0;

    seed_idx = 0;
    seed_tl_read_cnt = 0;

    for (int i = 0; i < RNG_BUS_WIDTH; i++) begin
      `uvm_info(`gfn, "Set REPCNTS cntr", UVM_DEBUG)
      repcnt[i] = (rst_type == HardReset) ? 0 :
                  (rst_type == Enable) ? 1 :
                  repcnt[i];
    end
    repcnt_symbol     = 1;

    prev_rng_val      = '0;

    // Clear records of repcnt/repnts failures
    continuous_fail_count     = 0;
    cont_fail_in_last_sample  = 0;

    // Reset the total_seeds_consumed count.
    cfg.total_seeds_consumed = 0;

    // Clear interrupt state
    known_intr_state                         = 0;
    intr_en_mask                             = 0;

    expected_obsfifo_entries_since_last_intr = 0;

    // After this event, all other inputs from the RNG interface will be discarded by the DUT
    // so we flush this queue to reflect the fact that the DUT will not be folding these into
    // outputs.
    rng_fifo.flush();
    // Note the CSRNG TLM analysis fifo should NOT be flushed, as it contains actual DUT
    // outputs which must be scoreboarded

    `uvm_info(`gfn, $sformatf("%s Detected", rst_type.name), UVM_MEDIUM)
  endfunction

  // Update our behavioral predictions based on new interrupts
  // from_csr: 1 if the new information was observed from the intr_state register
  //           0 if it was observed from the interrupt pins
  function void handle_new_interrupts(bit [NumEntropySrcIntr - 1:0] new_events,
                                      bit from_csr);
    string msg;

    if (new_events[ObserveFifoReady]) begin
      bit [6:0] obs_fifo_threshold =
          ral.OBSERVE_FIFO_THRESH.OBSERVE_FIFO_THRESH.get_mirrored_value();
      bit valid_thresh = ((obs_fifo_threshold <= ObserveFifoDepth) && (obs_fifo_threshold != 0));
      msg = $sformatf("No ObsFifo interrupts should be rec'd for threshold 0x%0h",
                      obs_fifo_threshold);
      `DV_CHECK_FATAL(valid_thresh, msg)
      expected_obsfifo_entries_since_last_intr = int'(obs_fifo_threshold);
      msg = $sformatf("Expecting at least 0x%0h new obsfifo entries",
                      expected_obsfifo_entries_since_last_intr);
      `uvm_info(`gfn, msg, UVM_FULL)
    end
    known_intr_state = known_intr_state | new_events;
  endfunction

  function void clear_interrupts(bit [NumEntropySrcIntr - 1:0] clear_mask);
    known_intr_state &= ~clear_mask;
    intr_test &= ~clear_mask;
    `uvm_info(`gfn, $sformatf("clear_mask: %01h", clear_mask), UVM_FULL)
    `uvm_info(`gfn, $sformatf("known_data: %01h", known_intr_state), UVM_FULL)
  endfunction

  // All the HT threshold registers are one-way: they can only become more strict unless
  // the DUT is reset.  This function encapsulates this behavior.
  //
  // This function operates on full 32-bit words, with some knowledge of the structure of each
  // register.
  // 1. These registers are consist of two 16b thresholds a bypass and a FIPS threshold.
  //    The one-way restriction is applied to them independently.
  // 2. Both thresholds have the same directional restriction: both can go up or both can go down.
  // If the structure of these registers ever becomes more varied we will have to generalize this
  // function, using structural cues from the RAL model
  //
  // new_val:       The value to be written to the register
  // prev_val:      The current value of the register
  // increase_only: 1 if the register values are allowed to increase.
  //
  // Returns the new predicted value for the register.
  function void predict_one_way_threshold(uvm_reg csr,
                                          bit [31:0] write_val,
                                          bit increase_only);

    localparam int ThreshW = 16;

    bit [31:0]          prev_val = `gmv(csr);
    int                 offset = csr.get_offset();
    bit [ThreshW - 1:0] new_thresh, prev_thresh, thresh_out;
    bit [31:0]          result;
    int                 i;
    string              msg, fmt;

    for (i=0; i < 32; i+=ThreshW) begin
      bit is_fips_thresh = (i==0);
      bit update_rejected;
      new_thresh  = write_val[i +: ThreshW];
      prev_thresh =  prev_val[i +: ThreshW];
      thresh_out  = increase_only ? (new_thresh > prev_thresh ? new_thresh : prev_thresh) :
                                    (new_thresh < prev_thresh ? new_thresh : prev_thresh);
      update_rejected = (thresh_out != new_thresh);
      result[i +: ThreshW] = thresh_out;
      cov_vif.cg_one_way_ht_threshold_reg_sample(offset, update_rejected, is_fips_thresh);
    end
    fmt = "Threshold Reg Update. Offset: %08x (%s), Orig: %08x, New: %08x, Final: %08x";
    msg = $sformatf(fmt, offset, prev_val, increase_only ? "INCREASES" : "DECREASES",
                    write_val, result);
    `uvm_info(`gfn, msg, UVM_DEBUG);
    void'(csr.predict(.value(result), .kind(UVM_PREDICT_WRITE)));
  endfunction

  // Function to check for correct values to register fields with mandatory redundancy
  // (i.e. MultiBit boolean values or the ALERT_THRESHOLD register).
  //
  // Performs several scoreboarding functions:
  // It checks that the recently written (mirrored) value is valid. If invalid, the function:
  // - Expects a recovereable alert
  // - Updates the prediction for the RECOV_ALERT_STS register
  // - Samples the relevant coverpoint for recoverable alert events.
  //
  // Arguments:
  // reg_name: the register to check
  // mubi_field: the specific field to examine (when checking for bad MuBi's)
  // sts_field_name: the name of the field to assert
  // which_mubi: The associated coverpoint value to assert when a bad
  //             redundancy is discovered. (includes bad writes to alert threshold
  //             as well as all MuBi fields).
  virtual function void check_redundancy_val(string reg_name, string mubi_field,
                                            string sts_field_name, invalid_mubi_e which_mubi);
    bit bad_redundancy;
    // Check the currently predicted value for the desired register and field
    //
    // Almost all of the redundant values are isolated MultiBit Booleans except for
    // ALERT_THRESHOLD in which the threhold field must equal the inverse of the
    // inverse threshold field.
    if (reg_name != "alert_threshold") begin
      bad_redundancy = mubi4_test_invalid(
          mubi4_t'(get_reg_fld_mirror_value(ral, reg_name, mubi_field)));
    end else begin
      bit [15:0] thresh     = get_reg_fld_mirror_value(ral, "alert_threshold", "alert_threshold");
      bit [15:0] thresh_inv = get_reg_fld_mirror_value(ral, "alert_threshold",
                                                       "alert_threshold_inv");
      bad_redundancy = (thresh != ~thresh_inv);
    end

    if (bad_redundancy) begin
      uvm_reg_field sts_field = ral.RECOV_ALERT_STS.get_field_by_name(sts_field_name);
      `DV_CHECK_FATAL(sts_field.predict(.value(1'b1), .kind(UVM_PREDICT_READ)))

      cov_vif.cg_mubi_err_sample(which_mubi);
    end
  endfunction

  task monitor_fw_ov_write_exceptions(virtual entropy_subsys_fifo_exception_if#(1) vif,
                                      bit active_in_fips_mode);
    bit fw_ov_mode, fw_ov_insert, fips_enabled, es_route, es_type, is_fips_mode;
    int i;

    forever begin
      @(vif.mon_cb);

      fw_ov_mode   = (cfg.otp_en_es_fw_over == MuBi8True) &&
                     (`gmv(ral.FW_OV_CONTROL.FW_OV_MODE) == MuBi4True);
      fw_ov_insert = fw_ov_mode && (`gmv(ral.FW_OV_CONTROL.FW_OV_ENTROPY_INSERT) == MuBi4True);
      fips_enabled = `gmv(ral.CONF.FIPS_ENABLE) == MuBi4True;
      es_route     = `gmv(ral.ENTROPY_CONTROL.ES_ROUTE) == MuBi4True;
      es_type      = `gmv(ral.ENTROPY_CONTROL.ES_TYPE) == MuBi4True;
      is_fips_mode = fips_enabled && !(es_route && es_type);

      // If we are not in FW_OV mode at this time, then this error event doesn't matter.
      // (Such events seem to happen in normal HW-driven operation, but they do not
      // reflect errors, as the HW chain has proper flow control)
      if (!fw_ov_insert) continue;

      // This fifo event also does matter if the FIFO is currently not active for FW_OV/FIPS mode
      if (active_in_fips_mode ^ is_fips_mode) continue;

      for (i=0; i<N_FIFO_ERR_TYPES; i++) begin
        if (vif.mon_cb.error_pulses[i]) begin
          case (i)
            FIFO_WRITE_ERR: begin
              uvm_reg_field fld = ral.RECOV_ALERT_STS.ES_FW_OV_WR_ALERT;
              `DV_CHECK_FATAL(fld.predict(1'b1, .kind(UVM_PREDICT_READ)));

              // Make a single-clock pulse to tell the TL process that this error has been
              // identified and the ongoing write should be ignored.
              ignore_fw_ov_data_pulse = 1;
              fork
                begin
                  @(vif.mon_cb);
                  // Clear the last pulse (unless there is another event right behind the last
                  // one)
                  if (!vif.mon_cb.error_pulses[FIFO_WRITE_ERR]) begin
                    ignore_fw_ov_data_pulse = 0;
                  end
                end
              join_none
            end
            default: begin
              // ignore other types as this FIFO has proper HW flow control at the other end.
            end
          endcase
        end
      end
    end
  endtask

  task process_fifo_exceptions();
    fork
      // The FW_OV_WR_DATA register is connected to the precon fifo in FIPS mode and the bypass
      // FIFO in bypass mode.  Monitor them both for exceptions.
      monitor_fw_ov_write_exceptions(cfg.precon_fifo_vif, 1);
      monitor_fw_ov_write_exceptions(cfg.bypass_fifo_vif, 0);
    join_none
  endtask

  function bit [FIPS_BUS_WIDTH - 1:0] get_fips_compliance(
      bit [FIPS_CSRNG_BUS_WIDTH - 1:0] fips_csrng);
    return fips_csrng[CSRNG_BUS_WIDTH +: FIPS_BUS_WIDTH];
  endfunction

  function bit [CSRNG_BUS_WIDTH - 1:0] get_csrng_seed(bit [FIPS_CSRNG_BUS_WIDTH - 1:0] fips_csrng);
    return fips_csrng[0 +: CSRNG_BUS_WIDTH];
  endfunction

  function bit do_condition_data();
    bit             route_sw;
    bit             sw_bypass;
    bit             fips_enable;
    bit             is_fips_mode;
    bit             predict_conditioned;

    route_sw    = (`gmv(ral.ENTROPY_CONTROL.ES_ROUTE) == MuBi4True);
    sw_bypass   = (`gmv(ral.ENTROPY_CONTROL.ES_TYPE)  == MuBi4True);
    fips_enable = (`gmv(ral.CONF.FIPS_ENABLE)         == MuBi4True);

    is_fips_mode = fips_enable && !(route_sw && sw_bypass);

    predict_conditioned = is_fips_mode;

    return predict_conditioned;

  endfunction


  // Note: this routine is destructive in that it empties the input argument
  function bit [FIPS_CSRNG_BUS_WIDTH - 1:0] predict_fips_csrng();
    bit [FIPS_CSRNG_BUS_WIDTH - 1:0] fips_csrng_data;
    bit [CSRNG_BUS_WIDTH - 1:0]      csrng_data;
    bit [FIPS_BUS_WIDTH - 1:0]       fips_data;
    bit                              predict_conditioned;
    mubi4_t                          rng_single_bit;

    int                              sample_frames;

    string                           msg, fmt;

    predict_conditioned = do_condition_data();

    rng_single_bit = mubi4_t'(`gmv(ral.CONF.RNG_BIT_ENABLE));

    sample_frames = predict_conditioned ? sha_process_q.size() : raw_process_q.size;

    fmt = "processing %01d 64-bit frames in %s mode";
    msg = $sformatf(fmt, sample_frames, predict_conditioned ? "FIPS" : "BYPASS");

    `uvm_info(`gfn, msg, UVM_FULL);

    fips_data = (`gmv(ral.CONF.FIPS_FLAG) == MuBi4True) &&
                (`gmv(ral.MODULE_ENABLE.MODULE_ENABLE) == MuBi4True);

    if (predict_conditioned) begin
      localparam int BytesPerSHAWord = SHACondWidth / 8;

      bit [7:0] sha_msg[];
      bit [7:0] sha_digest[CSRNG_BUS_WIDTH / 8];
      int unsigned msg_len = 0;

      sha_msg = new[sha_process_q.size() * BytesPerSHAWord];

      // The DUT's SHA engine takes data in 64 (SHACondWidth) bit chunks, whereas the DPI call
      // requires an array of bytes.  Here we break the SHA-words into a stream of bytes
      while (sha_process_q.size() > 0) begin
        bit [SHACondWidth - 1:0] sha_word    = '0;
        bit [7:0] sha_byte                   = '0;
        sha_word = sha_process_q.pop_front();
        for (int i = 0; i < BytesPerSHAWord; i++) begin
          sha_byte = sha_word[ 0 +: 8];
          sha_word = sha_word >> 8;
          `uvm_info(`gfn, $sformatf("msglen: %04h, byte: %02h", msg_len, sha_byte), UVM_FULL)
          sha_msg[msg_len] = sha_byte;
          msg_len++;
        end
      end

      `uvm_info(`gfn, $sformatf("DIGESTION COMMENCING of %d bytes", msg_len), UVM_FULL)

      digestpp_dpi_pkg::c_dpi_sha3_384(sha_msg, msg_len, sha_digest);

      `uvm_info(`gfn, "DIGESTING COMPLETE", UVM_FULL)

      csrng_data = '0;
      for(int i = 0; i < CSRNG_BUS_WIDTH / 8; i++) begin
        bit [7:0] sha_byte = sha_digest[i];

        `uvm_info(`gfn, $sformatf("repacking: %02d", i), UVM_FULL)

        csrng_data = (csrng_data >> 8) | (sha_byte << (CSRNG_BUS_WIDTH - 8));
      end
      `uvm_info(`gfn, $sformatf("Conditioned data: %096h", csrng_data), UVM_HIGH)

    end else begin

      while (raw_process_q.size() > 0) begin
        bit [SHACondWidth - 1:0] word = raw_process_q.pop_front();
        string fmt;

        fmt = "sample size: %01d, last elem.: %016h";
        `uvm_info(`gfn, $sformatf(fmt, raw_process_q.size()+1, word), UVM_FULL)

        csrng_data = csrng_data >> SHACondWidth;
        csrng_data[CSRNG_BUS_WIDTH - SHACondWidth +: SHACondWidth] = word;
      end
      `uvm_info(`gfn, $sformatf("Unconditioned data: %096h", csrng_data), UVM_HIGH)
    end

    fips_csrng_data = {fips_data, csrng_data};

    return fips_csrng_data;
  endfunction

  task wait_enabled();
    if (!dut_pipeline_enabled) begin
      wait(dut_pipeline_enabled);
      `uvm_info(`gfn, "Enable detected", UVM_MEDIUM)
    end
  endtask

  // Wait on the RNG queue for rng sequence items
  //
  // If bit selection is enabled, wait for RNG_BUS_WIDTH items. Otherwise, return after one item.
  // If dut_pipeline_enabled is deasserted before any data is found, this task
  // halts and asserts disable_detected.
  task wait_rng_queue(output rng_val_t val, output bit disable_detected);
    push_pull_item#(.HostDataWidth(RNG_BUS_WIDTH))  rng_item;
    bit bit_sel_enable = (`gmv(ral.CONF.RNG_BIT_ENABLE) == MuBi4True);
    int n_items        = bit_sel_enable ? RNG_BUS_WIDTH : 1;
    disable_detected   = 0;

    if(!dut_pipeline_enabled) begin
      disable_detected = 1;
      return;
    end

    for (int i = 0; i < n_items; i++) begin : rng_loop
      `DV_SPINWAIT_EXIT(rng_fifo.peek(rng_item);,
                        wait(!dut_pipeline_enabled);)
      // Pop any data off the rng_fifo below to resolve potential
      // race conditions if a new RNG word appears in the same
      // cycle that the dut is disabled.
      disable_detected = !rng_fifo.try_get(rng_item);
      if (disable_detected) break;

      if (bit_sel_enable) begin
        val[i] = rng_item.h_data[ral.CONF.RNG_BIT_SEL.get_mirrored_value()];
      end else begin
        val    = rng_item.h_data;
      end

      // Add the item to health_test_data_q for health test checking.
      health_test_data_q.push_back(rng_item.h_data);
    end : rng_loop
  endtask

  task collect_entropy();
    // Two levels of repacking to mimic the structure of the DUT
    // first RNG samples are packed into 32-bit TL DW's
    // then those are packed into 64-bit chunks suitable
    // for SHA3 input
    bit [32:0]           repacked_entropy_tl;
    bit [32:0]           repacked_entropy_release;
    bit [SHACondWidth:0] repacked_entropy_sha;
    int                  repack_idx_tl  = 0;
    int                  repack_idx_sha = 0;
    bit                  fw_ov_insert;
    bit                  disable_detected;
    rng_val_t            rng_val;
    string               fmt, msg;
    int                  observe_wait_cycles;
    bit                  predict_conditioning;

    localparam int RngPerTlDw = 32 / RNG_BUS_WIDTH;

    wait_enabled();

    fw_ov_insert = (cfg.otp_en_es_fw_over == MuBi8True) &&
                   (`gmv(ral.FW_OV_CONTROL.FW_OV_MODE) == MuBi4True) &&
                   (`gmv(ral.FW_OV_CONTROL.FW_OV_ENTROPY_INSERT) == MuBi4True);

    forever begin : collect_entropy_loop
      wait_rng_queue(rng_val, disable_detected);

      if (disable_detected) begin
        // Exit this task if a disable was detected.
        return;
      end else begin
        // Pack this data for redistribution
        repacked_entropy_tl = {rng_val,
                               repacked_entropy_tl[RNG_BUS_WIDTH +: (32 - RNG_BUS_WIDTH)]};
        repack_idx_tl++;
        `uvm_info(`gfn, $sformatf("repack_idx_tl: %0d", repack_idx_tl), UVM_DEBUG)
        if (repack_idx_tl == RngPerTlDw) begin
          repack_idx_tl = 0;
          // Push the repacked entropy into a release queue to make sure that repacked_entropy_tl
          // is not altered by the time the observe_wait_cycles pass.
          repacked_entropy_release_q.push_back(repacked_entropy_tl);
          // Wait until the data has reached the observe FIFO and predict the overflow state.
          // The FIFOs between the RNG input and the observe FIFO are: the esrng FIFO,
          // the esbit FIFO, the postht packer FIFO and the distribution FIFO. However, we
          // don't count the distribution FIFO here, since it is configured in pass through mode.
          // We end up with 2 cycles delay in the normal mode and an adiitional cycle in single
          // lane mode.
          observe_wait_cycles = (`gmv(ral.CONF.RNG_BIT_ENABLE) == MuBi4True) ? 3 : 2;
          fork
            begin
              cfg.clk_rst_vif.wait_clks(observe_wait_cycles);
              repacked_entropy_release = repacked_entropy_release_q.pop_front();
              // If the observe FIFO has overflown signal the overflow condition and predict the
              // fw_ov_rd_fifo_overflow register to be set to true. We drop the overflowing data by
              // not pushing into the observe FIFO queue.
              if (overflow_condition ||
                  (observe_fifo_q.size() >= (OBSERVE_FIFO_DEPTH + observe_read_incoming))) begin
                overflow_condition = 1;
                `DV_CHECK_FATAL(ral.FW_OV_RD_FIFO_OVERFLOW.FW_OV_RD_FIFO_OVERFLOW.predict('b1))

              // If there is no overflow condition going on then push the repacked entropy into the
              // observe FIFO queue.
              end else begin
                observe_fifo_q.push_back(repacked_entropy_release);
              end
              // Signal to potential reads to observe_fifo_depth that a word is currently being pushed
              // into the observe FIFO.
              observe_push_busy = 1;
              wait(!ral.OBSERVE_FIFO_DEPTH.is_busy());
              observe_push_busy = 0;
              `DV_CHECK_FATAL(ral.OBSERVE_FIFO_DEPTH.OBSERVE_FIFO_DEPTH.predict(
                  `gmv(ral.OBSERVE_FIFO_DEPTH.OBSERVE_FIFO_DEPTH)+1, .kind(UVM_PREDICT_DIRECT)))
            end
          join_none

          // Now repack the 32-bit width blocks into the larger SHA blocks
          // to publish to the correct processing fifo.
          // Since the raw and sha-conditioned data are handled differently
          // on disable events they go into different FIFOs
          //
          repacked_entropy_sha = {repacked_entropy_tl,
                                  repacked_entropy_sha[32 +: (SHACondWidth - 32)]};
          repack_idx_sha++;
          if (repack_idx_sha == SHACondWidth/32) begin
            repack_idx_sha = 0;
            if (!fw_ov_insert) begin
              predict_conditioning = do_condition_data();
              if (predict_conditioning) begin
                sha_process_q.push_back(repacked_entropy_sha);
                msg = $sformatf("RNG SHA word: %016x, count: 0x%01x",
                                repacked_entropy_sha, sha_process_q.size());
                `uvm_info(`gfn, msg, UVM_HIGH)
              end else begin
                `uvm_info(`gfn, $sformatf("RNG RAW word: %016x", repacked_entropy_sha) , UVM_HIGH)
                raw_process_q.push_back(repacked_entropy_sha);
              end
            end
          end
        end
      end
    end
  endtask

  // Propagate internal repetition counter to watermark register.  Call this function when changing
  // a setting that influences the switch between bypass and FIPS mode.  This will propagate the
  // internal repetition counters to the watermark field of the new mode (i.e., bypass or FIPS).
  function automatic void propagate_repcnt_to_watermark();
    bit fips_enable, bypass_to_sw, route_to_sw, bypass_mode, rng_bit_en;
    bit [1:0] rng_bit_sel;
    int max_repcnt = 0;
    // Determine whether FIPS or bypass mode is now active.
    fips_enable = `gmv(ral.CONF.FIPS_ENABLE) == MuBi4True;
    bypass_to_sw = `gmv(ral.ENTROPY_CONTROL.ES_TYPE) == MuBi4True;
    route_to_sw = `gmv(ral.ENTROPY_CONTROL.ES_ROUTE) == MuBi4True;
    rng_bit_en  = (`gmv(ral.CONF.RNG_BIT_ENABLE) == MuBi4True);
    rng_bit_sel = `gmv(ral.CONF.RNG_BIT_SEL);
    bypass_mode = ~fips_enable | (bypass_to_sw & route_to_sw);
    // Calculate the new value for repcnt_event_cnt, since it can change when we toggle rng_bit_en.
    for (int i = 0; i < RNG_BUS_WIDTH; i++) begin
      max_repcnt = (repcnt[i] > max_repcnt) ? repcnt[i] : max_repcnt;
    end
    repcnt_event_cnt = rng_bit_en ? repcnt[rng_bit_sel] : max_repcnt;
    if (bypass_mode) begin
      // Propagate internal repetition counter to bypass watermark fields.
      if (repcnt_event_cnt > `gmv(ral.REPCNT_HI_WATERMARKS.BYPASS_WATERMARK)) begin
        `DV_CHECK_FATAL(ral.REPCNT_HI_WATERMARKS.BYPASS_WATERMARK.predict(repcnt_event_cnt))
      end
      if (repcnts_event_cnt > `gmv(ral.REPCNTS_HI_WATERMARKS.BYPASS_WATERMARK)) begin
        `DV_CHECK_FATAL(ral.REPCNTS_HI_WATERMARKS.BYPASS_WATERMARK.predict(repcnts_event_cnt))
      end
    end else begin
      // Propagate internal repetition counter to FIPS watermark fields.
      if (repcnt_event_cnt > `gmv(ral.REPCNT_HI_WATERMARKS.FIPS_WATERMARK)) begin
        `DV_CHECK_FATAL(ral.REPCNT_HI_WATERMARKS.FIPS_WATERMARK.predict(repcnt_event_cnt))
      end
      if (repcnts_event_cnt > `gmv(ral.REPCNTS_HI_WATERMARKS.FIPS_WATERMARK)) begin
        `DV_CHECK_FATAL(ral.REPCNTS_HI_WATERMARKS.FIPS_WATERMARK.predict(repcnts_event_cnt))
      end
    end
  endfunction

  task health_test_scoring_thread();
    bit [15:0]                window_size;
    entropy_phase_e           dut_fsm_phase;
    int                       window_rng_frames;
    int                       pass_requirement, pass_count, startup_fail_count;
    bit                       fw_ov_insert;
    bit                       is_fips_mode;
    bit                       fips_enable, es_route, es_type;
    bit                       rng_bit_en;
    bit [1:0]                 rng_bit_sel;
    int                       failures_in_window;
    rng_val_t                 rng_val;
    queue_of_rng_val_t        window;

    string                    msg;

    forever begin : simulation_loop
      bit disable_detected = 0;

      wait_enabled();

      fips_enable = (`gmv(ral.CONF.FIPS_ENABLE)         == MuBi4True);
      es_route    = (`gmv(ral.ENTROPY_CONTROL.ES_ROUTE) == MuBi4True);
      es_type     = (`gmv(ral.ENTROPY_CONTROL.ES_TYPE)  == MuBi4True);
      rng_bit_en  = (`gmv(ral.CONF.RNG_BIT_ENABLE)      == MuBi4True);
      rng_bit_sel = `gmv(ral.CONF.RNG_BIT_SEL);

      is_fips_mode  = fips_enable && !(es_route && es_type);

      fw_ov_insert = (cfg.otp_en_es_fw_over == MuBi8True) &&
                     (`gmv(ral.FW_OV_CONTROL.FW_OV_MODE) == MuBi4True) &&
                     (`gmv(ral.FW_OV_CONTROL.FW_OV_ENTROPY_INSERT) == MuBi4True);

      pass_count = 0;
      startup_fail_count = 0;
      seed_idx = 0;

      forever begin : enabled_loop

        window.delete();

        `uvm_info(`gfn, $sformatf("SEED_IDX: %01d", seed_idx), UVM_FULL)

        dut_fsm_phase = convert_seed_idx_to_phase(seed_idx, is_fips_mode, fw_ov_insert);

        case (dut_fsm_phase)
          BOOT: begin
            pass_requirement = 1;
            ht_fips_mode     = 0;
          end
          STARTUP: begin
            pass_requirement = 2;
            ht_fips_mode     = 1;
          end
          CONTINUOUS: begin
            pass_requirement = 1;
            ht_fips_mode     = 1;
          end
          HALTED: begin
            // When in the post-boot, halted state the DUT will continue to monitor health checks,
            // but not output CSRNG data or data to the TL ENTROPY_DATA register.
            // In this cass the pass_requirement and ht_fips_mode values don't mean anything
            pass_requirement = 0;
            ht_fips_mode     = 0;
          end
          default: begin
            `uvm_fatal(`gfn, "Invalid predicted dut state (bug in environment)")
          end
        endcase

        `uvm_info(`gfn, $sformatf("phase: %s\n", dut_fsm_phase.name), UVM_HIGH)

        window_size = rng_window_size(seed_idx, is_fips_mode, fw_ov_insert,
                                      `gmv(ral.HEALTH_TEST_WINDOWS.FIPS_WINDOW) * RNG_BUS_WIDTH);

        `uvm_info(`gfn, $sformatf("window_size: %08d\n", window_size), UVM_HIGH)

        // Note on RNG bit enable and window frame count:
        // When rng_bit_enable is selected, the function below repacks the data so that
        // the selected bit fills a whole frame.
        // This mirrors the DUT's behavior of repacking the data before the health checks
        //
        // Thus the number of window frames 4 times as large when the bit select is enabled.

        window_rng_frames = rng_bit_en ? window_size : (window_size / RNG_BUS_WIDTH);

        if (disable_detected) break; // No events. DUT has shutdown

        failures_in_window = health_check_rng_data(window, ht_fips_mode);

        if (failures_in_window > 0) begin
          pass_count = 0;
          // Most failures are handled in the alert counter registers
          // However the startup phase has special handling.
          startup_fail_count++;
        end else begin
          pass_count++;
          if (startup_fail_count < 2) startup_fail_count = 0;
        end

        process_failures(failures_in_window, fw_ov_insert, dut_fsm_phase, startup_fail_count);
        window.delete();

        // Once in the halted state, or in the fw_ov_insert_entropy mode, pre-tested data is
        // discarded after the health checks
        if ((dut_fsm_phase == HALTED) || fw_ov_insert) begin
          continue;
        end

        `uvm_info(`gfn, $sformatf("pass_requirement: %01d", pass_requirement), UVM_HIGH)
        `uvm_info(`gfn, $sformatf("raw_process_q.size: %01d", raw_process_q.size()), UVM_HIGH)
        `uvm_info(`gfn, $sformatf("sha_process_q.size: %01d", sha_process_q.size()), UVM_HIGH)

        if (pass_count >= pass_requirement && !threshold_alert_active && !main_sm_escalates) begin
          package_and_release_entropy();
          // update counters for processing next seed:
          pass_count = 0;
          seed_idx++;
        end
      end : enabled_loop
    end : simulation_loop
  endtask

  function void package_and_release_entropy();
    bit [FIPS_CSRNG_BUS_WIDTH - 1:0] fips_csrng;
    bit [CSRNG_BUS_WIDTH - 1:0] csrng_seed;
    bit entropy_data_reg_enable;

    entropy_data_reg_enable = (cfg.otp_en_es_fw_read == MuBi8True) &&
                              (ral.CONF.ENTROPY_DATA_REG_ENABLE.get_mirrored_value() == MuBi4True);

    `uvm_info(`gfn, $sformatf("raw_process_q.size(): %01d", raw_process_q.size()), UVM_FULL)
    `uvm_info(`gfn, $sformatf("sha_process_q.size(): %01d", sha_process_q.size()), UVM_FULL)
    fips_csrng = predict_fips_csrng();

    // package data for routing to SW and to CSRNG:
    csrng_seed = get_csrng_seed(fips_csrng);

    // Only inject entropy data if entropy data is enabled
    if (entropy_data_reg_enable) begin
      entropy_data_q.push_back(csrng_seed);
    end

    fips_csrng_q.push_back(fips_csrng);

  endfunction

  virtual task process_csrng();
    push_pull_item#(.HostDataWidth(FIPS_CSRNG_BUS_WIDTH))  item;
    `uvm_info(`gfn, "task \"process_csrng\" starting\n", UVM_FULL)

    forever begin
      bit match_found = 0;

      csrng_fifo.get(item);
      if(!cfg.en_scb) begin
        continue;
      end
      `uvm_info(`gfn, $sformatf("process_csrng: new item: %096h\n", item.d_data), UVM_HIGH)

      // Check to see whether a recov_alert should be expected
      if (seeds_out != 0 && get_csrng_seed(item.d_data) == prev_csrng_seed) begin
        `DV_CHECK_FATAL(ral.RECOV_ALERT_STS.ES_BUS_CMP_ALERT.predict(1'b1));
      end

      prev_csrng_seed = get_csrng_seed(item.d_data);
      seeds_out++;

      while (fips_csrng_q.size() > 0) begin : seed_trial_loop
        bit [FIPS_CSRNG_BUS_WIDTH - 1:0] prediction;
        // Unlike in the TL case, there is no need to leave seed predictions in the queue.
        prediction = fips_csrng_q.pop_front();
        if (prediction == item.d_data) begin
          csrng_seeds++;
          cfg.total_seeds_consumed++;
          match_found = 1;
          `uvm_info(`gfn, $sformatf("CSRNG Match found: %d\n", csrng_seeds), UVM_FULL)
          break;
        end else begin
          csrng_drops++;
          `uvm_info(`gfn, $sformatf("CSRNG Dropped seed: %d\n", csrng_drops), UVM_FULL)
          `uvm_info(`gfn, $sformatf("item: %0x\n", item.d_data), UVM_FULL)
          `uvm_info(`gfn, $sformatf("pred: %0x\n", prediction), UVM_FULL)
        end
      end : seed_trial_loop
      `DV_CHECK_EQ_FATAL(match_found, 1,
                         "All candidate csrng seeds have been checked, with no match")
    end
  endtask

  virtual task predict_fw_ov_wr_full();
    bit [StateWidthPad-1:0] sha3pad_state, sha3pad_state_next;
    bit cs_aes_halt_o;
    bit fips_enabled;
    bit es_route;
    bit es_type;
    bit is_fips_mode;
    bit fw_ov_entropy_insert;
    forever begin
      @(posedge cfg.clk_rst_vif.clk);
      if(!cfg.en_scb) begin
        continue;
      end

      fips_enabled = ral.CONF.FIPS_ENABLE.get_mirrored_value() == MuBi4True;
      es_route     = ral.ENTROPY_CONTROL.ES_ROUTE.get_mirrored_value() == MuBi4True;
      es_type      = ral.ENTROPY_CONTROL.ES_TYPE.get_mirrored_value() == MuBi4True;
      is_fips_mode = fips_enabled && !(es_route && es_type);

      fw_ov_entropy_insert =
          (cfg.otp_en_es_fw_over == MuBi8True) &&
          (ral.FW_OV_CONTROL.FW_OV_MODE.get_mirrored_value() == MuBi4True) &&
          (ral.FW_OV_CONTROL.FW_OV_ENTROPY_INSERT.get_mirrored_value() == MuBi4True);

      `DV_CHECK(uvm_hdl_read(pad_st_path, sha3pad_state))
      `DV_CHECK(uvm_hdl_read(pad_st_d_path, sha3pad_state_next))
      `DV_CHECK(uvm_hdl_read(aes_halt_o_path, cs_aes_halt_o))

      // SHA3 only accepts new words if the SHA3 pad SM is the StMessage state and cs_aes_halt_o
      // is low. If the SHA3 pad SM is about to leave the StMessage state, the sha3_nsg_ready
      // signal will go low. This signal is needed to predict whether the precon FIFO is full.
      sha3_msg_ready = !cs_aes_halt_o && (sha3pad_state == StMessage) &&
                       (sha3pad_state_next == StMessage);
      // precon_fifo_full is updated whenever a new word is written to fw_ov_wr_data.
      // The full signal however is needed for prediction with one cycle of delay since
      // pushing/popping the FIFO takes one clock cycle as well.
      precon_fifo_full_q = precon_fifo_full;
      // Predict whether the precon FIFO is full.
      fork
        begin
          `DV_SPINWAIT_EXIT(wait(predict_fw_ov_wr_fifo_full);,
                            cfg.clk_rst_vif.wait_n_clks(1);)
          // If the FIFO has entered the full state, set precon_fifo_full to high.
          if (fw_ov_entropy_insert && is_fips_mode && !sha3_msg_ready &&
              !precon_fifo_full_q && (precon_fifo_cnt == 2) && predict_fw_ov_wr_fifo_full) begin
            // Reset predict_fw_ov_wr_fifo_full for the next time the fw_ov_wr_fifo_full is read.
            predict_fw_ov_wr_fifo_full = 0;
            precon_fifo_full = 1;
            // Wait for sha3_msg_ready and reset precon_fifo_full and precon_fifo_cnt.
            `DV_SPINWAIT_EXIT(wait(sha3_msg_ready);,
                              wait(!dut_pipeline_enabled);)
            precon_fifo_full = 0;
            precon_fifo_cnt = 0;
          end else begin
            // Reset predict_fw_ov_wr_fifo_full for the next time the fw_ov_wr_fifo_full is read.
            predict_fw_ov_wr_fifo_full = 0;
          end
        end
      join_none
    end
  endtask

  virtual function void reset(string kind = "HARD");
    super.reset(kind);

    if(kind == "HARD") begin
      // reset local fifos queues and variables
      handle_disable_reset(HardReset);
      // Immediately inform the collect_entropy process
      // that the IP is disabled
      dut_pipeline_enabled = 0;
    end
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    // Normally at this point a simulation checks that all FIFOs and
    // Queues are empty.  However, for entropy_src, which has no 1-1
    // mapping between inputs and potential output, most of the simulations
    // are time-based not transaction-based.
    //
    // The scoreboard FIFOs are allowed to have some entries at end of sim
    // as these may represent:
    // - unused RNG inputs
    // - unused internal state corresponding to partial seeds
    // - dropped outputs (due to finite buffer space inside the DUT)
    //
    // Entropy Source contains assertions to ensure that bits are only dropped
    // when its internal buffers are full.  These checks depend on DUT internals,
    // so we cannot and do not perform them in the scoreboard.
  endfunction

  // If this is a bus transaction that addresses a register, return the model of that register.
  //
  // If HSIZE means that the transaction doesn't address exactly the bits of the register, this
  // generates a warning (because the scoreboard might not know how to model the access).
  function dv_base_reg register_for_txn_request(ahb_txn_request_item bus_req);
    uvm_reg_map    map;
    uvm_reg_addr_t addr_mask;
    uvm_reg_addr_t narrow_base_addr;
    uvm_reg_addr_t reconstructed_wide_addr;
    uvm_reg        register;
    dv_base_reg    dv_register;
    int unsigned   msb;

    map = ral.get_default_map().get_root_map();

    // Get the address of the base of ral's register map, but narrowed down to the address width of
    // the AHB interface that is being monitored.
    //
    // Suppose that the block actually only has 16 bytes of registers, which can be accessed with a
    // 4-bit byte offset. Maybe the AHB has a wider 8-bit address width, and the larger system has a
    // much wider address range, with the block at address 'h210.
    //
    // Decoding addresses within the block is fine because the entire range is address by just the
    // bottom address nibble. An access to the fifth byte (at address 'h214) will be seen by the AHB
    // monitor as accessing address 'h14. To look up a register at that address, we have to subtract
    // the base address of the block, narrowed to the bits visible from the AHB interface.
    //
    // In this example, the addr_mask variable would be 'hff and narrow_base_addr would be 'h10.
    addr_mask = ((m_ahb_addr_width < $bits(uvm_reg_addr_t)) ?
                 ((uvm_reg_addr_t'(1) << m_ahb_addr_width) - 1) :
                 '1);
    narrow_base_addr = map.get_base_addr() & addr_mask;

    // At this point, we can find an offset from the start of the register block by subtracting
    // narrow_base_addr. But uvm_reg_map::get_reg_by_offset expects an address, not an offset (a
    // rather confusing name...) As such, we want to addr map.get_base_addr() back again, which
    // gives the wide address that would have been mapped to this narrow address
    reconstructed_wide_addr = bus_req.m_addr - narrow_base_addr + map.get_base_addr();

    register = map.get_reg_by_offset(reconstructed_wide_addr);
    if (register == null) return null;

    if (!$cast(dv_register, register)) begin
      `uvm_error(get_full_name(),
                 $sformatf("The %0s register is not a dv_base_reg.", register.get_name()))
      return null;
    end

    msb = dv_register.get_msb_pos();

    // At this point, msb is the highest bit of the register that is contained in a field. We know
    // that bus_req.m_addr targets the bottom byte of the register, so must check that
    // (1 << bus_req.m_size) bytes covers the MSB.
    if (msb >= (1 << bus_req.m_size) * 8) begin
      `uvm_error(get_full_name(),
                 $sformatf({"Bus access to 0x%0h addresses the %0s register, ",
                            "whose highest field has msb %0d. But HSIZE is %0d so ",
                            "the access only covers the bits with indices up to %0d. ",
                            "Partial register access is not yet modelled in the scoreboard."},
                           bus_req.m_addr,
                           dv_register.get_name(),
                           msb,
                           bus_req.m_size,
                           (1 << bus_req.m_size) * 8 - 1))
    end

    return dv_register;
  endfunction

  // The write function for m_ahb_txn_imp, which is called for every bus transaction reported by the
  // monitor in the AHB agent.
  function void write_ahb_txn(ahb_txn_item bus_txn);
    uvm_reg register;

    // If the transaction didn't run to completion (so didn't get a response), we ignore it: there
    // was probably a reset in the middle of the transaction.
    if (bus_txn.m_response == null) return;

    // If the m_trans value for the request was TransIdle or TransBusy, the manager was either
    // taking a break between bursts or pausing a sequence of beats. The monitor shouldn't be
    // generating these items, but they definitely aren't relevant for the scoreboard anyway: ignore
    // them.
    if (bus_txn.m_request.m_trans inside {ahb_agent_pkg::TransIdle,
                                          ahb_agent_pkg::TransBusy}) return;

    register = register_for_txn_request(bus_txn.m_request);
    if (register != null) begin
      on_reg_txn(bus_txn, register);
    end else begin
      if (!bus_txn.m_response.m_resp) begin
        `uvm_error(get_full_name(),
                   $sformatf({"Bus transaction to address 0x%0h (where there is no register) ",
                              "didn't get an error response."},
                             bus_txn.m_request.m_addr))
        return;
      end
    end
  endfunction

  // Called with a complete, successful monitored bus transaction item and the register that it
  // addressed.
  function void on_reg_txn(ahb_txn_item txn, uvm_reg register);
    `uvm_info("reg_access",
              $sformatf("Saw %0s register %0s",
                        txn.m_request.m_write ? "write to" : "read from",
                        register.get_name()),
              UVM_LOW)
  endfunction
endclass
