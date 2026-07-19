// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A sequence that sends multiple randomised reads and writes to the memory windows visible through
// a uvm_reg_block.
//
// To use it:
//
//    - Pass a uvm_reg_block that has at least one RW memory, using set_ral().
//
//    - Tell the sequence about the mapping from address to subordinate index using
//      set_subordinates().
//
//    - To perform more rounds of accesses, call set_num_rounds.
//
//    - Start the sequence on an AHB sequencer. When the sequence completes, the rsp field will have
//      m_sending_complete=1 if all the transactions ran to completion and m_sending_complete=0 if
//      the sequence was aborted by calling abort() or by a reset being asserted.

class ahb_mem_rw_seq extends uvm_sequence #(ahb_txn_request_item, uvm_sequence_item);
  `uvm_object_utils(ahb_mem_rw_seq)
  `uvm_declare_p_sequencer(ahb_txn_sequencer_t)

  // The register model to use. Set this by calling set_ral() before starting the sequence.
  local uvm_reg_block m_ral;

  // An array of known mappings from address range to subordinate index. Set this with
  // set_subordinates.
  local sub_addr_range_t m_subordinate_mappings[$];

  // The minimum number of memory accesses to make. This is a lower bound used when the memory is
  // small. Set it by calling set_num_accesses_range().
  local int unsigned m_min_accesses = 100;

  // The maximum number of memory accesses to make. This is an upper bound used when the memory is
  // large. Set it by calling set_num_accesses_range().
  local int unsigned m_max_accesses = 100_000;

  // The number of rounds of memory accesses to make. Set it by calling set_num_rounds().
  local int unsigned m_num_rounds = 1;

  // A flag that will cause the sequence not to start any more transfer sequences (and to finish
  // soon). This is set if one of the child sequences doesn't complete a transfer.
  local bit m_abort;

  // An associative array that tracks which (4-byte aligned) byte addresses have seen a 32-bit
  // write, and what value was written.
  local bit [31:0] m_written_values[bit [63:0]];

  extern function new(string name="");
  extern task body();

  // Set the register block to use.
  //
  // Call this to configure the sequence before starting it.
  extern function void set_ral(uvm_reg_block ral);

  // Set the subordinate mapping array
  //
  // Call this to configure the sequence before starting it.
  extern function void set_subordinates(const ref sub_addr_range_t mappings[$]);

  // Set a range for how many memory accesses to make. The number of accesses made will be the
  // number of 32-bit words across the memories, clamped to this range.
  extern function void set_num_accesses_range(int unsigned min_accesses,
                                              int unsigned max_accesses);

  // Set the number of rounds that the number of accesses implied by the memory size will be
  // performed. This allows a test to access the memory more, but in a way that scales with the size
  // of the memory (so that things stay nicely balanced if there are multiple uvm_reg_block
  // instances and these have differently sized memories).
  extern function void set_num_rounds(int unsigned rounds);

  // Start a transaction that writes to a location in mem.
  //
  // When the sequence has started, it is written to the seq output argument and the address that it
  // will write is written to the addr output argument.
  extern local task start_write(uvm_mem                 mem,
                                output ahb_transfer_seq seq,
                                output bit [63:0]       addr,
                                output bit [31:0]       wdata);

  // Start a transaction that reads from a location that has been written.
  //
  // When the sequence has started, it is written to the seq output argument and the address that it
  // will read is written to the addr output argument.
  extern local task start_read(output ahb_transfer_seq seq,
                               output bit [63:0]       addr);
endclass

function ahb_mem_rw_seq::new(string name="");
  super.new(name);
endfunction

