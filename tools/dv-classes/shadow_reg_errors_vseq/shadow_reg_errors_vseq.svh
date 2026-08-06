// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A virtual sequence that stimulates shadow registers in ways that will cause them to report update
// errors.
//
// To use this:
//
//    - For each status field that will be set to a particular value after an update or storage
//      error, call add_update_error_field() / add_storage_error_field().
//
//    - Add one or more dv_base_reg_block instances (which should contain one or more shadow errors
//      between them) by calling add_reg_block().
//
//    - Pass a handle to a reset event with set_reset_event().
//
// Configuration:
//
//    - To run a csr_rw sequence in parallel with the test that triggers the shadow register errors,
//      call set_run_csr_rw_seq(1).
//
//    - If there is no scoreboard tracking register read values, call set_external_checker(0), which
//      will cause the csr_rw sequence to include read value checks.
//
//    - To run through more than one block of shadow registers, call set_num_times().

class shadow_reg_errors_vseq extends uvm_sequence;
  `uvm_object_utils(shadow_reg_errors_vseq)

  // A register field, together with a uvm_reg_data_t to represent the value that this field will be
  // set to when a particular shadow reg error happens.
  typedef struct {
    uvm_reg_field  field;
    uvm_reg_data_t value;
  } field_value_on_error_t;

  // A queue of field_value_on_error_t structures that represent field updates that will happen
  // after a shadow update error.
  //
  // Add an item by calling add_update_error_field().
  local field_value_on_error_t m_update_error_fields[$];

  // A queue of field_value_on_error_t structures that represent field storages that will happen
  // after a shadow storage error.
  //
  // Add an item by calling add_storage_error_field().
  local field_value_on_error_t m_storage_error_fields[$];

  // An event that is triggered when the block changes reset state (either entering or leaving
  // reset). Set this with set_reset_event().
  //
  // The body() task watches this event and maintains the m_in_reset state variable. Each time the
  // event is triggered comes with a reset_edge_item that gives the new state of the reset line.
  local uvm_event m_reset_event;

  // A reset has been asserted (so the sequence should finish)
  bit m_seen_reset;

  // Register blocks that might contain shadowed registers. Add one by calling add_reg_block().
  local dv_base_reg_block m_reg_blocks[$];

  // A flag that says to run a csr_rw sequence in parallel to the test that triggers shadow register
  // errors. Set it with set_run_csr_rw_seq().
  local bit m_run_csr_rw_seq;

  // A bit that shows we are running in a context with a scoreboard that will check register read
  // values. This defaults to true. Call set_external_checker() to configure it.
  local bit m_external_checker = 1;

  // The number of times to run through <= 50 CSRs. Defaults to 1. Set this with set_num_times().
  local int unsigned m_num_times = 1;

  extern function new(string name="");
  extern task pre_start();
  extern task body();

  // Add the given field to m_update_error_fields: it is predicted to equal value after an update
  // error.
  extern function void add_update_error_field(uvm_reg_field field, uvm_reg_data_t value);

  // Add the given field to m_update_error_fields: it is predicted to equal value after a storage
  // error.
  extern function void add_storage_error_field(uvm_reg_field field, uvm_reg_data_t value);

  // Add the given register block to m_reg_blocks
  extern function void add_reg_block(dv_base_reg_block blk);

  // Set a handle to a reset event that the sequence should track. This event should be triggered on
  // each change of reset state and the associated data should be a reset_edge_item giving the new
  // value of the rst_n line.
  //
  // Call this before starting the sequence.
  extern function void set_reset_event(uvm_event reset_event);

  // Set the value of m_run_csr_rw_seq. If true, the virtual sequence will run a csr_rw sequence in
  // parallel with the test that triggers shadow register errors.
  extern function void set_run_csr_rw_seq(bit enable);

  // Configure whethere there is an external scoreboard. This defaults to being true. If set to
  // false, the CSR sequence will check register reads against expected values.
  extern function void set_external_checker(bit external_checker);

  // Set the number of times to loop through groups of <= 50 CSRs.
  extern function void set_num_times(int unsigned num_times);

  // Wait until m_reset_event is triggered with data showing that the tracked interface has entered
  // reset. When that happens, set m_seen_reset and return.
  extern local task wait_for_reset();

  // Run a single iteration of the loop in the middle of the sequence
  //
  // Note: This will permute shadowed_regs but otherwise leave the queue unchanged.
  extern local task single_iteration(int unsigned iteration_idx,
                                     int unsigned num_iterations,
                                     ref uvm_reg  shadowed_regs[$]);

  // Run a test based on the (shadowed) register. If m_run_csr_rw_seq is true, run a csr_rw sequence
  // in parallel, which has been constrained not to access the registers in shadowed_regs.
  extern local task test_reg(uvm_reg           register,
                             const ref uvm_reg shadowed_regs[$]);

  // Run a csr_rw sequence, constarined not to access the registers in shadowed_regs.
  extern local task run_csr_rw_seq(const ref uvm_reg shadowed_regs[$]);

  // Configure csr_seq to ignore the check excluded by excl_type for each of the registers in regs.
  extern local static function void ignore_regs_in_seq(uvm_reg         regs[$],
                                                       csr_base_seq    csr_seq,
                                                       csr_excl_type_e excl_type);

  // Configure csr_seq to ignore the check excluded by excl_type for each of the registers
  // containing a field in fields.
  extern local static function void ignore_fields_in_seq(field_value_on_error_t fields[$],
                                                         csr_base_seq           csr_seq,
                                                         csr_excl_type_e        excl_type);

  // Return a value to write to register which is different in at least one bit where the register
  // has a field.
  extern local function uvm_reg_data_t get_different_wdata(uvm_reg        register,
                                                           uvm_reg_data_t wdata0);

  // Pick two different wdata values that can be used for register
  extern local function void get_wdata_pair(uvm_reg               register,
                                            output uvm_reg_data_t wdata0,
                                            output uvm_reg_data_t wdata1);

  // Write a register with two different values. Check that the value isn't updated and that the
  // relevant status fields (that had been provided with add_update_error_field(),
  // add_storage_error_field()) have been set.
  extern local task write_and_check_update_error(uvm_reg register);

  // Do a single write to register, followed by a read, then two writes with the same value as each
  // other, different from the first one. Check that the register has the second value.
  extern local task check_read_clears_staged_val(uvm_reg register);

  // Update the prediction for the status registers to the values expected after an update error.
  extern local function void predict_status_after_update_err();

  // Read register and check that it has the predicted value.
  extern local task read_to_check_prediction(uvm_reg register);

  // Read the registers with the status fields in m_update_error_fields / m_storage_error_fields and
  // check them against their predicted values.
  extern local task read_and_check_status_regs();
endclass

function shadow_reg_errors_vseq::new(string name="");
  super.new(name);
endfunction

task shadow_reg_errors_vseq::pre_start();
  if (m_update_error_fields.size() == 0) begin
    `uvm_fatal(get_full_name(), "No fields to report update errors.")
  end
  if (m_storage_error_fields.size() == 0) begin
    `uvm_fatal(get_full_name(), "No fields to report storage errors.")
  end
  if (m_reset_event == null) `uvm_fatal(get_full_name(), "No reset_event provided.")
