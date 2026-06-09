// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

package dv_base_mubi_pkg;
  // macro includes
  `include "uvm_macros.svh"
  `include "dv_macros.svh"
  `include "dv_mubi_macros.svh"

  // dep packages
  import uvm_pkg::*;

  import prim_mubi_pkg::MuBi4True, prim_mubi_pkg::MuBi4False;
  import prim_mubi_pkg::MuBi8True, prim_mubi_pkg::MuBi8False;
  import prim_mubi_pkg::MuBi12True, prim_mubi_pkg::MuBi12False;
  import prim_mubi_pkg::MuBi16True, prim_mubi_pkg::MuBi16False;
  import prim_mubi_pkg::MuBi20True, prim_mubi_pkg::MuBi20False;
  import prim_mubi_pkg::MuBi24True, prim_mubi_pkg::MuBi24False;
  import prim_mubi_pkg::MuBi28True, prim_mubi_pkg::MuBi28False;
  import prim_mubi_pkg::MuBi32True, prim_mubi_pkg::MuBi32False;

  // Create functions that return a random value for the mubi type variable, based on weight
  // settings.
  //
  // The function is `get_rand_mubi4|8|16_val(t_weight, f_weight, other_weight)`
  // t_weight: randomization weight of the value True
  // f_weight: randomization weight of the value False
  // other_weight: collective randomization weight of all values other than True or False
`define _DV_MUBI_RAND_VAL(WIDTH_)                                                            \
  function automatic prim_mubi_pkg::mubi``WIDTH_``_t                                         \
      get_rand_mubi``WIDTH_``_val(int t_weight = 2, int f_weight = 2, int other_weight = 1); \
    bit[WIDTH_-1:0] val;                                                                     \
    if (!std::randomize(val) with {                                                          \
           `DV_MUBI``WIDTH_``_DIST(val, t_weight, f_weight, other_weight)                    \
         }) begin                                                                            \
      `uvm_fatal("Failed to randomise mubi value",                                           \
                 $sformatf("get_rand_mubi%0d_val", WIDTH_))                                  \
    end                                                                                      \
    return prim_mubi_pkg::mubi``WIDTH_``_t'(val);                                            \
  endfunction

  // Create function - get_rand_mubi4_val.
  `_DV_MUBI_RAND_VAL(4)

  // Create function - get_rand_mubi8_val.
  `_DV_MUBI_RAND_VAL(8)

  // Create function - get_rand_mubi12_val.
  `_DV_MUBI_RAND_VAL(12)

  // Create function - get_rand_mubi16_val.
  `_DV_MUBI_RAND_VAL(16)

  `undef _DV_MUBI_RAND_VAL

  `include "dv_base_mubi_cov.sv"
endpackage
