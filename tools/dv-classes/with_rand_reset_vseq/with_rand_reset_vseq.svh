// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A virtual sequence that runs a sequence in parallel with rand_reset_seq. That first sequence is
// expected to complete in the time that the reset is asserted (so is checked to have finished by
// the time the reset sequence has completed).
//
// To use this sequence:
//
//    - Use set_reset_sequencer() to supply the sequencer that the reset sequence should use.
//
//    - Start another sequence on a sequencer in the testbench, and register it with this sequence
//      with set_main_sequence().
//
//    - Randomise and start this sequence.

class with_rand_reset_vseq extends uvm_sequence;
  `uvm_object_utils(with_rand_reset_vseq)

  // The sequencer that will be used to run the reset sequence. Set this with set_reset_sequencer.
  local reset_sequencer_t m_reset_sequencer;

  // The sequence that is running in parallel with the reset sequence
  local uvm_sequence      m_main_seq;

  // The reset sequence that this sequence will start
  rand random_reset_seq   m_reset_seq;

  extern function new(string name="");
  extern task body();

  // Set the sequencer that will be used to run the reset sequnce.
  extern function void set_reset_sequencer(reset_sequencer_t sequencer);

  // Set the main sequence that is running alongside the injected reset.
  extern function void set_main_sequence(uvm_sequence seq);
endclass

function with_rand_reset_vseq::new(string name="");
  super.new(name);
  m_reset_seq = random_reset_seq::type_id::create("m_reset_seq");
endfunction

task with_rand_reset_vseq::body();
  if (m_reset_sequencer == null) begin
    `uvm_fatal(get_full_name(), "Cannot start with_rand_reset_vseq without a reset sequencer.")
  end

  if (m_main_seq == null) begin
    `uvm_fatal(get_full_name(), "Cannot start with_rand_reset_vseq: m_main_seq is null.")
  end
  if (!(m_main_seq.get_sequence_state() inside {UVM_PRE_START, UVM_PRE_BODY,
                                                UVM_BODY, UVM_POST_BODY, UVM_POST_START})) begin
    `uvm_fatal(get_full_name(),
               $sformatf("m_main_seq is in state %0s (not in UVM_PRE_START..UVM_POST_START).",
                         m_main_seq.get_sequence_state().name()))
  end

  fork : isolation_fork begin
    fork
      m_main_seq.wait_for_sequence_state(UVM_STOPPED | UVM_FINISHED);
      m_reset_seq.start(m_reset_sequencer);
      m_reset_seq.wait_asserted();
    join_any

    if (m_main_seq.get_sequence_state() inside {UVM_STOPPED, UVM_FINISHED}) begin
      // If m_main_seq has ended and is now in state UVM_STOPPED or UVM_FINISHED, our "randomly
      // applied reset in the middle" hasn't happened yet. Print a warning and abort the wait in
      // m_reset_seq.
      `uvm_warning(get_full_name(),
                   $sformatf({"Could not inject a reset in parallel because the ",
                              "main sequence (%0s) finished too quickly."},
                             m_main_seq.get_full_name()))

      // Tell m_reset_seq to apply its reset now.
      m_reset_seq.stop_waiting();
    end

    // At this point, one possibility is that m_main_seq had finished and we have just requested
    // m_reset_seq asserts reset immediately. The other possibility is that we have seen the reset
    // be asserted (which would be excellent news!).
    //
    // Wait for m_reset_seq to finish, which means the end of reset.
    m_reset_seq.wait_for_sequence_state(UVM_STOPPED | UVM_FINISHED);

    // By this time, m_main_seq definitely should have completed (possibly as a result of the reset
    // that was just asserted).
    if (!(m_main_seq.get_sequence_state() inside {UVM_STOPPED, UVM_FINISHED})) begin
      `uvm_error(get_full_name(),
                 $sformatf("The main sequence (%0s) has not finished by the end of a reset.",
                           m_main_seq.get_full_name()))
      m_main_seq.wait_for_sequence_state(UVM_STOPPED | UVM_FINISHED);
    end

    wait fork;
  end join
endtask

function void with_rand_reset_vseq::set_reset_sequencer(reset_sequencer_t sequencer);
  m_reset_sequencer = sequencer;
endfunction

function void with_rand_reset_vseq::set_main_sequence(uvm_sequence seq);
  m_main_seq = seq;
endfunction
