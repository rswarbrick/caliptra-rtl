// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class entropy_src_env extends dv_base_env #(
    .CFG_T              (entropy_src_env_cfg),
    .COV_T              (entropy_src_env_cov),
    .VIRTUAL_SEQUENCER_T(entropy_src_virtual_sequencer),
    .SCOREBOARD_T       (entropy_src_scoreboard)
  );
  `uvm_component_utils(entropy_src_env)

  push_pull_agent#(.HostDataWidth(entropy_src_pkg::RNG_BUS_WIDTH))         m_rng_agent;
  push_pull_agent#(.HostDataWidth(entropy_src_pkg::FIPS_CSRNG_BUS_WIDTH))  m_csrng_agent;
  push_pull_agent#(.HostDataWidth(0))                                      m_aes_halt_agent;

  // Agent to drive the reset interface
  local reset_agent m_reset_agent;

  // Agent to access the AHB interface
  local ahb_mgr_agent m_ahb_mgr_agent;

  // A reg_predictor that will be connected to the register model in cfg
  local uvm_reg_predictor #(ahb_txn_item) m_reg_predictor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    string hdl_path;

    super.build_phase(phase);

    // Lookup the CSRNG auxiliary reset. (Is only applied at end-of-sim)
    if (!uvm_config_db#(virtual clk_rst_if)::get(this, "", "csrng_rst_vif", cfg.csrng_rst_vif))
      begin
        `uvm_fatal(`gfn, "failed to get csrng_rst_if from uvm_config_db")
      end

    // Look up the AHB interface. Note that a block-level test will actually have done this already
    // (in order that the cfg object's initialize() function could work). Leave the lookup in place
    // here so that it also works for vertical reuse.
    if (cfg.m_ahb_vif == null &&
        !uvm_config_db#(virtual ahb_if)::get(this, "", "ahb_vif", cfg.m_ahb_vif)) begin
      `uvm_fatal(get_full_name(), "No ahb_vif supplied to environment.")
    end

    if (!uvm_config_db#(virtual reset_if)::get(this, "", "reset_vif", cfg.m_reset_vif)) begin
      `uvm_fatal(get_full_name(), "No reset_vif supplied to environment.")
    end

    if (!uvm_config_db#(int unsigned)::get(this, "", "ahb_subordinate_index",
                                           cfg.m_subordinate_idx)) begin
      `uvm_fatal(get_full_name(), "No subordinate index supplied to environment.")
    end

    m_reset_agent = reset_agent::type_id::create("m_reset_agent", this);
    m_reset_agent.set_vif(cfg.m_reset_vif);

    uvm_config_db#(virtual ahb_if)::set(this, "m_ahb_mgr_agent*", "vif", cfg.m_ahb_vif);
    m_ahb_mgr_agent = ahb_mgr_agent::type_id::create("m_ahb_mgr_agent", this);

    // Passing the address width of the AHB interface to the scoreboard, so that it knows how to
    // interpret offsets relative to a base address that isn't itself representable on the
    // interface.
    scoreboard.m_ahb_addr_width = cfg.m_ahb_vif.addr_width;

    m_rng_agent = push_pull_agent#(.HostDataWidth(entropy_src_pkg::RNG_BUS_WIDTH))::type_id::
                  create("m_rng_agent", this);
    uvm_config_db#(push_pull_agent_cfg#(.HostDataWidth(entropy_src_pkg::RNG_BUS_WIDTH)))::set
                  (this, "m_rng_agent*", "cfg", cfg.m_rng_agent_cfg);
    cfg.m_rng_agent_cfg.agent_type = push_pull_agent_pkg::PushAgent;
    cfg.m_rng_agent_cfg.if_mode    = dv_utils_pkg::Host;
    cfg.m_rng_agent_cfg.en_cov     = cfg.en_cov;

    // To correctly model ast/rng behavior, back-to-back entropy is not allowed
    // The actual AST/RNG ingores ready-signal backpressure, but this can be inconvenient for
    // tests which use a fixed (non-random) RNG sequence.  So the backpressure support is done
    // on a test by test basis.
    cfg.m_rng_agent_cfg.zero_delays = 0;
    cfg.m_rng_agent_cfg.host_delay_min = 1;
    cfg.m_rng_agent_cfg.host_delay_max = cfg.rng_max_delay;
    cfg.m_rng_agent_cfg.ignore_push_host_backpressure = cfg.rng_ignores_backpressure;

    m_csrng_agent = push_pull_agent#(.HostDataWidth(entropy_src_pkg::FIPS_CSRNG_BUS_WIDTH))::
                    type_id::create("m_csrng_agent", this);
    uvm_config_db#(push_pull_agent_cfg#(.HostDataWidth(entropy_src_pkg::FIPS_CSRNG_BUS_WIDTH)))::set
                  (this, "m_csrng_agent*", "cfg", cfg.m_csrng_agent_cfg);
    cfg.m_csrng_agent_cfg.agent_type = push_pull_agent_pkg::PullAgent;
    cfg.m_csrng_agent_cfg.if_mode    = dv_utils_pkg::Host;
    cfg.m_csrng_agent_cfg.en_cov     = cfg.en_cov;

    m_aes_halt_agent = push_pull_agent#(.HostDataWidth(0))::
                      type_id::create("m_aes_halt_agent", this);
    uvm_config_db#(push_pull_agent_cfg#(.HostDataWidth(0)))::set
                  (this, "m_aes_halt_agent*", "cfg", cfg.m_aes_halt_agent_cfg);
    cfg.m_aes_halt_agent_cfg.agent_type          = push_pull_agent_pkg::PullAgent;
    cfg.m_aes_halt_agent_cfg.if_mode             = dv_utils_pkg::Device;
    cfg.m_aes_halt_agent_cfg.pull_handshake_type = push_pull_agent_pkg::FourPhase;
    // When CSRNG has just started operating its AES, it may take up to 48 cycles to acknowledge
    // the request. When running ast/rng at the maximum rate (this is an unrealistic scenario
    // primarily used for reaching coverage metrics) we reduce the acknowledge delay to the minimum
    // to reduce backpressure and avoid entropy bits from being dropped from the pipeline as our
    // scoreboard cannot handle this.
    cfg.m_aes_halt_agent_cfg.zero_delays = 0;
    cfg.m_aes_halt_agent_cfg.device_delay_min = 0;
    cfg.m_aes_halt_agent_cfg.device_delay_max = (cfg.rng_max_delay == 1) ? 0 : 48;
    // CSRNG drops its ack in the cycle after entropy_src has dropped its req.
    cfg.m_aes_halt_agent_cfg.ack_lo_delay_max = 1;

    m_reg_predictor = uvm_reg_predictor#(ahb_txn_item)::type_id::create("m_reg_predictor", this);
    m_reg_predictor.adapter = ahb_mgr_reg_adapter::type_id::create("adapter");
    m_reg_predictor.map = cfg.ral.default_map;

    if (!uvm_config_db#(virtual entropy_subsys_fifo_exception_if#(1))::get(this, "",
                        "precon_fifo_vif", cfg.precon_fifo_vif)) begin
      `uvm_fatal(get_full_name(), "failed to get precon_fifo_vif from uvm_config_db")
    end

    if (!uvm_config_db#(virtual entropy_subsys_fifo_exception_if#(1))::get(this, "",
                        "bypass_fifo_vif", cfg.bypass_fifo_vif)) begin
      `uvm_fatal(get_full_name(), "failed to get precon_fifo_vif from uvm_config_db")
    end

    if (!uvm_config_db#(virtual entropy_src_fsm_cov_if)::get(this, "",
                        "main_sm_cov_vif", cfg.fsm_tracking_vif)) begin
      `uvm_fatal(get_full_name(), "failed to get fsm_tracking_vif from uvm_config_db")
    end

    if (!uvm_config_db#(virtual pins_if#(8))::get(this, "", "otp_en_es_fw_read_vif",
        cfg.otp_en_es_fw_read_vif)) begin
      `uvm_fatal(get_full_name(), "failed to get otp_en_es_fw_read_vif from uvm_config_db")
    end
    if (!uvm_config_db#(virtual pins_if#(8))::get(this, "", "otp_en_es_fw_over_vif",
        cfg.otp_en_es_fw_over_vif)) begin
      `uvm_fatal(get_full_name(), "failed to get otp_en_es_fw_over_vif from uvm_config_db")
    end

    if (!uvm_config_db#(virtual entropy_src_assertion_if)::get(this, "", "assertion_vif",
                                                               cfg.m_assertion_vif)) begin
      `uvm_fatal(get_full_name(), "failed to get assertion_vif from uvm_config_db")
    end

    // Get the path to the module instance and pass it to our config object (allowing the config
    // object to make HDL paths to its registers)
    if (!uvm_config_db#(string)::get(this, "", "hdl_path", hdl_path)) begin
      `uvm_fatal(get_full_name(), "Failed to get hdl_path from uvm_config_db.")
    end
    cfg.set_hdl_path(hdl_path);

    if (!uvm_config_db#(virtual entropy_src_path_if)::get(this, "", "entropy_src_path_vif",
         cfg.entropy_src_path_vif)) begin
      `uvm_fatal(`gfn, "failed to get entropy_src_path_vif from uvm_config_db")
    end
    if (!uvm_config_db#(virtual entropy_src_core_if)::get(this, "", "core_vif",
                                                          cfg.m_core_vif)) begin
      `uvm_fatal(get_full_name(), "Failed to get core_vif from uvm_config_db.")
    end

    if (cfg.en_cov) begin
      virtual entropy_src_cov_if cov_vif;
      if (!uvm_config_db#(virtual entropy_src_cov_if)::get
          (null, "*.env" , "entropy_src_cov_if", cov_vif)) begin
        `uvm_fatal(`gfn, $sformatf("Failed to get entropy_src_cov_if from uvm_config_db"))
      end

      cov.set_cov_vif(cov_vif);
      cov.set_core_vif(cfg.m_core_vif);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    uvm_reg_map maps[$];

    super.connect_phase(phase);

    m_rng_agent.monitor.analysis_port.connect(scoreboard.rng_fifo.analysis_export);
    m_csrng_agent.monitor.analysis_port.connect(scoreboard.csrng_fifo.analysis_export);

    virtual_sequencer.csrng_sequencer_h    = m_csrng_agent.sequencer;
    virtual_sequencer.rng_sequencer_h      = m_rng_agent.sequencer;
    virtual_sequencer.aes_halt_sequencer_h = m_aes_halt_agent.sequencer;

    // Bind the RAL default_map to the AHB sequencer + adapter so register accesses are issued via
    // the AHB agent.
    if (m_ahb_mgr_agent.get_is_active() == UVM_ACTIVE) begin
      cfg.ral.default_map.set_sequencer(m_ahb_mgr_agent.get_register_layering_sequencer(),
                                        m_ahb_mgr_agent.get_reg_adapter());
    end

    // Tell the AHB agent which registers are mapped to which subordinate.
    cfg.ral.get_maps(maps);
    foreach (maps[i]) begin
      m_ahb_mgr_agent.register_subordinate_for_map(maps[i], cfg.m_subordinate_idx);
    end

    m_ahb_mgr_agent.m_transaction_port.connect(m_reg_predictor.bus_in);
    m_ahb_mgr_agent.m_transaction_port.connect(scoreboard.m_ahb_txn_imp);
  endfunction

  function reset_agent get_reset_agent();
    return m_reset_agent;
  endfunction

  // Run the vseq inside m_ahb_mgr_agent that will support front-door register accesses
  //
  // This should be run by the test in the run phase; the task will never return.
  task run_layered_register_vseq();
    if (m_ahb_mgr_agent.get_is_active() != UVM_ACTIVE) begin
      `uvm_fatal(get_full_name(), "Cannot run layering vseq: the agent is not active.")
    end
    m_ahb_mgr_agent.run_layered_register_vseq();
  endtask
endclass
