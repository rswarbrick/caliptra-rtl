// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class sha3_ctrl_env extends dv_base_env #(
    .CFG_T              (sha3_ctrl_env_cfg),
    .COV_T              (sha3_ctrl_env_cov),
    .VIRTUAL_SEQUENCER_T(sha3_ctrl_virtual_sequencer),
    .SCOREBOARD_T       (sha3_ctrl_scoreboard)
  );
  `uvm_component_utils(sha3_ctrl_env)

  // Agent to access the AHB interface
  local ahb_mgr_agent m_ahb_mgr_agent;

  // A reg_predictor that will be connected to the register model in cfg
  local uvm_reg_predictor #(ahb_txn_item) m_reg_predictor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    // The HDL path to sha3_ctrl (supplied through the config db)
    string hdl_path;

    super.build_phase(phase);

    if (!uvm_config_db#(virtual ahb_if)::get(this, "", "ahb_vif", cfg.m_ahb_vif)) begin
      `uvm_fatal(get_full_name(), "No ahb_vif supplied to environment.")
    end
    if (!uvm_config_db#(virtual sha3_intr_if)::get(this, "", "intr_vif", cfg.m_intr_vif)) begin
      `uvm_fatal(get_full_name(), "Failed to get intr_vif from uvm_config_db.")
    end
    if (!uvm_config_db#(virtual pins_if #(1))::get(this, "", "busy_vif", cfg.m_busy_vif)) begin
      `uvm_fatal(get_full_name(), "Failed to get busy_vif from uvm_config_db.")
    end

    if (!uvm_config_db#(int unsigned)::get(this, "", "ahb_subordinate_index",
                                           cfg.m_subordinate_idx)) begin
      `uvm_fatal(get_full_name(), "No subordinate index supplied to environment.")
    end

    uvm_config_db#(virtual ahb_if)::set(this, "m_ahb_mgr_agent*", "vif", cfg.m_ahb_vif);
    m_ahb_mgr_agent = ahb_mgr_agent::type_id::create("m_ahb_mgr_agent", this);

    m_reg_predictor = uvm_reg_predictor#(ahb_txn_item)::type_id::create("m_reg_predictor", this);
    m_reg_predictor.adapter = ahb_mgr_reg_adapter::type_id::create("adapter");
    m_reg_predictor.map = cfg.ral.default_map;

    // Get the path to the module instance and pass it to our config object (allowing the config
    // object to make HDL paths to its registers)
    if (!uvm_config_db#(string)::get(this, "", "hdl_path", hdl_path)) begin
      `uvm_fatal(get_full_name(), "Failed to get hdl_path from uvm_config_db.")
    end
    cfg.set_hdl_path(hdl_path);
  endfunction

  function void connect_phase(uvm_phase phase);
    uvm_reg_map maps[$];

    super.connect_phase(phase);

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

  endfunction

  function ahb_mgr_agent get_ahb_mgr_agent();
    return m_ahb_mgr_agent;
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
