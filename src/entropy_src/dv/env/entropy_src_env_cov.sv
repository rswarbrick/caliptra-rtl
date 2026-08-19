// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Covergoups that are dependent on run-time parameters that may be available
 * only in build_phase can be defined here
 * Covergroups may also be wrapped inside helper classes if needed.
 */

class entropy_src_env_cov extends dv_base_env_cov #(.CFG_T(entropy_src_env_cfg));
  `uvm_component_utils(entropy_src_env_cov)

  // A handle to the coverage collecting interface, which contains covergroups stimulated by this
  // coverage collector. Set this by calling set_cov_vif() before this module's build_phase.
  local virtual entropy_src_cov_if m_cov_vif;

  // A handle to an entropy_src_core_vif, which has been bound into an entropy_src_core instance.
  // Set this by calling set_core_vif() before this module's build_phase.
  local virtual entropy_src_core_if m_core_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (m_cov_vif == null) `uvm_fatal(get_full_name(), "Coverage interface has not been set.")
    if (m_core_vif == null) `uvm_fatal(get_full_name(), "Core interface has not been set.")
  endfunction

  // Set m_cov_vif. This must be called before build_phase.
  function void set_cov_vif(virtual entropy_src_cov_if cov_vif);
    m_cov_vif = cov_vif;
  endfunction

  // Return a handle to the entropy_src_cov_if in m_cov_vif.
  function virtual entropy_src_cov_if get_vif();
    return m_cov_vif;
  endfunction

  // Return true if the mirrored MODULE_ENABLE register is MuBi4True.
  local function bit is_module_enabled();
    return cfg.ral.MODULE_ENABLE.MODULE_ENABLE.get_mirrored_value() == MuBi4True;
  endfunction

  // Set m_core_vif. This must be called before build_phase.
  function void set_core_vif(virtual entropy_src_core_if core_vif);
    m_core_vif = core_vif;
  endfunction

  // A transaction has just tried to write a register that is locked by REGWEN being false.
  function void on_write_to_locked_register(ahb_txn_item txn, uvm_reg register);
    `uvm_info(get_full_name(),
              $sformatf("Attempt to write %0s while locked.", register.get_name()),
              UVM_FULL)

    // Cover sw_update_sample if this if the new data represents an attempted change from the
    // previous value (one that can be confirmed by a follow-up read).
    if (txn.m_request.m_wdata != register.get_mirrored_value()) begin
      m_cov_vif.cg_sw_update_sample(register.get_offset(),
                                    cfg.ral.SW_REGUPD.SW_REGUPD.get_mirrored_value(),
                                    is_module_enabled());
    end
  endfunction

  // The module_enable register has just been written, by software trying to enable/disable the
  // module.
  //
  //  requested_enable: True if the value being written to MODULE_ENABLE is MuBi4True.
  function void on_module_enable_write(bit requested_enable);
    import entropy_src_main_sm_pkg::state_e;

    // Get the current state machine state. This is reflected in the registers as MAIN_SM_STATE, but
    // can be snooped even more easily through m_core_vif.
    state_e main_sm_state = state_e'(m_core_vif.es_main_sm_state_i);

    // Get the value of me_regwen (a regwen bit for the MODULE_ENABLE register)
    bit me_regwen = cfg.ral.ME_REGWEN.ME_REGWEN.get_mirrored_value();

    m_cov_vif.cg_sw_disable_sample(me_regwen, requested_enable, main_sm_state);
  endfunction

endclass
