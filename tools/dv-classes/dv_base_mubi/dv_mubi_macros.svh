// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`ifndef __DV_MUBI_MACROS_SVH__
`define __DV_MUBI_MACROS_SVH__

// Macros that expand to a ternary expression giving the smaller / larger of the two values.
//
// These make no guarantee to only evaluate arguments once.
`ifndef _DV_TERNARY_MIN
`define _DV_TERNARY_MIN(a_, b_) (((a_) < (b_)) ? (a_) : (b_))
`endif
`ifndef _DV_TERNARY_MAX
`define _DV_TERNARY_MAX(a_, b_) (((a_) < (b_)) ? (b_) : (a_))
`endif

// A macro that expands to a constraint giving distribution for a mubi-type variable
// Don't use this macro directly: use DV_MUBI4|8|16_DIST instead.
//
// Arguments:
//
//  VAR_           The variable whose distribution is being constrained
//  TRUE_          MuBi true value
//  FALSE_         MuBi false value
//  MAX_           The maximum value in the bit-vector range for the value
//  T_WEIGHT_      The weight to give the "true" value
//  F_WEIGHT_      The weight to give the "false" value
//  OTHER_WEIGHT_  The weight spread among all other values
//
// This macro uses ":=" to give weights for the other cases in order that the individual values
// won't have a weight that depends on the length of the range containing them. There are (MAX_ - 2)
// items in these other ranges, so we scale T_WEIGHT_ and F_WEIGHT_ by that value to ensure that
// T_WEIGHT_/F_WEIGHT_/OTHER_WEIGHT_ give the relative weights for true/false/something-else. For
// example, if T_WEIGHT_, F_WEIGHT_ and OTHER_WEIGHT_ are all equal then the probabilities of
// getting "true" and "false" and getting something else are all 1/3.
//
// Some tools generate a warning if there is a backwards range ([big:little]) in the distribution,
// even if an if/else check ensures that it isn't used. To avoid this warning, we use a ternary
// operator to extract the larger/smaller value.
`ifndef _DV_MUBI_DIST
`define _DV_MUBI_DIST(VAR_, TRUE_, FALSE_, MAX_, T_WEIGHT_, F_WEIGHT_, OTHER_WEIGHT_)  \
  VAR_ dist {                                                                          \
    TRUE_                                        := (T_WEIGHT_) * ((MAX_) - 1),        \
    FALSE_                                       := (F_WEIGHT_) * ((MAX_) - 1),        \
    [0 : `_DV_TERNARY_MIN(TRUE_, FALSE_)-1]      := (OTHER_WEIGHT_),                   \
    [(`_DV_TERNARY_MIN(TRUE_, FALSE_)+1) :                                             \
     (`_DV_TERNARY_MAX(TRUE_, FALSE_)-1)]        := (OTHER_WEIGHT_),                   \
    [(`_DV_TERNARY_MAX(TRUE_, FALSE_)+1):(MAX_)] := (OTHER_WEIGHT_)                    \
  };
`endif

`ifndef DV_MUBI4_DIST
`define DV_MUBI4_DIST(VAR_, T_WEIGHT_ = 2, F_WEIGHT_ = 2, OTHER_WEIGHT_ = 1) \
  `_DV_MUBI_DIST(VAR_, MuBi4True, MuBi4False, (1 << 4) - 1, T_WEIGHT_, F_WEIGHT_, OTHER_WEIGHT_)
`endif

`ifndef DV_MUBI8_DIST
`define DV_MUBI8_DIST(VAR_, T_WEIGHT_ = 2, F_WEIGHT_ = 2, OTHER_WEIGHT_ = 1) \
  `_DV_MUBI_DIST(VAR_, MuBi8True, MuBi8False, (1 << 8) - 1, T_WEIGHT_, F_WEIGHT_, OTHER_WEIGHT_)
`endif

`ifndef DV_MUBI12_DIST
`define DV_MUBI12_DIST(VAR_, T_WEIGHT_ = 2, F_WEIGHT_ = 2, OTHER_WEIGHT_ = 1) \
  `_DV_MUBI_DIST(VAR_, MuBi12True, MuBi12False, (1 << 12) - 1,T_WEIGHT_, F_WEIGHT_, OTHER_WEIGHT_)
`endif

`ifndef DV_MUBI16_DIST
`define DV_MUBI16_DIST(VAR_, T_WEIGHT_ = 2, F_WEIGHT_ = 2, OTHER_WEIGHT_ = 1) \
  `_DV_MUBI_DIST(VAR_, MuBi16True, MuBi16False, T_WEIGHT_, (1 << 16) - 1, F_WEIGHT_, OTHER_WEIGHT_)
`endif

`endif  // __DV_MUBI_MACROS_SVH__
