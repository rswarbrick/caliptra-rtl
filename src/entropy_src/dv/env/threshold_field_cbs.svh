// Copyright lowRISC contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A callback class that can be attached to fields with threshold behaviour (increment only or
// decrement only).

class threshold_field_cbs extends uvm_reg_cbs;
  `uvm_object_utils(threshold_field_cbs)

  // A map from field to whether the field is being used as an upper bound (that can only be
  // decremented). If a field maps to 0, it is a lower bound (that can only be incremented).
  local bit m_is_upper_bound[uvm_reg_field];

  extern function new (string name = "");

  // Add a field to be tracked, together with whether it is an upper or a lower bound
  extern function void add_field(uvm_reg_field fld, bit is_upper_bound);

  // A function from uvm_reg_cbs, called as part of predicting the field after a read or write.
  extern function void post_predict(input uvm_reg_field  fld,
                                    input uvm_reg_data_t previous,
                                    inout uvm_reg_data_t value,
                                    input uvm_predict_e  kind,
                                    input uvm_path_e     path,
                                    input uvm_reg_map    map);
endclass

function threshold_field_cbs::new(string name = "");
  super.new(name);
endfunction

function void threshold_field_cbs::add_field(uvm_reg_field fld, bit is_upper_bound);
  if (m_is_upper_bound.exists(fld)) begin
    `uvm_fatal("double_add",
               $sformatf("Cannot add field %0s.%0s: this is already in the map.",
                         fld.get_parent().get_name(), fld.get_name()))
  end

  m_is_upper_bound[fld] = is_upper_bound;
endfunction

function void threshold_field_cbs::post_predict(input uvm_reg_field  fld,
                                                input uvm_reg_data_t previous,
                                                inout uvm_reg_data_t value,
                                                input uvm_predict_e  kind,
                                                input uvm_path_e     path,
                                                input uvm_reg_map    map);
  bit is_upper_bound;

  if (!m_is_upper_bound.exists(fld)) begin
    `uvm_fatal("unknown_field",
               $sformatf("Cannot use callback for field %0s.%0s: it has not been added.",
                         fld.get_parent().get_name(), fld.get_name()))
  end

  is_upper_bound = m_is_upper_bound[fld];

  case (kind)
    UVM_PREDICT_READ: begin
      // Nothing to do here: the value we've just read must be correct.
    end

    UVM_PREDICT_WRITE: begin
      // Check that value is being updated in the correct direction
      if (is_upper_bound) begin
        if (value > previous) value = previous;
      end else begin
        if (value < previous) value = previous;
      end
    end

    default: begin
      `uvm_fatal("unknown_kind", $sformatf("Unknown kind value for post_predict: %0d", kind))
    end
  endcase
endfunction
