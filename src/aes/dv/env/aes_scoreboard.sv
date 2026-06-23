// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

import aes_model_dpi_pkg::*;
import aes_pkg::*;

class aes_scoreboard extends dv_base_scoreboard #(.CFG_T(aes_env_cfg),
                                                  .RAL_T(aes_dv_reg),
                                                  .COV_T(aes_env_cov));

  `uvm_component_utils(aes_scoreboard)
  `uvm_component_new

  // local variables
  aes_seq_item input_item;                    // item containing data and config
  aes_seq_item output_item;                   // item containing resulting output
  aes_seq_item complete_item;                 // merge of input and output items
  aes_seq_item complete_aad_item;             // aad input items
  aes_seq_item key_item;                      // sequence item holding last sideload valid key
  bit          ok_to_fwd          = 0;        // 0: item is not ready to forward
  bit          reset_rebuilding   = 0;        // reset message rebuilding task
  bit          exp_clear          = 0;        // if using sideload - we are expecting a clear

  bit [3:0]    datain_rdy         = '0;       // indicate if DATA_IN can be updated

  virtual      aes_cov_if   cov_if;           // handle to aes coverage interface
  // local queues to hold incoming packets pending comparison //

  // Items containing both input and output data, ready to be added to a message
  mailbox      #(aes_seq_item)      item_fifo;
  // completed message item ready for scoring
  mailbox      #(aes_message_item)  msg_fifo;
  // once an operation is started the item is put here to wait for the resulting output
  aes_seq_item                      rcv_item_q[$];
  aes_seq_item                      rcv_aad_item_q[$];

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    msg_fifo         = new();
    item_fifo        = new();
    input_item       = new("input_item");
    key_item         = new("key_item");
    output_item      = new ();

    if (!uvm_config_db#(virtual aes_cov_if)::get(null, "*.env" , "aes_cov_if", cov_if)) begin
      `uvm_fatal(`gfn, $sformatf("FAILED TO GET HANDLE TO COVER IF"))
    end
  endfunction


  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction


  task run_phase(uvm_phase phase);
    // disable check as we don't
    // know when the alert will happen
    super.run_phase(phase);
    if (cfg.en_scb) begin
      fork
        compare();
        rebuild_message();
      join_none
    end
  endtask

  function void on_ctrl_shadowed_write(logic [31:0] wdata);
    input_item.manual_op   = get_field_val(ral.aes_core.CTRL_SHADOWED.MANUAL_OPERATION, wdata);
    input_item.key_len     = get_field_val(ral.aes_core.CTRL_SHADOWED.KEY_LEN, wdata);
    input_item.sideload_en = get_field_val(ral.aes_core.CTRL_SHADOWED.SIDELOAD, wdata);
    `downcast(input_item.operation, get_field_val(ral.aes_core.CTRL_SHADOWED.OPERATION, wdata));
    input_item.valid = 1'b1;
    case (get_field_val(ral.aes_core.CTRL_SHADOWED.MODE, wdata))
      6'b00_0001:  input_item.mode = AES_ECB;
      6'b00_0010:  input_item.mode = AES_CBC;
      6'b00_0100:  input_item.mode = AES_CFB;
      6'b00_1000:  input_item.mode = AES_OFB;
      6'b01_0000:  input_item.mode = AES_CTR;
      6'b10_0000:  input_item.mode = AES_GCM;
      6'b11_1111:  input_item.mode = AES_NONE;
      default:     input_item.mode = AES_NONE;
    endcase
    // sample coverage on ctrl register
    cov_if.cg_ctrl_sample(get_field_val(ral.aes_core.CTRL_SHADOWED.OPERATION, wdata),
                          get_field_val(ral.aes_core.CTRL_SHADOWED.MODE, wdata),
                          get_field_val(ral.aes_core.CTRL_SHADOWED.KEY_LEN, wdata),
                          get_field_val(ral.aes_core.CTRL_SHADOWED.MANUAL_OPERATION, wdata),
                          get_field_val(ral.aes_core.CTRL_SHADOWED.SIDELOAD, wdata),
                          get_field_val(ral.aes_core.CTRL_SHADOWED.PRNG_RESEED_RATE, wdata));

    input_item.clean();
    input_item.start_item = 1;
    if (input_item.sideload_en) begin
      exp_clear = 1;
    end
  endfunction

  function void on_ctrl_gcm_shadowed_write(logic [31:0] wdata);
    bit [AES_GCMPHASE_WIDTH-1:0] gcm_phase;
    gcm_phase_e gcm_phase_prev;
    bit [4:0] num_valid_bytes;
    // The hardware resolves invalid values to GCM_INIT and only allows certain phase transitions.
    // General notes:
    // - Whether the initialization is actually done is hard to track. This is thus
    //   verified using a directed test.
    // - Whether a first block has been processed already and the DUT can enter GCM_SAVE is hard to
    //   track. This is thus verified using a directed test.
    gcm_phase_prev = gcm_phase_e'(`gmv(ral.aes_core.CTRL_GCM_SHADOWED.PHASE));
    gcm_phase = get_field_val(ral.aes_core.CTRL_GCM_SHADOWED.PHASE, wdata);
    if (!(gcm_phase inside {GCM_INIT,
                            GCM_RESTORE,
                            GCM_AAD,
                            GCM_TEXT,
                            GCM_SAVE,
                            GCM_TAG})) begin
      gcm_phase = GCM_INIT;
    end
    case (gcm_phase)
      GCM_INIT:; // Switching to GCM_INIT is always possible.
      GCM_RESTORE: begin
        // Restoring is only possible after initialization.
        if (gcm_phase_prev != GCM_INIT) begin
          gcm_phase = gcm_phase_prev;
        end
      end
      GCM_AAD: begin
        // Processing the AAD is only possible after initialization and restoring.
        if (gcm_phase_prev != GCM_INIT &&
            gcm_phase_prev != GCM_RESTORE) begin
          gcm_phase = gcm_phase_prev;
        end
      end
      GCM_TEXT: begin
        // Processing plain- and ciphertexts is only possible after initialization, restoring,
        // and after the AAD.
        if (gcm_phase_prev != GCM_INIT &&
            gcm_phase_prev != GCM_RESTORE &&
            gcm_phase_prev != GCM_AAD) begin
          gcm_phase = gcm_phase_prev;
        end
      end
      GCM_SAVE: begin
        // Saving a context is only possible after processing the AAD or the plain/ciphertext.
        if (gcm_phase_prev != GCM_AAD &&
            gcm_phase_prev != GCM_TEXT) begin
          gcm_phase = gcm_phase_prev;
        end
      end
      GCM_TAG: begin
        // Producing the tag is possible after initialization, and after processing AAD and plain-
        // or ciphertext.
        if (gcm_phase_prev != GCM_INIT &&
            gcm_phase_prev != GCM_AAD &&
            gcm_phase_prev != GCM_TEXT) begin
          gcm_phase = gcm_phase_prev;
        end
      end
      default:;
    endcase
    case (gcm_phase)
      GCM_INIT:     input_item.item_type = AES_CFG;
      GCM_RESTORE:  input_item.item_type = AES_GCM_RESTORE;
      GCM_AAD:      input_item.item_type = AES_GCM_AAD;
      GCM_TEXT:     input_item.item_type = AES_DATA;
      GCM_SAVE:     input_item.item_type = AES_GCM_SAVE;
      GCM_TAG:      input_item.item_type = AES_GCM_TAG;
      default:      input_item.item_type = AES_CFG;
    endcase
    // Invalid values such as values in the range of [17, 31] and 0 are resolved to 16 in hardware.
    num_valid_bytes = get_field_val(ral.aes_core.CTRL_GCM_SHADOWED.NUM_VALID_BYTES, wdata);
    input_item.data_len = (num_valid_bytes < 1) || (num_valid_bytes > 16) ? 16 : num_valid_bytes;

    cov_if.cg_ctrl_gcm_reg_sample(get_field_val(ral.aes_core.CTRL_GCM_SHADOWED.PHASE, wdata));
  endfunction

  function void on_key_share_write(string csr_name, logic [31:0] wdata);
    for (int share = 0; share < 2; share++) begin
      for (int i = 0; i < 8; i++) begin
        string keyname = $sformatf("key_share%0d_%0d", share, i);
        if (keyname == csr_name) begin
          input_item.key[share][i]     = wdata;
          input_item.key_vld[share][i] = 1'b1;
          cov_if.cg_key_sample(i + 8 * share);
        end
      end
    end
  endfunction

  function void on_data_in_write(string csr_name, logic [31:0] wdata);
    for (int i = 0; i < 4; i++) begin
      string keyname = $sformatf("data_in_%0d", i);
      // you can update datain until all have been
      // updated then DUT will auto start
      if (keyname == csr_name && (|datain_rdy || input_item.manual_op)) begin
        input_item.data_in[i]     = wdata;
        input_item.data_in_vld[i] = 1'b1;
        cov_if.cg_wr_data_sample(i);
        datain_rdy[i] = 0;
      end
    end
  endfunction

  function void on_iv_in_write(string csr_name, logic [31:0] wdata);
    for (int i = 0; i < 4; i++) begin
      string keyname = $sformatf("iv_%0d", i);
      if (keyname == csr_name) begin
        input_item.iv[i]      = wdata;
        input_item.iv_vld[i]  = 1'b1;
        cov_if.cg_iv_sample(i);
      end
    end
  endfunction

  function void on_trigger_write(logic [31:0] wdata);
    //start triggered
    cov_if.cg_trigger_sample(get_field_val(ral.aes_core.TRIGGER.START, wdata),
                             get_field_val(ral.aes_core.TRIGGER.KEY_IV_DATA_IN_CLEAR, wdata),
                             get_field_val(ral.aes_core.TRIGGER.DATA_OUT_CLEAR, wdata),
                             get_field_val(ral.aes_core.TRIGGER.PRNG_RESEED, wdata));
    `uvm_info(`gfn, $sformatf("\nWrite to Trigger register observed: 0x%h", wdata), UVM_MEDIUM)
    if (get_field_val(ral.aes_core.TRIGGER.START, wdata)) begin
      if (input_item.mode != AES_GCM) begin
        ok_to_fwd = input_item.mode != AES_NONE;
      end else if (`EN_GCM == 0) begin
        // We have an AES-GCM item but the hardware doesn't support GCM. This item is treated like
        // an item with mode AES_NONE.
        ok_to_fwd = 0;
      end else begin
        // In the AES-GCM mode, when we trigger the block, GCM is in the INIT
        // phase. In this phase, the hash subkey and the encrypted initial counter
        // block are generated, but no output that we want to read is generated.
        // Hence, do not forward this item.
        ok_to_fwd = input_item.item_type != AES_CFG;
      end
    end
    // clear key, IV, data_in
    if (get_field_val(ral.aes_core.TRIGGER.KEY_IV_DATA_IN_CLEAR, wdata)) begin
      void'(input_item.key_clean(0, 1));
      void'(input_item.iv_clean(0, 1));
      void'(key_item.key_clean(0, 1));
      input_item.clean_data_in();
      datain_rdy = 4'b0;
      // if in the middle of a message
      // this is seen as the beginning of a new message
      if (!input_item.start_item) begin
        input_item.start_item = 1;
        if (!exp_clear) input_item.split_item = 1;
        exp_clear = 0;
        `uvm_info(`gfn, $sformatf("splitting message"), UVM_MEDIUM)
      end
      `uvm_info(`gfn, $sformatf("\n\t ----| clearing KEY"), UVM_MEDIUM)
      `uvm_info(`gfn, $sformatf("\n\t ----| clearing IV"), UVM_MEDIUM)
      `uvm_info(`gfn, $sformatf("\n\t ----| clearing DATA_IN"), UVM_MEDIUM)
    end
    // clear data out
    if (get_field_val(ral.aes_core.TRIGGER.DATA_OUT_CLEAR, wdata)) begin
      `uvm_info(`gfn, $sformatf("\n\t ----| clearing DATA_OUT"), UVM_MEDIUM)
      if (cfg.clear_reg_w_rand) begin
        input_item.data_out = {4{$urandom()}};
      end else begin
        input_item.data_out = '0;
      end
      // marking the output item as potentially bad
      output_item.data_was_cleared = 1;
      // set to make sure any input item
      // waiting for output data is forwarded without the data.
    end
    // reseed
    if (get_field_val(ral.aes_core.TRIGGER.PRNG_RESEED, wdata)) begin
      // The PRNG reseeding is tested using the dedicated aes_reseed_vseq.sv sequence.
    end
  endfunction

  // Handle a write to a named CSR on the A channel
  function void on_addr_channel_write(string csr_name, logic [31:0] wdata);
    alert_test_t alert_test;
    // add individual case item for each csr
    case (1)
      (!uvm_re_match("alert_test", csr_name)): begin
        alert_test.recov_ctrl_update_err = wdata[0];
        alert_test.fatal_fault = wdata[1];
        cov_if.cg_alert_test_sample(alert_test);
      end

      (!uvm_re_match("ctrl_shadowed", csr_name)): begin
        // ignore reg write if busy
        if (cfg.idle_vif) on_ctrl_shadowed_write(wdata);
      end

      (!uvm_re_match("ctrl_gcm_shadowed", csr_name)): begin
        // ignore reg write if busy
        if (cfg.idle_vif) on_ctrl_gcm_shadowed_write(wdata);
      end

      (!uvm_re_match("key_share*", csr_name)): begin
        // ignore reg write if busy
        if (cfg.idle_vif) on_key_share_write(csr_name, wdata);
      end

      (!uvm_re_match("data_in_*", csr_name)): begin
        on_data_in_write(csr_name, wdata);
      end

      (!uvm_re_match("iv_*", csr_name)): begin
        // ignore reg write if busy
        if (cfg.idle_vif) on_iv_in_write(csr_name, wdata);
      end

      (!uvm_re_match("trigger", csr_name)): begin
        on_trigger_write(wdata);
      end

      (!uvm_re_match("ctrl_aux_regwen", csr_name)): begin
        cov_if.cg_aux_regwen_sample(wdata[0]);
      end

      // (!uvm_re_match("status", csr_name)): begin
      //   // not used in scoreboard
      //  end

      default: begin
        // DO nothing- trying to write to a read only register
      end
    endcase
  endfunction


  // takes items from the item queue and builds full
  // aes_messages with both input data and output data.
  virtual task rebuild_message();
    typedef enum {
      MSG_IDLE,
      MSG_START,
      MSG_RUN
    } aes_message_stat_t;
    aes_message_stat_t msg_state = MSG_IDLE;
    aes_message_item message, msg_clone;
    aes_seq_item full_item;
    string txt =  "";

    message = new();

    fork
      begin : rebuild_messages
        forever begin
          item_fifo.get(full_item);
          if (msg_state == MSG_IDLE) begin
            // We have just received the very first item after a reset and can now start the regular
            // processing.
            msg_state = MSG_START;
          end
          case (msg_state)
            MSG_START: begin
              if (!full_item.message_start()) begin
                // Check if e.g. the start trigger got fired prematurely and skip this message if
                // needed.
                if (full_item.start_item && full_item.manual_op) begin
                  `uvm_info(`gfn, "setting skip_msg", UVM_MEDIUM)
                  message.skip_msg = 1;
                end else begin
                  `uvm_fatal(`gfn,
                      $sformatf("\n\t ----| FIRST ITEM DID NOT HAVE MESSAGE START/CONFIG SETTINGS"))
                end
              end
              `uvm_info(`gfn, $sformatf("rebuilding %s message, adding start item",
                  full_item.mode.name()), UVM_MEDIUM)
              message.add_start_msg_item(full_item);
              msg_state = MSG_RUN;
            end

            MSG_RUN: begin
              if (full_item.message_start() || (full_item.start_item && full_item.manual_op)) begin
                // The current item marks the start of a new message. End the previous message and
                // add it to the message FIFO for scoring.
                `downcast(msg_clone, message.clone());
                `uvm_info(`gfn, $sformatf("adding %s message item of size %0d to msg_fifo",
                    msg_clone.aes_mode.name(), msg_clone.output_msg.size()), UVM_MEDIUM)
                msg_fifo.put(msg_clone);
                message = new();
                if (full_item.start_item && full_item.manual_op) begin
                  // Skip the message if this is item not really marks the start of a message.
                  if (!full_item.message_start() || !full_item.data_in_valid()) begin
                    `uvm_info(`gfn, $sformatf("setting skip_msg"), UVM_MEDIUM)
                    message.skip_msg = 1;
                  end else begin
                    message.skip_msg = 0;
                  end
                end
                `uvm_info(`gfn, $sformatf("rebuilding %s message, adding start item",
                    full_item.mode.name()), UVM_MEDIUM)
                message.add_start_msg_item(full_item);
              end else begin
                `uvm_info(`gfn, $sformatf("rebuilding %s message, adding data block #%0d",
                    full_item.mode.name(), message.output_msg.size()/16), UVM_MEDIUM)
                if (full_item.mode == AES_GCM) begin
                  if (full_item.item_type == AES_GCM_AAD) begin
                    message.add_aad_item(full_item);
                  end else if (full_item.item_type == AES_GCM_TAG) begin
                    message.add_tag_item(full_item);
                  end else begin
                    message.add_data_item(full_item);
                  end
                end else begin
                  message.add_data_item(full_item);
                end
              end
            end
          endcase // case (msg_state)
        end
      end

      begin : finish_last_message
        forever begin
          // AES indicates when it's done with processing individual blocks but not when it's done
          // with processing an entire message. To detect the end of a message, the DV environment
          // does the following:
          // - It tracks writes to the main control register. If two successful writes to this
          //   shadowed register are observed, this marks the start of a new message.
          // - DV then knows that the last output data retrieved marks the end of the previous
          //   message.
          // This works fine except for the very last message before the sequence ends. To mark the
          // end of the last message, the `finish_message` variable is used. It gets set by the
          // `post_body()` task defined in the base vseq.
          wait (cfg.finish_message)
          `uvm_info(`gfn, $sformatf("finish_message received"), UVM_MEDIUM)
          if (msg_state != MSG_IDLE) begin
            // The message rebuilding thread isn't idle, i.e., there was some activity since the
            // last reset.
            `downcast(msg_clone, message.clone());
            `uvm_info(`gfn, $sformatf("adding %s message item of size %0d to msg_fifo",
                msg_clone.aes_mode.name(), msg_clone.output_msg.size()), UVM_MEDIUM)
            msg_fifo.put(msg_clone);
            // Reset the message rebuilding thread.
            reset_rebuilding = 1;
          end
          // Increment counter for total number of messages seen. If the message rebuilding thread
          // is still idle, no message did actually go through the DUT and we can skip incrementing
          // the counter. The only exception is if all messages were corrupted. The DUT doesn't
          // produce any output in this case.
          if ((msg_state != MSG_IDLE) || (cfg.num_messages == cfg.num_corrupt_messages)) begin
            cfg.num_messages_tot += cfg.num_messages;
          end
          wait_fifo_empty();
          cfg.finish_message = 0;
        end
      end

      begin: reset_rebuild_messages
        forever begin
          wait (reset_rebuilding);
          msg_state = MSG_IDLE;
          message = new();
          reset_rebuilding = 0;
        end
      end
    join
  endtask // rebuild_message


  virtual task compare();
    string txt="";
    forever begin
      bit operation;
      int crypto_res;
      aes_message_item msg;
      bit [7:0] in_aad[];
      bit [3:0][31:0] predicted_tag;
      bit [3:0][31:0] out_tag;
      msg_fifo.get(msg);

      if (msg.aes_mode != AES_NONE && !msg.skip_msg &&
          (`EN_GCM || msg.aes_mode != AES_GCM)) begin
        msg.alloc_predicted_msg();

        operation = msg.aes_operation == AES_ENC ? 1'b0 :
                    msg.aes_operation == AES_DEC ? 1'b1 : 1'b0;

        if (msg.aes_mode == AES_GCM) begin
          in_aad = msg.aad_length == 0 ? {'0} : msg.input_aad;
          out_tag = msg.output_tag;
        end else begin
          // All modes except GCM do not take an AAD as an input. Just pass '0
          // to avoid passing a NULL object to the C_DPI library.
          in_aad = {'0};
          // As only GCM produces an tag, set it to 0 for all other modes. The
          // C_DPI library ignores it for those modes.
          out_tag = '0;
        end

        // ref-model    / operation     / chipher mode / IV             //
        // key_len      / key           / data length  / AAD length     //
        // data         / AAD           / tag          / data out       //
        // tag out      / crypto lib error code                         //
        c_dpi_aes_crypt_message(cfg.ref_model, operation, msg.aes_mode, msg.aes_iv,
                                msg.aes_keylen, msg.aes_key[0] ^ msg.aes_key[1],
                                msg.message_length, msg.aad_length, msg.input_msg,
                                in_aad, out_tag, msg.predicted_msg, predicted_tag,
                                crypto_res);
        if (crypto_res < 0) begin
          // The underlying c_dpi cyrpto lib returns an error code < 0 if something
          // is wrong.
          if (msg.aes_mode == AES_GCM) begin
            if (msg.output_tag_vld) begin
              // When doing an AES-GCM decryption, the tag is directly compared and
              // the c_dpi crypto lib returns -1.
              `uvm_fatal(`gfn, "c_dpi crypto lib tag mismatch detected!\n")
            end
          end else begin
            `uvm_fatal(`gfn, "c_dpi crypto lib returned an error code!\n")
          end
        end

        `uvm_info(`gfn, $sformatf("\n\t ----| printing MESSAGE %s", msg.convert2string()),
                  UVM_MEDIUM)
        txt = "";

        foreach (msg.input_msg[i]) begin
          txt = { txt, $sformatf("\n\t %d %h \t %h \t %h \t %b",
              i, msg.input_msg[i], msg.output_msg[i], msg.predicted_msg[i], msg.output_cleared[i])};
        end

        for (int n =0 ; n < msg.message_length; n++) begin
          if ((msg.output_msg[n] != msg.predicted_msg[n]) && ~msg.output_cleared[n]) begin
            txt = {"\t TEST FAILED MESSAGES DID NOT MATCH \n ", txt};

            txt = {txt,
                 $sformatf("\n\n\t ----| ACTUAL OUTPUT DID NOT MATCH PREDICTED OUTPUT |----")};
            txt = {txt,
                 $sformatf("\n\t ----| FAILED AT BYTE #%0d \t ACTUAL: 0x%h \t PREDICTED: 0x%h ",
                                  n, msg.output_msg[n], msg.predicted_msg[n])};
            `uvm_fatal(`gfn, $sformatf(" # %0d  \n\t %s \n", cfg.good_cnt, txt))
          end
        end

        // Only check the tag when in AES_GCM mode and we did an AES_ENC operation.
        // For AES_DEC, the tag check happens directly inside c_dpi_aes_crypt_message()
        // and we check the error code above.
        if (msg.aes_mode == AES_GCM && msg.aes_operation == AES_ENC) begin
          txt = "";
          predicted_tag = aes_transpose(predicted_tag);
          foreach(predicted_tag[n]) begin
            if ((predicted_tag[n] != msg.output_tag[n]) && msg.output_tag_vld) begin
              txt = {"\t TEST FAILED TAGS DID NOT MATCH \n ", txt};

              txt = {txt,
                  $sformatf("\n\n\t ----| ACTUAL OUTPUT DID NOT MATCH PREDICTED OUTPUT |----")};
              txt = {txt,
                  $sformatf("\n\t ----| FAILED AT WORD #%0d \t ACTUAL: 0x%h \t PREDICTED: 0x%h ",
                                    n, predicted_tag[n], msg.output_tag[n])};
              `uvm_fatal(`gfn, $sformatf(" # %0d  \n\t %s \n", cfg.good_cnt, txt))
            end
          end
        end

        `uvm_info(`gfn,
            $sformatf("\n\t ----|   MESSAGE #%0d MATCHED  %s  |-----",
                cfg.good_cnt, msg.aes_mode.name()), UVM_MEDIUM)
        cfg.good_cnt++;

        if (msg.aes_mode == AES_GCM) begin
          // As the message and tag matched the predicted output, sample AAD &
          // message length as well as the mode of operation.
          int msg_blocks = msg.message_length / 16;
          int msg_last_block_len_bytes = msg.message_length % 16;
          int msg_block_zero = msg.message_length == 0 ? 1 : 0;
          int aad_blocks = msg.aad_length / 16;
          int aad_last_block_len_bytes = msg.aad_length % 16;
          int aad_block_zero = msg.aad_length == 0 ? 1 : 0;
          cov_if.cg_gcm_len_sample(aad_blocks, aad_last_block_len_bytes, aad_block_zero,
                                   msg_blocks, msg_last_block_len_bytes, msg_block_zero,
                                   msg.aes_operation);
        end

      end else begin
        if (msg.aes_mode == AES_NONE) begin
          `uvm_info(`gfn,
              $sformatf("\n\t ----| MESSAGE #%0d HAS ILLEGAL MODE MESSAGE IGNORED     |-----",
                  cfg.good_cnt), UVM_MEDIUM)
          cfg.corrupt_cnt++;
        end
        if (msg.skip_msg) begin
          `uvm_info(`gfn,
              $sformatf("\n\t ----| MESSAGE #%0d was skipped due to start triggered prematurely",
                  cfg.good_cnt), UVM_MEDIUM)
          cfg.skipped_cnt++;
        end
        if ((`EN_GCM == 0) && (msg.aes_mode == AES_GCM)) begin
          `uvm_info(`gfn,
              $sformatf("\n\t ----| MESSAGE #%0d HAS ILLEGAL MODE MESSAGE IGNORED     |-----",
                  cfg.good_cnt), UVM_MEDIUM)
          cfg.corrupt_cnt++;
        end
      end
    end
  endtask


  virtual function void phase_ready_to_end(uvm_phase phase);
    if (phase.get_name() != "run") return;

    // Don't end the test yet. First, the last message needs to be scored, and all queues and
    // FIFOs need to be emptied.
    phase.raise_objection(this, "need time to finish last item");
    fork begin
      wait_fifo_empty();
      phase.drop_objection(this);
    end
    join_none
  endfunction


  virtual task wait_fifo_empty();
    `uvm_info(`gfn, $sformatf("item fifo entries %d", item_fifo.num()), UVM_MEDIUM)
    `uvm_info(`gfn, $sformatf("rcv_queue entries %d", rcv_item_q.size()), UVM_MEDIUM)
    `uvm_info(`gfn, $sformatf("rcv_aad_queue entries %d", rcv_aad_item_q.size()), UVM_MEDIUM)
    `uvm_info(`gfn, $sformatf("msg fifo entries %d", msg_fifo.num()), UVM_MEDIUM)
    wait (rcv_item_q.size()     == 0);
    wait (rcv_aad_item_q.size() == 0);
    wait (item_fifo.num()       == 0);
    wait (msg_fifo.num()        == 0);
  endtask


  virtual function void reset(string kind = "HARD");
    aes_seq_item     seq_item;
    aes_message_item msg_item;
    super.reset(kind);
    // reset local fifos queues and variables
    rcv_item_q.delete();
    rcv_aad_item_q.delete();
    while (item_fifo.try_get(seq_item));
    while (msg_fifo.try_get(msg_item));

    cfg.num_messages_tot = 0;
    cfg.good_cnt = 0;
    cfg.corrupt_cnt = 0;
    cfg.skipped_cnt = 0;
    cfg.split_cnt = 0;
    // if split is set before reset make sure to cancel
    input_item.split_item = 0;
    // reset compare task to start
    reset_rebuilding = 1;
  endfunction


  function string counters2string(string txt);
      txt = { txt, $sformatf("\n\t ----| Expected:           %0d", cfg.num_messages_tot)};
      txt = { txt, $sformatf("\n\t ----| Seen:               %0d", cfg.good_cnt)};
      txt = { txt, $sformatf("\n\t ----| Expected corrupted: %0d", cfg.num_corrupt_messages)};
      txt = { txt, $sformatf("\n\t ----| Seen corrupted:     %0d", cfg.corrupt_cnt)};
      txt = { txt, $sformatf("\n\t ----| Skipped:            %0d", cfg.skipped_cnt)};
      txt = { txt, $sformatf("\n\t ----| Split:              %0d", cfg.split_cnt)};
      return txt;
  endfunction


  function void check_message_counters();
    uvm_report_server rpt_srvr;
    string txt = "";
    // check that we saw all messages
    // if there is more than expected check split count
    if (cfg.good_cnt <
        (cfg.num_messages_tot - cfg.num_corrupt_messages - cfg.skipped_cnt)) begin
      rpt_srvr = uvm_report_server::get_server();
      if (rpt_srvr.get_severity_count(UVM_FATAL)
           + rpt_srvr.get_severity_count(UVM_ERROR) == 0) begin
        txt = "\n\t ----| NO FAILURES BUT NUMBER OF EXPECTED MESSAGES DOES NOT MATCH ACTUAL";
      end else begin
        txt = "\n\t ----| TEST FAILED";
      end
      txt = counters2string(txt);
      `uvm_fatal(`gfn, $sformatf("%s", txt))
    end
    if ((cfg.good_cnt >
        (cfg.num_messages_tot - cfg.num_corrupt_messages - cfg.skipped_cnt))
        && (cfg.split_cnt == 0)) begin
      txt = "\n\t ----| SAW TOO MANY MESSAGES AND NONE WAS SPLIT";
      txt = counters2string(txt);
      `uvm_fatal(`gfn, $sformatf("%s", txt))
    end
  endfunction


  function void check_phase(uvm_phase phase);
    if (cfg.en_scb) begin
      super.check_phase(phase);
      `DV_EOT_PRINT_MAILBOX_CONTENTS(aes_message_item, msg_fifo)
      `DV_EOT_PRINT_MAILBOX_CONTENTS(aes_seq_item, item_fifo)
      `DV_EOT_PRINT_Q_CONTENTS(aes_seq_item, rcv_item_q)
      `DV_EOT_PRINT_Q_CONTENTS(aes_seq_item, rcv_aad_item_q)
      check_message_counters();
    end
  endfunction


  function void report_phase(uvm_phase phase);
    uvm_report_server rpt_srvr;
    string txt = "";

    super.report_phase(phase);
    txt = "\n\t ----|        TEST FINISHED        |----";
    txt = counters2string(txt);
    rpt_srvr = uvm_report_server::get_server();
    if (rpt_srvr.get_severity_count(UVM_FATAL) + rpt_srvr.get_severity_count(UVM_ERROR) > 0) begin
      `uvm_info(`gfn, $sformatf("%s", cfg.convert2string()), UVM_LOW)
      txt = {txt, "\n\t ---------------------------------------"};
      txt = {txt, "\n\t ----            TEST FAILED        ----"};
      txt = {txt, "\n\t ---------------------------------------"};
    end else begin
      txt = {txt, "\n\t ---------------------------------------"};
      txt = {txt, "\n\t ----            TEST PASSED        ----"};
      txt = {txt, "\n\t ---------------------------------------"};
    end
    `uvm_info(`gfn, $sformatf("%s", txt), UVM_MEDIUM)

  endfunction // report_phase
endclass
