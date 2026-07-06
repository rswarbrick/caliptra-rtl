// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// An extension of intr_test_vseq, specialised for the interrupts for the KMAC inside sha3_ctrl.

class sha3_ctrl_intr_test_vseq extends intr_test_vseq_pkg::intr_test_vseq;
  `uvm_object_utils(sha3_ctrl_intr_test_vseq)

  // An interface to sample interrupts. Set this by calling set_vif.
  local virtual kmac_intr_if m_intr_vif;

  extern function new(string name="");

  // Set the interface for sampling interrupts. Call this before running the sequence.
  extern function void set_vif(virtual kmac_intr_if intr_vif);

  // Return the current interrupt state, as seen from m_intr_vif.
  //
  // This implements a function from intr_test_vseq
  extern function logic[63:0] peek_interrupt_pins();
endclass

function sha3_ctrl_intr_test_vseq::new(string name="");
  super.new(name);
endfunction

function void sha3_ctrl_intr_test_vseq::set_vif(virtual kmac_intr_if intr_vif);
  m_intr_vif = intr_vif;
endfunction

function logic[63:0] sha3_ctrl_intr_test_vseq::peek_interrupt_pins();
  return {m_intr_vif.kmac_err, m_intr_vif.fifo_empty, m_intr_vif.kmac_done};
endfunction
