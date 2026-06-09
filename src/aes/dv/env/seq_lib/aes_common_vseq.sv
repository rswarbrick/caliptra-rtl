// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Drives the dv_base_vseq automated CSR sequences (hw_reset / rw / bit_bash / aliasing /
// mem_walk) against the AES RAL. The OpenTitan version of this file relied on cip_base_vseq
// for shadow-register-aware CSR write wrappers, predicted-status helpers, and the
// stress_all-with-random-reset hook. Caliptra's dv_lib does not provide cip_base_vseq, so
// those overrides (csr_wr_for_shadow_reg_predict, predict_shadow_reg_status,
// run_seq_with_rand_reset_vseq, and the ctrl/ctrl_gcm invalid-value helpers they depended on)
// have been dropped. The remaining sequence is intentionally minimal: it skips aes_init and
// disables the scoreboard so the generic CSR tests can run.
class aes_common_vseq extends aes_base_vseq;
  `uvm_object_utils(aes_common_vseq)

  constraint num_trans_c {
    num_trans inside {[1:2]};
  }
  `uvm_object_new

  virtual task pre_start();
    do_aes_init = 1'b0;
    super.pre_start();
    cfg.en_scb = 0;
  endtask

  virtual task body();
    run_csr_vseq_wrapper(num_trans);
  endtask : body

endclass
