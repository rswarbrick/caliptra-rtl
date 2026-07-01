// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// A callback that should be installed on a field, with an event that triggers each time there is a
// predict() call that changes the field's value.
//
// An object waiting on the event can get extra information from fields in this class, saying
// whether the change is the result of a read or write.
//
// If there are multiple fields in the register, you have to attach the callback to each field
// (because a register write might only change some of the field values). When waiting on the event,
// the trick is to use the following structure:
//
//    forever begin
//      my_cb.m_event.wait_trigger();
//      #0;
//      // Handle the event here
//    end
//
// The #0 waits until the next region in the time slot. A uvm_reg_predictor that sees a write to the
// register will call predict on each of the fields, but these predictions will all happen in the
// same delta cycle. As such, when we get to the "Handle the event here" line, all predictions will
// have finished.
//
// Note that this event does not trigger when the mirrored field value is updated from a call to
// reset().

class dv_base_fld_change_cb extends uvm_reg_cbs;
  `uvm_object_utils(dv_base_fld_change_cb)

  // This event is triggered each time post_predict() sees the field's predicted value change
  uvm_event m_event;

  // The "kind" argument sent to the last predict() call that caused our post_predict() function to
  // run with a change in field value.
  uvm_predict_e m_kind;

  extern function new(string name = "");
  extern virtual function void post_predict(input uvm_reg_field fld,
                                            input uvm_reg_data_t previous,
                                            inout uvm_reg_data_t value,
                                            input uvm_predict_e kind,
                                            input uvm_path_e path,
                                            input uvm_reg_map map);
endclass

function dv_base_fld_change_cb::new(string name = "");
  super.new(name);
  m_event = new("m_event");
endfunction

function void dv_base_fld_change_cb::post_predict(input uvm_reg_field fld,
                                                  input uvm_reg_data_t previous,
                                                  inout uvm_reg_data_t value,
                                                  input uvm_predict_e kind,
                                                  input uvm_path_e path,
                                                  input uvm_reg_map map);
  if (value != previous) begin
    m_kind = kind;
    m_event.trigger();
  end
endfunction