endtask

task shadow_reg_errors_vseq::body();
  uvm_reg shadowed_regs[$];

  // Walk through the register blocks, searching for shadowed registers
  foreach (m_reg_blocks[i]) begin
    dv_base_reg dv_base_shadowed_regs[$];
    m_reg_blocks[i].get_shadowed_regs(dv_base_shadowed_regs);
    foreach (dv_base_shadowed_regs[j]) shadowed_regs.push_back(dv_base_shadowed_regs[j]);
  end

  // There had better be at least one shadowed register
  if (shadowed_regs.size() == 0) begin
    `uvm_fatal(get_full_name(),
               $sformatf("No register block (of %0d provided) has a shadowed register.",
                         m_reg_blocks.size()))
  end

  fork : isolation_fork begin
    fork
      begin
        for (int unsigned i = 0; i < m_num_times; i++) begin
          single_iteration(i + 1, m_num_times, shadowed_regs);
        end
      end
      begin
        wait_for_reset();
        wait (0);
      end
    join_any

    // Since the second process won't end, we must have finished loop of calls to single_iteration.
    // Disable the wait_for_reset() process.
    disable fork;
  end join
endtask

function void shadow_reg_errors_vseq::add_update_error_field(uvm_reg_field  field,
                                                             uvm_reg_data_t value);
  m_update_error_fields.push_back('{field: field, value: value});
endfunction

function void shadow_reg_errors_vseq::add_storage_error_field(uvm_reg_field  field,
                                                              uvm_reg_data_t value);
  m_storage_error_fields.push_back('{field: field, value: value});
endfunction

function void shadow_reg_errors_vseq::add_reg_block(dv_base_reg_block blk);
  m_reg_blocks.push_back(blk);
endfunction

function void shadow_reg_errors_vseq::set_reset_event(uvm_event reset_event);
  m_reset_event = reset_event;
endfunction

function void shadow_reg_errors_vseq::set_run_csr_rw_seq(bit enable);
  m_run_csr_rw_seq = enable;
endfunction

function void shadow_reg_errors_vseq::set_external_checker(bit external_checker);
  m_external_checker = external_checker;
endfunction

function void shadow_reg_errors_vseq::set_num_times(int unsigned num_times);
  m_num_times = num_times;
endfunction

task shadow_reg_errors_vseq::wait_for_reset();
  forever begin
    uvm_object                       event_item;
    reset_agent_pkg::reset_edge_item edge_item;

    m_reset_event.wait_trigger_data(event_item);
    if (!$cast(edge_item, event_item)) begin
      `uvm_fatal(get_full_name(), "Reset event was triggered with no reset_edge_item attached.")
    end

    // The edge item shows that a reset has been asserted if m_new_state (the tracked rst_n signal)
    // is zero.
    if (edge_item.m_new_state == 0) break;
  end

  m_seen_reset = 1;
