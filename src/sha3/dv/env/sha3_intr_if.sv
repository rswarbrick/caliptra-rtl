// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A simple interface that holds the pins for the interrupts coming out of sha3_ctrl
//
// These are just an "error" and a "notification" interrupt, which report that some interrupt of
// that level has been emitted from kmac.
//
//        KMAC        |  sha3_ctrl
// -------------------+-------------
//  intr_kmac_done_o  |   notif
//  intr_fifo_empty_o |   notif
//  intro_kmac_err_o  |   error

interface sha3_intr_if (input clk_i, input rst_ni);
  wire error;
  wire notif;
endinterface