task ahb_mem_rw_seq::body();
  // The memories accessible through m_ral
  uvm_mem mems[$];

  // The memories accessible through m_ral that can be used for a RW test (a subset of mems)
  uvm_mem usable_mems[$];

  // The total number of usable 32-bit words across the memories.
  int unsigned num_usable_words;

  // The number of memory accesses to make.
  int unsigned num_accesses;

  // The number of transactions that have been started in the loop below and have not yet finished.
  // Because AHB doesn't support pipelining, the loop is constructed so that this never goes above
  // 2.
  int unsigned num_pending_accesses;

  if (m_ral == null) `uvm_fatal(get_full_name(), "ral not set before calling start.")
  if (p_sequencer == null) `uvm_fatal(get_full_name(), "Sequencer not set before calling start.")
  if (m_subordinate_mappings.size() == 0) `uvm_fatal(get_full_name(), "No subordinate mappings.")

  // Get the list of memories from m_ral
  m_ral.get_memories(mems);

  // Now filter these for usable memories and count their total size.
  foreach (mems[i]) begin
    int unsigned usable_word_size = 0;
    if (!(mems[i].get_access() inside {"RO", "WO"})) begin
      usable_word_size = (mems[i].get_size() * mems[i].get_n_bytes()) / 4;
      usable_mems.push_back(mems[i]);
    end
    num_usable_words += usable_word_size;
  end

  // If we haven't found any usable words, we can't run this sequence: it depends on writing
  // values and then reading them back.
  if (num_usable_words == 0) begin
    `uvm_error(get_full_name(), "Can't run sequence: block has no nonempty usable memories.")
    return;
  end

  // Choose how many memory accesses to make per round. By default, this will be equal to the number
  // of word addresses across the memories, but clamped to lie in [m_min_accesses, m_max_accesses].
  num_accesses = num_usable_words;
  if (num_accesses < m_min_accesses) num_accesses = m_min_accesses;
  if (num_accesses > m_max_accesses) num_accesses = m_max_accesses;

  // Now scale num_accesses up by the number of rounds.
  num_accesses *= m_num_rounds;

  `uvm_info(get_full_name(),
            $sformatf("Will read/write the memory with %0d accesses.", num_accesses),
            UVM_HIGH)

  fork : isolation_fork begin
    repeat (num_accesses) begin
      // Wait until there is at most one transaction currently being sent. That way, we can queue up
      // the next access to run immediately after it without generating an enormous backlog.
      wait (num_pending_accesses < 2);

      if (m_abort) break;

      num_pending_accesses++;

      // Start a read from or a write to memory.
      randcase
        // Write
        1: begin
          ahb_transfer_seq seq;
          int unsigned     mem_idx = $urandom_range(0, usable_mems.size() - 1);
          bit [63:0]       addr;
          bit [31:0]       wdata;

          start_write(usable_mems[mem_idx], seq, addr, wdata);

          // Now that the write has started, fork off a process that will complete the transaction
          // and then should write the value to m_written_values.
          fork begin
            seq.wait_for_sequence_state(UVM_STOPPED | UVM_FINISHED);

            if (!seq.has_full_transaction()) begin
              // The sequence did not run to completion. Set m_abort to avoid starting any more
              // sequences.
              m_abort = 1;
            end else begin
              // The sequence ran to completion. Look at the last response, which will be the
              // response to the only non-busy data transfer that we sent.
              ahb_txn_response_item last_rsp = seq.m_responses[seq.m_responses.size() - 1];

              // Check that m_resp was false (so the memory didn't respond with an error)
              if (last_rsp.m_resp) begin
                `uvm_error(get_full_name(),
                           $sformatf("Error response when writing to address 0x%0h", addr))
              end

              // Update m_written_values
              m_written_values[addr] = wdata;
            end

            num_pending_accesses--;
          end join_none
        end

        // Read
        m_written_values.size() != 0: begin
          ahb_transfer_seq seq;
          bit [63:0]       addr;

          start_read(seq, addr);

          // Now that the read has started, fork off a process that will complete the transaction.
          fork begin
            seq.wait_for_sequence_state(UVM_STOPPED | UVM_FINISHED);

            if (!seq.has_full_transaction()) begin
              // The sequence did not run to completion. Set m_abort to avoid starting any more
              // sequences.
              m_abort = 1;
            end else begin
              // The sequence ran to completion. Look at the last response, which will be the
              // response to the only non-busy data transfer that we sent.
              ahb_txn_response_item last_rsp = seq.m_responses[seq.m_responses.size() - 1];

              // Check that m_resp was false (so the memory didn't respond with an error)
              if (last_rsp.m_resp) begin
                `uvm_error(get_full_name(),
                           $sformatf("Error response when reading from address 0x%0h", addr))
              end

              // Check that m_rdata matched the last value we wrote to that address
              if (last_rsp.m_rdata != m_written_values[addr]) begin
                `uvm_error(get_full_name(),
                           $sformatf({"Reading from address 0x%0h returned 0x%0h, but ",
                                      "the last value written was 0x%0h."},
                                     addr, last_rsp.m_rdata, m_written_values[addr]))
              end
            end

            num_pending_accesses--;
          end join_none
        end
      endcase
    end

    // At this point, there may still be up to two sequences running. Use wait fork to wait for them
    // to complete.
    wait fork;
  end join

  // Before returning, create an ahb_status_item in rsp to report whether everything ran to
  // completion. If it didn't, m_abort will have been set.
  begin
    ahb_status_item status_rsp = ahb_status_item::type_id::create("rsp");
    status_rsp.m_sending_complete = !m_abort;
    rsp = status_rsp;
  end
