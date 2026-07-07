// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A virtual sequence that repeatedly reads and writes the given register back-to-back several
// times, checking that the results are as expected.
//
// This virtual sequence will run the register read and write operations on an AHB sequencer, which
// should be used as the sequencer for it.
//
// This uses registers from a dv_base_reg_block register model, which is assumed to be kept up to
// date by a scoreboard or uvm_reg_predictor and also to have exclusion flags that might exclude the
// R/W operations that we will perform.
class ahb_one_csr_outstanding_vseq extends uvm_sequence #(ahb_txn_request_item, ahb_status_item);

  `uvm_object_utils(ahb_one_csr_outstanding_vseq)
  `uvm_declare_p_sequencer(ahb_txn_sequencer_t)

  // The register to access. Set this by calling set_csr_and_subordinate() before starting the
  // sequence.
  local dv_base_reg m_csr;

  // If this flag is set, all AHB transactions will use the smallest hsize that contains all the
  // bits of the CSR. This is necessary if the environment (or possibly the RTL) doesn't support
  // partial accesses.
  //
  // Set this with set_only_full_accesses().
  local bit m_only_full_accesses;

  // If this flag is set, AHB write transactions will use the maximum HWSTRB possible for their
  // HSIZE. Set this with set_use_full_wstrb().
  local bit m_use_full_wstrb;

  // The index of the subordinate to use for the transactions. Set this by calling
  // set_csr_and_subordinate() before starting the sequence.
  local int unsigned m_subordinate_idx;

  // A flag that gets set when the final read/write sequence for the register sends its last AHB
  // request. Wait for this with wait_for_last_request.
  local bit          m_sent_last_request;

  // A flag that might gate the decision to perform a register read. This can be configured with
  // set_allowed_operations().
  local bit          m_allow_read;

  // A flag that might gate the decision to perform a register write. This can be configured with
  // set_allowed_operations.
  local bit          m_allow_write;

  // The number of read/write sequences to run on the register.
  rand int unsigned  m_num_iterations;

  extern function new(string name="");
  extern task body();

  // Set the register to access and the subordinate index
  extern function void set_csr_and_subordinate(dv_base_reg csr, int unsigned subordinate_idx);

  // Set the m_only_full_accesses flag, meaning that all AHB transactions will use an hsize that
  // covers the entire CSR.
  extern function void set_only_full_accesses();

  // Set the m_use_full_wstrb flag, meaning that all AHB write transactions will use an HWSTRB that
  // covers all of the bytes visible with HSIZE.
  extern function void set_use_full_wstrb();

  // Configure whether this sequence is allowed to read/write the register
  extern function void set_allowed_operations(bit allow_read, bit allow_write);

  // Wait until the final AHB transaction for the register is sent (or a reset is asserted, if that
  // happens first).
  //
  // The task allows running several CSRs back-to-back with no gap between different runs of this
  // virtual sequence.
  extern task wait_for_last_request();

  // Start a single iteration, writing its underlying sequence to the seq output argument. Returns
  // as soon as the sequence has started (waiting with its wait_to_start task)
  extern local task start_iteration(output ahb_read_write_seq seq);

  // Constrain the number of iterations for the register to 2..20
  extern constraint num_iterations_c;
endclass

function ahb_one_csr_outstanding_vseq::new(string name="");
  super.new(name);
endfunction

