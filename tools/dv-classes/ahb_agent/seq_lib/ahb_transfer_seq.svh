// Copyright lowRISC contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A sequence that sends a sequence of ahb_txn_request_item items, representing a single burst.

class ahb_transfer_seq extends uvm_sequence #(ahb_txn_request_item, uvm_sequence_item);
  `uvm_object_utils(ahb_transfer_seq)

  // The percentage of transfers within the burst that should be TransBusy (so no data are sent)
  int unsigned m_busy_within_burst_pct = 50;

  // The number of bits available for the HPROT signal. Items will be constrained so that their
  // m_prot values fit in this many bits.
  int unsigned m_hprot_width = 7;

  // The subordinate that is being accessed by this burst.
  rand int unsigned m_subordinate_idx;

  // The HBURST value to send for items in the sequence.
  rand burst_e m_burst;

  // The number of transfers to perform in the burst. Note the sequence may contain some items with
  // a transfer type of TransBusy, so might have more than m_length items.
  rand int unsigned m_length;

  // The size of each data transfer (encoded as log2(byte_size))
  rand bit [2:0]    m_size;

  // Is this a sequence of writes?
  rand bit          m_write;

  // The address of the first data transfer (randomised with the sequence because it makes it easier
  // to avoid crossing boundaries)
  rand bit [63:0]   m_addr;

  // The set of requests that were sent. This will be at least as long as m_responses, but might be
  // longer if the sequence ended after a reset.
  ahb_txn_request_item  m_requests[$];

  // The responses that were seen to the requests in m_requests.
  ahb_txn_response_item m_responses[$];

  // If true then add an extra constraint to an item that gets randomised, forcing its m_wdata field
  // to equal the sequence's m_fixed_wdata field.
  protected bit               m_constrain_wdata;

  // If m_constrain_wdata is true when an item is randomised, that item will be constrained to have
  // an m_wdata field that matches this value.
  protected rand bit [1023:0] m_fixed_wdata;

  // If true then add an extra constraint to an item that gets randomised, forcing its m_wstrb field
  // to equal the sequence's m_fixed_wstrb field.
  protected bit               m_constrain_wstrb;

  // If m_constrain_wstrb is true when an item is randomised, that item will be constrained to have
  // an m_wstrb field that matches this value.
  protected rand bit [127:0]  m_fixed_wstrb;

  // This bit is cleared when the address phase for the first item has been sent by the driver. Wait
  // for it (once the whole sequence has started) with wait_for_first_request(). This should allow
  // back-to-back operations without a vast list of running sequences.
  //
  // If that first item finishes early (because of a reset), we clear m_first_request_waiting,
  // meaning that wait_for_first_request will always complete before the sequence or at the same
  // time as it does.
  local bit                   m_first_request_waiting = 1;

  extern function new(string name="");
  extern task body();

  // Does this sequence show a full transaction?
  //
  // Call this after the sequence has run to completion. Then the sequence has seen a full
  // transaction iff there are the same number of responses as requests (so we haven't seen a
  // reset).
  extern function bit has_full_transaction();

  // Wait until the first request in the sequence has been sent.
  //
  // If the sequence stops early because of a reset, this task finishes then too.
  extern task wait_for_first_request();

  // Randomize the first request item (constrained to match the fields in the sequence)
  extern virtual protected function void randomize_first_item(ahb_txn_request_item item);

  // Randomise a request item other than the first one, which is passed as the item0 argument.
  //
  // The m_addr field will be constrained to match addr.
  extern virtual protected function void randomize_later_item(ahb_txn_request_item item,
                                                              ahb_txn_request_item item0,
                                                              bit [63:0]           addr);

  // Consume a response from the driver. If had_seen_reset is true, we have already seen a reset. If
  // expect_request_item is true, we expect the driver to send an ahb_txn_request_item to say it has
  // sent the address phase of the item it is currently handling. If not, we expect the driver to
  // send an ahb_txn_response_item based on the data phase for the item.
  //
  // Return true if we have now seen a reset.
  extern local function bit consume_response(uvm_sequence_item base_response,
                                             bit               expect_request_item,
                                             bit               had_seen_reset);

  // Constrain m_length to be compatible with m_burst
  extern constraint length_burst_compat_c;

  // Alignment constraint for m_addr
  //
  // This constraint is a duplicate of ahb_txn_request_item::naturally_aligned_c and ensures that we
  // will pick a starting address that means the items in the sequence are aligned.
  extern constraint naturally_aligned_c;

  // No incrementing burst may cross a 1kb address boundary
  extern constraint increment_1kb_boundary_c;

  // Set m_fixed_wdata to a value that can be represented in a data phase transaction with the given
  // m_size. (Important if m_constrain_wdata is asserted).
  //
  // This is analogous to ahb_txn_request_item::write_size_c, but needs duplicating here because we
  // randomise m_fixed_wdata at the very start of the sequence.
  extern constraint fixed_wdata_upper_bound_c;

  // Set m_fixed_wstrb to a value that can be represented in a data phase transaction with the given
  // m_size. (Important if m_constrain_wstrb is asserted).
  //
  // This is analogous to ahb_txn_request_item::write_size_c, but needs duplicating here because we
  // randomise m_fixed_wstrb at the very start of the sequence.
  extern constraint fixed_wstrb_upper_bound_c;
endclass

function ahb_transfer_seq::new(string name="");
  super.new(name);
endfunction

task ahb_transfer_seq::body();
  ahb_txn_request_item item0  = ahb_txn_request_item::type_id::create("item0");

  // When the driver sees a reset being asserted, it sends a response that is an ahb_status_item.
  // Once that happens, we need to consume some extra responses (until responses_seen matches
  // m_requests.size())
  bit        have_seen_reset = 0;

  // The size (in bytes) of the entire burst, inferred from the number of words and the number of
  // bytes in each word.
  bit [63:0] total_size_bytes = m_length * (1 << m_size);

  // Wrapping bursts wrap their addresses, based on the total size of the burst (against which,
  // m_addr might not be naturally aligned). This variable is only used for wrapping bursts, where
  // m_length will be 4, 8 or 16. In that situation, total_size_bytes will be a power of 2 and
  // wrap_addr_base is the greatest multiple of total_size_bytes that is not larger than m_addr.
  bit [63:0] wrap_addr_base = m_addr & ~(total_size_bytes - 1);

  start_item(item0);

  // Randomise the first item that will be sent. This is also used as a template for later transfers
  // (which will use the same m_subordinate_idx, m_burst, m_size, m_write etc.)
  randomize_first_item(item0);

  fork : isolation_fork begin
    int unsigned         words_sent;
    uvm_sequence_item    base_response;

    // The last request that was sent in this sequence. This is used to match transaction IDs for
    // responses.
    ahb_txn_request_item last_request;

    // If saw_reset_on_first_request is true, we saw a reset when we were sending the request for
    // item0. As such, there is no "previous item" whose response we should wait for after the loop.
    bit                  saw_reset_on_first_request;

    // Start running item0 (with join_none) and then wait for the first response that the driver
    // sends for it.
    fork finish_item(item0); join_none

    get_base_response(base_response, item0.get_transaction_id());

    // What sort of response have we seen? The driver should either have sent an
    // ahb_txn_request_item (to say that it has managed to send the request for item0) or an
    // ahb_status_item (to say that there has been a reset on the interface).
    have_seen_reset = consume_response(base_response, 1, have_seen_reset);
    m_requests.push_back(item0);
    last_request = item0;
    m_first_request_waiting = 0;
    words_sent = 1;

    // If have_seen_reset is true now then the driver hase reported we sent it item0 when the
    // interface was already in reset (and it won't send any more responses to the item).
    saw_reset_on_first_request = have_seen_reset;

    // Send items for the rest of the burst, possibly with occasional TransBusy items (which will
    // end up in m_requests and m_responses, but aren't counted in words_sent). If we see a reset,
    // stop sending new items.
    while (words_sent < m_length && !have_seen_reset) begin
      ahb_txn_request_item item = ahb_txn_request_item::type_id::create("item");
      bit [63:0]           item_addr;

      if (m_burst inside {BurstWrap4, BurstWrap8, BurstWrap16}) begin
        // Offsets are measured from the start of the wrap window
        bit [63:0] linear_offset = (m_addr - wrap_addr_base) + words_sent * (64'h1 << m_size);
        bit [63:0] wrapped_offset = linear_offset % total_size_bytes;

        item_addr = wrap_addr_base + wrapped_offset;
      end else begin
        // Non-wrapping offsets are measured from m_addr, which was the address of the first access.
        item_addr = m_addr + words_sent * (64'h1 << m_size);
      end

      start_item(item);
      randomize_later_item(item, item0, item_addr);

      // We are sending a word from the burst if item.m_trans is not TransBusy.
      if (item.m_trans != TransBusy) words_sent++;

      // Start running item and, in parallel, wait for responses to the previous item. The join_any
      // will complete when get_base_response finishes with a response for the previous item, at
      // which point we keep going: the next iteration (or a wait fork at the end) will ensure the
      // finish_item task runs to completion.
      fork
        finish_item(item);
        begin
          // Get a response from the driver for last_request. This will either be a status item
          // saying there has been a reset or it will be a data response. Note that the driver
          // doesn't send a response until the subordinate responds that it is not busy, so we don't
          // need a loop waiting for that here.
          get_base_response(base_response, last_request.get_transaction_id());
          have_seen_reset = consume_response(base_response, 0, have_seen_reset);

          // Now get a response from the driver for item. This should not cause any delay, because
          // the address phase for item will go through at the same time as the data phase for
          // last_request.
          get_base_response(base_response, item.get_transaction_id());
          have_seen_reset = consume_response(base_response, 1, have_seen_reset);
        end
      join_any

      // Add item to m_requests to show that we've started trying to send this item, and set
      // last_request to point at it (the last request that has been sent).
      m_requests.push_back(item);
      last_request = item;
    end


    if (!saw_reset_on_first_request) begin
      // At this point, we have stopped sending items (either because we have sent enough or because
      // we have seen a reset). We haven't yet consumed a response for the last request that was
      // sent, so should do that now.
      get_base_response(base_response, last_request.get_transaction_id());
      void'(consume_response(base_response, 0, have_seen_reset));
    end

    // Finally, wait for any process that is still running in the isolation fork. That should only
    // be the call to finish_item for the last item, which will complete in zero time (which we know
    // because we've just consumed its final response).
    wait fork;
  end join
endtask

function bit ahb_transfer_seq::has_full_transaction();
  return (m_requests.size() == m_responses.size());
endfunction

task ahb_transfer_seq::wait_for_first_request();
  wait (!m_first_request_waiting);
endtask

function void ahb_transfer_seq::randomize_first_item(ahb_txn_request_item item);
  if (!item.randomize() with {
        m_subordinate_idx == local::m_subordinate_idx;
        m_burst           == local::m_burst;
        m_size            == local::m_size;
        m_write           == local::m_write;
        m_addr            == local::m_addr;
        m_trans           == TransNonSequential;
        if (local::m_constrain_wdata && m_trans != TransBusy) {
          m_wdata == local::m_fixed_wdata;
        }
        if (local::m_constrain_wstrb && m_trans != TransBusy) {
          m_wstrb == local::m_fixed_wstrb;
        }
        (m_prot >> m_hprot_width) == '0;
      }) begin
    `uvm_fatal(get_full_name(), "Failed to randomise first item.")
  end
