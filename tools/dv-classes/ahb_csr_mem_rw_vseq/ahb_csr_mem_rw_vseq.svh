// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A virtual sequence that runs randomised read and write sequences on the CSRs and memories of the
// associated uvm_reg_blocks
//
// This sequence will eventually terminate, but it's really designed to be used in a situation where
// a reset is injected (at which point this sequence will terminate).
//
// Before using the sequence:
//
//    - Pass one or more uvm_reg_block instances with add_ral().
//
//    - Set an AHB sequencer (to use for memory accesses) with set_ahb_sequencer().
//
//    - Tell the sequence about the mapping from address to subordinate index using
//      set_subordinates().
//
//    - Set a reset event, to allow the sequence to tell when a reset has been applied (so it should
//      not start any more CSR sequences). Do this by calling set_reset_event().

class ahb_csr_mem_rw_vseq extends uvm_sequence;
  `uvm_object_utils(ahb_csr_mem_rw_vseq)

  // The set of register models to use. Add a register model by calling add_ral() before starting
  // the sequence.
  local uvm_reg_block m_rals[$];

  // An AHB transaction sequencer. Set this by calling set_ahb_sequencer() before starting the
  // virtual sequence.
  local ahb_txn_sequencer_t m_sequencer;

  // An array of known mappings from address range to subordinate index. Set this with
  // set_subordinates.
  local sub_addr_range_t m_subordinate_mappings[$];

  // The number of times to repeat the CSR access sequence. If this is zero, the CSR access sequence
  // will run non-stop until a reset. Set this with set_csr_seq_scaling().
  local int unsigned m_csr_seq_scaling = 1;

  // A bit that shows we are running in a context with a scoreboard that will check register read
  // values. This defaults to true. Call set_external_checker() to configure it.
  local bit m_external_checker = 1;

  // An event that is triggered when the block changes reset state (either entering or leaving
  // reset). Set this with set_reset_event().
  //
  // The body() task watches this event and maintains the m_in_reset state variable. Each time the
  // event is triggered comes with a reset_edge_item that gives the new state of the reset line.
  local uvm_event m_reset_event;

  extern function new(string name="");
  extern task pre_start();
  extern task body();

  // Add a register block to use.
  //
  // Call this for each register block to use to configure the sequence before starting it.
  extern function void add_ral(uvm_reg_block ral);

  // Set the subordinate mapping array
  //
  // Call this to configure the sequence before starting it.
  extern function void set_subordinates(const ref sub_addr_range_t mappings[$]);

  // Configure whethere there is an external scoreboard. This defaults to being true. If set to
  // false, the CSR sequence will check register reads against expected values.
  extern function void set_external_checker(bit external_checker);

  // Set the AHB sequencer to use for any ahb_mem_rw_seq sequences
  extern function void set_ahb_sequencer(ahb_txn_sequencer_t sequencer);

  // Set a handle to a reset event that the sequence should track. This event should be triggered on
  // each change of reset state and the associated data should be a reset_edge_item giving the new
  // value of the rst_n line.
  //
  // Call this before starting the sequence.
  extern function void set_reset_event(uvm_event reset_event);

  // Set the number of times to repeat the CSR access sequence if there is no reset seen. If this is
  // zero, the CSR access sequence will be repeated indefinitely (until a reset).
  extern function void set_csr_seq_scaling(int unsigned scaling);

  // Return true if the given uvm_reg_block has at least one memory that is readable and writeable.
  extern local function static bit has_usable_memory(uvm_reg_block blk);

  // Wait until m_reset_event is triggered with data showing that the tracked interface has entered
  // reset.
  extern local task wait_for_reset();

  // Run a CSR access sequence once, writing 1 to the early_stop output argument if the sequence
  // stopped early (because of an injected reset or the sequence was stopped forcefully).
  extern local task run_csr_access_seq(output bit early_stop);

  // Run one or more iterations of a CSR access sequence, stopping early on an injected reset or if
  // one of those sequences was stopped forcefully.
  extern local task run_csr_access_iterations();
endclass

function ahb_csr_mem_rw_vseq::new(string name="");
  super.new(name);
endfunction

task ahb_csr_mem_rw_vseq::pre_start();
  super.pre_start();

  if (m_sequencer == null) `uvm_fatal(get_full_name(), "No AHB sequencer.")
  if (m_rals.size() == 0) `uvm_fatal(get_full_name(), "No register block.")
  if (m_subordinate_mappings.size() == 0) `uvm_fatal(get_full_name(), "No subordinate mappings.")
  if (m_reset_event == null) `uvm_fatal(get_full_name(), "No reset_event provided.")
endtask

task ahb_csr_mem_rw_vseq::body();
  fork : isolation_fork begin
    // Run one or more CSR read/write sequences in the background.
    fork begin
      run_csr_access_iterations();
    end join_none

    // Iterate over the register blocks. For each with a usable memory for mem_rw_vseq, start one of
    // those sequences.
    foreach (m_rals[i]) begin
      ahb_mem_rw_seq mem_seq;

      if (!has_usable_memory(m_rals[i])) continue;

      mem_seq = ahb_mem_rw_seq::type_id::create("mem_seq");
      mem_seq.set_ral(m_rals[i]);
      mem_seq.set_subordinates(m_subordinate_mappings);

      fork begin
        mem_seq.start(m_sequencer);
      end join_none
    end

    // At this point, we have started a csr_rw_seq and may have started multiple ahb_mem_rw_seq
    // sequences. Wait for them to complete.
    wait fork;
  end join
endtask

function void ahb_csr_mem_rw_vseq::add_ral(uvm_reg_block ral);
  m_rals.push_back(ral);
endfunction

function void ahb_csr_mem_rw_vseq::set_subordinates(const ref sub_addr_range_t mappings[$]);
  m_subordinate_mappings.delete();
  foreach (mappings[i]) begin
    m_subordinate_mappings.push_back(mappings[i]);
  end
endfunction

function void ahb_csr_mem_rw_vseq::set_external_checker(bit external_checker);
  m_external_checker = external_checker;
endfunction

function void ahb_csr_mem_rw_vseq::set_ahb_sequencer(ahb_txn_sequencer_t sequencer);
  m_sequencer = sequencer;
endfunction

function void ahb_csr_mem_rw_vseq::set_reset_event(uvm_event reset_event);
  m_reset_event = reset_event;
endfunction

function void ahb_csr_mem_rw_vseq::set_csr_seq_scaling(int unsigned scaling);
  m_csr_seq_scaling = scaling;
endfunction

function static bit ahb_csr_mem_rw_vseq::has_usable_memory(uvm_reg_block blk);
  uvm_mem mems[$];
  blk.get_memories(mems);
  foreach (mems[i]) begin
    if (!(mems[i].get_access() inside {"RO", "WO"})) return 1;
  end
  return 0;
endfunction

task ahb_csr_mem_rw_vseq::wait_for_reset();
  forever begin
    uvm_object                       event_item;
    reset_agent_pkg::reset_edge_item edge_item;

    m_reset_event.wait_trigger_data(event_item);
    if (!$cast(edge_item, event_item)) begin
      `uvm_fatal(get_full_name(), "Reset event was triggered with no reset_edge_item attached.")
    end

    // The edge item shows that a reset has been asserted if m_new_state (the tracked rst_n signal)
    // is zero.
    if (edge_item.m_new_state == 0) break;
  end
