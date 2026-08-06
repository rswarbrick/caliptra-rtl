// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

package shadow_reg_errors_vseq_pkg;
  import uvm_pkg::*;

  import dv_base_reg_pkg::dv_base_reg;
  import dv_base_reg_pkg::dv_base_reg_block;
  import dv_base_reg_pkg::csr_excl_type_e;
  import dv_base_reg_pkg::CsrExclAll;

  import csr_utils_pkg::csr_base_seq;
  import csr_utils_pkg::csr_rw_seq;

  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  `include "shadow_reg_errors_vseq.svh"

endpackage
