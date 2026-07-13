// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class sha3_ctrl_stress_all_vseq extends sha3_ctrl_base_vseq;

  `uvm_object_utils(sha3_ctrl_stress_all_vseq)
  `uvm_object_new

  string vseq_names[$] = {
    "sha3_ctrl_smoke_vseq",
    "sha3_ctrl_burst_write_vseq"
    // Do not include sha3 or shake test vectors as they require a specific value for a shared
    // plusarg - excluding them does not detract much from the stress_all test
    //
    // The stress sequence also doesn't include sha3_ctrl_long_msg_and_output_vseq: one iteration of
    // that vseq takes a couple of hours to simulate(!) and we don't really have any reason to
    // believe that its behaviour will interact interestingly with the other sequences.
  };

  virtual task pre_start();
    do_kmac_init = 0;
    super.pre_start();
  endtask

  task body();
    `uvm_info(`gfn, $sformatf("Running %0d random sequences", num_trans), UVM_LOW)
    for (int i = 0; i < num_trans; i++) begin
      uvm_sequence_base    seq;
      sha3_ctrl_base_vseq  kmac_vseq;
      uint                 seq_idx = $urandom_range(0, vseq_names.size() - 1);
      string               cur_vseq_name = vseq_names[seq_idx];

      seq = create_seq_by_name(cur_vseq_name);
      `downcast(kmac_vseq, seq)

      kmac_vseq.do_apply_reset = (do_apply_reset) ? $urandom_range(0, 1) : 0;

      kmac_vseq.set_sequencer(p_sequencer);
      kmac_vseq.set_ahb_sequencer(m_ahb_sequencer);

      // Limit the number of hashes performed by each subsequence as this can easily timeout
      `DV_CHECK_RANDOMIZE_WITH_FATAL(kmac_vseq, kmac_vseq.num_trans inside {[0 : 50]};)
      `uvm_info(`gfn, $sformatf("iteration[%0d]: starting %0s", i, cur_vseq_name), UVM_LOW)
      kmac_vseq.start(p_sequencer);
    end
  endtask

endclass
