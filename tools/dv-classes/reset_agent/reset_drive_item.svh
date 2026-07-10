// Copyright lowRISC contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A sequence item that represents a reset to be driven

class reset_drive_item extends uvm_sequence_item;
  `uvm_object_utils(reset_drive_item)

  // If this bit is set, the driver should inject a reset as soon as it gets the item (and not
  // concentrate on timings relative to clock edges). The not_immediate_c soft constraint makes this
  // false unless otherwise constrained.
  //
  // Note that this bit can be set after randomising the item (and indeed after starting to drive
  // the item). This will be noticed by the driver, which will abandon any wait that it was doing
  // and drive the item immediately.
  rand bit m_immediate;

  // The amount of time (in picoseconds) to wait before asserting a reset. The reset is asserted
  // asynchronously, and will probably not line up with a clock edge if this value is positive.
  //
  // The delay will be skipped if m_immediate is true.
  rand longint unsigned m_delay_ps;

  // The number of clock edges that should be seen while in reset. If this value is zero, the reset
  // will not be cleared: to keep an interface in reset for an extended time, send one of these
  // items with m_clk_count = 0 and follow it (later) with another item with m_clk_count != 0.
  rand int unsigned m_clk_count;

  extern function new(string name = "");
  extern function void do_print(uvm_printer printer);
  extern function void do_copy(uvm_object rhs);
  extern function bit do_compare(uvm_object rhs, uvm_comparer comparer);

  // A soft constraint causing m_immediate to be false.
  extern constraint not_immediate_c;

  // Constrain m_clk_count to be positive and small. This is a soft constraint, so can be overridden
  // when randomising.
  extern constraint short_count_c;
endclass

function reset_drive_item::new(string name="");
  super.new(name);
endfunction

function void reset_drive_item::do_print(uvm_printer printer);
  super.do_print(printer);
  printer.print_field_int("m_immediate", m_immediate, 1, UVM_BIN);
  printer.print_field_int("m_delay_ps", m_delay_ps, 64, UVM_DEC);
  printer.print_field_int("m_clk_count", m_clk_count, 32, UVM_DEC);
endfunction

function void reset_drive_item::do_copy(uvm_object rhs);
  reset_drive_item rhs_;
  if (rhs == null) `uvm_fatal("do_copy", "Cannot copy from RHS: it is null.")
  if (!$cast(rhs_, rhs)) `uvm_fatal("do_copy", "Cannot cast RHS: wrong type?")

  super.do_copy(rhs);
  this.m_immediate = rhs_.m_immediate;
  this.m_delay_ps  = rhs_.m_delay_ps;
  this.m_clk_count = rhs_.m_clk_count;
endfunction

function bit reset_drive_item::do_compare(uvm_object rhs, uvm_comparer comparer);
  reset_drive_item rhs_;

  // These items are only equivalent if rhs is actually a reset_drive_item.
  if (rhs == null || !$cast(rhs_, rhs)) begin
    comparer.print_msg("RHS is null or is not a reset_drive_item.");
    return 0;
  end

  return (super.do_compare(rhs, comparer) &
          comparer.compare_field_int("m_immediate", m_immediate, rhs_.m_immediate, 1, UVM_BIN) &
          comparer.compare_field_int("m_delay_ps", m_delay_ps, rhs_.m_delay_ps, 64, UVM_DEC) &
          comparer.compare_field_int("m_clk_count", m_clk_count, rhs_.m_clk_count, 32, UVM_DEC));
endfunction

constraint reset_drive_item::not_immediate_c {
  soft !m_immediate;
}

constraint reset_drive_item::short_count_c {
  soft m_clk_count != 0;
  soft m_clk_count < 3;
}
