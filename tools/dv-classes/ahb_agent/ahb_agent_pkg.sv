// Copyright lowRISC contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

package ahb_agent_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  typedef enum bit [1:0] {
    TransIdle = 0,
    TransBusy = 1,
    TransNonSequential = 2,
    TransSequential = 3
  } trans_e;

  typedef enum bit [2:0] {
    BurstSingle = 0,
    BurstIncr   = 1,
    BurstWrap4  = 2,
    BurstIncr4  = 3,
    BurstWrap8  = 4,
    BurstIncr8  = 5,
    BurstWrap16 = 6,
    BurstIncr16 = 7
  } burst_e;

  // A structure representing an address range and a particular subordinate index. A queue of these
  // structures defines a partial map from address to subordinate index (take the first item that
  // matches the address).
  //
  // This is used in ahb_mgr_agent, but also in ahb_mgr_register_layer_vseq.
  typedef struct {
    bit [63:0]   addr_min;        // Minimum address in the range
    bit [63:0]   addr_max;        // Maximum address in the range (inclusive)
    int unsigned subordinate_idx; // Index of the associated subordinate.
  } sub_addr_range_t;

  // Search in mappings for a subordinate that is associated with addr.
  //
  // If there is an item in the queue where the address range contains addr, this writes the
  // subordinate index to the sub_idx output argument and returns 1.
  //
  // If there is no item in the queue that contains addr, this writes '1 to the sub_idx output
  // argument and returns 0.
  function automatic bit get_subordinate_for_addr(bit [63:0]                 addr,
                                                  const ref sub_addr_range_t mappings[$],
                                                  output int unsigned        sub_idx);
    foreach (mappings[i]) begin
      if (mappings[i].addr_min <= addr && addr <= mappings[i].addr_max) begin
        sub_idx = mappings[i].subordinate_idx;
        return 1'b1;
      end
    end

    sub_idx = '1;
    return 1'b0;
  endfunction

  `include "ahb_status_item.svh"
  `include "ahb_reg_op_item.svh"

  `include "ahb_txn_request_item.svh"
  `include "ahb_txn_response_item.svh"
  `include "ahb_txn_item.svh"

  `include "ahb_monitor.svh"

  `include "ahb_mgr_driver.svh"
  `include "ahb_mgr_reg_adapter.svh"

  typedef uvm_sequencer#(ahb_reg_op_item)                         ahb_reg_op_sequencer_t;
  typedef uvm_sequencer#(ahb_txn_request_item, uvm_sequence_item) ahb_txn_sequencer_t;

  `include "seq_lib/ahb_transfer_seq.svh"
  `include "seq_lib/ahb_single_read_seq.svh"
  `include "seq_lib/ahb_single_write_seq.svh"
  `include "seq_lib/ahb_mgr_register_layer_vseq.svh"

  `include "ahb_mgr_agent.svh"
endpackage
