// Copyright lowRISC contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A callback class that can be attached to OBSERVE_FIFO_DEPTH.OBSERVE_FIFO_DEPTH to allow
// predicting things correctly if writes to the fifo overlap with reads from the depth.

class observe_fifo_depth_cbs extends uvm_reg_cbs;
  `uvm_object_utils(observe_fifo_depth_cbs)

  // The field that is being tracked.
  local uvm_reg_field m_fld;

  // The maximum possible depth in the FIFO (beyond which a push won't increment the depth)
  local int unsigned m_fifo_size;

  // The "delta" between the register model's most recent prediction and our belief about the value
  // that's actually in the register at the moment.
  local int m_delta;

  extern function new (string name = "");

  // Set the field that is tracked and the size of the FIFO.
  extern function void set_field_and_fifo_size(uvm_reg_field fld, int unsigned size);

  // What's the currently predicted value of the FIFO depth?
  extern function int unsigned get_prediction();

  // Does the current prediction of the FIFO depth think that the FIFO is full?
  extern function bit get_predicted_full();

  // Called when the block resets (which should clear any currently tracked value)
  extern function void on_reset();

  // Call this on a push into the FIFO, which should increment the FIFO depth.
  extern function void on_push();

  // Call this on a read from the FIFO, which should decrement the FIFO depth.
  extern function void on_pop();

  // A function from uvm_reg_cbs, called as part of predicting the field after a read or write.
  extern function void post_predict(input uvm_reg_field  fld,
                                    input uvm_reg_data_t previous,
                                    inout uvm_reg_data_t value,
                                    input uvm_predict_e  kind,
                                    input uvm_path_e     path,
                                    input uvm_reg_map    map);

  // Consume the difference in m_delta (clipping as necessary); update the register model's
  // prediction; clear the delta.
  //
  // This should only be called when the register is not busy.
  extern local function void apply_delta();
endclass

function observe_fifo_depth_cbs::new(string name = "");
  super.new(name);
endfunction

function void observe_fifo_depth_cbs::set_field_and_fifo_size(uvm_reg_field fld,
                                                              int unsigned size);
  m_fld       = fld;
  m_fifo_size = size;
endfunction

function int unsigned observe_fifo_depth_cbs::get_prediction();
  int raw_adjusted;

  if (m_fld == null) `uvm_fatal("no_fld", "No field registered for callbacks.")

  raw_adjusted = m_fld.get_mirrored_value() + m_delta;

  if (raw_adjusted < 0) return 0;
  else if (raw_adjusted > m_fifo_size) return m_fifo_size;
  else return raw_adjusted;
endfunction

function bit observe_fifo_depth_cbs::get_predicted_full();
  return (get_prediction() == m_fifo_size);
endfunction

function void observe_fifo_depth_cbs::on_reset();
  m_delta = 0;
endfunction

function void observe_fifo_depth_cbs::on_push();
  if (m_fld == null) `uvm_fatal("no_fld", "No field registered for callbacks.")

  if (m_fld.get_parent().is_busy()) begin
    // Increment the delta but only if the result will still fit under m_fifo_size
    if (m_delta + m_fld.get_mirrored_value() + 1 <= m_fifo_size) m_delta++;
  end else begin
    // Increment the delta (not worrying about the upper bound for the prediction), then use the
    // updated value to update the prediction.
    m_delta++;
    apply_delta();
  end
endfunction

function void observe_fifo_depth_cbs::on_pop();
  if (m_fld == null) `uvm_fatal("no_fld", "No field registered for callbacks.")

  if (m_fld.get_parent().is_busy()) begin
    // Decrement the delta but only if result would be non-negative.
    if (m_delta + m_fld.get_mirrored_value() >= 1) m_delta--;
  end else begin
    // Decrement the delta (not worrying about the lower bound for the prediction), then use the
    // updated value to update the prediction.
    m_delta--;
    apply_delta();
  end
endfunction

function void observe_fifo_depth_cbs::post_predict(input uvm_reg_field  fld,
                                                   input uvm_reg_data_t previous,
                                                   inout uvm_reg_data_t value,
                                                   input uvm_predict_e  kind,
                                                   input uvm_path_e     path,
                                                   input uvm_reg_map    map);
  case (kind)
    UVM_PREDICT_READ: begin
      // Nothing to do here: the value we've just read must be correct. Clear any m_delta value that
      // we were holding.
      m_delta = 0;
    end

    UVM_PREDICT_WRITE: begin
      // We've just finished writing to the field (which is read-only). But this is an opportunity
      // to update with our predicted value.
      value = get_prediction();
      m_delta = 0;
    end

    default: begin
      `uvm_fatal("unknown_kind", $sformatf("Unknown kind value for post_predict: %0d", kind))
    end
  endcase
endfunction

function void observe_fifo_depth_cbs::apply_delta();
  if (m_delta != 0) begin
    // Take m_delta into account and update the predicted value of the field.
    if (!m_fld.predict(get_prediction(), UVM_PREDICT_DIRECT)) begin
      `uvm_fatal("no_predict", "Failed to predict update to field.")
    end

    // Now that we have updated the field, clear m_delta.
    m_delta = 0;
  end
endfunction
