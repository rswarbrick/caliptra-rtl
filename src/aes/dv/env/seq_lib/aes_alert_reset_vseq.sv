// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This test randomly injects resets and alert conditions such as:
// - storage errors in the mode field of the shadowed main control register,
// - life cycle escalations, and
// - writes to the alert test CSR.
class aes_alert_reset_vseq extends aes_base_vseq;
  `uvm_object_utils(aes_alert_reset_vseq)

  `uvm_object_new
  aes_message_item my_message;
  status_t aes_status;
  bit finished_all_msgs = 0;
  rand bit [$bits(aes_mode_e)-1:0] mal_error;
  constraint mal_error_c { $countones(mal_error) > 1; }
  rand bit [$bits(lc_ctrl_pkg::lc_tx_t)-1:0] lc_esc;
  constraint lc_esc_c { lc_esc != lc_ctrl_pkg::Off; }
  rand alert_test_t alert_test_value;
  constraint alert_test_value_c { $countones(alert_test_value) > 1; }

  virtual task pre_start();
    super.pre_start();
    expect_fatal_alerts = 1;
  endtask

  // Write wdata to ALERT_TEST. Exit early on reset.
  task write_alert_test(uvm_reg_data_t wdata);
    uvm_status_e txn_status;

    ral.alert_test.write(txn_status, wdata);
    if (cfg.under_reset) return;
    if (txn_status != UVM_IS_OK) `uvm_error(get_full_name(), "Failed to write ALERT_TEST.")
  endtask

  task body();
    `uvm_info(`gfn, $sformatf("\n\n\t ----| STARTING AES MAIN SEQUENCE |----\n %s",
                              cfg.convert2string()), UVM_LOW)

    // generate list of messages //
    generate_message_queue();

    // process all messages //
    fork
      begin: isolation_fork
        fork
          error: begin
            cfg.clk_rst_vif.wait_clks(cfg.inj_delay);
            if (cfg.alert_reset_trigger == ShadowRegStorageErr) begin
              `uvm_info(`gfn, "Injecting storage error into shadowed main control register",
                  UVM_MEDIUM)
              if (!uvm_hdl_check_path(
                  "tb.dut.aes_inst.u_aes_core.u_ctrl_reg_shadowed.u_ctrl_reg_shadowed_mode.committed_q"
                  )) begin
                `uvm_fatal(`gfn, $sformatf("\n\t ----| PATH NOT FOUND"))
              end else begin
                void'(uvm_hdl_force(
                    "tb.dut.aes_inst.u_aes_core.u_ctrl_reg_shadowed.u_ctrl_reg_shadowed_mode.committed_q",
                    mal_error));
                wait(!cfg.clk_rst_vif.rst_n);
                void'(uvm_hdl_release(
                    "tb.dut.aes_inst.u_aes_core.u_ctrl_reg_shadowed.u_ctrl_reg_shadowed_mode.committed_q"));
              end
            end else if (cfg.alert_reset_trigger == PullReset) begin
              `uvm_info(`gfn, "Pulling reset", UVM_MEDIUM)
              aes_reset();
              #10ps;
              wait(!cfg.under_reset);
            end else if (cfg.alert_reset_trigger == LcEscalate) begin
              `uvm_info(`gfn, "Triggering life cycle escalation", UVM_MEDIUM)
               cfg.lc_escalate_vif.drive({lc_esc,1'b1});
               wait(!cfg.clk_rst_vif.rst_n);
               cfg.lc_escalate_vif.drive('0);
            end else if (cfg.alert_reset_trigger == AlertTest) begin
              `uvm_info(`gfn, "Writing alert test CSR", UVM_MEDIUM)
              write_alert_test(alert_test_value);
              if (cfg.under_reset) return;
              // Wait to see the actual alert signal. Note that the DUT doesn't block even if the
              // fatal_fault alert has been triggered.
              fork
                wait_for_fatal_alert: begin
                  if (alert_test_value.fatal_fault) begin
                    cfg.m_alert_agent_cfgs["fatal_fault"].vif.wait_ack_complete();
                  end
                end
                wait_for_recov_alert: begin
                  if (alert_test_value.recov_ctrl_update_err) begin
                    cfg.m_alert_agent_cfgs["recov_ctrl_update_err"].vif.wait_ack_complete();
                  end
                end
              join
              // Clear alert test CSR.
              write_alert_test(0);
              if (cfg.under_reset) return;
            end
          end
          basic: begin
            // Process messages and recover from randomly inserted resets and alert conditions.
            // If required, the DUT is reset to recover from fatal alert conditions.
            send_msg_queue(cfg.unbalanced, cfg.read_prob, cfg.write_prob);
            finished_all_msgs = 1;
          end
        join_none
        // make sure we don't wait for a reset that never comes
        // in case the inject happened after test finished
        wait (finished_all_msgs);
        /* wait_no_outstanding_access(): no-op after csr_utils removal */;
        disable fork;
      end // fork
    join
  endtask : body
endclass
