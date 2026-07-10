// Copyright lowRISC contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A monitor that watches a reset_if.

class reset_monitor extends uvm_monitor;
  `uvm_component_utils(reset_monitor)

  // The interface being tracked. Set this with set_vif().
  local virtual reset_if m_vif;

  // An event that is triggered on every edge of the reset line. Get this with get_event().
  local uvm_event m_event;

  // The analysis port for observed resets.
  uvm_analysis_port #(reset_edge_item) m_analysis_port;

  extern function new(string name, uvm_component parent);
  extern function void build_phase (uvm_phase phase);
  extern task run_phase(uvm_phase phase);

  // Get a handle to a uvm_event that is triggered on every edge of the reset line. The data value
  // that comes with the event a reset_edge_item that represents the new value of the reset line.
  extern function uvm_event get_event();

  // Set the interface that is being tracked
  extern function void set_vif(virtual reset_if vif);

  // Track requests and responses on m_vif
  extern local task watch_interface();
endclass

function reset_monitor::new(string name, uvm_component parent);
  super.new(name, parent);
  m_event = new("m_event");
endfunction

function void reset_monitor::build_phase(uvm_phase phase);
  super.build_phase(phase);
  m_analysis_port = new("m_analysis_port", this);

  if (m_vif == null && !uvm_config_db#(virtual reset_if)::get(this, "", "vif", m_vif)) begin
    `uvm_fatal(get_full_name(), "Interface neither supplied with set_vif nor with uvm_config_db.")
  end
endfunction

task reset_monitor::run_phase(uvm_phase phase);
  fork
    super.run_phase(phase);
    watch_interface();
  join
endtask

function void reset_monitor::set_vif(virtual reset_if vif);
  m_vif = vif;
endfunction

function uvm_event reset_monitor::get_event();
  return m_event;
endfunction

task reset_monitor::watch_interface();
  wait (!$isunknown(m_vif.rst_n));
  forever begin
    reset_edge_item item;
    bit cur_val = m_vif.rst_n;

    item = reset_edge_item::type_id::create("item");
    item.m_new_state = cur_val;
    m_analysis_port.write(item);

    m_event.trigger(item);

    wait(m_vif.rst_n == ~cur_val);
  end
endtask
