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

  local ahb_mgr_agent   m_ahb_mgr_agent;
  local ahb_reg_adapter m_ahb_reg_adapter;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Publish the AHB agent's cfg object into the config DB so the agent picks it up in its own
    // build_phase, then create the agent and a stateless register adapter.
    uvm_config_db#(ahb_agent_cfg)::set(this, "m_ahb_mgr_agent*", "cfg", cfg.m_ahb_agent_cfg);
    cfg.m_ahb_agent_cfg.en_cov = cfg.en_cov;

    m_ahb_mgr_agent   = ahb_mgr_agent::type_id::create("m_ahb_mgr_agent", this);
    m_ahb_reg_adapter = ahb_reg_adapter::type_id::create("m_ahb_reg_adapter");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // TODO(caliptra-port): when an AHB monitor / analysis port is added to ahb_mgr_agent, hook it
    // up to the scoreboard here. The OpenTitan TL flow split traffic into a/d channel FIFOs;
    // AES only needs one AHB bus.
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);

    // Bind the RAL default_map to the AHB sequencer + adapter so register accesses are issued via
    // the AHB agent.
    if (cfg.m_ahb_agent_cfg.is_active) begin
      cfg.ral.default_map.set_sequencer(m_ahb_mgr_agent.sequencer, m_ahb_reg_adapter);
    end
  endfunction

endclass
