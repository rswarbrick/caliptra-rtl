// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class sha3_ctrl_scoreboard extends dv_base_scoreboard #(
    .CFG_T(sha3_ctrl_env_cfg),
    .RAL_T(sha3_ctrl_dv_reg),
    .COV_T(sha3_ctrl_env_cov)
  );
  `uvm_component_utils(sha3_ctrl_scoreboard)

  // local variables

  bit do_check_digest = 1;

  // used solely for coverage sampling, indicates that keccak rounds are currently running
  bit in_keccak_rounds = 0;

  // Whenever the keccak rounds are running, the `complete` signal is raised at the end
  // for a single cycle to signal to sha3 control logic that the keccak engine is completed.
  //
  // There are some edge cases that may occur if a CmdProcess or a `kmac_app_last`is seen on this
  // "complete" cycle that need to be handled - this bit will be raised and lowered in conjunction
  // with the internal `complete` signal to allow the scb easier handling of these scenarios.
  bit keccak_complete_cycle = 0;

  // this bit goes high for a cycle when a manual squeezing is requested
  bit req_manual_squeeze = 0;

  // The CFG.entropy_ready field is only used to transition the entropy FSM into fetching entropy
  // from the reset state, so we can only rely on writes to CFG.entropy_ready to update internal
  // scoreboard state after a reset is seen.
  //
  // To that effect, we set this bit to 1 any time the scoreboard is reset, and will unset it
  // the first time that CFG.entropy_ready is updated.
  bit first_op_after_rst = 0;

  // CFG fields
  bit kmac_en;
  sha3_pkg::sha3_mode_e hash_mode;
  sha3_pkg::keccak_strength_e strength;
  entropy_mode_e entropy_mode = EntropyModeNone;
  bit entropy_fast_process;
  bit entropy_ready;

  // Set this bit when entropy_ready is 1 and entropy_mode is EntropyModeEdn,
  // to indicate that we are now waiting on the EDN to return valid entropy
  bit in_edn_fetch = 0;

  // CMD fields
  bit [KmacCmdIdx:0] kmac_cmd;
  kmac_cmd_e unchecked_kmac_cmd = CmdNone;
  kmac_cmd_e checked_kmac_cmd = CmdNone;

  bit msg_digest_done;

  // SHA3 status bits
  bit sha3_idle;
  bit sha3_absorb;
  bit sha3_squeeze;

  // FIFO status bits
  bit cmd_process_triggered;
  bit msgfifo_access;
  bit fifo_empty_status;
  bit fifo_full_status;
  bit fifo_full_detected;
  bit intr_fifo_empty_allowed;

  bit intr_kmac_done;
  bit intr_fifo_empty;
  bit pre_intr_fifo_empty;
  bit intr_kmac_err;

  // Error tracking
  kmac_pkg::err_t kmac_err = '{valid: 1'b0,
                               code: kmac_pkg::ErrNone,
                               info: '0};
  sha3_pkg::err_t sha3_err = '{valid: 1'b0,
                               code: sha3_pkg::ErrNone,
                               info: '0};
  // Need to track the FSM in `kmac_app` and the mux select value,
  // these are used in App-related error reporting
  kmac_app_st_e   app_st = StIdle;
  bit             app_fsm_active = 0;
  app_mux_sel_e   app_mux_sel = SelNone;

  // key length enum
  key_len_e key_len;

  // secret keys
  //
  // max key size is 512-bits
  bit [KMAC_NUM_SHARES-1:0][KMAC_NUM_KEYS_PER_SHARE-1:0][31:0] keys;

  // prefix words
  bit [31:0] prefix[KMAC_NUM_PREFIX_WORDS];

  // input message
  bit [7:0] msg[$];

  // input message from keymgr
  byte kmac_app_msg[$];

  // output digest from static KMAC_APP interfaces
  bit [kmac_pkg::AppDigestW-1:0] kmac_app_digest_share0;
  bit [kmac_pkg::AppDigestW-1:0] kmac_app_digest_share1;

  // output digests
  bit [7:0] digest_share0[];
  bit [7:0] digest_share1[];

  // This mask is used to mask reads from the state windows.
  // We need to make this a class variable as we set the mask value
  // during the address read phase, but then need its value to persist
  // through the data read phase.
  bit [3:0] state_mask;

  // This mask is used to avoid building a cycle accurate scoreboard to check kmac message fifo.
  // This SCB will only check that when KmacStatusFifoFull is set, the FIFO depth should be full
  // depth; when KmacStatusFifoEmpty is set, the FIFO depth should be 0. If none of them are set,
  // the Fifo depth should be between 0 and the max value.
  // The actually FIFO depth is covered in direct sequence.
  bit [31:0] status_mask = (1'b1 << KmacStatusFifoFull) |
                            (1'b1 << KmacStatusFifoEmpty) |
                            ({KMAC_FIFO_DEPTH{1'b1}} << KmacStatusFifoDepthLSB);

  `uvm_component_new

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    if (cfg.en_scb) begin
      fork
        process_checked_kmac_cmd();
        manage_fifo_empty_intr();
      join_none
    end
  endtask

  // This task spins forever and assigns `checked_kmac_cmd` to `unchecked_kmac_cmd`
  // with a 1 cycle delay.
  virtual task process_checked_kmac_cmd();
    @(negedge cfg.under_reset);
    forever begin
      wait(!cfg.under_reset);
      `DV_SPINWAIT_EXIT(
          @(unchecked_kmac_cmd);
          `uvm_info(`gfn, "BEFORE LATCHING KMAC_CMD", UVM_HIGH)
          `uvm_info(`gfn, $sformatf("unchecked_kmac_cmd: %0s", unchecked_kmac_cmd.name()), UVM_HIGH)
          `uvm_info(`gfn, $sformatf("checked_kmac_cmd: %0s", checked_kmac_cmd.name()), UVM_HIGH)
          cfg.clk_rst_vif.wait_clks(1);
          checked_kmac_cmd = unchecked_kmac_cmd;
          `uvm_info(`gfn, "AFTER LATCHING KMAC_CMD", UVM_HIGH)
          `uvm_info(`gfn, $sformatf("unchecked_kmac_cmd: %0s", unchecked_kmac_cmd.name()), UVM_HIGH)
          `uvm_info(`gfn, $sformatf("checked_kmac_cmd: %0s", checked_kmac_cmd.name()), UVM_HIGH)

          if (checked_kmac_cmd == CmdStart) begin
            sha3_idle = 0;
            sha3_absorb = 1;
            `uvm_info(`gfn, "raised sha3_absorb and dropped sha3_idle when issued start cmd",
                      UVM_HIGH)
          end
          if (checked_kmac_cmd == CmdDone) sha3_idle = 1;
          // If CmdDone is written, we know that a hash has completed.
          // So, we can set this to CmdNone one cycle later.
          cfg.clk_rst_vif.wait_clks(1);
          if (checked_kmac_cmd == CmdDone) begin
            checked_kmac_cmd = CmdNone;
          end
          ,
          wait(cfg.under_reset);
      )
    end
  endtask

  // Triggers the predict_fifo_empty_intr task only when necessary: on particular events or at each
  // clock cycles on particular occasions when signals need to be updated as accurately as possible
  virtual task manage_fifo_empty_intr();
    cmd_process_triggered = 0;

    @(negedge cfg.under_reset);
    forever begin
      wait(!cfg.under_reset);
      fork begin
        fork
          begin
            // Trigger the task only when required to avoid to overload the simulation
            forever @(msgfifo_access, sha3_absorb, kmac_cmd, sha3_idle) begin
              // Loop also on each clock cycle when intr_fifo_empty_allowed or when msgfifo_access
              // are high to avoid missing some FIFO status changes
              do begin
                // Do checks on the falling edge of the clock to ensure the DUT internal signals
                // will be up to date
                cfg.clk_rst_vif.wait_n_clks(1);
                fork begin
                  predict_fifo_empty_intr();
                end join_none
                // Ensure that intr_fifo_empty_allowed has been updated
                cfg.clk_rst_vif.wait_clks(1);
              end while (intr_fifo_empty_allowed || msgfifo_access);
            end
          end
          begin
            wait(cfg.under_reset);
          end
        join_any
        disable fork;
      end join
    end
  endtask : manage_fifo_empty_intr

  // Do a backdoor read of the STATUS register and use the result set set the fifo_empty and
  // fifo_full output arguments.
  task backdoor_read_fifo_status(output bit fifo_empty, output bit fifo_full);
    uvm_status_e   txn_status;
    uvm_reg_data_t reg_value;

    ral.kmac_core.STATUS.read(txn_status, reg_value, .path(UVM_BACKDOOR));
    if (txn_status != UVM_IS_OK) begin
      `uvm_error(get_full_name(), "Failed to backdoor-read STATUS register.")
    end

    fifo_empty = (reg_value >> ral.kmac_core.STATUS.fifo_empty.get_lsb_pos()) & 1;
    fifo_full  = (reg_value >> ral.kmac_core.STATUS.fifo_full.get_lsb_pos()) & 1;
  endtask

  // Reads FIFO empty/full status from the DUT registers to know the current level of the FIFOs as
  // it has been decided to not predict this here.
  // Then, it could be decided whether the FIFO empty interrupt could be raised. This should only be
  // the case when the FIFO is actually empty, but also if all of the following conditions are met:
  //   1- The KMAC block is not exercised by a hardware application interface.
  //   2- The SHA3 block is in the Absorb state.
  //   3- Software has not yet written the Process command to finish the absorption process.
  //   4- The message FIFO must also have been full previously. Otherwise, the hardware empties
  //      the FIFO faster than software can fill it and there is no point in interrupting the
  //      software to inform it about the message FIFO being empty.
  virtual task predict_fifo_empty_intr();
    uvm_status_e   txn_status;
    uvm_reg_data_t intr_state_rdata;

    bit fifo_empty_status_neg;
    bit fifo_empty_status_last = fifo_empty_status;

    // Get FIFO empty/full status directly from the DUT as the FIFO level is not modeled
    backdoor_read_fifo_status(fifo_empty_status, fifo_full_status);

    // Detect when FIFO is not empty anymore
    fifo_empty_status_neg = ~fifo_empty_status & fifo_empty_status_last;

    // Latch Command Process flag
    if (!cmd_process_triggered && (kmac_cmd == CmdProcess)) begin
      cmd_process_triggered = 1;
    end else if (sha3_idle) begin
      cmd_process_triggered = 0;
    end

    // Check whether FIFO full has been detected for the ongoing message
    // This flag is raised when the FIFO full status is high and it's cleared when empty is
    // reached or when the current message is done (idle)
    if (fifo_full_status) begin
      fifo_full_detected = 1;
    end else if (sha3_idle || fifo_empty_status_neg) begin
      fifo_full_detected = 0;
    end

    // Check if FIFO empty interrupt conditions are met
    if (sha3_absorb && !cmd_process_triggered && fifo_full_detected) begin
      intr_fifo_empty_allowed = 1;
    end else begin
      intr_fifo_empty_allowed = 0;
    end

    if (intr_fifo_empty_allowed && fifo_empty_status) begin
      pre_intr_fifo_empty = 1;
    end else begin
      pre_intr_fifo_empty = 0;
    end

    // Delay FIFO empty signal to be aligned with the DUT behavior
    fork
      begin
        cfg.clk_rst_vif.wait_clks(1);
        intr_fifo_empty = pre_intr_fifo_empty;
      end
    join_none

    // Wait needed to avoid race condition for register access
    wait(!ral.kmac_core.INTR_STATE.is_busy());

    // Update expected value
    if (!ral.kmac_core.INTR_STATE.FIFO_EMPTY.predict(.value(intr_fifo_empty),
                                                     .kind(UVM_PREDICT_DIRECT))) begin
      `uvm_error(get_full_name(), "Failed to predict FIFO_EMPTY field of INTR_STATE.")
    end

    ral.kmac_core.INTR_STATE.read(txn_status, intr_state_rdata, .path(UVM_BACKDOOR));
    if (txn_status != UVM_IS_OK) begin
      `uvm_error(get_full_name(), "Failed to backdoor-read INTR_STATE register.")
    end

    if (intr_state_rdata != ral.kmac_core.INTR_STATE.get_mirrored_value()) begin
      `uvm_error(get_full_name(),
                 $sformatf("Predicted value for INTR_STATE was 0x%0h but RTL holds 0x%0h",
                           ral.kmac_core.INTR_STATE.get_mirrored_value(),
                           intr_state_rdata))
    end
  endtask : predict_fifo_empty_intr


  virtual function void predict_err(bit is_sha3_err = 0, bit is_kmac_err = 0);
    // set interrupt
    if (!intr_kmac_err) intr_kmac_err = 1;
    `uvm_info(`gfn, "raised intr_kmac_err", UVM_HIGH)
    if (is_sha3_err) `uvm_info(`gfn, $sformatf("sha3_err: %0p", sha3_err), UVM_HIGH)
    if (is_kmac_err) `uvm_info(`gfn, $sformatf("kmac_err: %0p", kmac_err), UVM_HIGH)

    // predict error CSR
    if (is_sha3_err) begin
      `DV_CHECK(ral.kmac_core.ERR_CODE.predict(.value(sha3_err), .kind(UVM_PREDICT_DIRECT)));
    end else if (is_kmac_err) begin
      `DV_CHECK(ral.kmac_core.ERR_CODE.predict(.value(kmac_err), .kind(UVM_PREDICT_DIRECT)));
    end

    // collect coverage
    if (cfg.en_cov) begin
      cov.error_cg.sample(kmac_err.code, unchecked_kmac_cmd, hash_mode, strength);
    end

    kmac_err = '{valid: 1'b0,
                 code: kmac_pkg::ErrNone,
                 info: '0};
    sha3_err = '{valid: 1'b0,
                 code: sha3_pkg::ErrNone,
                 info: '0};
  endfunction

  virtual function void reset(string kind = "HARD");
    super.reset(kind);

    clear_state();

    checked_kmac_cmd   = CmdNone;
    unchecked_kmac_cmd = CmdNone;

    first_op_after_rst = 1;

    // status tracking bits
    sha3_idle         = ral.kmac_core.STATUS.sha3_idle.get_reset();
    sha3_absorb       = ral.kmac_core.STATUS.sha3_absorb.get_reset();
    sha3_squeeze      = ral.kmac_core.STATUS.sha3_squeeze.get_reset();
    fifo_empty_status = ral.kmac_core.STATUS.fifo_empty.get_reset();
    fifo_full_status  = ral.kmac_core.STATUS.fifo_full.get_reset();
    intr_fifo_empty   = ral.kmac_core.INTR_STATE.FIFO_EMPTY.get_reset();
  endfunction

  // This function should be called to reset internal state to prepare for a new hash operation
  virtual function void clear_state();
    `uvm_info(`gfn, "clearing scoreboard state", UVM_HIGH)

    if (first_op_after_rst) first_op_after_rst = 0;

    do_check_digest = 1;

    msg.delete();
    kmac_app_msg.delete();

    req_manual_squeeze      = 0;
    msg_digest_done         = 0;

    set_entropy_fetch(0);

    kmac_err = '{valid: 1'b0,
                 code: kmac_pkg::ErrNone,
                 info: '0};
    sha3_err = '{valid: 1'b0,
                 code: sha3_pkg::ErrNone,
                 info: '0};

    app_st = StIdle;

    keys          = '0;
    prefix        = '{default:0};
    digest_share0 = {};
    digest_share1 = {};

    kmac_app_digest_share0 = '0;
    kmac_app_digest_share1 = '0;
  endfunction

  // This function is called whenever a CmdDone command is issued to KMAC,
  // and will compare the seen digest against the digest calculated from the DPI model.
  //
  // Though we don't have direct access to the specified output length for XOF functions,
  // the last byte written to the msgfifo (only for XOFs) will be the number of preceding bytes
  // that encode the requested output length.
  // From this we can decode what the initially requested output length is.
  //
  // We also need to decode what the prefix is (only for KMAC), as only the encoded values
  // are written to the CSRs.  virtual function void check_digest();
  virtual function void check_digest();

    // Cast to an array so we can pass this into the DPI functions
    bit [7:0] msg_arr[];

    // Determines which kmac variant to use
    bit xof_en;

    // Set this to the calculated output length for XOFs
    int output_len_bytes;

    // Array to hold the digest read from the state windows
    bit [7:0] unmasked_digest[];

    // Array to hold the expected digest calculated by DPI model
    bit [7:0] dpi_digest[];

    // Function name and customization strings for KMAC operations
    string fname;
    string custom_str;

    // Use this to store the correct set of keys (SW-provided or sideloaded)
    bit [KMAC_NUM_SHARES-1:0][KMAC_NUM_KEYS_PER_SHARE-1:0][31:0] exp_keys;

    // The actual key used for KMAC operations
    bit [31:0] unmasked_key[$];

    // key byte-stream for the DPI model
    bit [7:0] dpi_key_arr[];

    // Intermediate array for streaming `unmasked_key` into `dpi_key_arr`
    bit [7:0] unmasked_key_bytes[];

    int key_word_len, key_byte_len;

    // Actual hash_mode based on interface or SW register
    sha3_pkg::sha3_mode_e actual_hash_mode = hash_mode;

    if (cfg.en_scb == 0) return;

    key_word_len = get_key_size_words(key_len);
    key_byte_len = get_key_size_bytes(key_len);

    `uvm_info(`gfn, $sformatf("key_word_len: %0d", key_word_len), UVM_HIGH)
    `uvm_info(`gfn, $sformatf("key_byte_len: %0d", key_byte_len), UVM_HIGH)

    // Calculate:
    // - the expected output length in bytes
    // - if we are using the xof version of kmac
    get_digest_len_and_xof(output_len_bytes, xof_en, msg);

    // quick check that the calculated output length is the same
    // as the number of bytes read from the digest window
    `DV_CHECK_EQ_FATAL(digest_share0.size(), output_len_bytes,
        $sformatf("Calculated output length(%0d) doesn't match actual output length(%0d)!",
                  output_len_bytes, digest_share0.size()))

    if (cfg.en_cov) begin
      // sample configuration coverage, as only now do we know which KMAC variant is used
      // (xof/non-xof)
      cov.sample_cfg(kmac_en, xof_en, strength, actual_hash_mode, key_len,
                     `gmv(ral.kmac_core.CFG_SHADOWED.msg_endianness),
                     `gmv(ral.kmac_core.CFG_SHADOWED.state_endianness),
                     entropy_mode, entropy_fast_process);

      // sample coverage on the digest length
      if (cfg.en_cov) begin
        cov.output_digest_len_cg.sample(output_len_bytes);
      end
    end


    `uvm_info(`gfn, $sformatf("output_len_bytes: %0d", output_len_bytes), UVM_HIGH)
    `uvm_info(`gfn, $sformatf("xof_en: %0d", xof_en), UVM_HIGH)

    // initialize arrays
    dpi_digest = new[output_len_bytes];
    unmasked_digest = new[output_len_bytes];

    /////////////////////////////////
    // Calculate the actual digest //
    /////////////////////////////////
    if (cfg.enable_masking) begin
      foreach (unmasked_digest[i]) begin
        unmasked_digest[i] = digest_share0[i] ^ digest_share1[i];
      end
    end else begin
      unmasked_digest = digest_share0;
    end
    `uvm_info(`gfn, $sformatf("unmasked_digest: %0p", unmasked_digest), UVM_HIGH)

    ///////////////////////////////////////////////////////////
    // Calculate the expected digest using the DPI-C++ model //
    ///////////////////////////////////////////////////////////
    msg_arr = msg;

    if (uvm_report_enabled(UVM_HIGH, UVM_INFO, "msg_arr")) begin
      `uvm_info("msg_arr",
                $sformatf("Message being passed to model over DPI (%0d bytes):", msg_arr.size()),
                UVM_HIGH)
      for (int unsigned i = 0; i < msg_arr.size() / 8; i++) begin
        `uvm_info("msg_arr",
                  $sformatf({"msg_arr[%0d .. %0d] = ",
                             "[ 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x ]"},
                            8 * i, 8 * i + 7,
                            msg_arr[8*i + 0], msg_arr[8*i + 1], msg_arr[8*i + 2], msg_arr[8*i + 3],
                            msg_arr[8*i + 4], msg_arr[8*i + 5], msg_arr[8*i + 6], msg_arr[8*i + 7]),
                  UVM_HIGH)
      end
      for (int unsigned ii = 8 * (msg_arr.size() / 8); ii < msg_arr.size(); ii++) begin
        `uvm_info("msg_arr",
                  $sformatf("msg_arr[%0d] = [ 0x%02x ]", ii, msg_arr[ii]),
                  UVM_HIGH)
      end
    end

    case (actual_hash_mode)
      ///////////
      // SHA-3 //
      ///////////
      sha3_pkg::Sha3: begin
        case (strength)
          sha3_pkg::L224: begin
            digestpp_dpi_pkg::c_dpi_sha3_224(msg_arr, msg_arr.size(), dpi_digest);
          end
          sha3_pkg::L256: begin
            digestpp_dpi_pkg::c_dpi_sha3_256(msg_arr, msg_arr.size(), dpi_digest);
          end
          sha3_pkg::L384: begin
            digestpp_dpi_pkg::c_dpi_sha3_384(msg_arr, msg_arr.size(), dpi_digest);
          end
          sha3_pkg::L512: begin
            digestpp_dpi_pkg::c_dpi_sha3_512(msg_arr, msg_arr.size(), dpi_digest);
          end
          default: begin
            `uvm_fatal(`gfn, $sformatf("strength[%0s] is not allowed for sha3", strength.name()))
          end
        endcase
      end
      ///////////
      // SHAKE //
      ///////////
      sha3_pkg::Shake: begin
        case (strength)
          sha3_pkg::L128: begin
            digestpp_dpi_pkg::c_dpi_shake128(msg_arr, msg_arr.size(), output_len_bytes, dpi_digest);
          end
          sha3_pkg::L256: begin
            digestpp_dpi_pkg::c_dpi_shake256(msg_arr, msg_arr.size(), output_len_bytes, dpi_digest);
          end
          default: begin
            `uvm_fatal(`gfn, $sformatf("strength[%0s] is not allowed for shake", strength.name()))
          end
        endcase
      end
      ////////////
      // CSHAKE //
      ////////////
      sha3_pkg::CShake: begin
        // Get the fname and custom_str string values from the writes to PREFIX csrs
        get_fname_and_custom_str(fname, custom_str);

        if (kmac_en) begin
          // Calculate the unmasked key
          exp_keys = keys;
          for (int i = 0; i < key_word_len; i++) begin
            if (cfg.enable_masking || cfg.sw_key_masked) begin
              unmasked_key.push_back(exp_keys[0][i] ^ exp_keys[1][i]);
            end else begin
              unmasked_key.push_back(exp_keys[0][i]);
            end
            `uvm_info(`gfn, $sformatf("unmasked_key[%0d] = 0x%0x", i, unmasked_key[i]), UVM_HIGH)
          end

          // Convert the key array into a byte array for the DPI model
          unmasked_key_bytes = {<< 32 {unmasked_key}};
          dpi_key_arr = {<< byte {unmasked_key_bytes}};
          `uvm_info(`gfn, $sformatf("dpi_key_arr.size(): %0d", dpi_key_arr.size()), UVM_HIGH)
          `uvm_info(`gfn, $sformatf("dpi_key_arr: %0p", dpi_key_arr), UVM_HIGH)

          case (strength)
            sha3_pkg::L128: begin
              if (xof_en) begin
                digestpp_dpi_pkg::c_dpi_kmac128_xof(msg_arr, msg_arr.size(),
                                                    dpi_key_arr, dpi_key_arr.size(),
                                                    custom_str,
                                                    output_len_bytes, dpi_digest);
              end else begin
                digestpp_dpi_pkg::c_dpi_kmac128(msg_arr, msg_arr.size(),
                                                dpi_key_arr, dpi_key_arr.size(),
                                                custom_str,
                                                output_len_bytes, dpi_digest);
              end
            end
            sha3_pkg::L256: begin
              if (xof_en) begin
                digestpp_dpi_pkg::c_dpi_kmac256_xof(msg_arr, msg_arr.size(),
                                                    dpi_key_arr, dpi_key_arr.size(),
                                                    custom_str,
                                                    output_len_bytes, dpi_digest);
              end else begin
                digestpp_dpi_pkg::c_dpi_kmac256(msg_arr, msg_arr.size(),
                                                dpi_key_arr, dpi_key_arr.size(),
                                                custom_str,
                                                output_len_bytes, dpi_digest);
              end
            end
            default: begin
              `uvm_fatal(`gfn, $sformatf("strength[%0s] is not allowed for kmac", strength.name()))
            end
          endcase
        end else begin
          // regular cshake - used for otp_ctrl/rom_ctrl application interfaces
          case (strength)
            sha3_pkg::L128: begin
              digestpp_dpi_pkg::c_dpi_cshake128(msg_arr, fname, custom_str, msg_arr.size(),
                                                output_len_bytes, dpi_digest);
            end
            sha3_pkg::L256: begin
              digestpp_dpi_pkg::c_dpi_cshake256(msg_arr, fname, custom_str, msg_arr.size(),
                                                output_len_bytes, dpi_digest);
            end
            default: begin
              `uvm_fatal(`gfn, $sformatf("strength[%0s] is not allowed for cshake", strength.name()))
            end
          endcase
        end
      end
    endcase

    if (uvm_report_enabled(UVM_HIGH, UVM_INFO, "dpi_digest")) begin
      `uvm_info("dpi_digest",
                $sformatf("Digest calculated over DPI (%0d bytes):", output_len_bytes),
                UVM_HIGH)
      for (int unsigned i = 0; i < output_len_bytes / 8; i++) begin
        `uvm_info("dpi_digest",
                  $sformatf({"dpi_digest[%0d .. %0d] = ",
                             "[ 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x ]"},
                            8 * i, 8 * i + 7,
                            dpi_digest[8*i + 0], dpi_digest[8*i + 1],
                            dpi_digest[8*i + 2], dpi_digest[8*i + 3],
                            dpi_digest[8*i + 4], dpi_digest[8*i + 5],
                            dpi_digest[8*i + 6], dpi_digest[8*i + 7]),
                  UVM_HIGH)
      end
      for (int unsigned ii = 8 * (output_len_bytes / 8); ii < output_len_bytes; ii++) begin
        `uvm_info("dpi_digest",
                  $sformatf("dpi_digest[%0d] = [ 0x%02x ]", ii, dpi_digest[ii]),
                  UVM_HIGH)
      end
    end

    /////////////////////////////////////////
    // Compare actual and expected digests //
    /////////////////////////////////////////
    for (int i = 0; i < output_len_bytes; i++) begin
      `DV_CHECK_EQ_FATAL(unmasked_digest[i], dpi_digest[i],
          $sformatf("Mismatch between unmasked_digest[%0d] and dpi_digest[%0d]", i, i))
    end

  endfunction

  // This function is used to calculate the requested digest length
  virtual function void get_digest_len_and_xof(ref int output_len, ref bit xof_en,
                                               ref bit [7:0] msg[$]);
    xof_en = 0;
    case (hash_mode)
      // For SHA3 hashes, the output length is the same as the security strength.
      sha3_pkg::Sha3: begin
        case (strength)
          sha3_pkg::L224: begin
            output_len = 224 / 8; // 28
          end
          sha3_pkg::L256: begin
            output_len = 256 / 8; // 32
          end
          sha3_pkg::L384: begin
            output_len = 384 / 8; // 48
          end
          sha3_pkg::L512: begin
            output_len = 512 / 8; // 64
          end
          default: begin
            `uvm_fatal(`gfn, $sformatf("strength[%0s] is not allowed for sha3", strength.name()))
          end
        endcase
      end
      // For Shake hashes, the output length isn't encoded anywhere,
      // so we just return the length of the state digest array.
      sha3_pkg::Shake: begin
        output_len = digest_share0.size();
      end
      // CShake is where things get more interesting.
      // We need to essentially decode the encoded output length that is
      // written to the msgfifo as a post-fix to the actual message.
      sha3_pkg::CShake: begin
        bit [MAX_ENCODE_WIDTH-1:0] full_len = '0;
        // the very last byte written to msgfifo is the number of bytes that
        // when put together represent the encoded output length.
        bit [7:0] num_encoded_byte = msg.pop_back();

        for (int i = 0; i < num_encoded_byte; i++) begin
          full_len[i*8 +: 8] = msg.pop_back();
        end

        // We should set xof_en if `right_encode(0)` was written to the msgfifo after the message.
        // right_encode(0) = '{'h0, 'h1}
        if (num_encoded_byte == 1 && full_len == 0) begin
          xof_en = 1;
          // can't set  the output length to 0, so we fall back to the Shake behavior here
          output_len = digest_share0.size();
        end else begin
          output_len = full_len / 8;
        end
      end
    endcase
  endfunction

  // This function is used to calculate the fname and custom_str string values
  // from the data written to the PREFIX csrs
  //
  // Strings are encoded as:
  //  `encode_string(S) = left_encode(len(S)) || S`
  virtual function void get_fname_and_custom_str(ref string fname,
                                                 ref string custom_str);
    bit [7:0] prefix_bytes[$];
    // The very first byte of each encoded string represents the number of bytes
    // that make up the encoded string's length.
    bit [7:0] num_enc_bytes_of_str_len;

    bit [16:0] str_len;

    byte fname_arr[];
    byte custom_str_arr[];

    prefix_bytes = {<< 32 {prefix}};
    prefix_bytes = {<< byte {prefix_bytes}};

    // sample coverage
    if (cfg.en_cov) begin
      foreach (prefix_bytes[i]) begin
        cov.prefix_range_cg.sample(byte'(prefix_bytes[i]));
      end
    end

    `uvm_info(`gfn, $sformatf("prefix: %0p", prefix), UVM_HIGH)
    `uvm_info(`gfn, $sformatf("prefix_bytes: %0p", prefix_bytes), UVM_HIGH)

    // fname comes first in the PREFIX registers

    // This value should be 1
    num_enc_bytes_of_str_len = prefix_bytes.pop_front();
    `DV_CHECK_EQ(num_enc_bytes_of_str_len, 1,
        $sformatf("Only one byte should be used to encode len(fname)"))

    // The string length is always in terms of bits, need to convert to byte length
    str_len = prefix_bytes.pop_front() / 8;

    fname_arr  = new[str_len];
    for (int i = 0; i < str_len; i++) begin
      fname_arr[i] = byte'(prefix_bytes.pop_front());
    end

    // custom_str is next

    num_enc_bytes_of_str_len = prefix_bytes.pop_front();

    // convert string length to length in bytes
    for (int i = 0; i < num_enc_bytes_of_str_len; i++) begin
      str_len[(num_enc_bytes_of_str_len  - i - 1)*8 +: 8] = prefix_bytes.pop_front();
    end
    str_len /= 8;

    custom_str_arr = new[str_len];
    for (int i = 0; i < str_len; i++) begin
      custom_str_arr[i] = byte'(prefix_bytes.pop_front());
    end

    // Convert the byte arrays into strings
    fname = str_utils_pkg::bytes_to_str(fname_arr);
    custom_str = str_utils_pkg::bytes_to_str(custom_str_arr);

    `uvm_info(`gfn, $sformatf("decoded fname: %0s", fname), UVM_HIGH)
    `uvm_info(`gfn, $sformatf("decoded custom_str: %0s", custom_str), UVM_HIGH)
  endfunction

  // Return `info` field for ErrSwCmdSequence with the current kmac_cmd as input.
  // This scb do not predict kmac internal state, so the FSM state information is all 0 and will be
  // masked out during read check.
  function kmac_sw_cmd_seq_err_info_t get_kmac_sw_cmd_seq_err_info(bit [KmacCmdIdx:0] kmac_cmd);
    kmac_sw_cmd_seq_err_info_t err_info;
    err_info.sw_cmd = kmac_cmd;
    err_info.sw_err = 1;
    return err_info;
  endfunction

  function void set_entropy_fetch(bit val);
    if (val) begin
      if (entropy_mode == EntropyModeEdn) in_edn_fetch = cfg.enable_masking;
    end else begin
      in_edn_fetch = 0;
      `uvm_info(`gfn, "dropped in_edn_fetch", UVM_HIGH)
    end
  endfunction
endclass