endtask

task ahb_csr_mem_rw_vseq::run_csr_access_seq(output bit early_stop);
  csr_rw_seq csr_seq = csr_rw_seq::type_id::create("csr_seq");
  bit        saw_reset;

  foreach (m_rals[i]) begin
    dv_base_reg_block dv_blk;
    if ($cast(dv_blk, m_rals[i])) begin
      csr_seq.models.push_back(dv_blk);
    end
  end

  if (csr_seq.models.size() == 0) begin
    `uvm_fatal(get_full_name(),
               "Could not run csr_rw_seq because no register block is a dv_base_reg_block.")
  end

  csr_seq.external_checker = m_external_checker;

  fork : isolation_fork begin
    fork
      csr_seq.start(null);
      begin
        wait_for_reset();
        saw_reset = 1;
        wait(0);
      end
    join_any

    // The only process that can complete is csr_seq. Disable the other one.
    disable fork;
  end join

  // At this point, the run of csr_seq has completed. Have we seen a reset, or was the sequence
  // forcibly stopped?
  early_stop = saw_reset || csr_seq.get_sequence_state() == UVM_STOPPED;
endtask

task ahb_csr_mem_rw_vseq::run_csr_access_iterations();
  for (int unsigned iteration = 0;
       (iteration < m_csr_seq_scaling) || (m_csr_seq_scaling == 0);
       iteration++) begin
    bit early_stop;
    run_csr_access_seq(early_stop);
    if (early_stop) break;
  end
endtask
