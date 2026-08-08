// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// An interface that can be used to control assertions in the design RTL, through an
// entropy_src_tb_assertion_if that watches its ports.
interface entropy_src_assertion_if (
  // Disable a set of assertions that might otherwise be triggered by fault injection
  output bit disable_assertions_o
);

  import uvm_pkg::*;

  initial disable_assertions_o = 0;

  // Drive the disable_assertions_o output port, controlling a entropy_src_tb_assertion_if that will
  // enable or disable a particular set of data integrity assertions.
  task automatic control_assertions(bit enable);
    `uvm_info($sformatf("%m"),
              $sformatf("Requesting that associated assertions are %0sabled.",
                        enable ? "en" : "dis"),
              UVM_HIGH)
    disable_assertions_o = !enable;
  endtask

endinterface