endfunction

function void ahb_transfer_seq::randomize_later_item(ahb_txn_request_item item,
                                                     ahb_txn_request_item item0,
                                                     bit [63:0]           addr);
  if (!item.randomize() with {
        m_subordinate_idx == local::item0.m_subordinate_idx;
        m_addr            == local::addr;
        m_burst           == local::item0.m_burst;
        m_lock            == local::item0.m_lock;
        m_prot            == local::item0.m_prot;
        m_size            == local::item0.m_size;
        m_write           == local::item0.m_write;
        m_trans dist {
          TransBusy       :/ local::m_busy_within_burst_pct,
          TransSequential :/ 100 - local::m_busy_within_burst_pct
        };
        if (local::m_constrain_wdata && m_trans != TransBusy) {
          m_wdata == local::m_fixed_wdata;
        }
        if (local::m_constrain_wstrb && m_trans != TransBusy) {
          m_wstrb == local::m_fixed_wstrb;
        }
        (m_prot >> m_hprot_width) == '0;
      }) begin
    `uvm_fatal(get_full_name(), "Failed to randomise item.")
  end
endfunction

function bit ahb_transfer_seq::consume_response(uvm_sequence_item base_response,
                                                bit               expect_request_item,
                                                bit               had_seen_reset);
  ahb_txn_request_item  txn_request;
  ahb_txn_response_item txn_response;
  ahb_status_item       status_response;
  bit have_seen_reset = had_seen_reset;

  if ($cast(txn_request, base_response)) begin
    if (!expect_request_item) begin
      `uvm_fatal(get_full_name(),
                 "Driver sent an ahb_txn_request_item when we were expecting a response.")
    end
  end else if ($cast(txn_response, base_response)) begin
    if (expect_request_item) begin
      `uvm_fatal(get_full_name(),
                 "Driver sent an ahb_txn_response_item when we were expecting a request.")
    end
    if (!had_seen_reset) m_responses.push_back(txn_response);
  end else if ($cast(status_response, base_response)) begin
    if (status_response.m_sending_complete) begin
      `uvm_error(get_full_name(), "Status response item sent with m_sending_complete=1.")
    end
    have_seen_reset = 1;
  end else begin
    `uvm_fatal(get_full_name(),
               {"Transaction sent a response that was neither an ",
                "ahb_txn_request_item, an ahb_txn_response_item nor an ahb_status_item."})
  end

  return have_seen_reset;
endfunction

constraint ahb_transfer_seq::length_burst_compat_c {
  m_length > 0;

  (m_burst == BurstSingle)                    -> m_length == 1;
  (m_burst inside {BurstWrap4, BurstIncr4})   -> m_length == 4;
  (m_burst inside {BurstWrap8, BurstIncr8})   -> m_length == 8;
  (m_burst inside {BurstWrap16, BurstIncr16}) -> m_length == 16;
}

constraint ahb_transfer_seq::naturally_aligned_c {
  (m_addr & ((1 << m_size) - 1)) == 0;
}

constraint ahb_transfer_seq::increment_1kb_boundary_c {
  if (m_burst inside {BurstIncr, BurstIncr4, BurstIncr8, BurstIncr16}) {
    ((m_addr + m_length * (1 << m_size) - 1) >> 10) == (m_addr >> 10);
  }
}

constraint ahb_transfer_seq::fixed_wdata_upper_bound_c {
  (m_fixed_wdata >> (8 << m_size)) == '0;
}

constraint ahb_transfer_seq::fixed_wstrb_upper_bound_c {
  (m_fixed_wstrb >> (1 << m_size)) == '0;
}
