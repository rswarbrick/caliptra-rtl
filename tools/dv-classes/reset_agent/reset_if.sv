// Copyright lowRISC contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// An interface to track a single reset line

interface reset_if (input clk_i, inout rst_n);
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // If this is set, the interface is being driven actively and rst_n follows rst_n_driven.
  bit is_active;

  // A copy of rst_n that can be driven (only used if is_active is true).
  logic rst_n_driven;

  assign rst_n = is_active ? rst_n_driven : 'z;
endinterface
