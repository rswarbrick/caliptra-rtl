// Copyright lowRISC contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A sequence that sends either READ; WRITE back-to-back or some subset of those operations.
//
// If m_double_write is true (set with set_double_write()) then the write will be done twice, which
// supports shadowed registers.
//
// The interface that will be used for this sequence has an effect on the items that should be
// created:
//
//   - If set_use_full_wstrb() has been called, the m_wstrb value of each generated item is
//     constrained to exactly match the strobe for m_write_size. (This allows the item to be
//     represented if the interface doesn't have an HWSTRB signal).
//
//   - If set_has_hprot(0) has been called, the m_prot signal of each generated item is constrained
//     to equal zero (representable with no HPROT signal). Otherwise, each generated item is
//     constrained to have m_prot = 1 (which means a data access, rather than an instruction fetch).
//
// The sequence generates an ahb_status_item response, which shows whether the AHB operation(s) ran
// to completion, rather than being interrupted by a reset.

class ahb_read_write_seq extends uvm_sequence #(ahb_txn_request_item, ahb_status_item);
  `uvm_object_utils(ahb_read_write_seq)
  `uvm_declare_p_sequencer(ahb_txn_sequencer_t)

  // This bit is set when the first request is sent on the sequencer. Wait for it (once the whole
  // sequence has started) with wait_for_first_request(). This should allow back-to-back operations
  // without a vast list of running sequences.
  local bit          m_sent_first_request;

  // This bit is set when the last request is sent on the sequencer. Wait for it (once the whole
  // sequence has started) with wait_for_last_request(). This is useful to allow higher level
  // sequences to make sure two copies of this sequence run in the expected order.
  local bit          m_sent_last_request;

  // If writing a register (because m_do_write is true), write twice. This is to support shadowed
  // registers. Set this with set_double_write().
  local bit          m_double_write;

  // The value that we expect to read if we do a read operation. Set this with set_expected_rdata().
  local bit [1023:0] m_expected_rdata;

  // A mask to use when comparing rdata with m_expected_rdata. Set this with set_expected_rdata().
  local bit [1023:0] m_expected_rdata_mask;

  // If set, there is a prediction for rdata if we do a read operation. Set this by calling
  // set_expected_rdata().
  local bit          m_have_expected_rdata;

  // Set this if the AHB interface doesn't support wstrb. With this flag, m_wstrb is constrained to
  // exactly match the strobe for m_write_size. To configure this, call set_use_full_wstrb().
  local bit          m_use_full_wstrb;

  // This should only be set if the AHB interface has a positive HPROT_WIDTH (4 or 7). To configure
  // this, call set_has_hprot().
  local bit          m_has_hprot = 1;

  // The address that is used for the read and write operations.
  rand bit [63:0]    m_addr;

  // The subordinate index to use for the transactions (which will probably be dictated by m_addr)
  rand int unsigned  m_subordinate_idx;

  // Read from the address
  rand bit           m_do_read;

  // Write to the address
  rand bit           m_do_write;

  // The size to use for the read operation
  rand bit [2:0]     m_read_size;

  // The size to use for the write operation
  rand bit [2:0]     m_write_size;

  // The value to use for the write operation (this is constrained to fit in 1 << m_write_size bytes
  // by write_size_c)
  rand bit [1023:0]  m_wdata;

  // The wstrb to use for the write operation (this is constrained to fit in 1 << m_write_size bits
  // by write_size_c)
  rand bit [127:0]   m_wstrb;

  extern function new(string name="");
  extern task body();

  // After this is called, a write operation will be run twice (to correctly handle shadowed
  // registers)
  extern function void set_double_write();

  // Set a value that we expect to read if we do a read operation. This can be run after the
  // sequence starts, but will only have an effect if it runs before any read transfer completes.
  extern function void set_expected_rdata(bit [1023:0] rdata, bit [1023:0] mask);

  // Set the m_use_full_wstrb flag so that the HWSTRB value always covers the entirety of HSIZE.
  extern function void set_use_full_wstrb();

  // Set the m_has_hprot flag. If this is false, m_hprot will be zero (which is representable
  // without an HPROT signal). If it is true, m_hprot will be 1, which means a data access.
  extern function void set_has_hprot(bit has_hprot);

  // Wait until the first item has been started by a read or write sequence. The task is guaranteed
  // to complete before the this sequence or in the same time slice.
  extern task wait_for_first_request();

  // Wait until the last item has been started by the sequence. The task is guaranteed to complete
  // before the this sequence or in the same time slice.
  extern task wait_for_last_request();

  // Do at least something (a read or a write)
  extern constraint nonempty_c;

  // Constrain m_wdata and m_wstrb to fit in (1 << m_write_size) bytes/bits
  extern constraint write_size_c;

  // Constrain m_wstrb to obey m_use_full_wstrb: if that flag is true, m_wstrb will be set to match
  // the maximum from m_write_size.
  extern constraint full_wstrb_c;
endclass

function ahb_read_write_seq::new(string name="");
  super.new(name);
endfunction

