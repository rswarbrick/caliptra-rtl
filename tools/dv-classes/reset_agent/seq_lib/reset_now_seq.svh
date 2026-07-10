// Copyright lowRISC contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A sequence that sends a single reset_drive_item, constrained to happen immediately.

class reset_now_seq extends reset_seq;
  `uvm_object_utils(reset_now_seq)

  extern function new(string name="");

  extern constraint immediate_c;
endclass

function reset_now_seq::new(string name="");
  super.new(name);
endfunction

constraint reset_now_seq::immediate_c {
  m_item.m_immediate;
}
