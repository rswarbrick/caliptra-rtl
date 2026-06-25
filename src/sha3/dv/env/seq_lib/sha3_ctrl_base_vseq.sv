// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This base sequence consists of common kmac tasks and functions.
// In this sequence, when it uses a plain `csr_rd` without checking, the read value should be
// predicted and checked in the sha3_ctrl scoreboard.
class sha3_ctrl_base_vseq extends dv_base_vseq #(
    .RAL_T               (sha3_ctrl_dv_reg),
    .CFG_T               (sha3_ctrl_env_cfg),
    .COV_T               (sha3_ctrl_env_cov),
    .VIRTUAL_SEQUENCER_T (sha3_ctrl_virtual_sequencer)
  );

  `uvm_object_utils(sha3_ctrl_base_vseq)
  `uvm_object_new

  // A sequencer for AHB transactions, which must be configured by the test by calling
  // set_ahb_sequencer() before running the sequence.
  protected ahb_txn_sequencer_t m_ahb_sequencer;

  // used to randomly enable interrupts
  rand bit [31:0] enable_intr;

  // This bit only applies to KMAC hashing operation.
  //
  // KMAC has two operation modes, one with known output length,
  // and with an unknown output length (as an XOF).
  //
  // When output length is known we write `right_encode(len)` to msgfifo
  // after the input message, but to enable the XOF mode we must write `right_encode(0)`
  // to the msgfifo after the input message.
  //
  // This bit enables the XOF mode of operation, and causes the correct output length
  // encoding to be written into the msgfifo.
  rand bit xof_en;

  // hashing mode (sha3/shake/cshake)
  rand sha3_pkg::sha3_mode_e hash_mode;

  // security strength
  rand sha3_pkg::keccak_strength_e strength;

  // endianness of message and secret key.
  // 0: little endian
  // 1: big endian
  rand bit msg_endian;

  // endianness of output digest.
  // 0: keep state endianness as is
  // 1: convert state to big endian
  rand bit state_endian;

  // set to provide the KMAC with a key through the sideload interface.
  // does not control whether the cfg.sideload field is set.
  rand bit provide_sideload_key;

  // So we use a static entropy mode value to hold the same mode through the whole test,
  // and constrain `entropy_mode` accordingly.
  kmac_pkg::entropy_mode_e static_entropy_mode = EntropyModeSw;

  // Message masking
  rand bit msg_mask;

  // output length in bytes.
  rand int unsigned output_len;

  // Keccak block size - used only for variable-length output functions.
  // strength128 -> 168
  // strength256 -> 136
  rand int unsigned keccak_block_size;

  // Function name and customization string length in bytes (1 char = 1 byte).
  // Since we cannot create random strings, we simplify by controlling the length of the fname.
  rand int unsigned fname_len;
  rand int unsigned custom_str_len;

  // Used to store N and S after encoding them
  rand byte fname_arr[];
  rand byte custom_str_arr[];

  // input msg - assume this is little endian
  rand bit [7:0] msg[];

  // 2 key shares - are XORed together to produce intended secret key
  //
  // max key length is 512 bits
  rand bit [KMAC_NUM_SHARES-1:0][KMAC_NUM_KEYS_PER_SHARE-1:0][31:0] key_share;

  // data mask used when accessing TLUL windows (msgfifo, state)
  rand bit [3:0] data_mask;

  // Error control fields
  rand kmac_pkg::err_code_e kmac_err_type;
  // When creating errors by issue the wrong SW command, we need to have access
  // to what operational state to send an erroneous command in,
  // as well as the proper random incorrect command to send.
  rand sha3_pkg::sha3_st_e err_sw_cmd_seq_st;
  rand kmac_pkg::kmac_cmd_e err_sw_cmd_seq_cmd;

  // Entropy related variables
  rand bit [9:0] hash_threshold;
  rand bit entropy_req;
  rand bit entropy_timer_en;
  rand bit [EntropyPeriodReserved-1:0] prescaler_val;
  rand bit [32-KmacWaitTimer-1:0] entropy_wait_timer;

  bit do_kmac_init = 1'b1;

  // output length constraints when using any SHA3 mode
  constraint output_len_sha3_c {
    if (hash_mode == sha3_pkg::Sha3) {
      (strength == sha3_pkg::L224) -> (output_len == 28);
      (strength == sha3_pkg::L256) -> (output_len == 32);
      (strength == sha3_pkg::L384) -> (output_len == 48);
      (strength == sha3_pkg::L512) -> (output_len == 64);
    }
  }

  // Constrain valid and invalid mode/strength combinations based on the following:
  // - only 128/256 bit strengths are supported for Shake/CShake
  // - 128 bit strength is not supported for Sha3
  constraint strength_c {
    solve kmac_err_type before hash_mode;
    solve kmac_err_type before strength;

    if (kmac_err_type == kmac_pkg::ErrUnexpectedModeStrength) {
      (hash_mode inside {sha3_pkg::Shake, sha3_pkg::CShake}) ->
        !(strength inside {sha3_pkg::L128, sha3_pkg::L256});

      (hash_mode == sha3_pkg::Sha3) -> (strength == sha3_pkg::L128);
    } else {
      (hash_mode inside {sha3_pkg::Shake, sha3_pkg::CShake}) ->
        (strength inside {sha3_pkg::L128, sha3_pkg::L256});

      (hash_mode == sha3_pkg::Sha3) -> (strength != sha3_pkg::L128);
    }
  }

  // Set the block size based on the random security strength.
  // This is only relevant for XOF functions (L128 or L256), but will be
  // set for all security strengths.
  //
  // The block size is calculated by:
  // `(1600 - (2 * strength_in_bits)) / 8`
  constraint keccak_block_size_c {
    (strength == sha3_pkg::L128) -> (keccak_block_size == 168);
    (strength == sha3_pkg::L224) -> (keccak_block_size == 144);
    (strength == sha3_pkg::L256) -> (keccak_block_size == 136);
    (strength == sha3_pkg::L384) -> (keccak_block_size == 104);
    (strength == sha3_pkg::L512) -> (keccak_block_size == 72);
  }

  // Create an appropriate incorrect command based on what state to send an error in
  constraint err_sw_cmd_seq_c {
    solve err_sw_cmd_seq_st before err_sw_cmd_seq_cmd;
    if (kmac_err_type == kmac_pkg::ErrSwCmdSequence) {
      if (err_sw_cmd_seq_st == sha3_pkg::StIdle) {
        err_sw_cmd_seq_cmd inside {CmdProcess, CmdManualRun, CmdDone};
      } else if (err_sw_cmd_seq_st == sha3_pkg::StAbsorb) {
        err_sw_cmd_seq_cmd inside {CmdStart, CmdManualRun, CmdDone};
      } else if (err_sw_cmd_seq_st == sha3_pkg::StSqueeze) {
        err_sw_cmd_seq_cmd inside {CmdStart, CmdProcess};
      } else if (err_sw_cmd_seq_st inside {sha3_pkg::StManualRun, sha3_pkg::StFlush}) {
        err_sw_cmd_seq_cmd != CmdNone;
      }
    }
  }

  // as per TL-UL spec, data mask must have contiguous 1s.
  //
  // we duplicate this constraint here as we manually write to the msgfifo window
  // via the tl_access() method.
  constraint data_mask_contiguous_c {
    $countones(data_mask ^ {data_mask[2:0], 1'b0}) <= 2;
  }

  // Bias the data mask to be {TL_DBW{1'b1}} half of the time,
  // to slightly increase simulation speed
  constraint data_mask_c {
    $countones(data_mask) dist {
      [1 : 4] :/ 1,
      4       :/ 1
    };
  }

  // as per spec, len(N+S) can be at most 288 bits (36 bytes).
  constraint prefix_len_c {
    fname_len + custom_str_len <= 36;

    fname_arr.size() == fname_len;
    custom_str_arr.size() == custom_str_len;
  }

  // constrains N and S to only be valid alphabet letters and space [A-Za-z]
  constraint prefix_is_char_c {
    foreach(fname_arr[i]) {
      //                space |  A-Z   |  a-z
      fname_arr[i] inside {32, [65:90], [97:122]};
    }
    foreach(custom_str_arr[i]) {
      //                     space |  A-Z   |  a-z
      custom_str_arr[i] inside {32, [65:90], [97:122]};
    }
  }

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
    uvm_reg_data_t mask = uvm_reg_data_t'(1) << bit_idx;
    masked_spinwait_register(register, desired_value ? mask : '0, mask);
  endtask

  virtual task dut_init(string reset_kind = "HARD");
    super.dut_init();
    if (do_kmac_init) kmac_init();
  endtask

  virtual task pre_start();
    super.pre_start();

    if (m_ahb_sequencer == null) begin
      `uvm_fatal(get_full_name(), "Cannot run sequence without an AHB sequencer.")
    end

    `DV_CHECK_STD_RANDOMIZE_WITH_FATAL(static_entropy_mode,
        static_entropy_mode inside {EntropyModeSw, EntropyModeEdn};)
  endtask

  // Set the sequencer to use for AHB transactions that will be sent to sha3_ctrl.
  function void set_ahb_sequencer(ahb_txn_sequencer_t sequencer);
    m_ahb_sequencer = sequencer;
  endfunction

  // Set or clear the given bits in the intr_enable register
  //
  // (This is copied from the cip_base_vseq class in OpenTitan)
  protected task cfg_interrupts(bit [31:0] mask, bit enable);
    uvm_reg      csr = ral.kmac_core.INTR_ENABLE;
    bit [31:0]   current, desired;
    uvm_status_e txn_status;

    current = csr.get_mirrored_value();

    if (enable) desired = current | mask;
    else        desired = current & ~mask;

    csr.set(desired);

    csr.update(txn_status);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to write intr_enable.")
  endtask

  // setup basic kmac features
  virtual task kmac_init(bit wait_init = 1, bit keymgr_app_intf = 0);
    // Wait for KMAC to reach idle state
    if (wait_init) begin
      wait (cfg.under_reset || !cfg.m_busy_vif.pins[0]);
      if (cfg.under_reset) return;
      `uvm_info(`gfn, "reached idle state", UVM_HIGH)
    end

    // set interrupts
    cfg_interrupts(enable_intr, 1);
    if (cfg.under_reset) return;

    // For error cases that does not support in scb, predict its value so can be used in
    // `check_err` task.
    if (cfg.en_scb == 0) void'(ral.kmac_core.INTR_ENABLE.predict(enable_intr));
    `uvm_info(`gfn, $sformatf("intr[KmacDone] = %0b", enable_intr[KmacDone]), UVM_HIGH)
    `uvm_info(`gfn, $sformatf("intr[KmacFifoEmpty] = %0b", enable_intr[KmacFifoEmpty]), UVM_HIGH)
    `uvm_info(`gfn, $sformatf("intr[KmacErr] = %0b", enable_intr[KmacErr]), UVM_HIGH)

    // setup CFG csr with default random values
    ral.kmac_core.CFG_SHADOWED.kstrength.set(strength);
    ral.kmac_core.CFG_SHADOWED.mode.set(hash_mode);
    ral.kmac_core.CFG_SHADOWED.msg_endianness.set(msg_endian);
    ral.kmac_core.CFG_SHADOWED.state_endianness.set(state_endian);
    double_update_to_desired(ral.kmac_core.CFG_SHADOWED);
    if (cfg.under_reset) return;

    // print debug info
    `uvm_info(`gfn, $sformatf("KMAC INITIALIZATION INFO:\n%0s", convert2string()), UVM_HIGH)
  endtask

  // Start a single 32-bit bus write with the given address and wdata
  //
  // The index of the subordinate is taken from cfg.m_subordinate_idx (which should have been
  // configured by the testbench).
  //
  // The write will be done by running an ahb_transfer_seq and this task waits until that sequence
  // manages to send its first request (using wait_for_first_request) and then returns with the
  // sequence running, passing the sequence through the transfer_seq output argument.
  task start_bus_write(bit [31:0]                             addr,
                       bit [1:0]                              size,
                       bit [31:0]                             wdata,
                       output ahb_agent_pkg::ahb_transfer_seq transfer_seq);
    ahb_agent_pkg::ahb_single_write_seq seq;

    // Check that addr is naturally aligned for a 32-bit write (the only width supported by the
    // block)
    if (addr & 3) begin
      `uvm_error(get_full_name(),
                 $sformatf("Cannot do 32-bit write to address 0x%0h: not naturally aligned.", addr))
      return;
    end

    seq = ahb_agent_pkg::ahb_single_write_seq::type_id::create("seq");

    // caliptra-rtl does not use HPROT
    seq.m_hprot_width = 0;

    if (!seq.randomize() with {
      m_subordinate_idx == local::cfg.m_subordinate_idx;
      m_size            == local::size;
      m_addr            == local::addr;
      m_wdata           == local::wdata;

      // Since the interface doesn't have HWSTRB, pick the value zero: it's an easy constant!
      m_wstrb           == '0;
    }) begin
      `uvm_fatal(get_full_name(), "Failed to randomise seq.")
    end

    // Run the entire sequence (which just has a single item) and wait until its first request gets
    // sent.
    fork
      seq.start(m_ahb_sequencer);
      seq.wait_for_first_request();
    join_any

    // At this point, the wait_for_first_request task will have completed (seq.start might have
    // completed too if we saw a reset before sending the request). Return from this task, writing
    // seq to the weaker-typed transfer_seq output argument.
    transfer_seq = seq;
  endtask


  // Perform a single 32-bit bus write with the given address, size and wdata
  //
  // The index of the subordinate is taken from cfg.m_subordinate_idx (which should have been
  // configured by the testbench).
  //
  // The status output argument is UVM_NOT_OK if the sequence was interrupted by a reset or if the
  // subordinate responded by asserting HRESP.
  task send_bus_write(bit [31:0]          addr,
                      bit [1:0]           size,
                      bit [31:0]          wdata,
                      output uvm_status_e status);
    import ahb_agent_pkg::ahb_txn_response_item;

    ahb_agent_pkg::ahb_transfer_seq seq;
    start_bus_write(addr, size, wdata, seq);

    // The sequence has been started. Wait until it is done.
    seq.wait_for_sequence_state(UVM_STOPPED | UVM_FINISHED);

    // Set status based on the sequence result. It should be UVM_NOT_OK if the sequence didn't have
    // a full transaction (probably because of a reset), or if the final response asserted an error
    // using the HRESP signal.
    if (!seq.has_full_transaction()) begin
      status = UVM_NOT_OK;
    end else begin
      ahb_txn_response_item last_rsp = seq.m_responses[seq.m_responses.size() - 1];
      status = last_rsp.m_resp ? UVM_NOT_OK : UVM_IS_OK;
    end
  endtask

  // Perform a single bus read from the given address.
  //
  // The index of the subordinate is taken from cfg.m_subordinate_idx (which should have been
  // configured by the testbench).
  //
  // The HSIZE in the read is taken to be the largest possible value (which might be constrained by
  // requiring the transfer to be naturally aligned).
  //
  // The rdata output argument is the value that was read. The status output argument is UVM_NOT_OK
  // if the sequence was interrupted by a reset or if the subordinate responded by asserting HRESP.
  task send_bus_read(bit [31:0]          addr,
                     output bit [31:0]   rdata,
                     output uvm_status_e status);
    import ahb_agent_pkg::ahb_single_read_seq, ahb_agent_pkg::ahb_txn_response_item;

    ahb_single_read_seq seq;
    int unsigned biggest_good_size = 0;

    // Find the largest size up to 32b where addr is naturally aligned (so addr & ((1 << size) - 1)
    // is zero)
    for (int unsigned size = 1; size <= 2; size++) begin
      if ((addr & ((1 << size) - 1)) == '0) biggest_good_size = size;
    end

    seq = ahb_single_read_seq::type_id::create("seq");

    // caliptra-rtl does not use HPROT
    seq.m_hprot_width = 0;

    if (!seq.randomize() with {
      m_subordinate_idx == local::cfg.m_subordinate_idx;
      m_size            == biggest_good_size;
      m_addr            == local::addr;
    }) begin
      `uvm_fatal(get_full_name(), "Failed to randomise seq.")
    end

    // Run the entire sequence (which just has a single item).
    seq.start(m_ahb_sequencer);

    // Set status based on the sequence result. It should be UVM_NOT_OK if the sequence didn't have
    // a full transaction (probably because of a reset), or if the final response asserted an error
    // using the HRESP signal.
    //
    // If there was a full transaction, relay the rdata from the last sequence item.
    if (!seq.has_full_transaction()) begin
      status = UVM_NOT_OK;
    end else begin
      ahb_txn_response_item last_rsp = seq.m_responses[seq.m_responses.size() - 1];
      rdata  = last_rsp.m_rdata;
      status = last_rsp.m_resp ? UVM_NOT_OK : UVM_IS_OK;
    end
  endtask

  // Read CFG_REGWEN, writing its single bit to regwen_value.
  //
  // The task exits early on reset, leaving regwen_value equal to zero (you can't write a register
  // when in reset!)
  task read_regwen(output bit regwen_value);
    uvm_status_e   txn_status;
    uvm_reg_data_t reg_value;

    ral.kmac_core.CFG_REGWEN.read(txn_status, reg_value);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to read CFG_REGWEN.")

    regwen_value = reg_value[0];
  endtask

  // Read the REGWEN register. If it is zero (so registers are locked), write a random value to
  // CFG_SHADOWED.
  //
  // This task exits early on reset.
  virtual task read_regwen_and_rand_write_locked_regs();
    bit regwen;

    read_regwen(regwen);
    if (cfg.under_reset) return;

    // Randomly write locked registers only if the cfg_regwen is locked.
    if (!regwen) begin
      uvm_status_e   txn_status;

      ral.kmac_core.CFG_SHADOWED.write(txn_status, $urandom_range(0, 32'hFFFF_FFFF));
      if (cfg.under_reset) return;
      if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to write CFG_SHADOWED.")
    end
  endtask

  // This task reads out the STATUS and INTR_STATE csrs so scb can check the status
  virtual task check_state();
    uvm_status_e txn_status;

    ral.kmac_core.STATUS.mirror(txn_status);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to read STATUS.")

    ral.kmac_core.INTR_STATE.mirror(txn_status);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to read INTR_STATE.")

    ral.kmac_core.INTR_STATE.write(txn_status, 32'hffff_ffff);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to write to INTR_STATE.")
  endtask

  // Read the bit corresponding to intr_kmac_err_o from the clp_reg.error_internal_intr_r register
  task read_error_interrupt_status(output bit sha3_error_sts);
    uvm_status_e   txn_status;
    uvm_reg_data_t reg_value;
    uvm_reg_field  status_fld = ral.clp_reg.intr_block_rf.error_internal_intr_r.sha3_error_sts;

    ral.clp_reg.intr_block_rf.error_internal_intr_r.read(txn_status, reg_value);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) begin
      `uvm_error(get_full_name(), "Failed to read ERROR_INTERNAL_INTR_R.")
    end

    sha3_error_sts = (reg_value >> status_fld.get_lsb_pos()) & 1;
  endtask

  // Read the bit controlling whether the intr_kmac_err_o KMAC interrupt will cause the ERROR
  // interrupt.
  task read_error_interrupt_enable(output bit sha3_error_en);
    uvm_status_e   txn_status;
    uvm_reg_data_t reg_value;
    uvm_reg_field  error_en_fld = ral.clp_reg.intr_block_rf.error_intr_en_r.sha3_error_en;

    ral.clp_reg.intr_block_rf.error_intr_en_r.read(txn_status, reg_value);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) begin
      `uvm_error(get_full_name(), "Failed to read ERROR_INTR_EN_R.")
    end

    sha3_error_en = (reg_value >> error_en_fld.get_lsb_pos()) & 1;
  endtask

  // Read and clear the KMAC INTR_STATE register
  task read_and_clear_intr_state(output bit [2:0] intr_state);
    uvm_status_e   txn_status;
    uvm_reg_data_t intr_state_raw;

    ral.kmac_core.INTR_STATE.read(txn_status, intr_state_raw);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to read INTR_STATE.")

    intr_state = intr_state_raw[2:0];

    if (|intr_state) begin
      ral.kmac_core.INTR_STATE.write(txn_status, 3'b111);
      if (cfg.under_reset) return;
      if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to write INTR_STATE.")
    end
  endtask

  virtual task check_err(bit clear_err = 1'b1);
    uvm_status_e txn_status;
    bit [2:0]    intr_state_seen;

    // wait for several cycles to allow interrupt to propagate
    cfg.clk_rst_vif.wait_clks_or_rst(10);
    if (cfg.under_reset) return;

    `uvm_info(`gfn, "Starting to check error", UVM_HIGH)
    if (enable_intr[KmacErr]) begin
      bit        intr_status;
      bit [31:0] intr_pins;

      // interrupt will take 2 cycles to propagate to the output pins
      cfg.clk_rst_vif.wait_clks_or_rst(2);
      if (cfg.under_reset) return;

      // We expect to be able to read the appropriate error register in from the Caliptra-added
      // status register.
      read_error_interrupt_status(intr_status);
      if (cfg.under_reset) return;
      if (!intr_status) begin
        `uvm_error(get_full_name(), "ERROR_INTERNAL_INTR_R doesn't show an expected error.")
      end

      // We might also expect the error to have been reported through intr_kmac_err_o, which will
      // have caused the "error" signal tracked in m_intr_vif to go high.
      if (cfg.m_intr_vif.error !== 1) begin
        bit intr_en;

        // We haven't seen the interrupt, which seems a bit concerning. But it might just be that
        // the interrupt isn't enabled.
        read_error_interrupt_enable(intr_en);
        if (cfg.under_reset) return;

        if (intr_en) begin
          `uvm_error(get_full_name(),
                     $sformatf("Expected ERROR interrupt but it has value %p",
                               cfg.m_intr_vif.error))
        end
      end
    end

    // Whether or not the interrupt pin is enabled, the interrupt status register should have been
    // asserted.
    `uvm_info(`gfn, "checking intr_state csr", UVM_HIGH)
    read_and_clear_intr_state(intr_state_seen);
    if (cfg.under_reset) return;

    ral.kmac_core.ERR_CODE.mirror(txn_status);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to mirror ERR_CODE.")

    // only clear the error if error is actually set,
    // otherwise we effectively reset the design
    if (cfg.enable_masking && clear_err &&
        kmac_err_type inside {kmac_pkg::ErrIncorrectEntropyMode,
                              kmac_pkg::ErrWaitTimerExpired}) begin
      cfg.clk_rst_vif.wait_clks_or_rst($urandom_range(10, 50));
      if (cfg.under_reset) return;
      // After entropy related errors, cannot set `err_processed` and `entropy_ready` together.
      // Otherwise design will ignore the `entropy_ready` field.
      issue_cmd(32'b1 << ral.kmac_core.CMD.err_processed.get_lsb_pos());
    end else if (kmac_err_type == kmac_pkg::ErrKeyNotValid) begin
      issue_cmd(32'b1 << ral.kmac_core.CMD.err_processed.get_lsb_pos());
    end
    `uvm_info(`gfn, "Finished checking error", UVM_HIGH)
  endtask

  virtual function string convert2string();
    return {$sformatf("intr_en[KmacDone]: %0b\n", enable_intr[KmacDone]),
            $sformatf("intr_en[KmacFifoEmpty]: %0b\n", enable_intr[KmacFifoEmpty]),
            $sformatf("intr_en[KmacErr]: %0b\n", enable_intr[KmacErr]),
            $sformatf("xof_en: %0b\n", xof_en),
            $sformatf("hash_mode: %0s\n", hash_mode.name()),
            $sformatf("strength: %0s\n", strength.name()),
            $sformatf("msg_length: %0d bytes\n", msg.size()),
            $sformatf("keccak_block_size: %0d\n", keccak_block_size),
            $sformatf("output_len %0d\n", output_len),
            $sformatf("msg_endian: %0b\n", msg_endian),
            $sformatf("state_endian: %0b\n", state_endian),
            $sformatf("provide_sideload_key: %0b\n", provide_sideload_key),
            $sformatf("fname_arr: %0p\n", fname_arr),
            $sformatf("fname: %0s\n", str_utils_pkg::bytes_to_str(fname_arr)),
            $sformatf("custom_str_arr: %0p\n", custom_str_arr),
            $sformatf("custom_str: %0s\n", str_utils_pkg::bytes_to_str(custom_str_arr))};
  endfunction

  // This function implements the bulk of integer encoding specified by NIST.SP.800-185
  //
  // As per spec, this function is valid for any 0 >= x > 2**2040
  //
  // Set `left_right` to 1'b1 for left encoding, and 1'b0 for right encoding
  //
  // Input `q` is assumed to be empty
  function void encode(bit [MAX_ENCODE_WIDTH-1:0] x, bit left_right, ref bit [7:0] q[$]);
    bit [7:0] b_str[$];
    byte b;
    if (x == 0) begin
      q.push_back(8'b0);
    end else begin
      // split the input number into a stream of bytes
      while (x > 0) begin
        b = x[7:0];
        x = x >> 8;
        q.push_back(b);
      end
      // append the size of the queue at the front or back of the queue,
      // depending whether we are left encoding or right encoding
    end
    // reverse bytes of q before prepending/appending q.size().
    {<< byte {q}} = q;
    b = q.size();
    if (left_right) begin
      q.push_front(b);
    end else begin
      q.push_back(b);
    end
  endfunction

  // This function performs the `left_encode(x)` function specified by NIST.SP.800-185
  //
  // As per spec, this function is valid for any 0 >= x > 2**2040
  function void left_encode(bit [MAX_ENCODE_WIDTH-1:0] x, ref bit [7:0] arr[]);
    bit [7:0] q[$];
    encode(x, 1'b1, q);
    arr = q;
  endfunction

  // This function performs the `right_encode(x)` specified by NIST.SP.800-185
  //
  // As per spec, this function is valid for any 0 >= x > 2**2040
  function void right_encode(bit [MAX_ENCODE_WIDTH-1:0] x, ref bit [7:0] arr[]);
    bit [7:0] q[$];
    encode(x, 1'b0, q);
    arr = q;
  endfunction

  // This function implements the `encode_string(S)` function specified by NIST.SP.800-185
  //
  // As per spec, this function is valid for any 0 >= bytes.size() > 2**2040.
  // Undefined behavior may result if this condition is broken.
  function void encode_string(byte bytes[], ref bit [7:0] arr[]);
    bit [7:0] encoded_len[];

    // convert from type `byte` to type `bit [7:0]`
    foreach (bytes[i]) begin
      arr[i] = 8'(bytes[i]);
    end

    left_encode(bytes.size() * 8, encoded_len);
    `uvm_info(`gfn, $sformatf("encoded_str_len: %0p", encoded_len), UVM_HIGH)
    arr = {encoded_len, arr};
  endfunction

  // This task will encode the function name and customization string,
  // and write them to the PREFIX csrs.
  virtual task set_prefix();
    bit [7:0] encoded_fname[] = new[fname_arr.size()];
    bit [7:0] encoded_custom_str[] = new[custom_str_arr.size()];
    bit [7:0] prefix_bytes[] = new[fname_arr.size() + custom_str_arr.size()];

    // PREFIX csr provides 288 bits for N+S, and 64 bits for the encoded lengths
    bit [31:0] prefix_arr[11];

    // encode function name and string
    encode_string(fname_arr, encoded_fname);
    encode_string(custom_str_arr, encoded_custom_str);
    `uvm_info(`gfn, $sformatf("encoded_fname: %0p", encoded_fname), UVM_HIGH)
    `uvm_info(`gfn, $sformatf("encoded_custom_str: %0p", encoded_custom_str), UVM_HIGH)

    // stream into chunks of 32-bits (size of the PREFIX csr)
    prefix_bytes = {encoded_fname, encoded_custom_str};
    for (int i = 0; i < (fname_len + custom_str_len) / 4 + 2 ; i++) begin
      bit [7:0] prefix_word_arr[] = new[4];
      for (int j = i*4; (j < i*4 + 4) && (j < prefix_bytes.size()); j++) begin
        prefix_word_arr[j % 4] = prefix_bytes[j];
      end
      prefix_arr[i] = {<< byte {prefix_word_arr}};
    end

    `uvm_info(`gfn, $sformatf("prefix_arr: %0p", prefix_arr), UVM_HIGH)

    // write to PREFIX csrs
    //
    // We need to overwrite all 10 of them each time we configure the prefix, as the customization
    // string is not guaranteed to be the full 256 bits every time, meaning that we might leave
    // stale information from the previous iteration otherwise.
    foreach (prefix_arr[i]) begin
      uvm_status_e txn_status;
      string csr_name = $sformatf("PREFIX_%0d", i);
      uvm_reg csr = ral.get_reg_by_name(csr_name);
      if (csr == null) begin
        `uvm_error(get_full_name(), $sformatf("Cannot find register: %0s", csr_name))
        return;
      end

      csr.write(txn_status, prefix_arr[i]);
      if (cfg.under_reset) return;
      if (txn_status != UVM_IS_OK) begin
        `uvm_error(get_full_name(), $sformatf("Failed to write to %0s.", csr_name))
      end
    end
  endtask

  // This task writes the given value to the CMD csr
  //
  // Since there is a 6-bit cmd field at the bottom of the register, this will send the appropriate
  // command if wvalue is the bits of an element of kmac_cmd_e.
  virtual task issue_cmd(bit [31:0] wvalue);
    uvm_status_e txn_status;

    ral.kmac_core.CMD.write(txn_status, wvalue);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) begin
      `uvm_error(get_full_name(), $sformatf("Failed to write 0x%0h to CMD.", wvalue))
    end
  endtask

  // This task commands KMAC to manually squeeze more output data,
  // and blocks until it has completed.
  virtual task squeeze_digest();
    issue_cmd(CmdManualRun);
    masked_spinwait_bit(ral.kmac_core.STATUS, 1, ral.kmac_core.STATUS.sha3_squeeze.get_lsb_pos());
  endtask

  // This task writes both key shares to the appropriate CSRs
  virtual task write_key_shares();
    // write keys to both shares by default regardless of masking configuration
    for (int i = 0; i < KMAC_NUM_SHARES; i++) begin
      for (int j = 0; j < KMAC_NUM_KEYS_PER_SHARE; j++) begin
        uvm_status_e txn_status;
        string       csr_name = $sformatf("KEY_SHARE%0d_%0d", i, j);
        uvm_reg      csr = ral.kmac_core.get_reg_by_name(csr_name);

        if (csr == null) begin
          `uvm_fatal(get_full_name(), $sformatf("No register at %0s", csr_name))
        end

        csr.write(txn_status, key_share[i][j]);
        if (cfg.under_reset) return;
        if (txn_status != UVM_IS_OK) begin
          `uvm_error(get_full_name(), $sformatf("Failed to write to %0s.", csr_name))
        end
      end
    end

    // debug - print out all keys
    for (int i = 0; i < KMAC_NUM_SHARES; i++) begin
      for (int j = 0; j < KMAC_NUM_KEYS_PER_SHARE; j++) begin
        `uvm_info(`gfn, $sformatf("key_share[%0d][%0d] = 0x%0x", i, j, key_share[i][j]), UVM_HIGH)
      end
    end
  endtask

  // Randomly pick an address in the KMAC fifo where we can send a naturally aligned write with the
  // given size
  local function bit [31:0] pick_fifo_addr(bit [1:0] size);
    bit [31:0] addr;

    if (!std::randomize(addr) with {
          KMAC_FIFO_BASE <= addr;
          addr <= KMAC_FIFO_END;
          (addr & ((1 << size) - 1)) == 0;
          // The caliptra-rtl AHB interface is specified to only support accesses that are 32-bit
          // aligned.
          addr % 4 == 0;
        }) begin
      `uvm_error(get_full_name(),
        $sformatf("Failed to randomize FIFO address (size = 0x%0h)", size))
      return KMAC_FIFO_BASE;
    end
    return addr;
  endfunction

  // This task writes a generic byte array into the msg_fifo
  //
  // The general flow of this task is this:
  //
  // - Read STATUS csr to make sure there is enough room in the msgfifo
  //   - If not, csr_spinwait until there is room
  //
  // - Pick a random address in the FIFO window.
  //
  // - Pick a random write mask, making sure that if there are M<4 bytes in the message then there
  //   are at most M enabled bits in the write mask.
  //   This behavior only applies
  //
  // - Pick a random write mask:
  //
  //   - If message is little endian, we can fully randomize the mask, making sure that
  //     if there are M<4 bytes left in the message then there are at most M enabled bits
  //     in the mask. This allows us to write <=4 bytes at a time which is ok since
  //     little endian ordering will be preserved.
  //
  //   - If message is big endian, things get more complicated.
  //     Since KMAC only endian-swaps the bytes in each word, and leaves word order alone,
  //     we need to write a full word at a time to the msgfifo (or the remainder of the message
  //     if M<4 bytes remain).
  //     This is because writing partial words with the big-endian scheme used by KMAC will mess up
  //     byte ordering and cause incorrect message to be accumulated.
  //
  // - Pull N bytes from the message queue, where N is the number of enable bits in the data mask
  //
  // - Stitch these N bytes together into a data word based off of the write mask
  //   - Bytes from the message are only placed in locations corresponding to
  //     an enabled bit in the mask
  //   - All other bytes in the word are randomized
  //
  // - Perform a bus access to the msgfifo with the random data/addr/mask, relying on the AHB agent
  //   to correctly align the final address and data size
  task write_msg(input bit [7:0] msg_arr[],
                 input bit       blocking = $urandom_range(0, 1),
                 input bit       wait_for_fifo_has_capacity = 1);

    bit        saw_reset;

    // The queue of bytes to be sent in the message, in the same order as msg_arr
    bit [7:0]  msg_q[$] = msg_arr;

    `uvm_info(get_full_name(),
              $sformatf("Writing a message of %0d bytes to MSG_FIFO.", msg_q.size()),
              UVM_HIGH)

    // The code below all runs inside an isolation fork, which will allow a "wait fork" to wait for
    // completion if !blocking.
    fork : isolation_fork begin
      // iterate through the message queue and pop off bytes to write to msgfifo
      while ((msg_q.size() > 0) && !saw_reset) begin
        bit        single_byte;
        bit [1:0]  hsize;
        bit [31:0] fifo_addr;
        bit [31:0] data_word;

        // Check that there is actually room in the fifo before we start writing anything.
        // Will skip this check if it is used in error case, where the fifo full is forced to high.
        if (wait_for_fifo_has_capacity) wait_fifo_has_capacity();

        // If there are fewer than 4 bytes left, we will just send a single byte from the queue
        // (hsize = 0). This is needed so that we can support queue lengths that are not a multiple
        // of 4. Otherwise, we send 4 bytes (hsize = 2).
        single_byte = (msg_q.size() < 4);
        hsize       = single_byte ? 0 : 2;
        fifo_addr   = pick_fifo_addr(hsize);

        // Construct the data word to send. If it is a single byte, that can just be popped from the
        // front of msg_q. If not, it is a 32-bit word, which takes four pops. In this case, we also
        // have to reverse the four bytes if msg_endian is true.
        if (single_byte) begin
          data_word = 32'(msg_q.pop_front());
        end else begin
          bit [31:0] le_word = '0;
          for (int i = 0; i < 4; i++) begin
            le_word[i*8 +: 8] = msg_q.pop_front();
          end

          data_word = (msg_endian ?
                       {le_word[7:0], le_word[15:8], le_word[23:16], le_word[31:24]} :
                       le_word);
        end

        // Send the requested bus transaction (assuming that we haven't yet seen a reset or an error
        // response)
        //
        // This uses fork/join_none to run in the background and then uses "wait fork" to wait for
        // completion if blocking is asserted (we're running inside another isolation fork, so this
        // will not be affected by any other part of the test).
        if (!saw_reset) begin
          fork
            begin
              uvm_status_e txn_status;
              send_bus_write(fifo_addr, hsize, data_word, txn_status);
              if (cfg.under_reset) saw_reset = 1;
              else if (txn_status != UVM_IS_OK) begin
                `uvm_error(get_full_name(), "Bus transaction failed.")
              end
            end
          join_none
          if (blocking) wait fork;
        end
      end

      // This "wait fork" will do nothing if blocking == 1. If blocking == 0, there may be several
      // transactions in flight. Wait for them here.
      wait fork;
    end join

    if (saw_reset) return;

    // Unless there has been a reset, read out status/intr_state CSRs to check.
    check_state();
  endtask

  // This task burst writes 32-bit chunks of the message into the msgfifo
  virtual task burst_write_msg(input bit [7:0] msg_arr[]);
    bit        saw_reset;
    bit [7:0]  msg_q[$];

    if (msg_endian) dv_utils_pkg::endian_swap_byte_arr(msg_arr);

    msg_q = msg_arr;

    if (uvm_report_enabled(UVM_HIGH, UVM_INFO, get_full_name())) begin
      `uvm_info(get_full_name(),
                $sformatf("msg to be written through burst_write_msg (%0d bytes):", msg_q.size()),
                UVM_HIGH)
      for (int unsigned i = 0; i < msg_q.size() / 8; i++) begin
        `uvm_info(get_full_name(),
                  $sformatf({"msg_q[%0d .. %0d] = ",
                             "[ 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x ]"},
                            8 * i, 8 * i + 7,
                            msg_q[8*i + 0], msg_q[8*i + 1], msg_q[8*i + 2], msg_q[8*i + 3],
                            msg_q[8*i + 4], msg_q[8*i + 5], msg_q[8*i + 6], msg_q[8*i + 7]),
                  UVM_HIGH)
      end
      for (int unsigned ii = 8 * (msg_q.size() / 8); ii < msg_q.size(); ii++) begin
        `uvm_info(get_full_name(), $sformatf("msg_q[%0d] = [ 0x%02x ]", ii, msg_q[ii]), UVM_HIGH)
      end
    end

    // The code below all runs inside an isolation fork, which will allow a "wait fork" to wait for
    // completion if !blocking.
    fork : isolation_fork begin
      while ((msg_q.size() > 0) && !saw_reset) begin
        `uvm_info(`gfn, $sformatf("msg size: %0d", msg_q.size()), UVM_HIGH)

        if (msg_q.size() >= KMAC_FIFO_NUM_BYTES) begin
          repeat (KMAC_FIFO_NUM_WORDS) begin
            bit [31:0] fifo_addr;
            bit [31:0] data_word;

            data_mask = (1 << 4) - 1;
            fifo_addr = pick_fifo_addr(2);

            for (int i = 0; i < 4; i++) begin
              data_word[i*8 +: 8] = msg_q.pop_front();
            end

            // Send the requested bus transaction (assuming that we haven't yet seen a reset or an
            // error response). Use start_bus_write to start the transaction (to guarantee that the
            // writes to msg_fifo happen in the order we expect), then use fork/join_none to allow
            // it to complete asynchronously.
            if (!saw_reset) begin
              ahb_agent_pkg::ahb_transfer_seq seq;

              start_bus_write(fifo_addr, 2, data_word, seq);
              fork begin
                seq.wait_for_sequence_state(UVM_FINISHED);
                if (cfg.under_reset) saw_reset = 1;
                else if (!seq.has_full_transaction()) begin
                  `uvm_fatal(get_full_name(),
                             "Sequence ended without full transaction, but cfg.under_reset = 0.")
                end else begin
                  ahb_txn_response_item last_rsp = seq.m_responses[seq.m_responses.size() - 1];
                  if (last_rsp.m_resp) begin
                    `uvm_error(get_full_name(),
                               {"Final AHB response had m_resp (error response): ",
                                "not expected by this vseq."})
                  end
                end
              end join_none

              // Block (waiting for the transaction to complete) but only some of the time. Note
              // that this might wait for all transactions in the isolation fork, but there's no
              // reason to make it more general: we are already forcing them to run in sequence.
              if ($urandom_range(0, 1)) wait fork;
            end
          end
          // wait for the fifo to be empty before writing more msg
          //
          // spinwait instead of checking the interrupt because it's not guaranteed
          // that the interrupt will remain high after writing the last word,
          // depending on how long the input message is.
          masked_spinwait_bit(ral.kmac_core.STATUS,
                              1,
                              ral.kmac_core.STATUS.fifo_empty.get_lsb_pos());
        end else begin
          // if we reach this case, means that the remaining message
          // is smaller in size than the fifo, so we can just write it normally
          // using `write_msg()`.
          write_msg(msg_q);
          msg_q = '{};
        end

        if (cfg.under_reset) begin
          saw_reset = 1;
          break;
        end
      end

      // This "wait fork" will do nothing if the last item was blocking. If not, there may be one or
      // more transactions in flight. Wait for them here.
      wait fork;
    end join
  endtask

  // This task checks the fifo_empty interrupt (if enabled) and clears it,
  // then waits for STATUS.fifo_full to be 0.
  virtual task wait_fifo_has_capacity();
    bit [2:0]  intr_state_seen;
    bit [31:0] status_data;

    // read out interrupt state and clear any set interrupts (fifo_empty).
    read_and_clear_intr_state(intr_state_seen);
    if (cfg.under_reset) return;

    masked_spinwait_bit(ral.kmac_core.STATUS,
                        0,
                        ral.kmac_core.STATUS.fifo_full.get_lsb_pos());
  endtask

  // Read the INTR_STATE register to check that the given interrupts have triggered
  task check_interrupts_asserted(bit [31:0] exp_mask);
    uvm_status_e   status;
    uvm_reg_data_t reg_value;
    bit [31:0]     missing;

    ral.kmac_core.INTR_STATE.read(status, reg_value);
    if (cfg.under_reset) return;
    if (status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to read INTR_STATE.")

    missing = exp_mask & ~reg_value;

    if (|missing) begin
      `uvm_error(get_full_name(),
                 $sformatf({"Not every expected interrupt was asserted. ",
                            "Bits expected: 0x%0h; Bits seen: 0x%0h; Bits missing: 0x%0h."},
                           exp_mask, reg_value, missing))
    end
  endtask

  // Read the INTR_STATE register to check that the kmac_done interrupt has triggered
  task check_done_interrupt();
    check_interrupts_asserted(1 << ral.kmac_core.INTR_STATE.KMAC_DONE.get_lsb_pos());
  endtask

  // Read the INTR_STATE register and check that its KMAC_DONE field has the expected value.
  //
  // If backdoor is true, this does a backdoor access (and will complete in zero time). If not, this
  // returns early if a reset is asserted.
  task read_and_check_kmac_done(bit exp_value, bit backdoor);
    uvm_status_e   txn_status;
    uvm_reg_data_t reg_value;
    bit            seen_value;

    ral.kmac_core.INTR_STATE.read(txn_status,
                                  reg_value,
                                  backdoor ? UVM_BACKDOOR : UVM_FRONTDOOR);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) begin
      `uvm_error(get_full_name(),
                 $sformatf("Failed to read INTR_STATE (%0sdoor)",
                           backdoor ? "back" : "front"))
    end

    seen_value = (reg_value >> ral.kmac_core.INTR_STATE.KMAC_DONE.get_lsb_pos()) & 1;
    if (seen_value != exp_value) begin
      `uvm_error(get_full_name(),
                 $sformatf({"INTR_STATE.KMAC_DONE doesn't have the expected value. ",
                            "We expected %0d but saw %0d."},
                           exp_value, seen_value))
    end
  endtask

  // This task waits for the kmac_done interrupt to trigger,
  // or waits for ral.kmac_core.INTR_STATE.KMAC_DONE to be high if interrupts are disabled.
  virtual task wait_for_kmac_done();
    uvm_status_e txn_status;

    // Loosen up the `kmac_done` checks slightly to ease timing pressure on the cycle accurate
    // model, instead of spinwaiting, we now do a "before" and "after" CSR read.

    // First do a backdoor read to make sure we don't encounter any race conditions with the
    // design.
    read_and_check_kmac_done(.exp_value(0), .backdoor(1));

    // Wait a long time for hashing to finish, then check that `kmac_done` is set
    cfg.clk_rst_vif.wait_clks_or_rst(150);
    if (cfg.under_reset) return;

    read_and_check_kmac_done(.exp_value(1), .backdoor(0));

    ral.kmac_core.INTR_STATE.set(0);
    ral.kmac_core.INTR_STATE.update(txn_status);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to write to INTR_STATE.")
  endtask

  // This task reads a chunk of data from the STATE window and appends it to the `digest`
  // array byte by byte.
  // This task can read at most `keccak_block_size` bytes from the digest window.
  // The `chunk_size` input is assumed to be greater than 0.
  //
  // The general idea is:
  // - Read 4-byte words from the STATE window
  // - Add each byte to a queue, decrementing the total output_len each time
  virtual task read_digest_chunk(bit [31:0] state_addr, int unsigned chunk_size,
                                 ref bit [7:0] digest[]);
    while (chunk_size > 0) begin
      bit [31:0]   digest_word;
      bit [7:0]    digest_byte;
      uvm_status_e status;

      // Get a random mask for the state window read, keeping it as 4'(1'b1) whenever possible
      `DV_CHECK_MEMBER_RANDOMIZE_WITH_FATAL(data_mask, $countones(data_mask) <= chunk_size;
                                                       data_mask[0] == 1;
                                                       if (chunk_size < 4) {
                                                         soft $countones(data_mask) == chunk_size;
                                                       } else {
                                                         soft $countones(data_mask) == 4;
                                                       })
      `uvm_info(`gfn, $sformatf("state read mask: 0b%0b", data_mask), UVM_HIGH)
      if (state_endian) begin
        data_mask = {<< bit {data_mask}};
        `uvm_info(`gfn, $sformatf("swapped state read mask: 0b%0b", data_mask), UVM_HIGH)
      end

      send_bus_read(state_addr, digest_word, status);
      if (cfg.under_reset) return;
      if (status != UVM_IS_OK) begin
        `uvm_error(get_full_name(), "Read from STATE window failed.")
      end

      `uvm_info(`gfn, $sformatf("digest_word: 0x%0x", digest_word), UVM_HIGH)

      // This section of code is used to return the read digest to the virtual sequence for any
      // checks.
      // This is only actually used for the NIST vector tests.
      if (state_endian) begin
        data_mask = {<< bit {data_mask}};
        digest_word = {<< byte {digest_word}};
      end
      for (int i = 0; i < 4; i++) begin
        if (chunk_size == 0) break;
        if (data_mask[i]) begin
          digest_byte = digest_word[i*8 +: 8];
          digest = {digest, digest_byte};
          chunk_size -= 1;
        end
      end

      state_addr = state_addr + 4;

    end

  endtask

  // This task reads the full `output_len` bytes from the digest window,
  // using the helper task `read_digest_chunk()` to read a block at a time
  // from the digest window.
  // More data is squeezed as necessary.
  //
  // Note: if masking is disabled we read the full 200 bytes from SHARE1,
  //       this is so we can check that it has been zeroed.
  virtual task read_digest_shares(int unsigned full_output_len, bit en_masking,
                                  ref bit [7:0] share0[], ref bit [7:0] share1[]);

    int unsigned remaining_output_len = full_output_len;

    int unsigned cur_chunk_size = 0;

    while (remaining_output_len > 0) begin
      cur_chunk_size = (remaining_output_len <= keccak_block_size) ? remaining_output_len : keccak_block_size;

      read_digest_chunk(KMAC_STATE_SHARE0_BASE, cur_chunk_size, share0);
      read_digest_chunk(KMAC_STATE_SHARE1_BASE, en_masking ? cur_chunk_size : 200, share1);

      `uvm_info(`gfn, $sformatf("read a %0d byte chunk of digest", cur_chunk_size), UVM_HIGH)

      remaining_output_len -= cur_chunk_size;

      if (remaining_output_len > 0) begin
        // send an incorrect SW command, this will be dropped internally,
        // so need to send the correct command afterwards.
        if (kmac_err_type == kmac_pkg::ErrSwCmdSequence &&
            err_sw_cmd_seq_st == sha3_pkg::StSqueeze) begin
          issue_cmd(err_sw_cmd_seq_cmd);
          check_err();
        end

        squeeze_digest();
      end

      `uvm_info(`gfn, $sformatf("remaining_output_len: %0d", remaining_output_len), UVM_HIGH)
    end

  endtask

  // This task checks after a local or global escalation, the KMAC is locked and cannot process any
  // more kmac SW operation.
  virtual task kmac_sw_lock_check();
    kmac_pkg::kmac_cmd_e rand_cmd;
    bit [7:0] share[];
    `DV_CHECK_STD_RANDOMIZE_FATAL(rand_cmd)
    `DV_CHECK_STD_RANDOMIZE_WITH_FATAL(msg, msg.size() inside {[1:100]};)

    kmac_init(0);
    set_prefix();
    write_key_shares();
    issue_cmd(rand_cmd);
    write_msg(msg, .wait_for_fifo_has_capacity(0));
    read_digest_chunk(KMAC_STATE_SHARE0_BASE, keccak_block_size, share);
    foreach (share[i]) `DV_CHECK_EQ_FATAL(share[i], '0)
    read_digest_chunk(KMAC_STATE_SHARE1_BASE, keccak_block_size, share);
    foreach (share[i]) `DV_CHECK_EQ_FATAL(share[i], '0)
  endtask

  // overriding timeout on outstanding accesses for the kmac_stress_test_all_with_rand_reset test
  virtual function int wait_cycles_with_no_outstanding_accesses();
    return 100_000;
  endfunction
endclass
