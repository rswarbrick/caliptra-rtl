// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class aes_base_vseq extends dv_base_vseq #(.CFG_T               (aes_env_cfg),
                                           .RAL_T               (aes_dv_reg),
                                           .COV_T               (aes_env_cov),
                                           .VIRTUAL_SEQUENCER_T (aes_virtual_sequencer));

  `uvm_object_utils(aes_base_vseq)

  aes_reg2hw_t       aes_reg;
  aes_seq_item       aes_item;
  aes_seq_item       aes_item_queue[$];
  aes_message_item   aes_message;
  aes_message_item   message_queue[$];

  // various knobs to enable certain routines
  bit                do_aes_init   = 1'b1;
  bit                global_reset  = 1'b0;

  // If this flag is set, the virtual sequence is being run in a situation where a reset will
  // eventually be applied. The sequence should not inject its own resets, and should complete
  // immediately when the reset is applied.
  //
  // This flag is set on the children of aes_stress_all_vseq if it has been configured with
  // require_resettable().
  bit                m_external_reset = 0;

  // handshake with key manager
  bit                key_used      = 0;
  bit                key_rdy       = 0;
  bit                new_key       = 0;

  // A flag used by start_sideload_seq / stop_sideload_seq to track whether a sideload sequence is
  // currently running. If true, there is currently a process running the sideload_sequences task.
  local bit          m_sideload_seq_running;

  // An event to control a sideload_sequences task if one is running. When the event is triggered,
  // the task will tell the currently running sequence to stop, then will clear
  // m_sideload_seq_running and exit.
  local uvm_event    m_stop_sideload_seqs_event;

  function new (string name="");
    super.new(name);
    m_stop_sideload_seqs_event = new();
  endfunction

  virtual task dut_init(string reset_kind = "HARD");
    super.dut_init();

    if (do_aes_init) aes_init();
    aes_item = new();
    aes_message_init();
    // `uvm_info(`gfn, $sformatf("\n TL delay: [%d:%d] \n zero delay %d",
    //           cfg.m_tl_agent_cfg.d_ready_delay_min,cfg.m_tl_agent_cfg.d_ready_delay_max,
    //           cfg.zero_delays  ), UVM_MEDIUM)
  endtask


  virtual task aes_reset(string kind = "HARD");
    global_reset = 1;
    wait(global_reset == 0); // make seq is ready for rest
    apply_reset(kind);
    #1ps; // workaround for race condition in dv_lib
    wait(!cfg.clk_rst_vif.rst_n); // under reset will not work here..
    wait(cfg.clk_rst_vif.rst_n);
  endtask // aes_reset

  // Read the STATUS register and write its 6-bit value to status_value.
  //
  // Exits early on reset.
  task read_status(output logic [5:0] status_value);
    uvm_status_e txn_status;

    ral.aes_core.STATUS.read(txn_status, status_value);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) begin
      `uvm_error(get_full_name(), "Failed to read STATUS register.")
    end
  endtask

  // Repeatedly read the given register until its value matches desired_value when both are masked.
  //
  // Exits early on reset.
  task masked_spinwait_register(uvm_reg        register,
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

  // Repeatedly read the given register until the bit at bit_idx has the desired value.
  task masked_spinwait_bit(uvm_reg register, bit desired_value, int unsigned bit_idx);
    uvm_reg_data_t mask = (uvm_reg_data_t'(1) << bit_idx) - 1;
    masked_spinwait_register(register, desired_value ? mask : '0, mask);
  endtask

  // Repeatedly read the STATUS register until its IDLE field is true
  //
  // Exits early on reset.
  task spinwait_status_idle();
    masked_spinwait_bit(ral.aes_core.STATUS, 1'b1, ral.aes_core.STATUS.IDLE.get_lsb_pos());
  endtask

  // Spinwait on the STATUS register until its INPUT_READY field is asserted.
  //
  // Returns early on reset.
  task spinwait_input_ready();
    masked_spinwait_bit(ral.aes_core.STATUS, 1'b1, ral.aes_core.STATUS.INPUT_READY.get_lsb_pos());
  endtask

  // Spinwait on the STATUS register until its OUTPUT_VALID field is asserted.
  //
  // Returns early on reset.
  task spinwait_output_valid();
    masked_spinwait_bit(ral.aes_core.STATUS, 1'b1, ral.aes_core.STATUS.OUTPUT_VALID.get_lsb_pos());
  endtask

  // Corrupt the mirrored value of a register in order that needs_update() will return 1
  //
  // This works by calling predict() then set(), but this only works when the register has a field
  // where get_access() returns RW or WO (where we can guess the value to pass to set to restore the
  // desired value).
  function void trigger_needs_update(uvm_reg register);
    uvm_reg_field  fields[$];

    // Nothing to do if the register already thinks it needs an update
    if (register.needs_update()) return;

    register.get_fields(fields);

    foreach (fields[i]) begin
      string field_access = fields[i].get_access();
      if (field_access inside {"RW", "WO"}) begin
        uvm_reg_data_t desired = fields[i].get();
        if (!fields[i].predict(.value(~desired))) begin
          `uvm_error(get_full_name(),
                     $sformatf("Failed to predict value for %0s field %0s.",
                               register.get_name(), fields[i].get_name()))
        end
        fields[i].set(desired);
        return;
      end
    end

    // If we get here, we didn't find any fields where we could force needs_update to be true.
    `uvm_error(get_full_name(),
               $sformatf("Can't trigger needs_update for register %0s.", register.get_name()))
  endfunction

  // Update a register to match its desired value (if the predicted value doesn't match).
  //
  // This is designed for a shadowed register so performs a double write when doing so. With this
  // task, you can write to a shadowed register by setting the value and then calling this task.
  task double_update_to_desired(uvm_reg dest_reg);
    if (!dest_reg.needs_update()) return;

    for (int unsigned i = 0; i < 2; i++) begin
      uvm_status_e txn_status;
      trigger_needs_update(dest_reg);

      dest_reg.update(txn_status);

      if (cfg.under_reset) return;
      if (txn_status != UVM_IS_OK) begin
        `uvm_error(get_full_name(),
                   $sformatf("Failed to update %0s register (iteration %0d).",
                             dest_reg.get_name(), i))
      end
    end
  endtask

  // Double-write the given register
  //
  // This is needed for a register that is shadowed. Exits early on reset.
  task double_write(uvm_reg dest_reg, bit [31:0] wdata);
    dest_reg.set(wdata);
    double_update_to_desired(dest_reg);
  endtask

  // Set up basic aes features.
  //
  // Return early on reset.
  virtual task aes_init();
    uvm_status_e txn_status;
    bit [31:0] aes_ctrl = '0;
    bit [31:0] aes_ctrl_aux = '0;
    bit [31:0] aes_trigger = '0;
    // Lock and check locking of auxiliary control register (1) or not (0).
    bit lock_ctrl_aux = $urandom_range(0, 1);

    `uvm_info(`gfn, $sformatf("\n\t ----| CHECKING FOR IDLE"), UVM_HIGH)
    spinwait_status_idle();
    if (cfg.under_reset) return;

    // initialize control register
    aes_ctrl[1:0]  = aes_pkg::AES_ENC;   // 2'b01
    aes_ctrl[7:2]  = aes_pkg::AES_ECB;   // 6'b00_0001
    aes_ctrl[10:8] = aes_pkg::AES_128;   // 3'b001

    double_write(ral.aes_core.CTRL_SHADOWED, aes_ctrl);
    if (cfg.under_reset) return;

    spinwait_status_idle();
    if (cfg.under_reset) return;

    ral.aes_core.CTRL_SHADOWED.read(txn_status, aes_ctrl);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to read CTRL_SHADOWED.")

    // Write auxiliary control register and make sure the update went through, i.e., the register
    // isn't locked already.
    ral.aes_core.CTRL_AUX_SHADOWED.KEY_TOUCH_FORCES_RESEED.set(cfg.do_reseed);
    double_update_to_desired(ral.aes_core.CTRL_AUX_SHADOWED);
    if (cfg.under_reset) return;

    ral.aes_core.CTRL_AUX_SHADOWED.read(txn_status, aes_ctrl_aux);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to read CTRL_AUX_SHADOWED.")

    if (aes_ctrl_aux[0] != cfg.do_reseed) begin
      `uvm_error(get_full_name(),
                 $sformatf("Writing %0d to KEY_TOUCH_FORCES_RESEED has not set the value.",
                           cfg.do_reseed))
    end

    // Lock auxiliary control register and try overwriting it afterwards.
    if (lock_ctrl_aux) begin
      `uvm_info(`gfn, "Locking auxiliary control register", UVM_MEDIUM)
      set_regwen(0);
      if (cfg.under_reset) return;

      `uvm_info(`gfn, "Try overwriting locked auxiliary control register", UVM_MEDIUM)

      ral.aes_core.CTRL_AUX_SHADOWED.KEY_TOUCH_FORCES_RESEED.set(!cfg.do_reseed);
      double_update_to_desired(ral.aes_core.CTRL_AUX_SHADOWED);
      if (cfg.under_reset) return;

      // Read the current value back to ensure the contents of the register didn't change.
      ral.aes_core.CTRL_AUX_SHADOWED.read(txn_status, aes_ctrl_aux);
      if (cfg.under_reset) return;
      if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to read CTRL_AUX_SHADOWED.")

      if (aes_ctrl_aux[0] != cfg.do_reseed) begin
        `uvm_error(get_full_name(),
                   $sformatf({"Managed to change KEY_TOUCH_FORCES_RESEED to %0d ",
                              "despite having locked the register."},
                             aes_ctrl_aux[0]))
      end

      // Try unlocking the auxiliary control register and overwriting it afterwards. This is not
      // possible either as the lock persists until the next reset.
      set_regwen(1);
      if (cfg.under_reset) return;

      ral.aes_core.CTRL_AUX_SHADOWED.KEY_TOUCH_FORCES_RESEED.set(!cfg.do_reseed);
      double_update_to_desired(ral.aes_core.CTRL_AUX_SHADOWED);
      if (cfg.under_reset) return;

      // Read the current value back to ensure the contents of the register didn't change.
      ral.aes_core.CTRL_AUX_SHADOWED.read(txn_status, aes_ctrl_aux);
      if (cfg.under_reset) return;
      if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to read CTRL_AUX_SHADOWED.")

      if (aes_ctrl_aux[0] != cfg.do_reseed) begin
        `uvm_error(get_full_name(),
                   $sformatf("Managed to unlock KEY_TOUCH_FORCES_RESEED and change it to %0d.",
                             aes_ctrl_aux[0]))
      end
    end else begin
      // Don't lock it. This is the default value after reset. The write is mostly for coverage.
      set_regwen(1);
    end
  endtask // aes_init

  // Write 1 to the TRIGGER register
  virtual task trigger();
    uvm_status_e txn_status;
    ral.aes_core.TRIGGER.write(txn_status, 32'h00000001);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to write TRIGGER.")
  endtask // trigger

  virtual task clear_regs(clear_t clr_vector);
    uvm_status_e txn_status;
    string txt="";
    bit [TL_DW:0] reg_val = '0;
    txt = {txt, $sformatf("\n data_out: \t %0b", clr_vector.dataout)};
    txt = {txt, $sformatf("\n key_iv_data_in: \t %0b", clr_vector.key_iv_data_in)};
    txt = {txt, $sformatf("\n vector: \t %0b", clr_vector)};
    `uvm_info(`gfn, $sformatf("%s",txt), UVM_MEDIUM)

    ral.aes_core.TRIGGER.set(0);
    ral.aes_core.TRIGGER.KEY_IV_DATA_IN_CLEAR.set(clr_vector.key_iv_data_in);
    ral.aes_core.TRIGGER.DATA_OUT_CLEAR.set(clr_vector.dataout);
    ral.aes_core.TRIGGER.update(txn_status);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to update TRIGGER.")
  endtask // clear_registers


  virtual task prng_reseed();
    uvm_status_e txn_status;

    ral.aes_core.TRIGGER.write(txn_status, 1 << ral.aes_core.TRIGGER.PRNG_RESEED.get_lsb_pos());
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to write TRIGGER.")
  endtask // prng_reseed


  virtual task set_regwen(bit val);
    uvm_status_e txn_status;
    ral.aes_core.CTRL_AUX_REGWEN.write(txn_status, val);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to write REGWEN.")
  endtask // set_regwen


  virtual task set_operation(bit [1:0] operation);
    ral.aes_core.CTRL_SHADOWED.OPERATION.set(operation);
    double_update_to_desired(ral.aes_core.CTRL_SHADOWED);
  endtask // set_operation


  virtual task set_mode(bit [5:0] mode);
    ral.aes_core.CTRL_SHADOWED.MODE.set(mode);
    double_update_to_desired(ral.aes_core.CTRL_SHADOWED);
  endtask


  virtual task set_key_len(bit [2:0] key_len);
    ral.aes_core.CTRL_SHADOWED.KEY_LEN.set(key_len);
    double_update_to_desired(ral.aes_core.CTRL_SHADOWED);
  endtask // set_key_len


  virtual task set_sideload(bit sideload);
    ral.aes_core.CTRL_SHADOWED.SIDELOAD.set(sideload);
    double_update_to_desired(ral.aes_core.CTRL_SHADOWED);
  endtask


  virtual task set_prng_reseed_rate(prs_rate_e reseed_rate);
    ral.aes_core.CTRL_SHADOWED.PRNG_RESEED_RATE.set(reseed_rate);
    double_update_to_desired(ral.aes_core.CTRL_SHADOWED);
  endtask


  virtual task set_manual_operation(bit manual_operation);
    ral.aes_core.CTRL_SHADOWED.MANUAL_OPERATION.set(manual_operation);
    double_update_to_desired(ral.aes_core.CTRL_SHADOWED);
  endtask


  // Write the supplied key to registers, in two shares
  //
  // If do_b2b is true, enqueue the write transactions as quickly as possible, which should mean the
  // writes are back-to-back.
  //
  // Exits early on reset.
  virtual task write_key(bit [7:0][31:0] key [2], bit do_b2b);
    uvm_status_e txn_status;

    `uvm_info(`gfn, $sformatf("\n\t --- back to back transactions : %b", do_b2b), UVM_MEDIUM)

    foreach (key[0][i]) begin
      ral.aes_core.KEY_SHARE0[i].write(txn_status, key[0][i]);
      if (cfg.under_reset) return;
    end
    foreach (key[1][i]) begin
      ral.aes_core.KEY_SHARE1[i].write(txn_status, key[1][i]);
      if (cfg.under_reset) return;
    end
  endtask // write_key

  // Read the two shares of the key from registers
  //
  // Exits early on reset.
  virtual task read_key(output bit [7:0][31:0] key [2]);
    for (int unsigned share_idx = 0; share_idx < 2; share_idx++) begin
      for (int unsigned word_idx = 0; word_idx < 8; word_idx++) begin
        uvm_status_e txn_status;
        uvm_reg src_reg = share_idx ?
                           ral.aes_core.KEY_SHARE1[word_idx] :
                           ral.aes_core.KEY_SHARE0[word_idx];

        src_reg.read(txn_status, key[share_idx][word_idx]);
        if (cfg.under_reset) return;
        if (txn_status != UVM_IS_OK) begin
          `uvm_error(get_full_name(),
                     $sformatf("Failed to read %0s register.", src_reg.get_name()))
        end
      end
    end
  endtask // write_key


  virtual task write_iv(bit  [3:0][31:0] iv, bit do_b2b);
    for (int unsigned i = 0; i < 4; i++) begin
      uvm_status_e txn_status;
      ral.aes_core.IV[i].write(txn_status, iv[i]);

      if (cfg.under_reset) return;
      if (txn_status != UVM_IS_OK) begin
        `uvm_error(get_full_name(), $sformatf("Failed to write IV[%0d] register.", i))
      end
    end
  endtask // write_iv


  virtual task read_iv(ref bit [3:0] [31:0] iv, bit do_b2b);
    int read_order[4] = {0,1,2,3};
    // randomize read order
    read_order.shuffle();

    foreach (read_order[i]) begin
      uvm_status_e txn_status;
      int unsigned idx = read_order[i];

      ral.aes_core.IV[idx].read(txn_status, iv[idx]);
      if (cfg.under_reset) return;
      if (txn_status != UVM_IS_OK) begin
        `uvm_error(get_full_name(), $sformatf("Failed to read IV[%0d] register.", idx))
      end

      `uvm_info(`gfn, $sformatf("\n\t ----| IV_%0d: %h ",idx,  iv[idx]), UVM_HIGH)
    end
  endtask

  // Make predictions of the PHASE and NUM_VALID_BYTES fields of CTRL_GCM_SHADOWED
  function void predict_gcm_shadowed(bit [5:0] phase,
                                     bit [4:0] num_valid_bytes);
    if (!ral.aes_core.CTRL_GCM_SHADOWED.PHASE.predict(phase)) begin
      `uvm_error(get_full_name(), "Failed to predict CTRL_GCM_SHADOWED.PHASE.")
    end
    if (!ral.aes_core.CTRL_GCM_SHADOWED.NUM_VALID_BYTES.predict(num_valid_bytes)) begin
      `uvm_error(get_full_name(), "Failed to predict CTRL_GCM_SHADOWED.NUM_VALID_BYTES.")
    end
  endfunction

  virtual task set_gcm_phase(gcm_phase_e phase, int num_bytes, bit wait_idle, bit config_err_en);
    uvm_status_e txn_status;
    ctrl_gcm_reg_t ctrl_gcm;
    gcm_phase_e phase_prev, phase_wr;
    int num_bytes_wr;

    if (wait_idle) begin
      spinwait_status_idle();
      if (cfg.under_reset) return;
    end

    // In case configuration error injection is enabled, we inject an error with a probability of
    // 33% as we want to hit the GCM_AAD, GCM_TEXT and GCM_TAG phases. Note that there are
    // actually two kinds of errors possible:
    // - Requesting illegal phase changes such as switching from GCM_TEXT back to GCM_AAD. The DUT
    //   needs to remain in the current phase in this case. This is what this task can test.
    //   However, there are some exceptions:
    //   1) testing that the DUT cannot move out of GCM_INIT without completing the initialization
    //      first,
    //   2) testing that the DUT does not enter GCM_SAVE after GCM_INIT (as this will clear the
    //      initialization status), and
    //   3) testing that the DUT does not enter the GCM_SAVE phase without having processed at
    //      least one block first.
    //   These special cases are verified using a directed test.
    // - Configuring invalid phase values such as the all-zero value or values with multiple bits
    //   set. The DUT switches back to GCM_INIT in this case (which also includes clearing the
    //   initialization status). This is however hard to handle which is why it is tested using a
    //   directed test.
    phase_prev = gcm_phase_e'(`gmv(ral.aes_core.CTRL_GCM_SHADOWED.PHASE));
    if (config_err_en && ($urandom_range(0, 2) == 0)) begin
      case (phase_prev)
        GCM_AAD: begin
          phase_wr = GCM_RESTORE;
        end
        GCM_TEXT: begin
          if (!std::randomize(phase_wr)
              with { phase_wr inside {GCM_AAD,
                                      GCM_RESTORE};}) begin
            `uvm_fatal(`gfn, $sformatf("Randomization failed"))
          end
        end
        GCM_SAVE: begin
          if (!std::randomize(phase_wr)
              with { phase_wr inside {GCM_RESTORE,
                                      GCM_AAD,
                                      GCM_TEXT,
                                      GCM_TAG};}) begin
            `uvm_fatal(`gfn, $sformatf("Randomization failed"))
          end
        end
        GCM_TAG: begin
          if (!std::randomize(phase_wr)
              with { phase_wr inside {GCM_RESTORE,
                                      GCM_AAD,
                                      GCM_TEXT,
                                      GCM_SAVE};}) begin
            `uvm_fatal(`gfn, $sformatf("Randomization failed"))
          end
        end
        default: begin
          phase_wr = phase;
        end
      endcase
    end else begin
      phase_wr = phase;
    end
    // Invalid values such as values in the range of [17, 31] and 0 for the number of valid bytes
    // are resolved to 16 in hardware. We inject such values with a 25% chance when writing 16.
    if (num_bytes == 16) begin
      num_bytes_wr = ($urandom_range(0, 3) != 0) ? num_bytes              :
                     ($urandom_range(0, 1) == 0) ? $urandom_range(17, 31) : 0;
    end else begin
      num_bytes_wr = num_bytes;
    end
    // Update the desired values in the abstraction class.
    ral.aes_core.CTRL_GCM_SHADOWED.PHASE.set(phase_wr);
    ral.aes_core.CTRL_GCM_SHADOWED.NUM_VALID_BYTES.set(num_bytes_wr);
    // Update the DUT if the desired and mirrored values mismatch. The DUT resolves potentially
    // invalid values internally.
    `uvm_info(`gfn,
        $sformatf("Current GCM phase %s, writing %s, actually requested %s",
        phase_prev.name(), phase_wr.name(), phase.name()), UVM_MEDIUM)
    `uvm_info(`gfn, $sformatf("Writing num_bytes_valid %0d", num_bytes_wr), UVM_MEDIUM)

    ral.aes_core.CTRL_GCM_SHADOWED.update(txn_status);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to update CTRL_GCM_SHADOWED.")

    if (phase != phase_wr) begin
      // Reflect the resolution of invalid values in the abstraction class.
      ral.aes_core.CTRL_GCM_SHADOWED.PHASE.set(phase_prev);
      ral.aes_core.CTRL_GCM_SHADOWED.NUM_VALID_BYTES.set(num_bytes);
      // Update the mirrored values.
      predict_gcm_shadowed(phase_prev, num_bytes);
      // Perform a readback to check that the DUT resolved potentially illegal phase value changes
      // correctly.
      ral.aes_core.CTRL_GCM_SHADOWED.read(txn_status, ctrl_gcm);

      if (cfg.under_reset) return;
      if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to read CTRL_GCM_SHADOWED.")

      if (ctrl_gcm.phase != phase_prev) begin
        `uvm_fatal(`gfn, $sformatf("Expected GCM phase %s, got %s",
                                   phase_prev.name(), ctrl_gcm.phase.name()))
      end

      // Repeat the update but now with the correct values.
      ral.aes_core.CTRL_GCM_SHADOWED.PHASE.set(phase);
      ral.aes_core.CTRL_GCM_SHADOWED.NUM_VALID_BYTES.set(num_bytes);
      ctrl_gcm.phase = phase;
      ctrl_gcm.num_valid_bytes = num_bytes;
      `uvm_info(`gfn,
          $sformatf("Current GCM phase %s, writing %s",
          phase_prev.name(), phase.name()), UVM_MEDIUM)
      `uvm_info(`gfn, $sformatf("Writing num_bytes_valid %0d", num_bytes), UVM_MEDIUM)
      ral.aes_core.CTRL_GCM_SHADOWED.write(txn_status, ctrl_gcm);
      if (cfg.under_reset) return;
      if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to write CTRL_GCM_SHADOWED.")
    end else if (num_bytes != num_bytes_wr) begin
      // Reflect the resolution of invalid values in the abstraction class and update the mirrored
      // values.
      ral.aes_core.CTRL_GCM_SHADOWED.NUM_VALID_BYTES.set(num_bytes);
      predict_gcm_shadowed(phase, num_bytes);
    end else begin
      // Just update the mirrored values.
      predict_gcm_shadowed(phase, num_bytes);
    end
  endtask

  virtual task add_data(ref bit [3:0] [31:0] data, bit do_b2b);
    int write_order[4] = {0,1,2,3};
    write_order.shuffle();

    `uvm_info(`gfn, $sformatf("\n\t ----| ADDING DATA TO DUT %h ", data),  UVM_MEDIUM)

    foreach (write_order[i]) begin
      uvm_status_e txn_status;
      int idx = write_order[i];

      `uvm_info(`gfn, $sformatf("\n\t ----| DATA_IN_%0d: %h ",idx,  data[idx]), UVM_HIGH)
      ral.aes_core.DATA_IN[idx].write(txn_status, data[idx][31:0]);

      if (cfg.under_reset) return;
      if (txn_status != UVM_IS_OK) begin
        `uvm_error(get_full_name(), $sformatf("Failed to write DATA_IN[%0d] register.", idx))
      end
    end
  endtask


  virtual task read_data(ref bit [3:0] [31:0] cypher_txt, bit do_b2b);
    int read_order[4] = {0,1,2,3};
    // randomize read order
    read_order.shuffle();

    foreach (read_order[i]) begin
      uvm_status_e txn_status;
      int idx = read_order[i];
      ral.aes_core.DATA_OUT[idx].read(txn_status, cypher_txt[idx]);

      if (cfg.under_reset) return;
      if (txn_status != UVM_IS_OK) begin
        `uvm_error(get_full_name(), $sformatf("Failed to read DATA_IN[%0d] register.", idx))
      end

      `uvm_info(`gfn, $sformatf("\n\t ----| DATA_OUT_%0d: %h ",idx,  cypher_txt[idx]), UVM_HIGH)
    end
  endtask // read_data


  ///////////////////////////////////////
  // ADVANCED TASKS                    //
  ///////////////////////////////////////

  virtual task setup_dut(aes_seq_item item);
    // Write the shadwoed CTRL register.
    status_t aes_status;
    // Setup fields one by one (0) or all fields together (1).
    bit setup_mode = 0;
    // Trigger a control update error (1) or not (0). Only applicable if setup_mode = 1.
    bit control_update_error = 0;
    // Index of the field which shall trigger the control update error.
    int idx_error_field = 0;
    `DV_CHECK_STD_RANDOMIZE_FATAL(setup_mode)
    if ($urandom_range(1, 100) > 95) control_update_error = 1;
    idx_error_field = $urandom_range(0, 5);
    spinwait_status_idle();
    // Any successful update to the shadowed control register marks the start of a new message. If
    // sideload is enabled and a valid sideload key is available, it may be latched upon the second
    // write and - depending on KEY_TOUCH_FORCES_RESEED - trigger a reseed operation which prevents
    // further updates to the control register until AES becomes idle again. For simplicity, we
    // just disable sideload here and then update the sideload bit last.
    ral.aes_core.CTRL_SHADOWED.SIDELOAD.set(0);
    if (!setup_mode) begin
      set_operation(item.operation);
      set_mode(item.aes_mode);
      set_key_len(item.key_len);
      set_manual_operation(item.manual_op);
      set_prng_reseed_rate(prs_rate_e'(item.reseed_rate));
      set_sideload(item.sideload_en);
      if (cfg.under_reset) return;
    end else begin
      uvm_status_e txn_status;

      // Assemble the intended value.
      ral.aes_core.CTRL_SHADOWED.OPERATION.set(item.operation);
      ral.aes_core.CTRL_SHADOWED.MODE.set(item.mode);
      ral.aes_core.CTRL_SHADOWED.KEY_LEN.set(item.key_len);
      ral.aes_core.CTRL_SHADOWED.SIDELOAD.set(item.sideload_en);
      ral.aes_core.CTRL_SHADOWED.MANUAL_OPERATION.set(item.manual_op);
      ral.aes_core.CTRL_SHADOWED.PRNG_RESEED_RATE.set(item.reseed_rate);
      // Trigger a control update error.
      if (control_update_error) begin
        `uvm_info(`gfn, $sformatf("Triggering control update error in field %0d", idx_error_field),
            UVM_MEDIUM)
        // Perform the first write using the correct data.
        ral.aes_core.CTRL_SHADOWED.update(txn_status);
        if (cfg.under_reset) return;
        if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to update CTRL_SHADOWED.")

        // Make sure at least one field is flipped.
        begin
          unique case (idx_error_field)
            0: ral.aes_core.CTRL_SHADOWED.OPERATION.set(item.operation == AES_DEC ? AES_ENC : AES_DEC);
            1: ral.aes_core.CTRL_SHADOWED.MODE.set(item.mode == AES_ECB ? AES_NONE : AES_ECB);
            2: ral.aes_core.CTRL_SHADOWED.KEY_LEN.set(item.key_len == AES_128 ? AES_256 : AES_128);
            3: ral.aes_core.CTRL_SHADOWED.SIDELOAD.set(item.sideload_en ? 1'b0 : 1'b1);
            4: ral.aes_core.CTRL_SHADOWED.MANUAL_OPERATION.set(item.manual_op ? 1'b0 : 1'b1);
            5: ral.aes_core.CTRL_SHADOWED.PRNG_RESEED_RATE.set(item.reseed_rate == PER_64 ? PER_8K : PER_64);
            default:;
          endcase
        end
        // Perform the second write.
        ral.aes_core.CTRL_SHADOWED.update(txn_status);
        if (cfg.under_reset) return;
        if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to update CTRL_SHADOWED.")

        // Check that we get the recoverable alert. It's possible that DV inserted a fatal error
        // condition before the second write could go through. The recovery from the fatal alert
        // is handled separately.
        read_status(aes_status);
        if (cfg.under_reset) return;

        `DV_CHECK_FATAL(aes_status.alert_recov_ctrl_update_err == 1'b1 ||
                        aes_status.alert_fatal_fault == 1'b1);
        // Re-assemble the intended value.
        ral.aes_core.CTRL_SHADOWED.OPERATION.set(item.operation);
        ral.aes_core.CTRL_SHADOWED.MODE.set(item.mode);
        ral.aes_core.CTRL_SHADOWED.KEY_LEN.set(item.key_len);
        ral.aes_core.CTRL_SHADOWED.SIDELOAD.set(item.sideload_en);
        ral.aes_core.CTRL_SHADOWED.MANUAL_OPERATION.set(item.manual_op);
        ral.aes_core.CTRL_SHADOWED.PRNG_RESEED_RATE.set(item.reseed_rate);
      end
      // Perform the register update without control update error. This will resolve potential
      // previous update errors.
      spinwait_status_idle();
      if (cfg.under_reset) return;

      ral.aes_core.CTRL_SHADOWED.update(txn_status);
      if (cfg.under_reset) return;
      if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to update CTRL_SHADOWED.")

      // Make sure the update went through and there wasn't an update error. It's possible that DV
      // inserted a fatal error condition before the second write could go through. In this case,
      // the recoverable alert condition may still be visible together with the fatal alert. The
      // fatal alert is handled separately.
      read_status(aes_status);
      if (cfg.under_reset) return;

      `DV_CHECK_FATAL(aes_status.alert_recov_ctrl_update_err == 1'b0 ||
                      aes_status.alert_fatal_fault == 1'b1);
    end
  endtask

  function void generate_aes_item_queue(aes_message_item msg_item);
    // init aes item
    aes_item_init(msg_item);
    // generate DUT cfg
    generate_ctrl_item();
    if (msg_item.aes_mode == AES_GCM) begin
      // Generate AAD message items if in AES-GCM mode.
      generate_data_stream(msg_item, 1, 0);
    end
    generate_data_stream(msg_item, 0, 0);
    if (msg_item.aes_mode == AES_GCM) begin
      // Generate TAG message item if in AES-GCM mode.
      generate_data_stream(msg_item, 0, 1);
    end
    aes_print_item_queue(aes_item_queue);
  endfunction

  // Generate the data for a single message based
  // on the configuration in the message Item
  virtual function void generate_data_stream(aes_message_item msg_item, bit aad, bit tag);
    aes_seq_item item_clone;
    bit [3:0][31:0] len_aad_data_conc;
    bit [3:0][31:0] len_aad_data;
    aes_item_type_e  item_type = AES_DATA;
    int msg_length = msg_item.message_length;
    bit fixed_data_en = msg_item.fixed_data_en;
    aes_item.item_type = AES_DATA;
    if (aad) begin
      item_type = AES_GCM_AAD;
      aes_item.item_type = AES_GCM_AAD;
      msg_length = msg_item.aad_length;
      fixed_data_en = msg_item.fixed_aad_en;
    end else if (tag) begin
      item_type = AES_GCM_TAG;
      aes_item.item_type = AES_GCM_TAG;
      // len(aad) || len(data)
      len_aad_data_conc = ((msg_item.aad_length * 8 << 64) | msg_item.message_length * 8);
      len_aad_data = {<<8{len_aad_data_conc}};
      msg_length = 16;
    end

    // generate an item for each 128b message block
    `uvm_info(`gfn, $sformatf("\n\t ----| FIXED DATA ENABLED? : %0b", msg_item.fixed_data_en),
              UVM_MEDIUM)
    for (int n = 0; n < msg_length - 15; n += 16) begin
      aes_item.data_len = 0;
      if (fixed_data_en) begin
        `DV_CHECK_RANDOMIZE_WITH_FATAL(aes_item, data_in == (aad ? msg_item.fixed_aad :
                                                             msg_item.fixed_data);)
      end else begin
        `DV_CHECK_RANDOMIZE_FATAL(aes_item)
      end
      if (tag) begin
        // set // len(aad) || len(data).
        aes_item.data_in = len_aad_data;
      end

      `uvm_info(`gfn, $sformatf("\n ----| DATA AES ITEM %s", aes_item.convert2string()), UVM_HIGH)
      `downcast(item_clone, aes_item.clone());
      aes_item_queue.push_front(item_clone);
    end

    // check if message length is not divisible by 16bytes
    if (msg_length[3:0] != 4'd0) begin
      `uvm_info(`gfn, $sformatf("\n ----| generating runt "), UVM_MEDIUM)
      aes_item.data_len = msg_length[3:0];
      if (fixed_data_en) begin
        `DV_CHECK_RANDOMIZE_WITH_FATAL(aes_item, data_in == fixed_data;)
      end else begin
        `DV_CHECK_RANDOMIZE_FATAL(aes_item)
      end
      aes_item.item_type = item_type;
      `downcast(item_clone, aes_item.clone());
      aes_item_queue.push_front(item_clone);
    end
  endfunction // generate_data_stream


  virtual task write_data_key_iv(
    aes_seq_item item,         // sequence item with configuration
    aes_seq_item data_item,        // sequence item with data to process
    bit          new_msg,          // is this a new msg -> do dut config
    bit          manual_operation, // use manual operation
    bit          sideload_en,      // we are currently using sideload key
    bit          read_output,      // read output or leave untouched
    ref  bit     rst_set           // reset was forced - restart message
    );

    status_t aes_status;
    bit      return_on_idle   = 1;
    bit [3:0] [7:0] data      = data_item.data_in;
    string   txt              ="";
    bit      is_blocking      = ~item.do_b2b;
    int      wait_on_reseed   = 16;
    string interleave_queue[$] = '{ "key_share0_0", "key_share0_1", "key_share0_2", "key_share0_3",
                                   "key_share0_4", "key_share0_5", "key_share0_6", "key_share0_7",
                                   "key_share1_0", "key_share1_1", "key_share1_2", "key_share1_3",
                                   "key_share1_4", "key_share1_5", "key_share1_6", "key_share1_7",
                                   "data_in_0", "data_in_1", "data_in_2", "data_in_3"};

    // if non ECB mode add IV to queue
    if (item.mode != AES_ECB) begin
      interleave_queue = {"iv_0", "iv_1", "iv_2", "iv_3", interleave_queue};
    end


    if (item.mode == AES_GCM) begin
      // if GCM mode, only write key and IV as we need to trigger the IP before
      // sending the first block.
      interleave_queue = '{ "key_share0_0", "key_share0_1", "key_share0_2", "key_share0_3",
                            "key_share0_4", "key_share0_5", "key_share0_6", "key_share0_7",
                            "key_share1_0", "key_share1_1", "key_share1_2", "key_share1_3",
                            "key_share1_4", "key_share1_5", "key_share1_6", "key_share1_7",
                            "iv_0", "iv_1", "iv_2", "iv_3"};
      // if GCM mode, put AES into GCM_INIT before configuring the IP.
      set_gcm_phase(GCM_INIT, 16, 0, 0);
      if (cfg.under_reset) return;
    end

    if (|item.clear_reg) begin
      interleave_queue = { interleave_queue, "clear_reg"};
      `uvm_info(`gfn, $sformatf("\n\t ----| Clear reg enabled adding register clear to Queue"),
                 UVM_MEDIUM)
    end


    if (cfg.random_data_key_iv_order) begin
      int q_size = interleave_queue.size();
      interleave_queue.shuffle();
    end

    txt = {txt, $sformatf("\n\t IS blocking %b", is_blocking) };

    for (int i = 0;  i < interleave_queue.size(); i++) begin
      uvm_status_e txn_status;
      string csr_name = interleave_queue[i];

      txt = {txt, $sformatf("\n\t ----| \t %s",csr_name )};

      case (1)
        (!uvm_re_match("key_share0_*", csr_name)): begin
          int idx = get_multireg_idx(csr_name);
          ral.aes_core.KEY_SHARE0[idx].write(txn_status, item.key[0][idx]);
          if (cfg.under_reset) return;
          if (txn_status != UVM_IS_OK) begin
            `uvm_error(get_full_name(), $sformatf("Failed to write %0s register.", csr_name))
          end
          wait_on_reseed -= 1;
        end
        (!uvm_re_match("key_share1_*", csr_name)): begin
          int idx = get_multireg_idx(csr_name);
          ral.aes_core.KEY_SHARE1[idx].write(txn_status, item.key[1][idx]);
          if (cfg.under_reset) return;
          if (txn_status != UVM_IS_OK) begin
            `uvm_error(get_full_name(), $sformatf("Failed to write %0s register.", csr_name))
          end          wait_on_reseed -= 1;
        end
        (!uvm_re_match("iv_*", csr_name)): begin
          int idx = get_multireg_idx(csr_name);
          ral.aes_core.IV[idx].write(txn_status, item.iv[idx]);
          if (cfg.under_reset) return;
          if (txn_status != UVM_IS_OK) begin
            `uvm_error(get_full_name(), $sformatf("Failed to write %0s register.", csr_name))
          end
        end
        (!uvm_re_match("data_in_*", csr_name)): begin
          int idx = get_multireg_idx(csr_name);
          ral.aes_core.DATA_IN[idx].write(txn_status, data[idx]);
          if (cfg.under_reset) return;
          if (txn_status != UVM_IS_OK) begin
            `uvm_error(get_full_name(), $sformatf("Failed to write %0s register.", csr_name))
          end
        end
        (csr_name == "clear_reg"): begin
          clear_regs(item.clear_reg);
          if (cfg.under_reset) return;
          spinwait_status_idle();
          if (cfg.under_reset) return;
          // manual mode requires all to be written again
          if (manual_operation) begin
            //remove clear from queue
            interleave_queue.delete(i);
            i = -1;
            wait_on_reseed = 16;
          end
        end
      endcase // case interleave_queue[i]

      if (wait_on_reseed == 0) begin
        // inject write to reg if enabled 25% of the time
        if (cfg.error_types.mal_inject && $urandom(3)==0 && !manual_operation) begin
          int wr_reg = $urandom_range(3,1);
          case (wr_reg)
            1: ral.aes_core.KEY_SHARE0[$urandom(7)].write(txn_status, $urandom());
            2: ral.aes_core.IV[$urandom(3)].write(txn_status, $urandom());
            3: ral.aes_core.DATA_IN[$urandom(3)].write(txn_status, $urandom());
            default: `uvm_fatal(`gfn, $sformatf("UNREACHABLE BUT NEEDED DUE TO SYNTAX CHECK"))
          endcase
          if (cfg.under_reset) return;
          if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to write register.")
        end
        status_fsm(item, data_item, new_msg,
                   manual_operation, sideload_en, return_on_idle, read_output, aes_status, rst_set);
        if (cfg.under_reset) return;
        wait_on_reseed = 16;
      end
      if (rst_set) break;
    end

    `uvm_info(`gfn,
              $sformatf("\n\t  Configuring the DUT in the following order:  %s, \n\t data 0x%0h",
                        txt, data), UVM_MEDIUM)
  endtask // write_data_key_iv

  // Repeatedly run the sideload sequence, which generates new keys at random times.
  //
  // This task runs until there is a reset or stop_sideload_seq() is called. The sequences that pass
  // the new keys are run with priority 100: to pass a different key, send a sequence with a higher
  // priority.
  task start_sideload_seq();
    // TODO(caliptra-port): sideload-key driving used the OpenTitan
    // key_sideload_agent (key_sideload_set_seq + keymgr_pkg::hw_key_req_t).
    // Caliptra has no equivalent agent yet, so wait for the stop event.
    if (m_sideload_seq_running) begin
      `uvm_fatal(get_name(), "Cannot start multiple sideload sequences.")
    end
    m_sideload_seq_running = 1;
    m_stop_sideload_seqs_event.wait_ptrigger();
    m_sideload_seq_running = 0;
  endtask

  // Stop a sideload sequence if there is one running. Returns when the sequence has finished.
  task stop_sideload_seq();
    m_stop_sideload_seqs_event.trigger();
    wait (!m_sideload_seq_running);
  endtask

  // Repeatedly send a sideload key sequence, setting key_rdy each time, until key_used is set. The
  // first sequence is randomised. When new_key is set, a later sequence will be randomised before
  // it is sent, then new_key will be cleared.
  //
  // The sequences used send their items with a higher priority than the ones generated by
  // start_sideload_seq.
  //
  // Exit immediately on reset.
  task req_sideload_key();
    // TODO(caliptra-port): same OpenTitan key_sideload_agent dependency as
    // start_sideload_seq. Stub: just flag the key as ready so callers that
    // wait on key_rdy/key_used can make forward progress.
    if (cfg.under_reset) return;
    new_key = 0;
    key_rdy = 1;
    wait (key_used || cfg.under_reset);
    key_used = 0;
  endtask // req_sideload_key


  // the index of multi-reg is at the last char of the name
  virtual function int get_multireg_idx(string name);
    string s = string'(name.getc(name.len - 1));
    return s.atoi();
  endfunction

  // Send an AES message
  //
  // m_external_reset is true, this task will not generate its own resets. When an event that locks
  // up the block happens, the task will just wait for a reset to be generated elsewhere and then
  // return. If m_external_reset is false, the task checks that no external reset has been
  // generated.
  virtual task send_msg (
     bit manual_operation,                   // use manual operation
     bit sideload_en,                        // use sideload key
     bit unbalanced,                         // randomize if we read or write
     int read_prob,                          // chance of reading an available output
     int write_prob,                         // chance of writing input data to a ready DUT
     ref bit rst_set                         // reset was forced - restart message
     );

    status_t     aes_status;                     // AES aes_status
    aes_seq_item cfg_item   = new();         // the configuration for this message
    aes_seq_item data_item  = new();         // the next data to transmit
    aes_seq_item read_item;                  // the read item to store output in
    aes_seq_item clone_item;
    bit  new_msg            = 1;             // set when starting a new msg
    aes_seq_item read_queue[$];              // queue to hold items waiting for output

    bit read;
    bit write;
    bit return_on_idle = 1;
    bit first_aad_block = 1;
    bit first_data_block = 1;
    rst_set = 0;
    cfg_item = aes_item_queue.pop_back();

    // Make sure the DUT is idle before setting it up. Writes to the main control register are only
    // accepted when idle.
    status_fsm(cfg_item, data_item, new_msg, manual_operation, sideload_en, 1, 0, aes_status, rst_set);
    if (cfg.under_reset) return;

    // Configure the main control register.
    setup_dut(cfg_item);
    if (cfg.under_reset) return;

    // For some reason DV just waits for the DUT to be idle but not necessarily for it to accept
    // new input data before providing the first block. But at the beginning of a message, the DUT
    // is always ready to accept new input data anyway. Waiting for the DUT to be idle is required
    // to provide IV and initial key.
    return_on_idle = 1;
    if (unbalanced == 0 || manual_operation) begin
       data_item = new();
      while ((aes_item_queue.size() > 0) && !rst_set) begin
        status_fsm(cfg_item, data_item, new_msg, manual_operation,
                   sideload_en, return_on_idle, 0, aes_status, rst_set);
        if (cfg.under_reset) return;

        // From now on, DV always waits for the DUT to be idle and to accept new input data.
        return_on_idle = 0;
        if (aes_status.input_ready && aes_status.idle) begin
          // The DUT is ready to accept new input data, as well as updates to IV and initial key
          // registers (only allowed when idle). The first config_and_transmit() call configures
          // key and IV.
          bit read_output = 1;
          data_item = aes_item_queue.pop_back();
          if (data_item.mode == AES_GCM) begin
            // In AES-GCM mode, we only want to read when we are either processing
            // the AES_DATA or the AES_TAG.
            // When processing AES_AAD, no output is generated that we want to
            // read, so skip it. Also the the first message AES_CFG (i.e., new_msg
            // == true), does not contain any data input as we first need to configure
            // the GCM, so do not read.
            read_output = data_item.item_type == AES_GCM_AAD ? 0 : ~new_msg;
          end
          config_and_transmit(cfg_item, data_item, new_msg, first_data_block,
                              first_aad_block, manual_operation, sideload_en,
                              read_output, rst_set);
          if (cfg.under_reset) return;

          if (data_item.mode == AES_GCM && new_msg == 1) begin
            // In comparison to other modes, in AES-GCM, the config_and_transmit()
            // function only configures key and IV as we need to first put the
            // AES into the AES_GCM_AAD or AES_TEXT phase before writing to the data_in
            // registers.
            aes_item_queue.push_back(data_item);
          end

          if (data_item.item_type == AES_GCM_AAD && new_msg == 0) begin
            first_aad_block = 0;
          end

          if (data_item.item_type == AES_DATA && new_msg == 0) begin
            first_data_block = 0;
          end

          new_msg = 0;

        end else if (cfg_item.mode == AES_NONE) begin
          // The DUT won't produce any output when this mode is configured. Just write the new
          // input data.
          data_item = aes_item_queue.pop_back();
          config_and_transmit(cfg_item, data_item, new_msg, 0, 0,
                              manual_operation, sideload_en, 0, rst_set);
          if (cfg.under_reset) return;
        end
      end

    end else begin
      while (((aes_item_queue.size() > 0) || (read_queue.size() > 0)) && !rst_set) begin
        bit wait_for_idle = 0;
        if (aes_item_queue.size() > 0 ) data_item = new();
        // When processing an AES-GCM message, setting the GCM phase requires us
        // waiting for the IDLE.
        if (cfg_item.mode == AES_GCM && aes_item_queue.size() > 0) begin
          if (new_msg) begin
            // When starting a new message, we need to put GCM into the GCM_INIT
            // phase. Hence, wait for the IDLE status.
            wait_for_idle = 1;
          end else begin
            // Pop the data item such that we can get the item type and the item
            // length.
            data_item = aes_item_queue.pop_back();
            if (data_item.data_len != 0) begin
              // If we have a partial block (i.e., data length is not 0 (=16 bytes))
              // we neet to put the GCM into the GCM_TEXT or GCM_AAD phase.
              wait_for_idle = 1;
            end else if (data_item.item_type == AES_DATA && first_data_block) begin
              // When processing the first block, we need to put the GCM first
              // into the GCM_TEXT phase.
              wait_for_idle = 1;
            end else if (data_item.item_type == AES_GCM_AAD && first_aad_block) begin
              // When processing the first block, we need to put the GCM first
              // into the GCM_AAD phase.
              wait_for_idle = 1;
            end else if (data_item.item_type == AES_GCM_TAG) begin
              // As we only have a single tag block, always wait to configure
              // the GCM_TAG phase.
              wait_for_idle = 1;
            end
            // Push the item back to the queue as we haven't processed it yet.
            aes_item_queue.push_back(data_item);
          end
        end
        // get the status to make sure we can provide data - but don't wait for output //
        status_fsm(cfg_item, data_item, new_msg,
                   manual_operation, sideload_en, return_on_idle, 0, aes_status, rst_set);
        if (cfg.under_reset) return;

        return_on_idle = 0;
        read  = ($urandom_range(0, 100) <= read_prob);
        write = ($urandom_range(0, 100) <= write_prob);

        if ( (($countones(cfg_item.mode) != 1) || cfg_item.mode == AES_NONE)
            && (aes_item_queue.size() > 0)) begin
          // just write the data - don't expect and output
          data_item = aes_item_queue.pop_back();
          config_and_transmit(cfg_item, data_item, new_msg, 0, 0,
                               manual_operation, sideload_en, 0, rst_set);
          if (cfg.under_reset) return;

        end else if (aes_status.input_ready && (aes_item_queue.size() > 0) && write &&
                     (~wait_for_idle || aes_status.idle)) begin
          data_item = aes_item_queue.pop_back();
          config_and_transmit(cfg_item, data_item, new_msg, first_data_block, first_aad_block,
                              manual_operation, sideload_en, 0, rst_set);
          if (cfg.under_reset) return;

          if (data_item.mode == AES_GCM && new_msg == 1) begin
            // In comparison to other modes, in AES-GCM, the config_and_transmit()
            // function only configures key and IV when processing the AES_CFG
            // item. However, as we already popped the next aes_item_queue once,
            // push it again to the queue such that it gets processed in the next
            // iteration.
            aes_item_queue.push_back(data_item);
          end
          `downcast(clone_item, data_item.clone());
          if (data_item.mode == AES_GCM) begin
            if (new_msg == 0 && (data_item.item_type == AES_DATA ||
                                 data_item.item_type == AES_GCM_TAG)) begin
              // Only read the output for AES_DATA (ptx or ctx) and AES_GCM_TAG
              // items. AES_AAD and AES_CFG items do not produce an output.
              read_queue.push_back(clone_item);
            end
          end else begin
            read_queue.push_back(clone_item);
          end

          if (write) begin
            if (data_item.item_type == AES_GCM_AAD && new_msg == 0) begin
              first_aad_block = 0;
            end

            if (data_item.item_type == AES_DATA && new_msg == 0) begin
              first_data_block = 0;
            end
          end
        end
        if (write) new_msg = 0;
        if (aes_status.output_valid && read) begin
          if (read_queue.size() > 0)  begin
            read_item = read_queue.pop_front();
            read_data(read_item.data_out, cfg_item.do_b2b);
            if (cfg.under_reset) return;
          end else begin
            `uvm_fatal(`gfn, $sformatf("\n\t ----| DATA READY but no ITEM to add it to! |----"))
          end
        end
      end
    end // else: !if(unbalanced == 0 || manual_operation)
  endtask // send_msg


  ////////////////////////////////////////////////////////////////////////////////////////////
  // this task will handle setup and transmission
  // of a message on a block level.
  // it will send one block then return to the caller for the next item.
  // if read output is enabled it will call the status fsm for get the
  // output of the processed block
  // NOTE IT IS UP TO THE CALLER OF THIS TASK
  // TO ENSURE THE DUT IS READY/IDLE
  // this opens up for calling this task in random times
  // to provoke weird behavior
  ////////////////////////////////////////////////////////////////////////////////////////////

  virtual task config_and_transmit (
      aes_seq_item cfg_item,         // sequence item with configuration
      aes_seq_item data_item,        // sequence item with data to process
      bit          new_msg,          // is this a new msg -> do dut config
      bit          new_data,         // first data block -> set GCM_TEXT phase in GCM mode
      bit          new_aad,          // first aad block -> set GCM_AAD phase in GCM mode
      bit          manual_operation, // use manual operation
      bit          sideload_en,      // we are currently using sideload key
      bit          read_output,      // read output or leave untouched
      ref  bit     rst_set           // reset was forced - restart message
      );

    bit                   is_blocking = ~cfg_item.do_b2b;
    status_t              aes_status;
    rst_set = 0;
    if (new_msg) begin
      write_data_key_iv(cfg_item, data_item, new_msg,
                        manual_operation, sideload_en, 0, rst_set);
      if (cfg.under_reset) return;
    end else begin
      if (data_item.mode == AES_GCM) begin
        int valid_bytes;
        if (data_item.item_type == AES_GCM_AAD) begin
          read_output = 0;
          if (new_aad || data_item.data_len[3:0] != 4'd0) begin
            // Configure AAD phase as this is either the first AAD block or a
            // partial block.
            valid_bytes = data_item.data_len == 0 ? 16 : data_item.data_len;
            set_gcm_phase(GCM_AAD, valid_bytes, 0,
                          cfg.error_types.cfg && cfg.config_error_type_en.gcm_phase);
            if (cfg.under_reset) return;
          end
        end else if (data_item.item_type == AES_DATA) begin
          if (new_data || data_item.data_len[3:0] != 4'd0) begin
            // Configure TEXT phase as this is either the first plaintext block or a
            // partial block.
            valid_bytes = data_item.data_len == 0 ? 16 : data_item.data_len;
            set_gcm_phase(GCM_TEXT, valid_bytes, 0,
                          cfg.error_types.cfg && cfg.config_error_type_en.gcm_phase);
            if (cfg.under_reset) return;
          end
        end else if (data_item.item_type == AES_GCM_TAG) begin
          set_gcm_phase(GCM_TAG, 16, 0,
                        cfg.error_types.cfg && cfg.config_error_type_en.gcm_phase);
          if (cfg.under_reset) return;
        end
      end
      add_data(data_item.data_in, cfg_item.do_b2b);
      if (cfg.under_reset) return;

      // sometimes randomly write a reg while busy
      if (!manual_operation && cfg.error_types.mal_inject && ($urandom(3) == 1)) begin
        uvm_status_e txn_status;
        uvm_reg      reg_to_write;

        randcase
          1: reg_to_write = ral.aes_core.KEY_SHARE0[$urandom(7)];
          1: reg_to_write = ral.aes_core.IV[$urandom(3)];
          1: reg_to_write = ral.aes_core.DATA_IN[$urandom(3)];
        endcase

        reg_to_write.write(txn_status, $urandom());

        if (cfg.under_reset) return;
        if (txn_status != UVM_IS_OK) begin
          `uvm_error(get_full_name(),
                     $sformatf("Failed to write %0s register.", reg_to_write.get_name()))
        end
      end
    end

    if (manual_operation && !rst_set) trigger();
    // When in AES-GCM mode, trigger twice to encrypt the all-zero block and afterwards the
    // initial counter block and load them into the GHASH block.
    if (cfg_item.mode == AES_GCM && manual_operation && new_msg && !rst_set) trigger();
    if (read_output && !rst_set) begin
       status_fsm(cfg_item, data_item, new_msg,
                   manual_operation, sideload_en, 0, read_output, aes_status, rst_set);
      if (cfg.under_reset) return;
    end
    // After having read the tag in GCM, move the DUT back into the GCM_INIT phase with a 25%
    // chance. This is not really needed but it allows checking that the DUT can't be moved
    // to other phases if the injection of conifg errors is turned on at the same time.
    if ((data_item.item_type == AES_GCM_TAG) && ($urandom_range(0, 3) == 0)) begin
      set_gcm_phase(GCM_INIT, 16, 0,
                    cfg.error_types.cfg && cfg.config_error_type_en.gcm_phase);
      if (cfg.under_reset) return;
    end
  endtask // config_and_transmit


  // Reset the DUT after a fatal-fault condition has been observed in the status register.
  //
  // If m_external_reset is false, apply a reset, re-initialise the dut, and return. If
  // m_external_reset is true, we expect some other mechanism to apply the reset. Wait until one is
  // asserted and then return immediately.
  //
  // Note(caliptra-port): the OpenTitan version of this task also waited on the fatal_fault alert
  // agent's vif before resetting. Caliptra's top-level wrappers do not wire up alerts, so the
  // alert-agent wait has been removed; callers already gate this task on aes_status.alert_fatal_fault.
  virtual task wait_for_fatal_alert_and_reset ();
    if (m_external_reset) begin
      wait(cfg.under_reset);
    end else begin
      // Reset and re-initialize the DUT.
      // To avoid assertions firing erroneously due to resetting AES prior to the EDN
      // interface, pull all resets concurrently. See
      // https://github.com/lowRISC/opentitan/issues/13573 for details.
      apply_resets_concurrently();
      dut_init("HARD");
    end
  endtask

  ////////////////////////////////////////////////////////////////////////////////////////////
  // the status fsm has two tasks
  // 1 determine the status of the DUT
  //   it will recover from any configurational deadlock
  //   i.e update error / clear error / misconfiguration or missing configuration
  // 2. if wanted it will read output data when ready and return it to the caller
  //
  // If m_external_reset argument is true, this task will not generate its own resets. When an event
  // that locks up the block happens, the task will just wait for a reset to be generated elsewhere
  // and then return. If m_external_reset is false, the task checks that no external reset has been
  // generated.
  ////////////////////////////////////////////////////////////////////////////////////////////

  virtual task status_fsm (
      aes_seq_item        cfg_item,         // sequence item with configuration
      aes_seq_item        data_item,        // sequence item with data to process
      bit                 new_msg,          // is this a new msg -> do dut config
      bit                 manual_operation, // use manual operation
      bit                 sideload_en,      // currently using sideload key
      bit                 return_on_idle,   // return if DUT status is idle
      bit                 read_output,      // read output or leave untouched
      ref  status_t       aes_status,           // the current AES aes_status
      ref  bit            rst_set           // we forced a reset - abort current message and restart
      );

    ctrl_reg_t ctrl;
    bit                   is_blocking       = ~cfg_item.do_b2b;
    bit                   done              = 0;
    string                txt               = "";
    int                   not_idle_cnt      = 0;

    txt     = "\n Entering FSM";
    rst_set = 0;


    // enable get status when provided with an empty Item.
    if (data_item.mode === 'X) begin
      read_status(aes_status);
      if (cfg.under_reset) return;
    end

    while(!done && !global_reset) begin
      if (cfg.under_reset) return;

      //read the status register to see that we have triggered the operation
      read_status(aes_status);
      if (cfg.under_reset) return;

      txt = {txt, "\n ----|reading STATUS", status2string(aes_status)};
      // check status and act accordingly //
      if (aes_status.alert_fatal_fault) begin
        // stuck pull reset //
        if (cfg.error_types.mal_inject || cfg.error_types.lc_esc) begin
          `uvm_info(`gfn,
                  $sformatf("\n\t ----| Saw expected Fatal alert - trying to recover \n\t ----| %s",
                              status2string(aes_status)), UVM_MEDIUM)
          try_recover(cfg_item, data_item, manual_operation, sideload_en, new_msg);
          if (cfg.under_reset) return;

          read_status(aes_status);
          if (cfg.under_reset) return;

          if ( !aes_status.alert_fatal_fault) begin
            `uvm_fatal(`gfn, $sformatf("\n\t Was able to clear FATAL ALERT without reset \n\t %s",
                       status2string(aes_status)))
          end else begin
            wait_for_fatal_alert_and_reset();
            if (cfg.under_reset) return;

            rst_set = 1;
            done    = 1;
          end
        end else begin
          `uvm_fatal(`gfn, $sformatf("\n\t Unexpected Fatal alert in AES FSM \n\t %s",
             status2string(aes_status)))
        end
      end else if (cfg_item.mode == AES_NONE) begin
        // In this mode, the DUT is not ever supposed to accept input data or provide output data.
        // But it can for example trigger a reseed operation upon loading a new initial key. Here,
        // we just need to wait for the DUT to be idle.
        if (aes_status.idle) begin
          done = 1;
        end
      end else begin
        // state 0
        if (aes_status.idle && aes_status.input_ready) begin
          if (aes_status.output_valid && read_output) begin
            read_data(data_item.data_out, is_blocking);
            if (cfg.under_reset) return;

            txt = {txt, $sformatf("\n\t ----| status state 0 ")};
            done = 1;
          end else if (!read_output) begin
            done = 1; // get more data
          end else begin
            try_recover(cfg_item, data_item, manual_operation, sideload_en, new_msg);
            if (cfg.under_reset) return;
          end
        end else if (aes_status.idle && !aes_status.input_ready) begin
          // state 1 //
          // if data ready just read and return
          if (aes_status.output_valid && read_output) begin
            read_data(data_item.data_out, is_blocking);
            if (cfg.under_reset) return;
            done = 1;
          end else if (return_on_idle) begin
            // We expect dut to be IDLE
            done = 1;
          end else begin
            // if data is not ready the DUT is missing
            // KEY and IV - or the configuration
            try_recover(cfg_item, data_item, manual_operation, sideload_en, new_msg);
            if (cfg.under_reset) return;
            txt = {txt, $sformatf("\n\t ----| status state 1 ")};
          end
        end else if (aes_status.output_valid) begin
          // state 2 //
          // data ready to be read out
          // read or return
          done = 1;
          if (read_output) begin
            read_data(data_item.data_out, is_blocking);
            if (cfg.under_reset) return;
            txt = {txt, $sformatf("\n\t ----| status state 2 ")};
          end


        end else if (!(aes_status.idle || aes_status.stall || aes_status.output_valid)) begin
          // state 3 //
          // Not idle, not stalling, not ready for input and no valid output should only occur when
          // requesting entropy for reseeding the PRNGs which for example happens directly after
          // reset.
          if (!(aes_status.input_ready || aes_requesting_entropy())) begin
            not_idle_cnt++;
            if (not_idle_cnt == 1000) begin
              txt = "\nFor 1000 consecutive reads, AES";
              txt = {txt, $sformatf("\n- neither reported IDLE, STALL, OUTPUT_VALID, INPUT_READY")};
              txt = {txt, $sformatf("\n- nor did it fetch entropy")};
              `uvm_fatal(`gfn, $sformatf("%s", txt))
            end
          end else begin
            not_idle_cnt = 0;
          end
          if (!read_output && !return_on_idle) done = 1;
          // else DUT is in operation wait for new output
          txt = {txt, $sformatf("\n\t ----| status state 3 ")};


        end else begin
          txt = {txt, $sformatf("\n ----| STATUS RETURNED ILLEGAL STATE |---- ")};
          txt = {txt, $sformatf("\n ----| IDLE %0b",aes_status.idle)};
          txt = {txt, $sformatf("\n ----| STALL %0b",aes_status.stall)};
          txt = {txt, $sformatf("\n ----| INPUT_READY %0b",aes_status.input_ready)};
          txt = {txt, $sformatf("\n ----| OUTPUT_VALID %0b",aes_status.output_valid)};
          `uvm_fatal(`gfn, $sformatf("\n\t %s",txt))
        end
      end // else: !if(aes_status.alert_fatal_fault)
    end // while (!done)


    if (global_reset) begin
      rst_set = 1;
    end
    `uvm_info(`gfn, $sformatf("\n\t %s",txt), UVM_MEDIUM)
  endtask


  virtual task try_recover(
    aes_seq_item        cfg_item,         // sequence item with configuration
    aes_seq_item        data_item,        // sequence item with data to process
    bit                 manual_operation,
    bit                 sideload_en,
    bit                 new_msg
    );
    // if data is not ready the DUT is missing
    // KEY and IV - or the configuration
    ctrl_reg_t            ctrl;
    status_t              aes_status;         // the current AES aes_status
    bit                   is_blocking = ~cfg_item.do_b2b;
    uvm_status_e          txn_status;

    ral.aes_core.CTRL_SHADOWED.read(txn_status, ctrl);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to read CTRL_SHADOWED.")

    ral.aes_core.CTRL_SHADOWED.OPERATION.set(cfg_item.operation);
    ral.aes_core.CTRL_SHADOWED.MODE.set(cfg_item.mode);
    ral.aes_core.CTRL_SHADOWED.KEY_LEN.set(cfg_item.key_len);
    ral.aes_core.CTRL_SHADOWED.MANUAL_OPERATION.set(cfg_item.manual_op);
    ral.aes_core.CTRL_SHADOWED.SIDELOAD.set(cfg_item.sideload_en);

    // key and IV missing clear all and rewrite (a soon to come update will merge
    // the clear options into a single bit)
    clear_regs(2'b11);
    if (cfg.under_reset) return;

    // when using sideload we need to generate
    // new key for agent to send new key item
    if (sideload_en) begin
      new_key = 1;
      key_rdy = 0;
      wait(key_rdy || cfg.under_reset);
      if (cfg.under_reset) return;
    end

    // check for fatal
    read_status(aes_status);
    if (cfg.under_reset) return;

    if (!aes_status.alert_fatal_fault) begin
      // wait for idle
      if (!aes_status.idle) begin
        spinwait_status_idle();
        if (cfg.under_reset) return;
      end

      double_update_to_desired(ral.aes_core.CTRL_SHADOWED);
      if (cfg.under_reset) return;

      spinwait_status_idle();
      if (cfg.under_reset) return;
    end else begin
      // if alert just try to update ctrl and everything else
      double_update_to_desired(ral.aes_core.CTRL_SHADOWED);
      if (cfg.under_reset) return;
    end

    // Read the main control register. This will update the mirrored values thereby getting them
    // back in sync with the DUT (updated via csr_update() above) and the predicted values (updated
    // via set() above).
    ral.aes_core.CTRL_SHADOWED.read(txn_status, ctrl, .path(UVM_BACKDOOR));
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) begin
      `uvm_error(get_full_name(), "Failed to backdoor-read CTRL_SHADOWED register.")
    end

    if (cfg_item.mode == AES_GCM && !aes_status.alert_fatal_fault) begin
      // As we are splitting the message, we also need to recalculate the length
      // of the AAD and PTX -> len(aad) || len(data) that is stored in a AES_GCM_TAG
      // block. Image we split the message after the first AAD block:
      // |AAD|AAD|PTX|PTX|TAG|
      // we will land up having:
      // |AAD|PTX|PTX|TAG
      // Hence, recalculate here the new len(aad) || len(data).
      aes_seq_item    aes_item_queue_clone[$];
      aes_seq_item    data_item_tmp;
      bit [3:0][31:0] len_aad_data_conc;
      bit [3:0][31:0] len_aad_data;
      int aad_len = 0;
      int ptx_len = 0;
      // Get AAD or PTX length of the current data_item.
      if (data_item.item_type == AES_DATA) begin
        ptx_len = data_item.data_len == 0 ? 16 : data_item.data_len;
      end else if (data_item.item_type == AES_GCM_AAD) begin
        aad_len = data_item.data_len == 0 ? 16 : data_item.data_len;
      end
      // Fetch all remaining data items and accumulate the AAD/PTX length.
      while (aes_item_queue.size() > 0) begin
        int data_len;
        data_item_tmp = aes_item_queue.pop_back();
        aes_item_queue_clone.push_front(data_item_tmp);
        data_len = data_item_tmp.data_len == 0 ? 16 : data_item_tmp.data_len;
        if (data_item_tmp.item_type == AES_GCM_AAD) begin
          aad_len += data_len;
        end else if (data_item_tmp.item_type == AES_DATA) begin
          ptx_len += data_len;
        end
      end
      // Resemble len(aad) || len(data).
      len_aad_data_conc = ((aad_len * 8 << 64) | ptx_len * 8);
      len_aad_data = {<<8{len_aad_data_conc}};
      // Put all items back to the aes_item_queue in the correct order.
      while (aes_item_queue_clone.size() > 0) begin
        data_item_tmp = aes_item_queue_clone.pop_back();
        if (data_item_tmp.item_type == AES_GCM_TAG) begin
          // Once we reached the AES_GCM_TAG block, put in the new
          // len(aad) || len(data)
          data_item_tmp.data_in = len_aad_data;
        end
        aes_item_queue.push_front(data_item_tmp);
      end
      aes_item_queue_clone.delete();

      // After re-calculating len(aad) || len(data) start the AES-GCM operation
      // by putting the block into the GCM_INIT phase.
      set_gcm_phase(GCM_INIT, 16, 1, 0);
      if (cfg.under_reset) return;
    end

    write_key(cfg_item.key, is_blocking);
    if (cfg.under_reset) return;

    // wait for reseed but check for fatal
    // if fatal idle will never come
    read_status(aes_status);
    if (cfg.under_reset) return;

    if (!aes_status.alert_fatal_fault && !aes_status.idle) begin
      if (cfg.reseed_en) spinwait_status_idle();
      if (cfg.under_reset) return;
    end
    write_iv(cfg_item.iv, is_blocking);
    if (cfg.under_reset) return;

    // When in AES-GCM mode & manual operation is enabled, we need to trigger
    // twice to process IV/key and calculate the hash subkey.
    if (cfg_item.mode == AES_GCM && manual_operation && !aes_status.alert_fatal_fault) trigger();
    if (cfg_item.mode == AES_GCM && manual_operation && !aes_status.alert_fatal_fault) trigger();
      if (cfg.under_reset) return;

    if (cfg_item.mode == AES_GCM) begin
      int valid_bytes = data_item.data_len == 0 ? 16 : data_item.data_len;
      if (new_msg == 0 && !aes_status.alert_fatal_fault) begin
        if (data_item.item_type == AES_GCM_AAD) begin
          set_gcm_phase(GCM_AAD, valid_bytes, 1, 0);
          add_data(data_item.data_in, cfg_item.do_b2b);
          if (manual_operation) trigger();
        end else if (data_item.item_type == AES_DATA) begin
          set_gcm_phase(GCM_TEXT, valid_bytes, 1, 0);
          add_data(data_item.data_in, cfg_item.do_b2b);
          if (manual_operation) trigger();
        end else if (data_item.item_type == AES_GCM_TAG) begin
          set_gcm_phase(GCM_TAG, 16, 1, 0);
          add_data(data_item.data_in, cfg_item.do_b2b);
          if (manual_operation) trigger();
        end
      end
    end else begin
      add_data(data_item.data_in, cfg_item.do_b2b);
      if (manual_operation) trigger();
    end
  endtask // try_recover

  // Send the messages in message_queue, removing them as we go
  //
  // The unbalanced, read_prob and write_prob arguments are passed to send_msg, controlling to read
  // or write each message.
  //
  // If m_external_reset is true and reset is asserted, exit immediately. If m_external_reset is
  // false, the task might itself cause resets.
  virtual task send_msg_queue (bit unbalanced, int read_prob, int write_prob);
    bit  rst_set = 0;
    bit  enable_sideload = 0;

    while (message_queue.size() > 0 && !cfg.under_reset) begin
      aes_message_item my_message;

      `uvm_info(`gfn, $sformatf("Starting New Message - messages left %d",
                                 message_queue.size() ), UVM_MEDIUM)
      my_message = message_queue.pop_back();
      generate_aes_item_queue(my_message);

      fork
        // This process supplies sideload keys, then setting key_rdy. It will exit when key_used is
        // set. If sideload_en is false, key_rdy is set immediately.
        begin
          if (my_message.sideload_en) begin
            req_sideload_key();
          end else begin
            key_rdy = 1;
          end
        end

        begin
          // Send the message. This will consume the key (waiting for key_rdy)
          send_msg(my_message.manual_operation, my_message.sideload_en,
                   unbalanced, read_prob, write_prob, rst_set);

          // Note that the resets checks here are not predicated on m_external_reset, because
          // send_msg might have injected a reset if m_external_reset is false. We'll handle that
          // cleanly after the join.
          if (my_message.sideload_en && !cfg.under_reset) begin
            // If we sent a sideload message, set key_used. This tells req_sideload_key that we are
            // done, causing that task to clear key_used again and exit.
            key_used = 1;

            if (!cfg.under_reset) spinwait_status_idle();
            if (!cfg.under_reset) clear_regs(2'b11);
            if (!cfg.under_reset) spinwait_status_idle();
          end
        end
      join

      // Clear key_rdy again for the next loop
      key_rdy = 0;
    end

    // If we are in reset and m_external_reset is false, this may have been caused by a call to
    // send_msg in the loop. If so, we need to tidy it up before exiting. If m_external_reset is
    // true, we haven't caused a reset ourselves, so don't need to do any tidying up: if we are in
    // reset, we should just return.
    if (!m_external_reset) return;

    if (rst_set || cfg.under_reset) begin
      aes_item_queue.delete();
      message_queue.delete();
      // send a few msg to make sure
      // everything still works
      cfg.num_messages = 2;
      generate_message_queue();
      // if process was halted from the outside //
      if (global_reset) begin
        global_reset = 0;
        // wait for resset to get set
        wait(cfg.under_reset);
        `uvm_info(`gfn, $sformatf("WAITING FOR RESET RELEASE"), UVM_MEDIUM)
        wait(cfg.clk_rst_vif.rst_n);
        #1ps;
        dut_init("HARD");
      end
    end
  endtask // send_msg_queue

  virtual task post_body();

    if (cfg.en_scb) begin
      bit [31:0] idle_mask = 32'h1 << ral.aes_core.STATUS.IDLE.get_lsb_pos();
      bit [31:0] output_valid_mask = 32'h1 << ral.aes_core.STATUS.OUTPUT_VALID.get_lsb_pos();

      // AES indicates when it's done with processing individual blocks but not when it's done
      // with processing an entire message. To detect the end of a message, the DV environment
      // does the following:
      // - It tracks writes to the main control register. If two successful writes to this
      //   shadowed register are observed, this marks the start of a new message.
      // - DV then knows that the last output data retrieved marks the end of the previous
      //   message.
      // This works fine except for the very last message before the sequence ends. To mark the
      // end of the last message, and trigger its scoring, the `finish_message` variable is set.
      // It gets read by the `rebuild_message()` task in the scoreboard.
      //
      // Before doing this, wait for the DUT to become idle and final output to have been read (so
      // output_valid is false).
      `uvm_info(`gfn, "waiting for DUT to become idle and final output to be read", UVM_MEDIUM)
      masked_spinwait_register(ral.aes_core.STATUS,
                               idle_mask,
                               idle_mask | output_valid_mask);
      `uvm_info(`gfn, "sending finish_message", UVM_MEDIUM)
      cfg.finish_message = 1;
    end

    super.post_body();

  endtask


  ///////////////////////////////////////////////////////////
  ///////////////        FUNCTIONS       ////////////////////
  ///////////////////////////////////////////////////////////

  // initialize the global sequence item
  // with values from the message item (happens once per message item
  function void aes_item_init(aes_message_item message_item);
    aes_item = new();
    aes_item.operation        = message_item.aes_operation;
    aes_item.mode             = message_item.aes_mode;
    aes_item.key_len          = message_item.aes_keylen;
    aes_item.key              = message_item.aes_key;
    aes_item.iv               = message_item.aes_iv;
    aes_item.manual_op        = message_item.manual_operation;
    aes_item.key_mask         = message_item.keymask;
    aes_item.sideload_en      = message_item.sideload_en;
    aes_item.reseed_rate      = message_item.reseed_rate;
    aes_item.clear_reg_pct    = cfg.clear_reg_pct;
    aes_item.clear_reg_w_rand = cfg.clear_reg_w_rand;
  endfunction // aes_item_init


  function void generate_ctrl_item();
    aes_seq_item item_clone;

    aes_item.item_type = AES_CFG;

    `DV_CHECK_RANDOMIZE_FATAL(aes_item)
    `uvm_info(`gfn, $sformatf("\n\t ----| CONFIG  AES ITEM %s",
                                aes_item.convert2string()), UVM_HIGH)

    `downcast(item_clone, aes_item.clone());
    aes_item_queue.push_front(item_clone);
  endfunction


  // init the first message - following will rerandomize with the same constraints
  function void aes_message_init();
    aes_message = new();
    aes_message.ecb_weight           = cfg.ecb_weight;
    aes_message.cbc_weight           = cfg.cbc_weight;
    aes_message.ofb_weight           = cfg.ofb_weight;
    aes_message.cfb_weight           = cfg.cfb_weight;
    aes_message.ctr_weight           = cfg.ctr_weight;
    aes_message.gcm_weight           = cfg.gcm_weight;
    aes_message.key_128b_weight      = cfg.key_128b_weight;
    aes_message.key_192b_weight      = cfg.key_192b_weight;
    aes_message.key_256b_weight      = cfg.key_256b_weight;
    aes_message.message_len_max      = cfg.message_len_max;
    aes_message.message_len_min      = cfg.message_len_min;
    aes_message.aad_len_max          = cfg.aad_len_max;
    aes_message.aad_len_min          = cfg.aad_len_min;
    aes_message.config_error_pct     = cfg.config_error_pct;
    aes_message.error_types          = cfg.error_types;
    aes_message.config_error_type_en = cfg.config_error_type_en;
    aes_message.manual_operation_pct = cfg.manual_operation_pct;
    aes_message.keymask              = cfg.key_mask;
    aes_message.fixed_key_en         = cfg.fixed_key_en;
    aes_message.fixed_data_en        = cfg.fixed_data_en;
    aes_message.fixed_operation_en   = cfg.fixed_operation_en;
    aes_message.fixed_operation      = cfg.fixed_operation;
    aes_message.fixed_keylen_en      = cfg.fixed_keylen_en;
    aes_message.fixed_keylen         = cfg.fixed_keylen;
    aes_message.fixed_iv_en          = cfg.fixed_iv_en;
    aes_message.fixed_aad_en         = cfg.fixed_aad_en;
    aes_message.sideload_pct         = cfg.sideload_pct;
    aes_message.per1_weight          = cfg.per1_weight;
    aes_message.per64_weight         = cfg.per64_weight;
    aes_message.per8k_weight         = cfg.per8k_weight;
  endfunction


  function void generate_message_queue();
    aes_message_item cloned_message;
    for (int i=0; i < cfg.num_messages; i++) begin
      `DV_CHECK_RANDOMIZE_FATAL(aes_message)
      // For errors in the mode field, the DUT will not produce any output. Such messages are
      // counted as corrupt messages.
      if (aes_message.cfg_error_type.mode == 1'b1) begin
        cfg.num_corrupt_messages += 1;
      end
      `downcast(cloned_message, aes_message.clone());
      message_queue.push_front(cloned_message);
      `uvm_info(`gfn, $sformatf("\n\t ----| MESSAGE #%0d\n %s",
          i, cloned_message.convert2string()), UVM_MEDIUM)
      `uvm_info(`gfn, $sformatf("\n\t ----| \n %s",
          cloned_message.cfg_error_string()), UVM_MEDIUM)
      `uvm_info(`gfn, $sformatf("\n\t ----| \n %s",
          cloned_message.field_distribution_string()), UVM_MEDIUM)
    end
  endfunction // generate_message_queue


  function void aes_print_item_queue(aes_seq_item item_queue[$]);
    aes_seq_item print_item;
    `uvm_info(`gfn, $sformatf("----| Item queue size: %d", item_queue.size()), UVM_MEDIUM)
    for (int n = 0; n < item_queue.size(); n++) begin
      print_item = item_queue[n];
      `uvm_info(`gfn, $sformatf("----|  ITEM #%d", n ), UVM_MEDIUM)
      `uvm_info(`gfn, $sformatf("%s", print_item.convert2string()), UVM_MEDIUM)
    end
  endfunction // aes_print_item_queue


  function string status2string(status_t aes_status);
    string txt="";
    txt ={txt, $sformatf("\n\t ---| Idle:          %0b", aes_status.idle)};
    txt ={txt, $sformatf("\n\t ---| Stall:         %0b", aes_status.stall)};
    txt ={txt, $sformatf("\n\t ---| Output Lost:   %0b", aes_status.output_lost)};
    txt ={txt, $sformatf("\n\t ---| Output Valid:  %0b", aes_status.output_valid)};
    txt ={txt, $sformatf("\n\t ---| Input Ready:   %0b", aes_status.input_ready)};
    txt ={txt, $sformatf("\n\t ---| Alert - Recov: %0b", aes_status.alert_recov_ctrl_update_err)};
    txt ={txt, $sformatf("\n\t ---| Alert - Fatal: %0b", aes_status.alert_fatal_fault)};
    return txt;
  endfunction // status2string


  function automatic bit aes_requesting_entropy();
    bit requesting_entropy;
    if ((cfg.aes_reseed_vif.entropy_clearing_req == 1'b1) ||
        (cfg.aes_reseed_vif.entropy_masking_req == 1'b1)) begin
      requesting_entropy = 1'b1;
    end else begin
      requesting_entropy = 1'b0;
    end
    return requesting_entropy;
  endfunction

endclass : aes_base_vseq
