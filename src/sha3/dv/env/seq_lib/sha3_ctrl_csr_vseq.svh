// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A very small virtual sequence that wraps the dv_base_vseq::run_csr_vseq_wrapper task to run CSR
// vseqs.
class sha3_ctrl_csr_vseq extends sha3_ctrl_base_vseq;
  `uvm_object_utils(sha3_ctrl_csr_vseq)

  extern function new(string name="");
  extern task body();
endclass

function sha3_ctrl_csr_vseq::new(string name="");
  super.new(name);
endfunction

task sha3_ctrl_csr_vseq::body();
  run_csr_vseq_wrapper();
endtask