task ahb_read_write_seq::body();
  // Set the rsp variable to an "incomplete" status. We'll only update this to mark completion if we
  // get to the end of body() without seeing a reset and finishing early.
  rsp = ahb_status_item::type_id::create("rsp");
  rsp.m_sending_complete = 0;

  if (m_do_read) begin
    ahb_single_read_seq read_seq = ahb_single_read_seq::type_id::create("read_seq");
    ahb_txn_response_item last_rsp;

    if (!m_has_hprot) read_seq.m_hprot_width = 0;

    if (!read_seq.randomize() with {
          m_subordinate_idx == local::m_subordinate_idx;
          m_size            == local::m_read_size;
          m_addr            == local::m_addr;
        }) begin
      `uvm_fatal(get_full_name(), "Failed to randomise read_seq.")
    end

    fork
      read_seq.start(p_sequencer);
      begin
        read_seq.wait_for_first_request();
        m_sent_first_request = 1;

        // If we are not going to do any writes, this is the last sequence that we will run. Note
        // that the sequence (ahb_single_read_seq) only sends a single request itself, so we have
        // sent its first and last request.
        if (!m_do_write) m_sent_last_request = 1;
      end
    join

    // If the sequence didn't send a complete transaction, it must have been interrupted by a reset.
    // Return from the task (leaving rsp.m_sending_complete zero)
    if (!read_seq.has_full_transaction()) begin
      put_response(rsp);
      m_sent_last_request = 1;
      return;
    end

    // The sequence ran to completion. The response to the single read will be the last response in
    // read_seq.m_responses.
    last_rsp = read_seq.m_responses[read_seq.m_responses.size() - 1];

    if (last_rsp.m_resp) begin
      // We definitely don't expect to get an error response.
      `uvm_error(get_full_name(),
                 $sformatf({"Unexpected HRESP error when reading from address 0x%0h ",
                            "from subordinate %0d."},
                           m_addr, m_subordinate_idx))
    end else if (m_have_expected_rdata &&
                 ((last_rsp.m_rdata ^ m_expected_rdata) & m_expected_rdata_mask)) begin
      // If m_have_expected_rdata is true, we have a prediction about the value we should have read.
      // Generate an error if this doesn't match (under m_expected_rdata_mask).
      `uvm_error(get_full_name(),
                 $sformatf({"Mismatch when reading from address 0x%0h on subordinate %0d. ",
                            "When masked with 0x%0h, sequence expected to see 0x%0h ",
                            "but we actually saw 0x%0h."},
                           m_addr, m_subordinate_idx, m_expected_rdata_mask,
                           (m_expected_rdata & m_expected_rdata_mask),
                           (last_rsp.m_rdata & m_expected_rdata_mask)))
    end
  end

  if (m_do_write) begin
    int unsigned num_writes = 1 + m_double_write;

    for (int unsigned write_idx = 0; write_idx < num_writes; write_idx++) begin
      ahb_txn_response_item last_rsp;
      ahb_single_write_seq write_seq = ahb_single_write_seq::type_id::create("write_seq");

      if (!m_has_hprot) write_seq.m_hprot_width = 0;

      if (!write_seq.randomize() with {
        m_subordinate_idx == local::m_subordinate_idx;
        m_size            == local::m_write_size;
        m_addr            == local::m_addr;
        m_wdata           == local::m_wdata;
        m_wstrb           == local::m_wstrb;
      }) begin
        `uvm_fatal(get_full_name(), "Failed to randomise write_seq.")
      end

      fork
        write_seq.start(p_sequencer);
        begin
          write_seq.wait_for_first_request();
          m_sent_first_request = 1;

          // If this is the final write, this is the last sequence that we will run. Note that the
          // sequence (ahb_single_write_seq) only sends a single request itself, so we have sent its
          // first and last request.
          if (write_idx == num_writes - 1) m_sent_last_request = 1;
        end
      join

      // If the sequence didn't send a complete transaction, it must have been interrupted by a
      // reset. Return from the task (leaving rsp.m_sending_complete zero)
      if (!write_seq.has_full_transaction()) begin
        put_response(rsp);
        return;
      end

      last_rsp = write_seq.m_responses[write_seq.m_responses.size() - 1];

      // As with a read, we don't expect to get an error response.
      if (last_rsp.m_resp) begin
        `uvm_error(get_full_name(),
                   $sformatf({"Unexpected HRESP error when writing to address 0x%0h ",
                              "on subordinate %0d."},
                             m_addr, m_subordinate_idx))
      end
    end
  end

  // If we get here then we didn't get interrupted by a reset (in a read or a write). Change
  // m_sending_complete to be true, which will show a sequence that runs us that we ran to
  // completion.
  rsp.m_sending_complete = 1;
  put_response(rsp);
endtask

function void ahb_read_write_seq::set_double_write();
  m_double_write = 1;
endfunction

function void ahb_read_write_seq::set_expected_rdata(bit [1023:0] rdata, bit [1023:0] mask);
  m_expected_rdata      = rdata;
  m_expected_rdata_mask = mask;
  m_have_expected_rdata = 1;
endfunction

function void ahb_read_write_seq::set_use_full_wstrb();
  m_use_full_wstrb = 1;
endfunction

function void ahb_read_write_seq::set_has_hprot(bit has_hprot);
  m_has_hprot = has_hprot;
endfunction

task ahb_read_write_seq::wait_for_first_request();
  wait(m_sent_first_request);
endtask

task ahb_read_write_seq::wait_for_last_request();
  wait(m_sent_last_request);
endtask

constraint ahb_read_write_seq::nonempty_c {
  m_do_read || m_do_write;
}

constraint ahb_read_write_seq::write_size_c {
  (m_wdata >> (8 << m_write_size)) == '0;
  (m_wstrb >> (1 << m_write_size)) == '0;
}

constraint ahb_read_write_seq::full_wstrb_c {
  if (m_use_full_wstrb) {
    m_wstrb == (1 << (1 << m_write_size)) - 1;
  }
}
