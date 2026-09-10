// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class entropy_src_base_test extends dv_base_test #(
    .CFG_T(entropy_src_env_cfg),
    .ENV_T(entropy_src_env)
  );

  `uvm_component_utils(entropy_src_base_test)
  `uvm_component_new


  // the base class dv_base_test creates the following instances:
  // entropy_src_env_cfg: cfg
  // entropy_src_env:     env

  // the base class also looks up UVM_TEST_SEQ plusarg to create and run that seq in
  // the run_phase; as such, nothing more needs to be done

   virtual function void build_phase(uvm_phase phase);
     super.build_phase(phase);

     configure_env();
   endfunction // build_phase

  virtual task run_phase(uvm_phase phase);
    fork
      begin
        // Because we want to cause something to happen before starting super.run_phase, we need an
        // overlapping objection to avoid the run_phase completing before we get as far as running
        // the real test.
        phase.raise_objection(this, "entropy_src_base_test run_phase");

        // The standard run_phase will immediately start running a virtual sequence. Inject an reset
        // beforehand on the main rst_ni line and also on the CSRNG interface.
        if (cfg.is_active) begin
          fork
            env.get_reset_agent().reset_now();
            cfg.csrng_rst_vif.apply_reset();
          join
        end

        super.run_phase(phase);

        phase.drop_objection(this, "entropy_src_base_test run_phase");
      end

      if (cfg.is_active) begin
        env.run_layered_register_vseq();
      end
    join
  endtask

  // An extension of dv_base_test::initialize_env_cfg
  //
  // The cfg.initialize() function configures itself by looking at the sizes in an associated AHB
  // virtual interface. Since this happens before building the environment, we have to provide up
  // that interface here.
  virtual function void initialize_env_cfg();
    if (!uvm_config_db#(virtual ahb_if)::get(env, "", "ahb_vif", cfg.m_ahb_vif)) begin
      `uvm_fatal(get_full_name(), "No ahb_vif supplied to environment.")
    end

    super.initialize_env_cfg();
  endfunction

  // The following knob settings will serve as the defaults.
  // Overrides should happen in the specific testcase.

  virtual function void configure_env();
    // Take plusargs into account.
    int rng_max_delay;
    if ($value$plusargs("rng_max_delay=%0d", rng_max_delay)) begin
      `uvm_info(`gfn, $sformatf("+rng_max_delay specified"), UVM_MEDIUM)
      cfg.rng_max_delay = rng_max_delay;
    end

    cfg.rng_ignores_backpressure       = 0;
    cfg.otp_en_es_fw_read_pct          = 100;
    cfg.otp_en_es_fw_read_inval_pct    = 0;
    cfg.otp_en_es_fw_over_pct          = 100;
    cfg.otp_en_es_fw_over_inval_pct    = 0;
    cfg.dut_cfg.en_intr_pct            = 75;
    cfg.dut_cfg.me_regwen_pct          = 100;
    cfg.dut_cfg.sw_regupd_pct          = 100;

    cfg.dut_cfg.module_enable_pct      = 100;
    cfg.dut_cfg.type_bypass_pct        = 100;
    cfg.dut_cfg.preconfig_disable_pct  = 100;
    cfg.dut_cfg.fips_flag_pct          = 75;
    cfg.dut_cfg.rng_fips_pct           = 75;
    // Unless testing bad MuBi's the initial value for fw_ov_insert_start should always be false
    cfg.dut_cfg.fw_ov_insert_start_pct = 0;

    // Setting the following parameters to less than zero means that random reconfig or random
    // fatal alerts will not be driven by the RNG virtual sequence unless they are overridden
    // in one of the derived test classes.
    cfg.mean_rand_reconfig_time   = -1.0;
    cfg.mean_rand_csr_alert_time  = -1.0;
    cfg.max_silent_reconfig_time  = -1.0;
    cfg.soft_mtbf                 = -1.0;
    cfg.hard_mtbf                 = -1.0;

    cfg.dut_cfg.bad_mubi_cfg_pct       = 0;
    cfg.induce_targeted_transition_pct = 0;
    cfg.dut_cfg.tight_thresholds_pct   = 0;

    // Set the maximum threshold for the observe FIFO threshold randomization to ObserveFifoDepth.
    cfg.dut_cfg.max_observe_fifo_threshold = entropy_src_reg_pkg::ObserveFifoDepth;

  endfunction

  virtual function void configure_sequence(uvm_sequence_base seq);
    entropy_src_base_vseq vseq;

    super.configure_sequence(seq);

    if (!$cast(vseq, seq)) begin
      `uvm_fatal(get_full_name(), "Test expects to run instances of entropy_src_base_vseq.")
    end

    vseq.set_reset_sequencer(env.get_reset_agent().get_sequencer());
  endfunction

endclass : entropy_src_base_test
