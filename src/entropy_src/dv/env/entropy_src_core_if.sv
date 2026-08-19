// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// An interface that should be bound into an entropy_src_core instance. It uses its ports to pass
// on that module's internal signals.

interface entropy_src_core_if (
  input logic [8:0] es_main_sm_state_i
);

endinterface