task ahb_one_csr_outstanding_vseq::body();
  bit seen_reset;

  if (m_csr == null) `uvm_fatal(get_full_name(), "Register not set before calling start.")
  if (p_sequencer == null) `uvm_fatal(get_full_name(), "Sequencer not set before calling start.")

  `uvm_info(get_full_name(),
            $sformatf("Running %0d back-to-back read/write pairs for register %0s.",
                      m_num_iterations, m_csr.get_full_name()),
            UVM_MEDIUM)

  fork : isolation_fork begin
    for (int unsigned i = 0; i < m_num_iterations && !seen_reset; i++) begin
      ahb_read_write_seq seq;
      bit [1023:0]       rdata_mask_from_size;
      uvm_reg_data_t     rdata_mask_from_ral;

      `uvm_info(get_full_name(),
                $sformatf({"Starting iteration %0d/%0d for ",
                           "read/write outstanding vseq with register %0s"},
                          i + 1, m_num_iterations, m_csr.get_full_name()),
                UVM_HIGH)

      start_iteration(seq);

      // At this point, seq has started its first operation, which might be a register read. If so,
      // we know that any write to the register has completed and a uvm_reg_predictor will have
      // updated a prediction of the register value. Call set_expected_rdata with the prediction:
      // this way, we get in before that first operation completes.
      rdata_mask_from_size = (1024'd1 << (8 << seq.m_read_size)) - 1;
      rdata_mask_from_ral  = m_csr.get_csr_test_mask(dv_base_reg_pkg::CsrExclWriteCheck,
                                                     dv_base_reg_pkg::CsrRwTest);

      seq.set_expected_rdata(m_csr.get_mirrored_value(),
                             rdata_mask_from_size & rdata_mask_from_ral);

      // Watch the sequence continue until the final request that it will send
      seq.wait_for_last_request();

      // If this is the final iteration, we have just sent the last request for this vseq.
      if (i == m_num_iterations - 1) begin
        m_sent_last_request = 1;
      end

      fork begin
        // Wait for the sequence to stop or actually run to completion.
        seq.wait_for_sequence_state(UVM_STOPPED | UVM_FINISHED);

        // At this point, seq is finished. Did it exit early because of a reset? If so, set
        // seen_reset. This will stop the loop from starting any more items: it will have only
        // started the one directly after this one.
        if (seq.rsp == null || !seq.rsp.m_sending_complete) begin
          seen_reset = 1;
        end
      end join_none
    end

    // Now that the loop has finished, we have either sent the last AHB request from our final
    // planned iteration or we have seen a reset at some earlier point. If the latter,
    // m_sent_last_request won't yet be set: set it now.
    m_sent_last_request = 1;

    // Wait until the final iteration has actually finished.
    wait fork;
  end join

  // At this point, we have finished sending things if seen_reset is false.
  rsp = ahb_status_item::type_id::create("rsp");
  rsp.m_sending_complete = !seen_reset;
  put_response(rsp);
endtask

function void ahb_one_csr_outstanding_vseq::set_csr_and_subordinate(dv_base_reg csr,
                                                                    int unsigned subordinate_idx);
  m_csr = csr;
  m_subordinate_idx = subordinate_idx;
endfunction

function void ahb_one_csr_outstanding_vseq::set_only_full_accesses();
  m_only_full_accesses = 1;
endfunction

function void ahb_one_csr_outstanding_vseq::set_use_full_wstrb();
  m_use_full_wstrb = 1;
endfunction

function void ahb_one_csr_outstanding_vseq::set_allowed_operations(bit allow_read, bit allow_write);
  m_allow_read  = allow_read;
  m_allow_write = allow_write;
endfunction

task ahb_one_csr_outstanding_vseq::wait_for_last_request();
  wait(m_sent_last_request);
endtask

task ahb_one_csr_outstanding_vseq::start_iteration(output ahb_read_write_seq seq);
  bit [1023:0] write_mask = m_csr.get_csr_test_mask(dv_base_reg_pkg::CsrExclWrite,
                                                    dv_base_reg_pkg::CsrRwTest);
  bit [63:0]   csr_addr = m_csr.get_offset();

  // The register should be thought of as a block of bits with indices 0..msb, where msb can be
  // found by m_csr.get_msb_pos(). This is m_csr.get_msb_pos()+1 bits, which needs
  // ((m_csr.get_msb_pos() + 1) + 7) / 8 bytes to represent it.
  int unsigned register_size_bytes = (m_csr.get_msb_pos() + 8) / 8;

  int unsigned max_hsize = $clog2(register_size_bytes);

  seq = ahb_read_write_seq::type_id::create("seq");

  // If m_csr is a shadowed register, tell seq to double-write it.
  if (m_csr.get_is_shadowed()) begin
    seq.set_double_write();
  end

  if (m_use_full_wstrb) seq.set_use_full_wstrb();

  if (!seq.randomize() with {
        m_addr == local::csr_addr;
        m_subordinate_idx == local::m_subordinate_idx;
        if (local::m_only_full_accesses) {
          m_read_size == local::max_hsize;
          m_write_size == local::max_hsize;
        } else {
          m_read_size <= local::max_hsize;
          m_write_size <= local::max_hsize;
        }
        if (!local::m_allow_read) {
          m_do_read == 0;
        }
        if (!local::m_allow_write) {
          m_do_write == 0;
        }
        |(m_wdata & ~write_mask) == 0;
      }) begin
    `uvm_error(get_full_name(), "Failed to randomise read_write sequence.")
    seq.kill();
    return;
  end

  // Start seq running, using join_none (wrapped in an isolation fork in the body task)
  fork seq.start(p_sequencer); join_none

  // Now wait until seq starts its first item
  seq.wait_for_first_request();
endtask

constraint ahb_one_csr_outstanding_vseq::num_iterations_c {
  2 <= m_num_iterations;
  m_num_iterations <= 20;
}