endtask

function void ahb_mem_rw_seq::set_ral(uvm_reg_block ral);
  m_ral = ral;
endfunction

function void
  ahb_mem_rw_seq::set_subordinates(const ref sub_addr_range_t mappings[$]);

  m_subordinate_mappings.delete();
  foreach (mappings[i]) begin
    m_subordinate_mappings.push_back(mappings[i]);
  end
endfunction

function void ahb_mem_rw_seq::set_num_accesses_range(int unsigned min_accesses,
                                                     int unsigned max_accesses);
  if (max_accesses < min_accesses) begin
    `uvm_fatal(get_full_name(),
               $sformatf("Cannot set access range with minimum (%0d) > maximum (%0d)",
                         min_accesses, max_accesses))
  end

  m_min_accesses = min_accesses;
  m_max_accesses = max_accesses;
endfunction

function void ahb_mem_rw_seq::set_num_rounds(int unsigned rounds);
  if (rounds == 0) begin
    `uvm_fatal(get_full_name(), "The number of rounds cannot be zero.")
  end

  m_num_rounds = rounds;
endfunction

task ahb_mem_rw_seq::start_write(uvm_mem                 mem,
                                 output ahb_transfer_seq seq,
                                 output bit [63:0]       addr,
                                 output bit [31:0]       wdata);
  ahb_single_write_seq write_seq;
  uvm_reg_addr_t       min_addr = mem.get_address();
  uvm_reg_addr_t       max_addr = min_addr + mem.get_size() * mem.get_n_bytes() - 1;
  int unsigned         sub_idx;

  // Choose an address in the memory.
  //
  // Because the AHB-lite interface in caliptra-rtl only supports HSIZE=2 (except for a couple of
  // special-case memories), this address is chosen to be naturally aligned.
  if (!std::randomize(addr) with {
         min_addr <= addr;
         addr <= max_addr;
         addr % 4 == 0;
       }) begin
    `uvm_fatal(get_full_name(), "Failed to randomise write address.")
  end

  // Randomise the data to be written
  if (!std::randomize(wdata)) `uvm_fatal(get_full_name(), "Failed to randomise wdata.")

  // Get the index of the subordinate for that address
  if (!ahb_agent_pkg::get_subordinate_for_addr(addr, m_subordinate_mappings, sub_idx)) begin
    `uvm_fatal(get_full_name(), $sformatf("No subordinate for address 0x%0h.", addr))
  end

  write_seq = ahb_agent_pkg::ahb_single_write_seq::type_id::create("seq");

  if (!write_seq.randomize() with {
         m_subordinate_idx == sub_idx;
         m_size            == 2;
         m_addr            == local::addr;
         m_wdata           == local::wdata;
         m_wstrb           == 'b1111;
       }) begin
    `uvm_fatal(get_full_name(), "Failed to randomise write sequence.")
  end

  // Start the sequence and wait until its first (and only) request gets sent.
  seq = write_seq;
  fork
    seq.start(p_sequencer);
    seq.wait_for_first_request();
  join_any
endtask

task ahb_mem_rw_seq::start_read(output ahb_transfer_seq seq,
                                output bit [63:0]       addr);
  int unsigned sub_idx;

  // Pick the address to read.
  //
  // Annoyingly, "addr inside {m_written_values.keys()}" doesn't work with the default settings that
  // we use for some EDA tools. Instead, pick an offset into the list of keys and use next() that
  // many times.
  int unsigned idx_of_addr = $urandom_range(0, m_written_values.size() - 1);
  if (!m_written_values.first(addr)) `uvm_fatal(get_full_name(), "No first written value")
  repeat (idx_of_addr) begin
    if (!m_written_values.next(addr)) `uvm_fatal(get_full_name(), "Can't step written value addr.")
  end

  // Get the index of the subordinate for that address
  if (!ahb_agent_pkg::get_subordinate_for_addr(addr, m_subordinate_mappings, sub_idx)) begin
    `uvm_fatal(get_full_name(), $sformatf("No subordinate for address 0x%0h.", addr))
  end

  seq = ahb_single_read_seq::type_id::create("seq");

  if (!seq.randomize() with {
         m_subordinate_idx == sub_idx;
         m_size            == 2;
         m_addr            == local::addr;
       }) begin
    `uvm_fatal(get_full_name(), "Failed to randomise read sequence.")
  end

  fork
    seq.start(p_sequencer);
    seq.wait_for_first_request();
  join_any
endtask
