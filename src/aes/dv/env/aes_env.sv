// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class aes_env extends dv_base_env #(
    .CFG_T              (aes_env_cfg),
    .COV_T              (aes_env_cov),
    .VIRTUAL_SEQUENCER_T(aes_virtual_sequencer),
    .SCOREBOARD_T       (aes_scoreboard)
  );
  `uvm_component_utils(aes_env)

  `uvm_component_new

  local ahb_mgr_agent m_ahb_mgr_agent;

  function void build_phase(uvm_phase phase);
    // The HDL path to aes_clp_wrapper (supplied through the config db)
    string hdl_path;

    super.build_phase(phase);

    if (!uvm_config_db#(virtual ahb_if)::get(this, "", "ahb_vif", cfg.ahb_vif)) begin
      `uvm_fatal(get_full_name(), "No ahb_vif supplied to environment.")
    end

    if (!uvm_config_db#(int unsigned)::get(this, "", "ahb_subordinate_index",
                                           cfg.m_subordinate_idx)) begin
      `uvm_fatal(get_full_name(), "No subordinate index supplied to environment.")
    end

    // Pass the AHB interface to the AHB agent
    uvm_config_db#(virtual ahb_if)::set(this, "m_ahb_mgr_agent*", "vif", cfg.ahb_vif);

    m_ahb_mgr_agent = ahb_mgr_agent::type_id::create("m_ahb_mgr_agent", this);

    // Get the path to aes_clp_wrapper and pass it to our config object (allowing the config object
    // to make HDL paths to its registers)
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

    // TODO(caliptra-port): when an AHB monitor / analysis port is added to ahb_mgr_agent, hook it
    // up to the scoreboard here. The OpenTitan TL flow split traffic into a/d channel FIFOs;
    // AES only needs one AHB bus.
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
