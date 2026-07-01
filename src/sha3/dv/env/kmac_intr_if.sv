// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A simple interface that holds the pins for the interrupts coming out of the kmac block inside
// sha3_ctrl.
//
// The sha3_ctrl layer merges these interrupts into two stateful interrupts (error and notif). Those
// are tracked in sha3_intr_if.sv.

interface kmac_intr_if ();
  wire kmac_done;
  wire fifo_empty;
  wire kmac_err;
endinterface
