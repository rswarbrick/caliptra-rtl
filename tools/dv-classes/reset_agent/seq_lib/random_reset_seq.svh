// Copyright lowRISC contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A sequence that sends a single reset_drive_item, which waits a reasonably long time (to allow
// another sequence to put the device into an interesting state) before asserting the reset.

class random_reset_seq extends reset_seq;
  `uvm_object_utils(random_reset_seq)

  // The maximum delay before the item should assert a reset.
  //
  // By default, it is set to represent 100,000 cycles at a notional clock frequency of 100MHz (so
  // lasts 1ms). This probably needs scaling when the sequence is constructed, to configure the
  // clock frequency and the amount of work to allow before the reset is asserted.
  int unsigned m_max_delay_ns = 1_000_000;

  extern function new(string name="");

  // Set the m_immediate field of the single item driven in the sequence, which will cause its
  // driver to abort the wait and assert the reset now.
  extern function void stop_waiting();

  // Give the device some time before reset, but not an enormous simulation time. To use a different
  // constraint, either subclass this sequence and replace the constraint or disable the constraint
  // and replace it with a different inline constraint.
  //
  // The bound chosen here is to represent 100,000 cycles at the notional clock frequency.
  extern constraint delay_max_c;
endclass

function random_reset_seq::new(string name="");
  super.new(name);
endfunction

function void random_reset_seq::stop_waiting();
  m_item.m_immediate = 1;
endfunction

constraint random_reset_seq::delay_max_c {
  m_item.m_delay_ps <= (m_max_delay_ns * 64'd1000);
}
