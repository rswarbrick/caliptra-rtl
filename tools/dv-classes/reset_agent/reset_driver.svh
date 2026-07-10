// Copyright lowRISC contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A driver for reset_if.
//
// It will normally send two responses for each reset_drive_item: one for the edge where the reset
// is asserted and then one for the edge where it is de-asserted. The one exception is for items
// with m_clk_count = 0, where the driver doesn't clear the reset, and doesn't send the second item.

class reset_driver extends uvm_driver #(reset_drive_item, reset_edge_item);
  `uvm_component_utils(reset_driver)

  local virtual reset_if m_vif;

  extern function new(string name, uvm_component parent);
  extern virtual task run_phase(uvm_phase phase);

  // Set m_vif. This must be called before run_phase.
  extern function void set_vif(virtual reset_if vif);

  // Drive a single reset on the interface
  extern local task drive_item(reset_drive_item item);

  // Wait the time specified by item before asserting reset. Stops early if item.m_immediate becomes
  // true.
  extern local task delay_before_reset(reset_drive_item item);
endclass

function reset_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

function void reset_driver::set_vif(virtual reset_if vif);
  if (m_vif != null) begin
    `uvm_fatal(get_full_name(), "Cannot call set_vif: there is already an interface.")
    return;
  end
  m_vif = vif;
endfunction

task reset_driver::run_phase(uvm_phase phase);
  if (m_vif == null) begin
    `uvm_fatal(get_full_name(), "Cannot drive interface: m_vif is null.")
    return;
  end

  if (!m_vif.is_active) begin
    `uvm_warning(get_full_name(), "Driving interface will have no effect: is_active is false")
  end

  forever begin
    reset_drive_item item;

    seq_item_port.get_next_item(item);
    drive_item(item);
    seq_item_port.item_done();
  end
 endtask

task reset_driver::drive_item(reset_drive_item item);
  reset_edge_item start_item;

  // Wait the requested delay, dropping out early if item.m_immediate becomes true (and checking
  // that nothing else asserts a reset while we are waiting)
  delay_before_reset(item);

  // Assert the reset
  m_vif.rst_n_driven = 0;

  start_item = reset_edge_item::type_id::create("start_item");
  start_item.m_new_state = 0;
  start_item.set_id_info(item);
  seq_item_port.put_response(start_item);

  // If m_clk_count is positive, wait for that many posedges of the clock and then clear the reset
  // again.
  if (item.m_clk_count > 0) begin
    reset_edge_item end_item;

    repeat (item.m_clk_count) @(posedge m_vif.clk_i);
    m_vif.rst_n_driven = 1;

    end_item = reset_edge_item::type_id::create("end_item");
    end_item.m_new_state = 1;
    end_item.set_id_info(item);
    seq_item_port.put_response(end_item);
  end
endtask

task reset_driver::delay_before_reset(reset_drive_item item);
  if (item.m_immediate) return;

  fork : isolation_fork begin
    fork
      wait(item.m_immediate);

      // Keep an eye on the reset line and spot if a reset is newly asserted while we are waiting
      // (which would imply contention on the interface)
      forever begin
        wait(m_vif.rst_n);
        wait(!m_vif.rst_n);
        `uvm_error(get_full_name(), "Reset newly asserted while driver was waiting.")
      end

      // Wait the requested delay in the item
      #(item.m_delay_ps * 1ps);
    join_any
    disable fork;
  end join
endtask
