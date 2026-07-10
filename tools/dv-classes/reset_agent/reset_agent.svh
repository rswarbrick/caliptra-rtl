// Copyright lowRISC contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class reset_agent extends uvm_agent;
  `uvm_component_utils(reset_agent)

  // An analysis port for monitored resets
  uvm_analysis_port #(reset_edge_item) m_analysis_port;

  // The virtual interface. This can either be set by calling set_vif() before the build phase, or
  // provided through uvm_config_db.
  local virtual reset_if m_vif;

  // The monitor for the interface
  local reset_monitor m_monitor;

  // The driver that can drive resets
  local reset_driver m_driver;

  // A sequencer that supplies m_driver.
  local reset_sequencer_t m_sequencer;

  extern function new (string name, uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);

  // Set m_vif to the provided interface
  extern function void set_vif(virtual reset_if vif);

  // Get a handle to a uvm_event that is triggered on every edge of the reset line. The data value
  // that comes with the event is the new value of rst_n. As such, the event will be triggered at
  // the start of a reset and will have value 0.
  extern function uvm_event get_event();

  // Get the sequencer. Can only be called after build_phase, and the agent must be active.
  extern function reset_sequencer_t get_sequencer();

  // Run a sequence that immediately causes a reset. This task is a convenience to avoid every
  // "start of test call-site" having to implement the same thing.
  extern task reset_now();
endclass

function reset_agent::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

function void reset_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);

  m_analysis_port = new("m_analysis_port", this);

  if (m_vif == null && !uvm_config_db#(virtual reset_if)::get(this, "", "vif", m_vif)) begin
    `uvm_fatal(get_full_name(), "failed to get vif from uvm_config_db")
  end
  if (m_vif == null) begin
    `uvm_fatal(get_full_name(), "No non-null m_vif provided.")
  end

  m_monitor = reset_monitor::type_id::create("m_monitor", this);
  m_monitor.set_vif(m_vif);

  if (get_is_active() == UVM_ACTIVE) begin
    // Generate a driver and sequencer
    m_driver = reset_driver::type_id::create("m_driver", this);
    m_sequencer = reset_sequencer_t::type_id::create("m_sequencer", this);
  end

  m_vif.is_active = (get_is_active() == UVM_ACTIVE);
endfunction

function void reset_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  m_monitor.m_analysis_port.connect(m_analysis_port);

  // If the agent is active, connect the driver to the interface and sequencer
  if (get_is_active() == UVM_ACTIVE) begin
    m_driver.set_vif(m_vif);
    m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
  end
endfunction

function void reset_agent::set_vif(virtual reset_if vif);
  if (m_vif != null) `uvm_fatal(get_full_name(), "Cannot set vif: m_vif is already non-null.")
  m_vif = vif;
endfunction

function uvm_event reset_agent::get_event();
  return m_monitor.get_event();
endfunction

function reset_sequencer_t reset_agent::get_sequencer();
  if (m_sequencer == null) `uvm_fatal(get_full_name(), "m_sequencer is null.")
  return m_sequencer;
endfunction

task reset_agent::reset_now();
  reset_now_seq seq = reset_now_seq::type_id::create("seq");
  if (!seq.randomize()) `uvm_fatal(get_full_name(), "Failed to randomise seq")
  seq.start(m_sequencer);
endtask