endtask

task shadow_reg_errors_vseq::single_iteration(int unsigned   iteration_idx,
                                              int unsigned   num_iterations,
                                              ref uvm_reg shadowed_regs[$]);
  int unsigned max_idx = shadowed_regs.size() - 1;
  if (max_idx > 49) max_idx = 49;

  `uvm_info(get_full_name(),
            $sformatf({"Running shadow reg error test iteration %0d/%0d. ",
                       "(touching %0d shadowed regs)"},
                      iteration_idx, num_iterations, max_idx + 1),
            UVM_LOW)

  shadowed_regs.shuffle();

  for (int unsigned i = 0; i <= max_idx; i++) begin
    `uvm_info(get_full_name(),
              $sformatf("Considering CSR %0s", shadowed_regs[i].get_name()),
              UVM_HIGH)
    repeat (5) test_reg(shadowed_regs[i], shadowed_regs);
  end
endtask

task shadow_reg_errors_vseq::test_reg(uvm_reg           register,
                                      const ref uvm_reg shadowed_regs[$]);
  bit ready_to_trigger_csr_rw = 0;
  fork
    begin
      ready_to_trigger_csr_rw = 1;
      randcase
        1: write_and_check_update_error(register);
        1: check_read_clears_staged_val(register);
      endcase
    end
    begin
      if (m_run_csr_rw_seq) begin
        wait (ready_to_trigger_csr_rw == 1);
        run_csr_rw_seq(shadowed_regs);
      end
    end
  join
