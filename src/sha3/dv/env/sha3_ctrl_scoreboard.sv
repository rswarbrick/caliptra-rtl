// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class sha3_ctrl_scoreboard extends dv_base_scoreboard #(
    .CFG_T(sha3_ctrl_env_cfg),
    .RAL_T(sha3_ctrl_dv_reg),
    .COV_T(sha3_ctrl_env_cov)
  );
  `uvm_component_utils(sha3_ctrl_scoreboard)

  // An import for AHB requests. There will be one for each AHB transaction. It appears at the start
  // of a transaction. Together with m_ahb_txn_imp, this lets us see the "period where the
  // transaction is in flight".
  uvm_analysis_imp_ahb_req #(ahb_txn_request_item, sha3_ctrl_scoreboard) m_ahb_req_imp;

  // An import for AHB transactions. Some will be handled by the register predictor, but this
  // explicit import is needed as well, to allow us to track access to the STATE memory and
  // MSG_FIFO.
  uvm_analysis_imp_ahb_txn #(ahb_txn_item, sha3_ctrl_scoreboard) m_ahb_txn_imp;

  // A counter of the number of requests that have been seen in m_ahb_req_imp since the last reset
  local int unsigned m_ahb_req_counter;

  // A counter of the number of transactions that have been seen in m_ahb_txn_imp since the last
  // reset. This will always be <= m_req_counter.
  local int unsigned m_ahb_txn_counter;

  // A callback that is installed on the CFG_SHADOWED register and has an event that triggers
  // whenever a prediction changes the value of some field in the register.
  //
  // Note that there are several fields in the register, so a register write may trigger the event
  // several times. This may or may not cause calls to wait_trigger() to finish multiple times: it
  // depends on the scheduling in the EDA tool.
  local dv_base_fld_change_cb cfg_change_cb;

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

  // SHA3 status bits
  bit sha3_idle;
  bit sha3_absorb;
  bit sha3_squeeze;

  // FIFO status bits
  bit cmd_process_triggered;
  bit fifo_empty_status;
  bit fifo_full_status;
  bit fifo_full_detected;
  bit intr_fifo_empty_allowed;

  // A flag that shows a transaction is writing to MSG_FIFO. This is set in write_ahb_req when it
  // sees a request to write in the fifo. At the same time, we set msgfifo_txn_idx. When there is a
  // write to m_ahb_txn_imp with m_ahb_txn_counter equal to msgfifo_txn_idx, we will clear the flag
  // again.
  local bit msgfifo_access;

  // The value of m_ahb_req_counter when we last saw a request to write MSG_FIFO, setting
  // msgfifo_access. The flag should be cleared again once m_ahb_txn_counter gets incremented past
  // this number.
  local int unsigned msgfifo_txn_idx;

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

  // prefix words
  bit [31:0] prefix[KMAC_NUM_PREFIX_WORDS];

  // input message
  bit [7:0] msg[$];

  // input message from keymgr
  byte kmac_app_msg[$];

  // The Keccak state has a single share, which is 1600 bits (200 bytes) in size.
  localparam BytesInObservedState = 200;

  // The digest can be found by reading from the STATE window.
  //
  // The observed_state_t represents the information that we have seen from reading the Keccak state
  // since the last time there was a PROCESS or RUN command.
  //
  // The offsets in this window all treat the state as having been reported in little-endian form:
  // the scoreboard will record the bytes of each 32-bit word in reverse order if it sees a read
  // from the STATE window when state_endianness is true (so the state is reported by the RTL in
  // big-endian order).
  typedef struct {
    bit [BytesInObservedState-1:0] valid;
    bit [7:0]                      seen [BytesInObservedState];
  } observed_state_t;

  // The current observed state. This will be discarded when starting a new computation (CmdStart)
  // and will be appended to m_observed_states when there is a squeeze operation (CmdRun) then
  // cleared to hold observations of the new state.
  observed_state_t m_cur_state;

  // A queue of observed states. These states (together with the current state from m_cur_state) are
  // used by check_digest, which compares their observed values with a C++ model over DPI.
  //
  // The queue is cleared when starting a new operation (CmdStart).
  observed_state_t m_observed_states[$];

  // This mask is used to avoid building a cycle accurate scoreboard to check kmac message fifo.
  // This SCB will only check that when KmacStatusFifoFull is set, the FIFO depth should be full
  // depth; when KmacStatusFifoEmpty is set, the FIFO depth should be 0. If none of them are set,
  // the Fifo depth should be between 0 and the max value.
  // The actually FIFO depth is covered in direct sequence.
  bit [31:0] status_mask = (1'b1 << KmacStatusFifoFull) |
                            (1'b1 << KmacStatusFifoEmpty) |
                            ({KMAC_FIFO_DEPTH{1'b1}} << KmacStatusFifoDepthLSB);

  function new(string name, uvm_component parent);
    super.new(name, parent);
    m_ahb_req_imp = new("m_ahb_req_imp", this);
    m_ahb_txn_imp = new("m_ahb_txn_imp", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg_change_cb = dv_base_fld_change_cb::type_id::create("cfg_change_cb");
  endfunction

  function void start_of_simulation_phase(uvm_phase phase);
    uvm_reg_field cfg_fields[$];

    super.start_of_simulation_phase(phase);

    // Register a callback for each field of CFG_SHADOWED. Doing so for just the register doesn't
    // work: we want to hang from post_predict, which only gets called for the fields.
    ral.kmac_core.CFG_SHADOWED.get_fields(cfg_fields);
    foreach (cfg_fields[i]) begin
      uvm_callbacks#(uvm_reg_field, uvm_reg_cbs)::add(cfg_fields[i], cfg_change_cb);
    end
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    if (cfg.en_scb) begin
      fork
        process_checked_kmac_cmd();
        manage_fifo_empty_intr();
        track_cfg_changes();
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

  // Return true if this is a bus write with an address that overlaps with MSG_FIFO.
  local function bit is_write_to_msg_fifo(ahb_txn_request_item bus_req);
    uvm_mem        msg_fifo       = ral.kmac_core.MSG_FIFO.m_mem;
    uvm_reg_addr_t msg_fifo_start = msg_fifo.get_address();
    int unsigned   msg_fifo_size  = msg_fifo.get_size() * msg_fifo.get_n_bytes();

    // An access touches MSG_FIFO if the bottom address is below the top of the region and the top
    // address is above the start of the region. Here, msg_fifo_start + msg_fifo_size is the address
    // of the first byte above the fifo and bus_req.m_addr + (1 << bus_req.m_size) - 1 is the last
    // byte of the access.
    return (bus_req.m_write &&
            bus_req.m_addr < msg_fifo_start + msg_fifo_size &&
            msg_fifo_start <= bus_req.m_addr + (1 << bus_req.m_size) - 1);
  endfunction

  // If addr is an address in the STATE window, return 1 and write the byte offset to the index
  // output argument. If not, return 0.
  local
  function bit get_index_in_state_window(bit [63:0] addr, output uvm_reg_addr_t index);
    uvm_mem        state_mem   = ral.kmac_core.STATE.m_mem;
    uvm_reg_addr_t state_start = state_mem.get_address();
    int unsigned   state_size  = state_mem.get_size() * state_mem.get_n_bytes();

    if (state_start <= addr && addr - state_start < state_size) begin
      index = addr - state_start;
      return 1;
    end

    return 0;
  endfunction

  // If this is a bus transaction that addresses a register, return the model of that register.
  //
  // If HSIZE means that the transaction doesn't address exactly the bits of the register, this
  // generates a warning (because the scoreboard might not know how to model the access).
  function dv_base_reg register_for_txn_request(ahb_txn_request_item bus_req);
    uvm_reg       register;
    dv_base_reg   dv_register;
    int unsigned  msb;

    register = ral.get_default_map().get_reg_by_offset(bus_req.m_addr);
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

  // The write function for m_ahb_req_imp, which is called for every bus request reported by the
  // monitor in the AHB agent.
  function void write_ahb_req(ahb_txn_request_item bus_req);
    // Clear a flag that tracks access to MSG_FIFO (for more details, see the code that might set it
    // further below in this function)
    msgfifo_access = 1'b0;

    // Consider just requests where m_trans is TransSequential or TransNonSequential (not idle or
    // busy).
    if (bus_req.m_trans inside {ahb_agent_pkg::TransSequential,
                                ahb_agent_pkg::TransNonSequential}) begin
      // Keep track of the start of transactions that write to MSG_FIFO. When we see one, we set
      // msgfifo_access here, which will be cleared again by this line at the start of the next
      // transaction, or when this transaction gets a result (in write_ahb_txn).
      //
      // An access touches MSG_FIFO if the bottom address is below the top of the region and the top
      // address is above the start of the region.
      if (is_write_to_msg_fifo(bus_req)) begin
        msgfifo_access = 1'b1;
        msgfifo_txn_idx = m_ahb_req_counter;
      end

      // If this is a request to read the STATUS register, take a snapshot now of the values we
      // expect for sha3_idle, sha3_absorb and sha3_squeeze. When the register transaction
      // completes, we'll check the value matches (in on_reg_txn)
      if (!bus_req.m_write && bus_req.m_addr == ral.kmac_core.STATUS.get_offset()) begin
        if (!ral.kmac_core.STATUS.sha3_idle.predict(.value(sha3_idle), .kind(UVM_PREDICT_READ)))
          `uvm_fatal(get_full_name(), "Failed to predict STATUS.sha3_idle")
        if (!ral.kmac_core.STATUS.sha3_absorb.predict(.value(sha3_absorb), .kind(UVM_PREDICT_READ)))
          `uvm_fatal(get_full_name(), "Failed to predict STATUS.sha3_absorb")
        if (!ral.kmac_core.STATUS.sha3_squeeze.predict(.value(sha3_squeeze),
                                                       .kind(UVM_PREDICT_READ)))
          `uvm_fatal(get_full_name(), "Failed to predict STATUS.sha3_squeeze")
      end
    end

    // Increment the number of requests that have been seen
    m_ahb_req_counter++;
  endfunction

  // The write function for m_ahb_txn_imp, which is called for every bus transaction reported by the
  // monitor in the AHB agent.
  function void write_ahb_txn(ahb_txn_item bus_txn);
    // If m_ahb_txn_counter is at least msgfifo_txn_idx, we have seen the end of the last bus
    // transaction that wrote to MSG_FIFO. Clear msgfifo_access.
    if (m_ahb_txn_counter >= msgfifo_txn_idx) msgfifo_access = 0;

    // Consider just transactions that ran to completion and didn't get an error response. Only
    // consider them if the request had m_trans equal to TransSequential or TransNonSequential (not
    // idle or busy).
    if (bus_txn.m_response != null &&
        !bus_txn.m_response.m_resp &&
        bus_txn.m_request.m_trans inside {ahb_agent_pkg::TransSequential,
                                          ahb_agent_pkg::TransNonSequential}) begin
      uvm_reg_addr_t idx_in_state_window;

      // Was this a successful transaction that addressed a register? If so, pass it to on_reg_txn
      // to update the register model's prediction of the register contents.
      uvm_reg register = register_for_txn_request(bus_txn.m_request);
      if (register != null) begin
        on_reg_txn(bus_txn, register);
      end

      // Was this transaction a write to MSG_FIFO? If so, we should track some associated functional
      // coverage and set msg (a class variable that tracks the input message)
      if (is_write_to_msg_fifo(bus_txn.m_request)) begin

        // Add the data from this request by appending the bytes to the queue in msg.
        int unsigned num_bytes = (1 << bus_txn.m_request.m_size);
        bit big_endian         = ral.kmac_core.CFG_SHADOWED.msg_endianness.get_mirrored_value();

        for (int unsigned i = 0; i < num_bytes; i++) begin
          int unsigned pick_idx = big_endian ? num_bytes - 1 - i : i;
          msg.push_back(bus_txn.m_request.m_wdata[(8 * pick_idx) +: 8]);
        end
      end

      // If this is a read from the STATE window, update m_cur_state with the bytes that have been
      // read.
      if (!bus_txn.m_request.m_write &&
          get_index_in_state_window(bus_txn.m_request.m_addr, idx_in_state_window)) begin
        int unsigned end_idx = idx_in_state_window + (1 << bus_txn.m_request.m_size);
        bit          big_endian = ral.kmac_core.CFG_SHADOWED.state_endianness.get_mirrored_value();

        if (idx_in_state_window > $size(m_cur_state.seen)) begin
          `uvm_fatal(get_full_name(),
                     $sformatf({"The address 0x%0h is reported as being in the STATE window, ",
                                "with offset %0d. But m_cur_state.seen only has %0d elements."},
                               bus_txn.m_request.m_addr,
                               idx_in_state_window,
                               $size(m_cur_state.seen)))
        end

        for (int unsigned idx = idx_in_state_window;
             idx < end_idx && idx < $size(m_cur_state.seen);
             idx++) begin
          int unsigned idx_in_txn = idx - idx_in_state_window;
          int unsigned lsb = 8*idx_in_txn;

          int unsigned idx_in_word    = idx & 3;
          int unsigned le_idx_in_word = big_endian ? 3 - idx_in_word : idx_in_word;
          int unsigned le_idx         = idx - idx_in_word + le_idx_in_word;

          m_cur_state.valid[le_idx] = 1;
          m_cur_state.seen[le_idx]  = (bus_txn.m_response.m_rdata >> lsb) & 8'hff;
        end
      end
    end

    // Increment the number of transactions that have been seen
    m_ahb_txn_counter++;
  endfunction

  // Called with a complete, successful monitored bus transaction item and the register that it
  // addressed.
  function void on_reg_txn(ahb_txn_item txn, uvm_reg register);
    if (register == ral.kmac_core.INTR_STATE) begin
      // On a read of the INTR_STATE register when coverage is enabled, update some covergroups with
      // the enable bits that we have seen and interrupt pins that were asserted.
      if (cfg.en_cov && !txn.m_request.m_write) begin
        uvm_reg_data_t intr_en = ral.kmac_core.INTR_ENABLE.get_mirrored_value();
        logic [2:0] intr_pins = {cfg.m_kmac_intr_vif.kmac_err,
                                 cfg.m_kmac_intr_vif.fifo_empty,
                                 cfg.m_kmac_intr_vif.kmac_done};

        for (int unsigned i = 0; i < KmacNumIntrs; i++) begin
          cov.intr_cg.sample(i, intr_en[i], txn.m_response.m_rdata[i]);
          cov.intr_pins_cg.sample(i, intr_pins[i]);
        end
      end
    end else if (register == ral.kmac_core.INTR_TEST) begin
      // On a write to the INTR_TEST register, update the prediction of INTR_STATE to match the bits
      // that are being set.
      //
      // If coverage is enabled, sample intr_test_cg as well.
      if (txn.m_request.m_write) begin
        uvm_reg_data_t intr_en   = ral.kmac_core.INTR_ENABLE.get_mirrored_value();
        uvm_reg_data_t old_state = ral.kmac_core.INTR_STATE.get_mirrored_value();
        uvm_reg_data_t real_mask = (1 << KmacNumIntrs) - 1;
        // Note: This works because we have few enough interrupts that all of them will be in the
        // bottom byte of wdata.
        uvm_reg_data_t wmask     = txn.m_request.m_wstrb[0] ? '1 : '0;
        uvm_reg_data_t bits_set  = real_mask & txn.m_request.m_wdata & wmask;
        uvm_reg_data_t new_state = old_state | bits_set;

        // Predict the new state with UVM_PREDICT_READ (telling the register model that we just read
        // new_state from the register). Using this instead of UVM_PREDICT_DIRECT avoids a race if
        // there is write to INTR_STATE that has been queued up in the register agent. We can't use
        // UVM_PREDICT_WRITE because the register is W1C.
        if (!ral.kmac_core.INTR_STATE.predict(.value(new_state), .kind(UVM_PREDICT_READ))) begin
          `uvm_error(get_full_name(), "Failed to predict new value for INTR_STATE.")
        end

        if (cfg.en_cov && |wmask) begin
          for (int unsigned i = 0; i < KmacNumIntrs; i++) begin
            cov.intr_test_cg.sample(i, bits_set[i], intr_en[i], new_state[i]);
          end
        end
      end
    end else if (register == ral.kmac_core.CMD) begin
      if (txn.m_request.m_write) begin
        bit [31:0] wdata = txn.m_request.m_wdata[31:0];
        bit [31:0] cmd_field_mask_at_0 = (32'd1 << ral.kmac_core.CMD.cmd.get_n_bits()) - 1;

        // Mirror the value written to the cmd field into the kmac_cmd class variable (which will
        // trigger other tasks in this class).
        kmac_cmd = (wdata >> ral.kmac_core.CMD.cmd.get_lsb_pos()) & cmd_field_mask_at_0;

        case (kmac_cmd)
          CmdStart: begin
            if (checked_kmac_cmd != CmdNone) begin
              // If checked_kmac_cmd is not CmdNone, that means that there is some other command
              // currently in progress.

              kmac_err.valid = 1;
              kmac_err.code  = kmac_pkg::ErrSwCmdSequence;
              kmac_err.info  = get_kmac_sw_cmd_seq_err_info(kmac_cmd);

              predict_err(.is_kmac_err(1));
            end else if (!valid_hash_mode_and_strength()) begin
              // Predict the error if hash_mode and strength aren't valid together.

              kmac_err.valid  = 1;
              kmac_err.code   = kmac_pkg::ErrUnexpectedModeStrength;
              kmac_err.info   = {8'h2, 10'h0, 2'(hash_mode), 1'b0, 3'(strength)};

              predict_err(.is_kmac_err(1));
            end else begin
              // We seem to be good to start the operation. Update the prediction for CFG_REGWEN:
              // registers are read-only while the operation is running.
              unchecked_kmac_cmd = CmdStart;
              predict_regwen(0);
            end

            // Starting a new command will invalidate any digest that we have read (and we might
            // have read some extra digest words after sending Done). Clear the validity bits for
            // any such words here.
            m_cur_state.valid = '0;
            m_observed_states.delete();
          end
          CmdProcess: begin
            if (checked_kmac_cmd == CmdStart) begin
              // kmac will now compute the digest
              unchecked_kmac_cmd = CmdProcess;
            end else begin // SW sent wrong command
              kmac_err.valid = 1;
              kmac_err.code  = kmac_pkg::ErrSwCmdSequence;
              kmac_err.info  = get_kmac_sw_cmd_seq_err_info(kmac_cmd);

              predict_err(.is_kmac_err(1));
            end
          end
          CmdManualRun: begin
            if (checked_kmac_cmd inside {CmdProcess, CmdManualRun}) begin
              // kmac will now squeeze more output data
              unchecked_kmac_cmd = CmdManualRun;

              // Append any observed state in m_cur_state to m_observed_states and clear m_cur_state
              // again.
              m_observed_states.push_back(m_cur_state);
              m_cur_state.valid = '0;

              // Mask out status squeeze check because it requires cycle accurate prediction.
              // Use sequence to backdoor check if squeeze is reset to 0 after each squeeze
              // command.
              status_mask[KmacStatusSha3Squeeze] = 1;
            end else begin // SW sent wrong command
              kmac_err.valid = 1;
              kmac_err.code  = kmac_pkg::ErrSwCmdSequence;
              kmac_err.info  = get_kmac_sw_cmd_seq_err_info(kmac_cmd);

              predict_err(.is_kmac_err(1));
            end
          end
          CmdDone: begin
            if (checked_kmac_cmd inside {CmdProcess, CmdManualRun}) begin
              unchecked_kmac_cmd = CmdDone;

              sha3_squeeze = 0;
              `uvm_info(`gfn, "dropped sha3_squeeze", UVM_HIGH)

              // sample coverage of message length
              if (cfg.en_cov) begin
                cov.msg_len_cg.sample(msg.size());
              end

              status_mask[KmacStatusSha3Squeeze] = 0;

              // Calculate the digest using DPI and check for correctness
              if (do_check_digest) check_digest();

              // Flush all scoreboard state to prepare for the next hash operation
              clear_state();

              predict_regwen(1);

            end else begin // SW sent wrong command

              kmac_err.valid = 1;
              kmac_err.code  = kmac_pkg::ErrSwCmdSequence;
              kmac_err.info  = get_kmac_sw_cmd_seq_err_info(kmac_cmd);

              predict_err(.is_kmac_err(1));
            end
          end
          CmdNone: begin
            // RTL internal value, doesn't actually do anything
          end
          default: begin
            `uvm_error(get_full_name(),
                       $sformatf({"Invalid value written to CMD register (0x%0h): ",
                                  "not modelled in scoreboard."},
                                 kmac_cmd))
          end
        endcase
      end
    end else if (register == ral.kmac_core.STATUS) begin
      if (!txn.m_request.m_write) begin
        // This is a read of the STATUS register. We took a snapshot of our expected value for the
        // sha3_idle, sha3_absorb and sha3_squeeze fields when we saw the request. We have *not*
        // pre-populated the register model with predictions for the fifo fields (fifo_depth,
        // fifo_empty, fifo_full), so we will start by looking at them by hand.

        bit [31:0] rdata = txn.m_response.m_rdata;
        bit [4:0] fifo_depth_seen = ((rdata >> ral.kmac_core.STATUS.fifo_depth.get_lsb_pos()) &
                                     ((1 << 5) - 1));
        bit fifo_empty_seen = (rdata >> ral.kmac_core.STATUS.fifo_empty.get_lsb_pos()) & 1;
        bit fifo_full_seen = (rdata >> ral.kmac_core.STATUS.fifo_full.get_lsb_pos()) & 1;

        // Check that the empty/full status flags are consistent with the depth.
        //
        //  - The flags fifo_empty_seen and fifo_full_seen can't both be true.
        //  - If fifo_empty_seen is true then the depth should be zero.
        //  - If fifo_full_seen is true then the depth should be KMAC_FIFO_DEPTH.
        //  - If neither is true then the depth should be strictly less than KMAC_FIFO_DEPTH, but we
        //    don't also require that the depth is positive. This is discussed in OpenTitan issue
        //    #14286.
        if (fifo_empty_seen) begin
          if (fifo_full_seen) begin
            `uvm_error(get_full_name(), "STATUS reported the fifo to be both empty and full.")
          end
          if (fifo_depth_seen > 0) begin
            `uvm_error(get_full_name(),
                       $sformatf("STATUS reported fifo empty but with a depth of %0d.",
                                 fifo_depth_seen))
          end
        end else if (fifo_full_seen) begin
          if (fifo_depth_seen != KMAC_FIFO_DEPTH) begin
            `uvm_error(get_full_name(),
                       $sformatf({"STATUS reported fifo full but with a depth of %0d ",
                                  "(KMAC_FIFO_DEPTH = %0d)"},
                                 fifo_depth_seen, KMAC_FIFO_DEPTH))
          end
        end else begin
          if (fifo_depth_seen >= KMAC_FIFO_DEPTH) begin
            `uvm_error(get_full_name(),
                       $sformatf({"STATUS didn't report fifo full, but reported a depth of %0d ",
                                  "(KMAC_FIFO_DEPTH = %0d)"},
                                 fifo_depth_seen, KMAC_FIFO_DEPTH))
          end
        end

        // Check that the other fields of the register are as predicted (knocking out the bits in
        // status_mask, which are all the bits corresponding to the fifo fields above.
        if ((rdata ^ ral.kmac_core.STATUS.get_mirrored_value()) & ~status_mask) begin
          bit [31:0]     masked_seen = rdata & ~status_mask;
          uvm_reg_data_t masked_expected = ral.kmac_core.STATUS.get_mirrored_value() & ~status_mask;

          `uvm_error(get_full_name(),
                     $sformatf({"Unexpected value of STATUS. After masking out the fifo bits, we ",
                                "expect 0x%0h but just read 0x%0h."},
                               masked_expected, masked_seen))
        end

        // Finally update functional coverage with the STATUS value we just read.
        if (cfg.en_cov) begin
          bit idle_seen = (rdata >> ral.kmac_core.STATUS.sha3_idle.get_lsb_pos()) & 1;
          bit absorb_seen = (rdata >> ral.kmac_core.STATUS.sha3_absorb.get_lsb_pos()) & 1;
          bit squeeze_seen = (rdata >> ral.kmac_core.STATUS.sha3_squeeze.get_lsb_pos()) & 1;

          cov.msgfifo_level_cg.sample(fifo_empty_seen,
                                      fifo_full_seen,
                                      fifo_depth_seen,
                                      hash_mode,
                                      kmac_en);
          cov.sha3_status_cg.sample(idle_seen, absorb_seen, squeeze_seen);
        end
      end
    end
  endfunction

  // Return true if the mirrored hash_mode and strength are a valid pair
  function bit valid_hash_mode_and_strength();
    case (hash_mode)
      sha3_pkg::Shake, sha3_pkg::CShake: begin
        return (strength inside {sha3_pkg::L128, sha3_pkg::L256});
      end

      sha3_pkg::Sha3: begin
        return (strength != sha3_pkg::L128);
      end

      default: begin
        return 0;
      end
    endcase
  endfunction

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

  // Watch the event in cfg_change_cb, which will be triggered whenever the predicted value of the
  // field changes.
  task track_cfg_changes();
    import sha3_pkg::sha3_mode_e;
    import sha3_pkg::keccak_strength_e;

    forever begin
      cfg_change_cb.m_event.wait_trigger();

      // We have just seen a change to the CFG_SHADOWED register. Of course, that might have changed
      // several fields and we only want to reason about the result after all of the predictions
      // have been updated.
      //
      // As such, we cheat here and use #0 to wait until the next region of the time slot. All of
      // the field predictions will happen in the same region, so this will ensure we only see one
      // event (after all the predictions have been updated).
      #0;

      // If sha3_idle is false, the engine is already running something. Don't update the
      // configuration that is mirrored into the scoreboard.
      if (!sha3_idle) continue;

      hash_mode = sha3_mode_e'(ral.kmac_core.CFG_SHADOWED.mode.get_mirrored_value());
      strength = keccak_strength_e'(ral.kmac_core.CFG_SHADOWED.kstrength.get_mirrored_value());
    end
  endtask

  // Set the access permissions for all fields controlled by CFG_REGWEN to the given value
  //
  // Conveniently, all of these fields are RW until the regwen is cleared, at which point they
  // become RO.
  function void apply_regwen_access(string mode);
    uvm_reg_field cfg_fields[$];

    ral.kmac_core.CFG_SHADOWED.get_fields(cfg_fields);
    foreach (cfg_fields[i]) void'(cfg_fields[i].set_access(mode));

    for (int unsigned i = 0; i < 11; i++) begin
      uvm_reg_field reg_fields[$];

      string  reg_name = $sformatf("PREFIX_%0d", i);
      uvm_reg pfx_reg  = ral.kmac_core.get_reg_by_name(reg_name);

      pfx_reg.get_fields(reg_fields);
      foreach (reg_fields[j]) void'(reg_fields[j].set_access(mode));
    end
  endfunction

  // Update the prediction for CFG_REGWEN to the given value
  //
  // This calls predict() to update the register model, using UVM_PREDICT_DIRECT (since the register
  // is maintained by HW anyway). It also updates the access for all fields that are protected by
  // the flag.
  function void predict_regwen(bit new_value);
    bit old_value = |ral.kmac_core.CFG_REGWEN.get_mirrored_value();
    if (new_value != old_value) begin
      if (!ral.kmac_core.CFG_REGWEN.predict(.value(new_value), .kind(UVM_PREDICT_DIRECT))) begin
        `uvm_error(get_full_name(), "Failed to predict value of CFG_REGWEN.")
      end
      apply_regwen_access(new_value ? "RW" : "RO");
    end
  endfunction

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
  //
  // This task consumes time while waiting for the fifo empty status to be updated, but exits early
  // on reset.
  virtual task predict_fifo_empty_intr();
    uvm_status_e   txn_status;
    uvm_reg_data_t intr_state_rdata;

    bit fifo_empty_status_neg;
    bit fifo_empty_status_last = fifo_empty_status;
    bit pre_intr_fifo_empty;

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

    // The dut takes a cycle to update its FIFO_EMPTY signal. Wait that cycle, then wait for
    // INTR_STATE not to be busy (so that we can backdoor-read and predict its value). Exit early on
    // reset.
    fork : isolation_fork begin
      fork
        wait(cfg.under_reset);
        begin
          cfg.clk_rst_vif.wait_clks(1);
          wait(!ral.kmac_core.INTR_STATE.is_busy());
        end
      join_any
      disable fork;
    end join
    if (cfg.under_reset) return;

    // Update expected register value
    if (!ral.kmac_core.INTR_STATE.FIFO_EMPTY.predict(.value(pre_intr_fifo_empty),
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
    import sha3_pkg::sha3_mode_e;
    import sha3_pkg::keccak_strength_e;

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

    // Reset fields tracked in CFG_SHADOWED.
    hash_mode = sha3_mode_e'(ral.kmac_core.CFG_SHADOWED.mode.get_reset());
    strength  = keccak_strength_e'(ral.kmac_core.CFG_SHADOWED.kstrength.get_reset());

    // Zero the request and transaction counters
    m_ahb_req_counter = 0;
    m_ahb_txn_counter = 0;

    // Clear the msgfifo_access flag (there's nothing currently accessing MSG_FIFO)
    msgfifo_access = 0;

    // The reset means that we are no longer running a SHA operation (which would cause the
    // hardware-maintained CFG_REGWEN to be false).
    predict_regwen(1);
  endfunction

  // This function should be called to reset internal state to prepare for a new hash operation
  virtual function void clear_state();
    `uvm_info(`gfn, "clearing scoreboard state", UVM_HIGH)

    if (first_op_after_rst) first_op_after_rst = 0;

    do_check_digest = 1;

    msg.delete();
    kmac_app_msg.delete();

    set_entropy_fetch(0);

    kmac_err = '{valid: 1'b0,
                 code: kmac_pkg::ErrNone,
                 info: '0};
    sha3_err = '{valid: 1'b0,
                 code: sha3_pkg::ErrNone,
                 info: '0};

    app_st = StIdle;

    prefix = '{default:0};

    m_cur_state.valid = '0;
    m_observed_states.delete();
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
  // are written to the CSRs.
  virtual function void check_digest();
    // Cast to an array so we can pass this into the DPI functions
    bit [7:0] msg_arr[];

    // Determines which kmac variant to use
    bit xof_en;

    // Set this to the calculated output length for XOFs
    int output_len_bytes;

    // The number of digest bytes that have been compared in the loop at the bottom of the function.
    // The function will print a warning if none are checked.
    int unsigned checked_count;

    // A flag that counts the number of mismatches seen by the comparison loop at the bottom of the
    // function. Using this (and UVM_WARNING) allows a few bytes to be reported before the
    // simulation stops, even when UVM_MAX_QUIT_COUNT=1.
    int unsigned mismatches_seen;

    // Array to hold the digest read from the state windows
    bit [7:0] unmasked_digest[];

    // Function name and customization strings for KMAC operations
    string fname;
    string custom_str;

    // key byte-stream for the DPI model
    bit [7:0] dpi_key_arr[];

    // Actual hash_mode based on interface or SW register
    sha3_pkg::sha3_mode_e actual_hash_mode = hash_mode;

    // Array to hold the expected digest calculated by DPI model
    bit [7:0] dpi_digest[];

    if (cfg.en_scb == 0) return;

    // Calculate:
    // - the expected output length in bytes
    // - if we are using the xof version of kmac
    get_digest_len_and_xof(output_len_bytes, xof_en, msg);

    if (cfg.en_cov) begin
      // sample configuration coverage, as only now do we know which KMAC variant is used
      // (xof/non-xof)
      cov.sample_cfg(kmac_en, xof_en, strength, actual_hash_mode,
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

    // This loop is needed for SHAKE and cSHAKE, where we might have issued Run commands to get new
    // states.
    for (int unsigned i = 0; i < 1 + m_observed_states.size(); i++) begin
      compare_state(i,
                    dpi_digest,
                    (i == m_observed_states.size()) ? m_cur_state : m_observed_states[i]);
    end
  endfunction

  // Compare observed digests for a state with dpi_digest (which came from the model).
  //
  //    state_idx:  The number of times the Run command had been issued before the observed state
  //                was seen.
  //
  //    dpi_digest: A complete digest computed by the model, which should have a "correct" value for
  //                every value available in observed.
  //
  //    observed:   The bus reads that have been observed for this state.
  function void compare_state(int unsigned     state_idx,
                              bit [7:0]        dpi_digest[],
                              observed_state_t observed);
    // The size of a single STATE object is determined by the capacity which, in turn, is determined
    // by the strength.
    int unsigned capacity_bytes = strength_to_capacity(strength) / 8;

    // The state whose values are in observed might not start at index zero in dpi_digest (the
    // digest from the model).
    int unsigned model_offset = capacity_bytes * state_idx;

    int unsigned num_comparisons;
    int unsigned num_mismatches;

    // That digest had better have enough bytes to represent everything in observed. If not, there
    // is a bug in our DV code.
    if (dpi_digest.size() < model_offset + capacity_bytes) begin
      `uvm_fatal(get_full_name(),
                 $sformatf({"The state with index %0d should cover ",
                            "indices %0d..%0d in dpi_digest (capacity is %0d). ",
                            "But dpi_digest only has size %0d."},
                           state_idx,
                           model_offset,
                           model_offset + capacity_bytes - 1,
                           capacity_bytes * 8,
                           dpi_digest.size()))
    end

    // Now work through the observed state values
    for (int unsigned i = 0; i < BytesInObservedState; i++) begin
      if (!observed.valid[i]) continue;

      if (i < capacity_bytes) begin
        bit [7:0] model_byte = dpi_digest[model_offset + i];
        bit [7:0] seen_byte = observed.seen[i];

        if (model_byte != seen_byte) begin
          `uvm_warning(get_full_name(),
                       $sformatf({"Mismatch at index %0d (offset %0d within state %0d). ",
                                  "RTL value: 0x%0h; Model value: 0x%0h."},
                                 model_offset + i, i, state_idx, seen_byte, model_byte))
          num_mismatches++;
        end
      end else begin
        // This is a read outside the state window, so should have evaluated to zero.
        if (observed.seen[i]) begin
          `uvm_warning(get_full_name(),
                       $sformatf({"Mismatch at offset %0d (on state %0d). This is outside of ",
                                  "the size given by capacity (%0d bytes) so the read value ",
                                  "should have been zero but the RTL reported 0x%0h."},
                                 i, state_idx, capacity_bytes, observed.seen[i]))
          num_mismatches++;
        end
      end
      num_comparisons++;

      // Don't print more messages to the console after 16 mismatches.
      if (num_mismatches >= 16) break;
    end

    // If there were any mismatches, report an error.
    if (num_mismatches) begin
      `uvm_error(get_full_name(),
                 $sformatf("Comparing digests found %0s%0d mismatch%0s.",
                           (num_mismatches >= 16) ? "at least " : "",
                           num_mismatches,
                           (num_mismatches > 1) ? "s" : ""))
    end

    if (!num_comparisons) begin
      `uvm_warning(get_full_name(),
                   $sformatf("Digest check vacuous: no digest bytes were read for state %0d.",
                             state_idx))
    end

    `uvm_info(get_full_name(),
              $sformatf("Digest check compared %0d digest bytes for state %0d.",
                        num_comparisons, state_idx),
              UVM_HIGH)
  endfunction

  // Calculate the capacity (in bits) for a given Keccak strength
  static function int unsigned strength_to_capacity(sha3_pkg::keccak_strength_e s);
    case (s)
      sha3_pkg::L128: return 1344;
      sha3_pkg::L224: return 1152;
      sha3_pkg::L256: return 1088;
      sha3_pkg::L384: return  832;
      sha3_pkg::L512: return  576;
      default: begin
        `uvm_fatal_context("strength_to_capacity",
                           $sformatf("Unknown strength: %0d", s),
                           uvm_root::get())
      end
    endcase
  endfunction

  // Calculate the requested digest length
  virtual function void get_digest_len_and_xof(ref int output_len, ref bit xof_en,
                                               ref bit [7:0] msg[$]);
    int unsigned capacity_bytes = strength_to_capacity(strength) / 8;

    xof_en = 0;
    case (hash_mode)
      // For SHA3 hashes, the output length is the same as the security strength.
      sha3_pkg::Sha3: begin
        if (!(strength inside {sha3_pkg::L224, sha3_pkg::L256,
                               sha3_pkg::L384, sha3_pkg::L512})) begin
          `uvm_fatal(`gfn, $sformatf("strength[%0s] is not allowed for sha3", strength.name()))
        end
        output_len = capacity_bytes;
      end
      // For SHAKE hashes, the output length isn't encoded anywhere, so we just return the amount
      // that has been seen (and thus needs consuming from a model for comparison). To do this,
      // count the number of states that have been seen (1 + m_observed_states.size()) and multiply
      // by the capacity in bytes.
      sha3_pkg::Shake: begin
        output_len = (1 + m_observed_states.size()) * capacity_bytes;
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
          output_len = $size(digest_seen);
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
