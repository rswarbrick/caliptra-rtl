// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This test verifies the behavior of different registers matches the specification. In particular:
// - Initial key registers are not readable.
// - Registers are cleared with pseudo-random data if requested (including the unreadable key
//   registers).

class aes_readability_vseq extends aes_base_vseq;
  `uvm_object_utils(aes_readability_vseq)
  `uvm_object_new

  aes_seq_item data_item;
  aes_seq_item cfg_item;
  aes_message_item my_message;
  string str = "";
  int success = 1;

  // The the DATA_OUT register and update item.data_out with its value
  //
  // Returns early on reset
  task read_data_out(aes_seq_item item);
    foreach (item.data_out[idx]) begin
      uvm_status_e txn_status;
      ral.aes_core.DATA_OUT[idx].read(txn_status, item.data_out[idx]);
      if (cfg.under_reset) return;

      if (txn_status != UVM_IS_OK) begin
        `uvm_error(get_full_name(), $sformatf("Failed to read DATA_OUT[%0d] register.", idx))
      end
    end
  endtask

  // The the IV register and update item.iv with its value
  //
  // Returns early on reset
  task read_iv(aes_seq_item item);
    foreach (item.iv[idx]) begin
      uvm_status_e txn_status;
      ral.aes_core.IV[idx].read(txn_status, item.iv[idx]);
      if (cfg.under_reset) return;

      if (txn_status != UVM_IS_OK) begin
        `uvm_error(get_full_name(), $sformatf("Failed to read IV[%0d] register.", idx))
      end
    end
  endtask

  task body();
    aes_seq_item cfg_item       = new();         // the configuration for this message
    aes_seq_item data_item      = new();
    aes_message_item my_message = new();
    aes_seq_item check_item     = new();

    `uvm_info(`gfn, $sformatf("\n\n\t ----| STARTING AES MAIN SEQUENCE |----\n %s",
                              cfg.convert2string()), UVM_LOW)

    // turnoff keymask
    cfg.key_mask = 0;
    // make sure we write at least a full data word
    cfg.message_len_min = 16;

    // generate list of messages //
    aes_message_init();
    generate_message_queue();

    // check key is unreadable!
    my_message = message_queue.pop_back();
    generate_aes_item_queue(my_message);
    cfg_item   = aes_item_queue.pop_back();
    data_item  = aes_item_queue.pop_back();


    setup_dut(cfg_item);

    write_key(cfg_item.key, cfg_item.do_b2b);
    if (cfg.under_reset) return;

    read_key(check_item.key);
    if (cfg.under_reset) return;

    foreach (cfg_item.key[0][idx]) begin
      if ((cfg_item.key[0][idx] == check_item.key[0][idx]) ||
          (cfg_item.key[1][idx] == check_item.key[1][idx])) begin
              `uvm_fatal(`gfn, $sformatf("----| Key reg was readable |-----"))
      end
    end

    // check read data //
    add_data(data_item.data_in, cfg_item.do_b2b);
    foreach (data_item.data_in[idx]) begin
      uvm_status_e txn_status;

      ral.aes_core.DATA_IN[idx].read(txn_status, check_item.data_in[idx]);
      if (cfg.under_reset) return;
      if (txn_status != UVM_IS_OK) begin
        `uvm_error(get_full_name(), $sformatf("Failed to read DATA_IN[%0d] register.", idx))
      end
    end

    // read output regs before clear
    read_data_out(data_item);
    if (cfg.under_reset) return;

    // read IV before clear
    read_iv(data_item);
    if (cfg.under_reset) return;

    // clear regs
    clear_regs(2'b11);
    spinwait_status_idle();
    if (cfg.under_reset) return;

    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.data_in[0]", check_item.data_in[0]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.data_in[1]", check_item.data_in[1]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.data_in[2]", check_item.data_in[2]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.data_in[3]", check_item.data_in[3]);

    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.key_share0[0]", check_item.key[0][0]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.key_share0[1]", check_item.key[0][1]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.key_share0[2]", check_item.key[0][2]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.key_share0[3]", check_item.key[0][3]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.key_share0[4]", check_item.key[0][4]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.key_share0[5]", check_item.key[0][5]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.key_share0[6]", check_item.key[0][6]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.key_share0[7]", check_item.key[0][7]);

    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.key_share1[0]", check_item.key[1][0]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.key_share1[1]", check_item.key[1][1]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.key_share1[2]", check_item.key[1][2]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.key_share1[3]", check_item.key[1][3]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.key_share1[4]", check_item.key[1][4]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.key_share1[5]", check_item.key[1][5]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.key_share1[6]", check_item.key[1][6]);
    success &= uvm_hdl_read("tb.dut.u_reg.hw2reg.key_share1[7]", check_item.key[1][7]);
    `DV_CHECK_FATAL(success == 1)

    foreach (data_item.data_in[idx]) begin
      if ((check_item.data_in[idx] == data_item.data_in[idx]) ||
         (check_item.data_out[idx] == data_item.data_out[idx])) begin
        `uvm_fatal(`gfn, $sformatf("----| Data reg was did not clear |---- %s", str))
      end
    end

    read_data_out(check_item);
    if (cfg.under_reset) return;
    foreach (data_item.data_out[idx]) begin
      if (data_item.data_out[idx] == check_item.data_out[idx] ) begin
        `uvm_fatal(`gfn, $sformatf("----| data out reg was not cleared |---- %s", str))
      end
    end

    // check IV
    read_iv(check_item);
    foreach (data_item.iv[idx]) begin
      if (data_item.iv[idx] == check_item.iv[idx] ) begin
        `uvm_fatal(`gfn, $sformatf("----| IV reg was not cleared |---- %s", str))
      end
    end

    // check key is pseudo random
    read_key(check_item.key);
    if (cfg.under_reset) return;

    foreach (cfg_item.key[0][idx]) begin
      if ((check_item.key[0][idx] == data_item.key[0][idx]) ||
         (check_item.key[1][idx] == data_item.key[1][idx])) begin
        `uvm_fatal(`gfn, $sformatf("----| Key reg was not cleared |---- %s", str))
      end
    end

  endtask // body

endclass // aes_readability_vseq
