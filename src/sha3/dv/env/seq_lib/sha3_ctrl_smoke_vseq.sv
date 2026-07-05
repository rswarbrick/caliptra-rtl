// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// smoke test vseq
class sha3_ctrl_smoke_vseq extends sha3_ctrl_base_vseq;

  `uvm_object_utils(sha3_ctrl_smoke_vseq)
  `uvm_object_new

  bit kmac_done = 0;

  // Set this bit if we want to burst write the message into the msgfifo
  bit burst_write = 0;

  // Set this bit to one if entropy fetched successfully without timeout error.
  bit entropy_fetched;

  constraint num_trans_c {
    num_trans inside {[1:200]};
    if (cfg.smoke_test) {
      num_trans == 10;
    } else {
      num_trans inside {[1:200]};
    }
  }

  constraint disable_err_c {
    kmac_err_type == kmac_pkg::ErrNone;
  }

  constraint custom_str_len_c {
    custom_str_len == 0;
  }

  constraint entropy_refresh_c {
    hash_threshold == 0;
    entropy_req    == 0;
  }

  // Constraint output byte length to be at most the keccak block size (168/136).
  // This way we can read the entire digest without having to manually squeeze data.
  constraint output_len_c {
    output_len inside {[1:keccak_block_size]};
  }

  // for smoke test keep message below 32 bytes
  constraint msg_c {
    msg.size() dist {
      0      :/ 1,
      [1:32] :/ 9
    };
  }

  // We want to disable do_kmac_init here because we wil re-initialize the KMAC each time we do
  // a message hash.
  virtual task pre_start();
    do_kmac_init = 0;
    super.pre_start();
  endtask

  // Do a full message hash, repeated num_trans times
  task body();
    `uvm_info(`gfn, $sformatf("Starting %0d message hashes", num_trans), UVM_LOW)

    for (int i = 0; i < num_trans; i++) begin
      bit [7:0] share0[];
      bit [7:0] share1[];

      `uvm_info(`gfn, $sformatf("iteration: %0d", i), UVM_LOW)

      `DV_CHECK_RANDOMIZE_FATAL(this)

      kmac_init(.keymgr_app_intf(0));
      if (cfg.under_reset) return;
      `uvm_info(`gfn, "kmac_init done", UVM_HIGH)

      read_regwen_and_rand_write_locked_regs();
      if (cfg.under_reset) return;

      if (cfg.enable_masking && kmac_err_type == kmac_pkg::ErrIncorrectEntropyMode) begin
        if (!entropy_fetched) begin
          check_err();
          continue;
        end
      end else if (cfg.enable_masking) begin
        entropy_fetched = 1;
      end

      set_prefix();
      if (cfg.under_reset) return;

      // normal hashing operation

      // issue an incorrect SW command, this will be dropped internally,
      // so need to send correct command afterwards.
      if (kmac_err_type == kmac_pkg::ErrSwCmdSequence &&
          err_sw_cmd_seq_st == sha3_pkg::StIdle) begin
        issue_cmd(err_sw_cmd_seq_cmd);
        if (cfg.under_reset) return;
        check_err();
      end

      // issue Start cmd
      issue_cmd(CmdStart);
      if (cfg.under_reset) return;

      read_regwen_and_rand_write_locked_regs();
      if (cfg.under_reset) return;

      // write the message into msgfifo
      `uvm_info(`gfn, $sformatf("msg: %0p", msg), UVM_HIGH)
      if (burst_write) begin
        burst_write_msg(msg);
      end else begin
        write_msg(msg);
      end
      if (cfg.under_reset) return;

      // wait for some cycles after writing message to let internal state settle
      cfg.clk_rst_vif.wait_clks_or_rst($urandom_range(5, 10));
      if (cfg.under_reset) return;

      // issue an incorrect SW command, this will be dropped internally,
      // so need to send the correct command afterwards.
      if (kmac_err_type == kmac_pkg::ErrSwCmdSequence &&
          err_sw_cmd_seq_st == sha3_pkg::StAbsorb) begin
        issue_cmd(err_sw_cmd_seq_cmd);
        if (cfg.under_reset) return;
        check_err();
      end

      // issue Process cmd
      issue_cmd(CmdProcess);
      if (cfg.under_reset) return;

      if (kmac_err_type == kmac_pkg::ErrUnexpectedModeStrength) begin
        continue;
      end

      wait_for_kmac_done();
      if (cfg.under_reset) return;
      kmac_done = 1;

      read_regwen_and_rand_write_locked_regs();
      if (cfg.under_reset) return;

      // read out intr_state and status, scb will check
      check_state();
      if (cfg.under_reset) return;

      // Read the output digest, scb will check digest
      //
      // If performing a KMAC_APP operation, digest will be sent directly to the m_kmac_app_agent,
      // so scoreboard will handle everything
      //
      read_digest_shares(output_len, cfg.enable_masking, share0, share1);
      if (cfg.under_reset) return;

      // issue an incorrect SW command, this will be dropped internally,
      // so need to send the correct command afterwards.
      if (kmac_err_type == kmac_pkg::ErrSwCmdSequence &&
          err_sw_cmd_seq_st == sha3_pkg::StSqueeze) begin
        issue_cmd(err_sw_cmd_seq_cmd);
        if (cfg.under_reset) return;
        check_err();
      end

      // issue Done cmd to tell KMAC to clear internal state
      issue_cmd(CmdDone);
      if (cfg.under_reset) return;

      // randomly read out both digests after issuing Done cmd.
      if ($urandom_range(0, 1)) begin
        read_digest_chunk(KMAC_STATE_SHARE0_BASE, keccak_block_size, share0);
        if (cfg.under_reset) return;
        read_digest_chunk(KMAC_STATE_SHARE1_BASE, keccak_block_size, share1);
        if (cfg.under_reset) return;
      end
    end

  endtask : body
endclass
