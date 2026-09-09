// Copyright lowRISC contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A callback class that can be attached to the error fields in ERR_CODE to allow predicting things
// correctly if hardware updates to the error state overlap with reads from the register.

class err_code_cbs extends uvm_reg_cbs;
  `uvm_object_utils(err_code_cbs)

  // A map from field to a bit that shows that the field's error is waiting to be asserted when the
  // relevant register is no longer busy.
  //
  // After the callbacks have been attached to a register, this map will be complete for the fields
  // in that register.
  local bit m_pending_errs[uvm_reg_field];

  extern function new (string name = "");

  // Register the this callbacks class with each of the fields in a register (assumed to be
  // ERR_CODE). This can only be called once.
  extern function void attach_to_register(uvm_reg register);

  // What's the currently predicted value of the register?
  extern function uvm_reg_data_t get_prediction();

  // Called when the block resets (which should clear any currently tracked value)
  extern function void on_reset();

  // Called when hardware knows a field's error should be asserted.
  extern function void assert_err(uvm_reg_field fld);

  // A function from uvm_reg_cbs, called as part of predicting the field after a read or write.
  extern function void post_predict(input uvm_reg_field  fld,
                                    input uvm_reg_data_t previous,
                                    inout uvm_reg_data_t value,
                                    input uvm_predict_e  kind,
                                    input uvm_path_e     path,
                                    input uvm_reg_map    map);
endclass

function err_code_cbs::new(string name = "");
  super.new(name);
endfunction

function void err_code_cbs::attach_to_register(uvm_reg register);
  uvm_reg_field fields[$];

  if (m_pending_errs.size()) begin
    `uvm_fatal("double_reg",
               $sformatf("Trying to attach to the register %0s when already attached to fields.",
                         register.get_name()))
  end

  register.get_fields(fields);
  foreach (fields[i]) begin
    // Check that the field is actually a 1-bit field
    if (fields[i].get_n_bits() != 1) begin
      `uvm_fatal("wide_field",
                 $sformatf("Cannot attach err_code_cbs to field %0s.%0s: it is not a single bit.",
                           fields[i].get_parent().get_name(), fields[i].get_name()))
    end

    m_pending_errs[fields[i]] = 0;
    uvm_reg_field_cb::add(fields[i], this);
  end
endfunction

function uvm_reg_data_t err_code_cbs::get_prediction();
  uvm_reg_data_t mirrored_value;
  uvm_reg_field  fld0;

  // Check that there is at least one field (so we've actually been attached to a register)
  if (!m_pending_errs.first(fld0)) begin
    `uvm_fatal("no_fields", "Cannot get a prediction: the cbs instance has no associated register.")
  end

  // First get the prediction from the underlying register (which is the parent of fld0).
  mirrored_value = fld0.get_parent().get_mirrored_value();

  // Now apply any pending error from m_pending_errs.
  foreach (m_pending_errs[fld]) begin
    if (m_pending_errs[fld]) begin
      mirrored_value |= (uvm_reg_data_t'(1) << fld.get_lsb_pos());
    end
  end

  return mirrored_value;
endfunction

function void err_code_cbs::on_reset();
  foreach (m_pending_errs[fld]) begin
    m_pending_errs[fld] = 0;
  end
endfunction

function void err_code_cbs::assert_err(uvm_reg_field fld);
  uvm_reg register = fld.get_parent();

  if (!m_pending_errs.exists(fld)) begin
    `uvm_fatal("unknown_field",
               $sformatf({"This cbs instance can't assert an error for the field %0s.%0s: that ",
                          "field is not tracked in m_pending_errs."},
                         register.get_name(), fld.get_name()))
  end

  if (register.is_busy()) begin
    // If the register is busy at the moment, set the field's flag in m_pending_errs.
    m_pending_errs[fld] = 1;
  end else begin
    // If the register isn't busy, we can do an immediate direct prediction. Clear any pending error
    // as well (which shouldn't really be set, but it probably makes sense to be sure).
    if (!fld.predict(1, UVM_PREDICT_DIRECT)) begin
      `uvm_fatal("cannot_predict",
                 $sformatf("Failed to predict field %0s.%0s.", register.get_name(), fld.get_name()))
    end
    m_pending_errs[fld] = 0;
  end
endfunction

function void err_code_cbs::post_predict(input uvm_reg_field  fld,
                                         input uvm_reg_data_t previous,
                                         inout uvm_reg_data_t value,
                                         input uvm_predict_e  kind,
                                         input uvm_path_e     path,
                                         input uvm_reg_map    map);
  // Check that fld is actually being tracked
  if (!m_pending_errs.exists(fld)) begin
    `uvm_fatal("unknown_field",
               "This cbs instance is attached to a field that is not a key in m_pending_errs.")
  end

  case (kind)
    UVM_PREDICT_READ: begin
      // Nothing to do here: the value we've just read must be correct. Clear any m_delta value that
      // we were holding.
      m_pending_errs[fld] = 0;
    end

    UVM_PREDICT_WRITE: begin
      // We've just finished writing to the field (which is read-only). But this is an opportunity
      // to pass through any pending error.
      value |= m_pending_errs[fld];
      m_pending_errs[fld] = 0;
    end

    default: begin
      `uvm_fatal("unknown_kind", $sformatf("Unknown kind value for post_predict: %0d", kind))
    end
  endcase
endfunction
