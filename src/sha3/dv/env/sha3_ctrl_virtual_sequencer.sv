// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class sha3_ctrl_virtual_sequencer extends dv_base_virtual_sequencer #(
    .CFG_T(sha3_ctrl_env_cfg),
    .COV_T(sha3_ctrl_env_cov)
  );
  `uvm_component_utils(sha3_ctrl_virtual_sequencer)

  `uvm_component_new

endclass