endtask

task shadow_reg_errors_vseq::run_csr_rw_seq(const ref uvm_reg shadowed_regs[$]);
  csr_rw_seq csr_seq = csr_rw_seq::type_id::create("csr_seq");

  foreach (m_reg_blocks[i]) begin
    csr_seq.models.push_back(m_reg_blocks[i]);
  end
  csr_seq.external_checker = m_external_checker;

  // Configure csr_seq not to access any of the shadowed registers or any of the registers that
  // report update/storage errors.
  ignore_regs_in_seq(shadowed_regs, csr_seq, CsrExclAll);
  ignore_fields_in_seq(m_update_error_fields, csr_seq, CsrExclAll);
  ignore_fields_in_seq(m_storage_error_fields, csr_seq, CsrExclAll);

  csr_seq.start(null);
endtask

function void shadow_reg_errors_vseq::ignore_regs_in_seq(uvm_reg         regs[$],
                                                         csr_base_seq    csr_seq,
                                                         csr_excl_type_e excl_type);
  foreach (regs[i]) begin
    csr_seq.exclude_register(regs[i], excl_type);
  end
endfunction

function void shadow_reg_errors_vseq::ignore_fields_in_seq(field_value_on_error_t fields[$],
                                                           csr_base_seq           csr_seq,
                                                           csr_excl_type_e        excl_type);
  foreach (fields[i]) begin
    csr_seq.exclude_register(fields[i].field.get_parent(), excl_type);
  end
endfunction

