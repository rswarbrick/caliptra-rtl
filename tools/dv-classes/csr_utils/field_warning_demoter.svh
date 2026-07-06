// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A class that demotes UVM_WARNING messages caused by explicit access to a uvm_reg_field. This
// access causes a call to uvm_reg_field::is_indv_accessible and we don't necessarily have
// field-local access.
//
// The reason for the warning is that the workaround (sending e.g. a register write with the
// predicted values of the other fields) is only safe if the predictions are correct. Fortunately,
// there are several sequences in csr_utils where this *is* safe. For these, we want to demote the
// warning to UVM_NONE (essentially turning it off).

class field_warning_demoter extends uvm_report_catcher;
  extern function new(string name="");
  extern function action_e catch();
endclass

function field_warning_demoter::new(string name="");
  super.new(name);
endfunction

function uvm_report_catcher::action_e field_warning_demoter::catch();
  // The warning looks like this:
  //
  //  UVM_WARNING @   6544578 ps: (uvm_reg_field.svh:1724)
  //    [RegModel] Individual field access not available for field
  //    'long.path.to.register.field'. Accessing complete register instead.
  if (get_id() == "RegModel" &&
      get_severity() == UVM_WARNING &&
      uvm_is_match("*Individual field access not available for field*", get_message())) begin
    set_severity(UVM_INFO);
  end
  return THROW;
endfunction
