// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class sha3_ctrl_test_vectors_base_vseq extends sha3_ctrl_smoke_vseq;

  `uvm_object_utils(sha3_ctrl_test_vectors_base_vseq)
  `uvm_object_new

  string test_list[];

  virtual task pre_start();
    msg_c.constraint_mode(0);
    output_len_c.constraint_mode(0);
    super.pre_start();
  endtask

  task body();
    test_vectors_pkg::test_vectors_t vectors[];

    // Randomly pick a single test vector set to limit test run time.
    int test_idx = $urandom_range(0, test_list.size - 1);
    test_list = {test_list[test_idx]};
    `uvm_info(`gfn, $sformatf("test_idx = %0d", test_idx), UVM_MEDIUM)

    foreach (test_list[i]) begin
      // parse each test vector file
      test_vectors_pkg::get_hash_test_vectors(test_list[i], vectors);

      `uvm_info(`gfn, $sformatf("Starting %0s test vectors", test_list[i]), UVM_LOW)
      `uvm_info(`gfn, $sformatf("Preparing %0d test vectors...", vectors.size()), UVM_LOW)

      // Run a basic hash operation for each parsed test vector
      foreach (vectors[j]) begin
        // `compare_digest()` passes three arrays by reference, one of which is contained
        // inside of the vectors[j] struct.
        //
        // Hierarchical references to an array inside a struct is not supported by VCS,
        // so
        bit [7:0] exp_digest[] = vectors[j].exp_digest;
        bit [7:0] share0[];
        bit [7:0] share1[];

        `uvm_info(`gfn, $sformatf("Running test vector %0d", j), UVM_LOW)
        `uvm_info(`gfn, $sformatf("vectors[%0d]: %0p", j, vectors[j]), UVM_HIGH)

        // Use this hook to set the appropriate configuration options
        randomize_cfg(vectors[j]);

        msg = vectors[j].msg;
        `uvm_info(`gfn, $sformatf("msg: %0p", msg), UVM_HIGH)

        kmac_init();

        issue_cmd(CmdStart);

        write_msg(msg, 1);

        issue_cmd(CmdProcess);

        wait_for_kmac_done();

        read_digest_shares(output_len, cfg.enable_masking, share0, share1);

        `uvm_info(`gfn, $sformatf("share0: %0p", share0), UVM_HIGH)
        `uvm_info(`gfn, $sformatf("share1: %0p", share1), UVM_HIGH)

        issue_cmd(CmdDone);

        compare_digest(exp_digest, share0, share1, cfg.enable_masking);
      end
    end
  endtask

  // This function is used to randomize the KMAC settings
  // based on the test vector config
  virtual function void randomize_cfg(test_vectors_pkg::test_vectors_t vector);
    `uvm_fatal(`gfn, "Should not be called in the base class")
  endfunction

  virtual function void compare_digest(const ref bit [7:0] exp_digest[],
                                       const ref bit [7:0] act_share0[],
                                       const ref bit [7:0] act_share1[],
                                       input bit           en_masking);
    int unsigned num_mismatches;
    for (int i = 0; i < output_len; i++) begin
      bit [7:0] act_digest;

      if (en_masking) begin
        act_digest = act_share0[i] ^ act_share1[i];
      end else begin
        act_digest = act_share0[i];
      end

      if (act_digest != exp_digest[i]) begin
        num_mismatches++;
        `uvm_warning(get_full_name(),
                     $sformatf("Digest mismatch at byte %0d: expected 0x%0h; seen: 0x%0h",
                               i, exp_digest[i], act_digest))
        if (num_mismatches >= 10) break;
      end
    end
    if (num_mismatches) begin
      `uvm_error(get_full_name(), "Digest had one or more mismatches with the model.")
    end
  endfunction

endclass