function uvm_reg_data_t shadow_reg_errors_vseq::get_different_wdata(uvm_reg        register,
                                                                    uvm_reg_data_t wdata0);
  uvm_reg_field  fields[$];
  uvm_reg_data_t field_mask;

  register.get_fields(fields);
  foreach (fields[i]) begin
    field_mask |= (((1 << fields[i].get_n_bits()) - 1) << fields[i].get_lsb_pos());
  end

  randcase
    1: begin
      // Generate a completely random value, constrained to be different from wdata0 when masked by
      // field_mask.
      uvm_reg_data_t wdata1;
      if (!std::randomize(wdata1) with { |((wdata1 ^ wdata0) & field_mask); }) begin
        `uvm_fatal(get_full_name(), "Cannot generate differing wdata.")
      end
      return wdata1;
    end

    1: begin
      // Flip a single one of the masked bits
      int unsigned bit_idx;
      if (!std::randomize(bit_idx) with { field_mask[bit_idx]; }) begin
        `uvm_fatal(get_full_name(), "Cannot pick bit to flip in wdata.")
      end
      return wdata0 ^ (uvm_reg_data_t'(1) << bit_idx);
    end
  endcase
endfunction

function void shadow_reg_errors_vseq::get_wdata_pair(uvm_reg               register,
                                                     output uvm_reg_data_t wdata0,
                                                     output uvm_reg_data_t wdata1);
  if (!std::randomize(wdata0)) `uvm_fatal(get_full_name(), "Failed to randomise wdata0")
  wdata1 = get_different_wdata(register, wdata0);
endfunction

task shadow_reg_errors_vseq::write_and_check_update_error(uvm_reg register);
  uvm_reg_data_t wdata0, wdata1, rdata;
  uvm_status_e   txn_status;

  get_wdata_pair(register, wdata0, wdata1);

  `uvm_info(get_full_name(),
            $sformatf("About to write %0s with differing values 0x%0h; 0x%0h.",
                      register.get_name(), wdata0, wdata1),
            UVM_HIGH)

  register.write(txn_status, wdata0);
  if (m_seen_reset) return;
  if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Write transaction 0 failed.")

  register.write(txn_status, wdata1);
  if (m_seen_reset) return;
  if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Write transaction 1 failed.")

  // At this point, we have written two different values to the register, which should trigger the
  // update error. Predict that the fields in m_update_error_fields will have changed value.
  predict_status_after_update_err();

  // Now read those registers and check the fields are as expected (clearing the update error as a
  // side effect)
  `uvm_info(get_full_name(),
            "Reading status registers to check update error was reported.",
            UVM_HIGH)
  read_and_check_status_regs();
  if (m_seen_reset) return;

  // Finally read the register that was written and check it matches its predicted value, which will
  // not have changed. (The unchanged value might be checked by a scoreboard as well.)
  `uvm_info(get_full_name(),
            $sformatf("Reading %0s to check it has the (unchanged) predicted value.",
                      register.get_name()),
            UVM_HIGH)
  read_to_check_prediction(register);
endtask

task shadow_reg_errors_vseq::check_read_clears_staged_val(uvm_reg register);
  uvm_reg_data_t wdata0, wdata1, rdata;
  uvm_status_e   txn_status;

  get_wdata_pair(register, wdata0, wdata1);

  `uvm_info(get_full_name(),
            $sformatf("About to half-write %0s with 0x%0h, then read and full-write with 0x%0h.",
                      register.get_name(), wdata0, wdata1),
            UVM_HIGH)

  // Do the initial single write to the register
  register.write(txn_status, wdata0);
  if (m_seen_reset) return;
  if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Write transaction 0 failed.")

  // Now read the register, which should return the predicted value (which will not have changed)
  // and should cause the staged value to be cleared.
  read_to_check_prediction(register);
  if (m_seen_reset) return;

  // Now double-write wdata1, which should actually take effect.
  for (int unsigned i = 0; i < 2; i++) begin
    register.write(txn_status, wdata1);
    if (m_seen_reset) return;
    if (txn_status != UVM_IS_OK) begin
      `uvm_error(get_full_name(), $sformatf("Write transaction %0d failed.", 1 + i))
    end
  end

  // Read the status registers and check that they are as predicted before (because we haven't
  // predicted any change)
  read_and_check_status_regs();
  if (m_seen_reset) return;

  // Finally, read the register that was written and check that it matches its predicted value,
  // which will now be wdata1.
  read_to_check_prediction(register);
endtask

function void shadow_reg_errors_vseq::predict_status_after_update_err();
  foreach (m_update_error_fields[i]) begin
    if (!m_update_error_fields[i].field.predict(m_update_error_fields[i].value,
                                                UVM_PREDICT_DIRECT)) begin
      `uvm_fatal(get_full_name(),
                 $sformatf("Failed to update prediction of %0s.",
                           m_update_error_fields[i].field.get_full_name()))
    end
  end
endfunction

task shadow_reg_errors_vseq::read_to_check_prediction(uvm_reg register);
  uvm_reg_data_t rdata;
  uvm_status_e   txn_status;

  register.read(txn_status, rdata);
  if (m_seen_reset) return;
  if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Read transaction failed.")

  if (rdata != register.get_mirrored_value()) begin
    `uvm_error(get_full_name(),
               $sformatf("Unexpected read data from %0s. Prediction is 0x%0h but rdata was 0x%0h.",
                         register.get_name(), register.get_mirrored_value(), rdata))
  end
endtask

task shadow_reg_errors_vseq::read_and_check_status_regs();
  // The set of registers that contain at least one status field.
  bit regs_with_status_fields[uvm_reg];

  // Work through the list of status fields, collecting up the set of registers in which they are
  // contained in regs_with_status_fields (an associative array with meaningless value).
  foreach (m_update_error_fields[i]) begin
    regs_with_status_fields[m_update_error_fields[i].field.get_parent()] = 0;
  end
  foreach (m_storage_error_fields[i]) begin
    regs_with_status_fields[m_storage_error_fields[i].field.get_parent()] = 0;
  end

  // Read each of those registers and check that it matches its predicted value
  foreach (regs_with_status_fields[register]) begin
    read_to_check_prediction(register);
    if (m_seen_reset) return;
  end
endtask
