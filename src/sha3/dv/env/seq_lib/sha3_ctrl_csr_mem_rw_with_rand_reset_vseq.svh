// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// An virtual sequence that runs multiple iterations of sha3_ctrl_stress_all_vseq in conjunction
// with rand_reset_vseq (which will cause a reset to interrupt each iteration).
//
// To use this sequence:
//
//    - Use set_reset_sequencer() to supply the sequencer that the reset sequence should use (as
//      required by the base class).
//
//    - Use set_subordinates() to supply a mapping from address to subordinate index.
//
//    - Set a reset event, to allow "main_sequence" to tell when a reset has been applied (so it
//      should not start any more CSR sequences). Note that *this* sequence can spot resets by
//      looking at cfg.clk_rst_if, but wiring it up like this is easier than re-implementing a
//      monitor in the sequence. Set the reset event by calling set_reset_event().

class sha3_ctrl_csr_mem_rw_with_rand_reset_vseq extends sha3_ctrl_rand_reset_vseq;
  `uvm_object_utils(sha3_ctrl_csr_mem_rw_with_rand_reset_vseq)

  // An array of known mappings from address range to subordinate index. Set this with
  // set_subordinates.
  local sub_addr_range_t m_subordinate_mappings[$];

  // An event that is triggered when the block changes reset state (either entering or leaving
  // reset). Set this with set_reset_event().
  local uvm_event m_reset_event;

  extern function new(string name="");
  extern task pre_start();

  // Set the subordinate mapping array
  //
  // Call this to configure the sequence before starting it.
  extern function void set_subordinates(const ref sub_addr_range_t mappings[$]);

  // Set the event that tells the sequence about a reset that was applied
  extern function void set_reset_event(uvm_event reset_event);

  // Create, configure and randomise the sequence that will be run (and then interrupted by a
  // reset).
  //
  // This overrides sha3_ctrl_rand_reset_vseq::create_main_sequence and supplies an
  // ahb_csr_mem_rw_vseq.
  extern protected function uvm_sequence create_main_sequence();
endclass

function sha3_ctrl_csr_mem_rw_with_rand_reset_vseq::new(string name="");
  super.new(name);

  // As a maximum delay before reset, let's give time for 25 register accesses, giving each 2
  // cycles.
  m_max_reset_delay_cycles = 50;
endfunction

task sha3_ctrl_csr_mem_rw_with_rand_reset_vseq::pre_start();
  super.pre_start();
  if (m_subordinate_mappings.size() == 0) `uvm_fatal(get_full_name(), "No subordinate mappings.")
  if (m_reset_event == null) `uvm_fatal(get_full_name(), "No reset_event provided.")
endtask

function void
  sha3_ctrl_csr_mem_rw_with_rand_reset_vseq::
    set_subordinates(const ref sub_addr_range_t mappings[$]);

  m_subordinate_mappings.delete();
  foreach (mappings[i]) begin
    m_subordinate_mappings.push_back(mappings[i]);
  end
endfunction

function void sha3_ctrl_csr_mem_rw_with_rand_reset_vseq::set_reset_event(uvm_event reset_event);
  m_reset_event = reset_event;
endfunction

function uvm_sequence sha3_ctrl_csr_mem_rw_with_rand_reset_vseq::create_main_sequence();
  ahb_csr_mem_rw_vseq mem_rw_vseq;

  mem_rw_vseq = ahb_csr_mem_rw_vseq::type_id::create("mem_rw_vseq");

  mem_rw_vseq.add_ral(ral.kmac_core);
  mem_rw_vseq.set_ahb_sequencer(m_ahb_sequencer);
  mem_rw_vseq.set_subordinates(m_subordinate_mappings);
  mem_rw_vseq.set_reset_event(m_reset_event);

  // Scaling up by 25 means that we'll run through the CSRs 25 times. Even if there is only 1 CSR,
  // this should be guaranteed to complete before m_max_reset_delay_cycles (which has time for 25
  // register accesses).
  mem_rw_vseq.set_csr_seq_scaling(10);

  if (!mem_rw_vseq.randomize()) `uvm_fatal(get_full_name(), "Failed to randomise vseq.")

  return mem_rw_vseq;
endfunction
