// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A virtual sequence that repeatedly reads and writes registers back-to-back, checking that the
// results are as expected.
//
// This virtual sequence will run the register read and write operations on an AHB sequencer, which
// should be used as the sequencer for it.
//
// This uses registers from a dv_base_reg_block register model, which is assumed to be kept up to
// date by a scoreboard or uvm_reg_predictor and also to have exclusion flags that might exclude the
// R/W operations that we will perform.
class ahb_same_csr_outstanding_vseq extends uvm_sequence #(ahb_txn_request_item, ahb_status_item);
  `uvm_object_utils(ahb_same_csr_outstanding_vseq)
  `uvm_declare_p_sequencer(ahb_txn_sequencer_t)

  // The register model to use. Set this by calling set_ral() before starting the sequence.
  local dv_base_reg_block m_ral;

  // An array of known mappings from address range to subordinate index. Set this with
  // set_subordinates.
  local sub_addr_range_t m_subordinate_mappings[$];

  // If this flag is set, all AHB transactions will use the smallest hsize that contains all the
  // bits of the CSR. This is necessary if the environment (or possibly the RTL) doesn't support
  // partial accesses.
  //
  // Set this with set_only_full_accesses().
  local bit m_only_full_accesses;

  // If this flag is set, AHB write transactions will use the maximum HWSTRB possible for their
  // HSIZE. Set this with set_use_full_wstrb().
  local bit m_use_full_wstrb;

  extern function new(string name="");
  extern task body();

  // Set the register model to use.
  //
  // Call this to configure the sequence before starting it.
  extern function void set_ral(dv_base_reg_block ral);

  // Set the subordinate mapping array
  //
  // Call this to configure the sequence before starting it.
  extern function void set_subordinates(const ref sub_addr_range_t mappings[$]);

  // Set the m_only_full_accesses flag, meaning that all AHB transactions will use an hsize that
  // covers the entire CSR.
  extern function void set_only_full_accesses();

  // Set the m_use_full_wstrb flag, meaning that all AHB write transactions will use an HWSTRB that
  // covers all of the bytes visible with HSIZE.
  extern function void set_use_full_wstrb();

  // Start an ahb_one_csr_outstanding_vseq and wait until its last iteration has started. Write that
  // sequence to the seq output argument.
  //
  // The test can only send reads if allow_read is true. Similarly, it only sends writes if
  // allow_writes is true.
  extern local task start_csr(dv_base_reg                         csr,
                              bit                                 allow_read,
                              bit                                 allow_write,
                              output ahb_one_csr_outstanding_vseq seq);
endclass

function ahb_same_csr_outstanding_vseq::new(string name="");
  super.new(name);
endfunction

task ahb_same_csr_outstanding_vseq::body();
  dv_base_reg csrs[$];
  bit         seen_reset;

  if (m_ral == null) `uvm_fatal(get_full_name(), "ral not set before calling start.")
  if (p_sequencer == null) `uvm_fatal(get_full_name(), "Sequencer not set before calling start.")

  m_ral.get_dv_base_regs(csrs);
  csrs.shuffle();

  fork : isolation_fork begin
    foreach (csrs[i]) begin
      import dv_base_reg_pkg::CsrExclWriteCheck, dv_base_reg_pkg::CsrExclWrite;
      import dv_base_reg_pkg::CsrRwTest;
      import csr_utils_pkg::reg_is_excluded;

      ahb_one_csr_outstanding_vseq seq;

      bit read_excluded  = reg_is_excluded(csrs[i], CsrExclWriteCheck, CsrRwTest);
      bit write_excluded = reg_is_excluded(csrs[i], CsrExclWrite, CsrRwTest);

      if (read_excluded && write_excluded) begin
        `uvm_info(get_full_name(),
                  $sformatf({"Skipping register %0s: it has both ",
                             "CsrExclWriteCheck and CsrExclWrite."},
                            csrs[i].get_full_name()),
                  UVM_HIGH)
        continue;
      end

      start_csr(csrs[i], !read_excluded, !write_excluded, seq);

      // If start_csr failed to even *create* the sequence, skip over this register. If the
      // uvm_error didn't stop the simulation, there's no reason we can't continue.
      if (seq == null) continue;

      fork begin
        // Now wait for the sequence to stop or actually run to completion.
        seq.wait_for_sequence_state(UVM_STOPPED | UVM_FINISHED);

        // seq is now finished. Did it exit early because of a reset, or fail to start at all? If
        // so, set seen_reset, which will stop the loop from starting any more items.
        if (seq.rsp == null || !seq.rsp.m_sending_complete) begin
          seen_reset = 1;
        end
      end join_none

      if (seen_reset) break;
    end

    // If the loop has finished, we have started all the CSRs. In fact, we've finished all but
    // possibly the last. Wait until that is complete too.
    wait fork;
  end join

  // At this point, we have finished sending things if seen_reset is false.
  rsp = ahb_status_item::type_id::create("rsp");
  rsp.m_sending_complete = !seen_reset;
  put_response(rsp);
endtask

function void ahb_same_csr_outstanding_vseq::set_ral(dv_base_reg_block ral);
  m_ral = ral;
endfunction

function void
  ahb_same_csr_outstanding_vseq::set_subordinates(const ref sub_addr_range_t mappings[$]);

  m_subordinate_mappings.delete();
  foreach (mappings[i]) begin
    m_subordinate_mappings.push_back(mappings[i]);
  end
endfunction

function void ahb_same_csr_outstanding_vseq::set_only_full_accesses();
  m_only_full_accesses = 1;
endfunction

function void ahb_same_csr_outstanding_vseq::set_use_full_wstrb();
  m_use_full_wstrb = 1;
endfunction

task ahb_same_csr_outstanding_vseq::start_csr(dv_base_reg                         csr,
                                              bit                                 allow_read,
                                              bit                                 allow_write,
                                              output ahb_one_csr_outstanding_vseq seq);
  int unsigned sub_idx;

  if (!ahb_agent_pkg::get_subordinate_for_addr(csr.get_offset(),
                                               m_subordinate_mappings,
                                               sub_idx)) begin
    `uvm_error(get_full_name(),
               $sformatf("No subordinate in the mapping for address 0x%0h (register %0s)",
                         csr.get_offset(), csr.get_full_name()))
    return;
  end

  seq = ahb_one_csr_outstanding_vseq::type_id::create("seq");
  seq.set_csr_and_subordinate(csr, sub_idx);
  if (m_only_full_accesses) seq.set_only_full_accesses();
  if (m_use_full_wstrb) seq.set_use_full_wstrb();
  seq.set_allowed_operations(allow_read, allow_write);

  if (!seq.randomize()) begin
    `uvm_fatal(get_full_name(), "Failed to randomize seq.")
  end

  // Start seq running, using join_none (wrapped in an isolation fork in the body task)
  fork seq.start(p_sequencer); join_none

  // Wait until seq sends its final AHB request.
  seq.wait_for_last_request();
endtask
