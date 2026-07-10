// Copyright lowRISC contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A sequence that sends a single reset_drive_item, with no particular constraints (so a finite
// reset will be injected a short time from when the sequence starts)

class reset_seq extends uvm_sequence #(reset_drive_item, reset_edge_item);
  `uvm_object_utils(reset_seq)

  // The one and only item that will be driven by the sequence. Note that the randomisation happens
  // with the sequence itself, rather than when the item is allocated to the sequencer.
  rand reset_drive_item m_item;

  // A bit that gets set when the driver reports it has asserted the reset. Wait for this with the
  // wait_asserted() task.
  local bit m_seen_reset;

  extern function new(string name="");
  extern task body();

  // Wait until the driver reports that it has asserted the reset for the item in the sequence
  extern task wait_asserted();
endclass

function reset_seq::new(string name="");
  super.new(name);
  m_item = reset_drive_item::type_id::create("m_item");
endfunction

task reset_seq::body();
  start_item(m_item);

  fork
    finish_item(m_item);
    begin
      get_response(rsp, m_item.get_transaction_id());
      m_seen_reset = 1;

      `uvm_info(get_full_name(), "Reset asserted", UVM_HIGH)

      // If the driver will clear the reset again, consume the message it sends at that point.
      if (m_item.m_clk_count > 0) begin
        get_response(rsp, m_item.get_transaction_id());
        `uvm_info(get_full_name(), "End of reset", UVM_HIGH)
      end
    end
  join
endtask

task reset_seq::wait_asserted();
  wait(m_seen_reset);
endtask
