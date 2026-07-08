// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

package sha3_ctrl_test_pkg;
  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  import uvm_pkg::*;
  import sha3_ctrl_env_pkg::*;

  import dv_lib_pkg::dv_base_test;

  `include "sha3_ctrl_base_test.sv"
  `include "sha3_ctrl_intr_test_test.svh"
  `include "sha3_ctrl_same_csr_outstanding_test.svh"
endpackage
