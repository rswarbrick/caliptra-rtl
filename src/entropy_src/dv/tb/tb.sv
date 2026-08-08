// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
module tb;
  // dep packages
  import uvm_pkg::*;
  import dv_utils_pkg::*;
  import entropy_src_env_pkg::*;
  import entropy_src_test_pkg::*;
  import entropy_src_pkg::entropy_src_xht_rsp_t;

  import caliptra_prim_mubi_pkg::mubi8_t;

  // macro includes
  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  localparam int unsigned ahb_data_width = `CALIPTRA_AHB_HDATA_SIZE;
  localparam int unsigned ahb_addr_width = `CALIPTRA_SLAVE_ADDR_WIDTH(`CALIPTRA_SLAVE_SEL_ENTROPY_SRC);

  wire clk, rst_n;
  clk_rst_if clk_rst_if(.clk(clk), .rst_n(rst_n));
  reset_if reset_if(.clk_i(clk), .rst_n(rst_n));

  // An additional local reset for the csrng pull agent
  //
  // This is needed in particular for this pull agent as
  // the entropy source may (by design!) become unable to provide
  // seeds to the CSRNG under certain conditions.  This reset
  // communicates to the agent that it is time to cleanly exit.
  // By using a reset, the VIF is allowed to clear REQ, within
  // triggering an assertion.
  wire csrng_rst_n;
  clk_rst_if csrng_rst_if(.clk(), .rst_n(csrng_rst_n));

  // AHB host-side interface.
  //
  // This gets configured by an initial block to be in Host mode, meaning that an agent will drive
  // the manager side of the interface (which also includes a decoder and multiplexor).
  //
  // The subordinate side of the interface has a single subordinate, which is driven by the dut
  // below.
  ahb_if ahb_if_h (.clk_i(clk), .rst_ni(rst_n));

  initial begin
    ahb_if_h.if_mode           = Host;
    ahb_if_h.addr_width        = ahb_addr_width;
    ahb_if_h.hburst_width      = 0;
    ahb_if_h.hprot_width       = 0;
    ahb_if_h.data_width        = ahb_data_width;
    ahb_if_h.has_write_strobes = 0;
    ahb_if_h.num_subordinates  = 1;
  end

  wire [7:0] otp_en_es_fw_read, otp_en_es_fw_over;
  pins_if#(8) otp_en_es_fw_read_if(otp_en_es_fw_read);
  pins_if#(8) otp_en_es_fw_over_if(otp_en_es_fw_over);

  push_pull_if#(.HostDataWidth(entropy_src_pkg::RNG_BUS_WIDTH))
      rng_if(.clk(clk), .rst_n(csrng_rst_n));
  push_pull_if#(.HostDataWidth(entropy_src_pkg::FIPS_CSRNG_BUS_WIDTH))
      csrng_if(.clk(clk), .rst_n(csrng_rst_n));
  push_pull_if#(.HostDataWidth(0)) aes_halt_if(.clk(clk), .rst_n(csrng_rst_n && rst_n));

  entropy_src_path_if entropy_src_path_if ();

  // dut
  entropy_src #(
    .AHBDataWidth(ahb_data_width),
    .AHBAddrWidth(ahb_addr_width)
  ) dut (
    .clk_i                        ( clk        ),
    .rst_ni                       ( rst_n      ),

    .haddr_i                      ( ahb_if_h.haddr[ahb_addr_width-1:0]     ),
    .hwdata_i                     ( ahb_if_h.hwdata[ahb_data_width-1:0]    ),
    .hsel_i                       ( ahb_if_h.hsel[0]                       ),
    .hwrite_i                     ( ahb_if_h.hwrite                        ),
    .hready_i                     ( ahb_if_h.hready                        ),
    .htrans_i                     ( ahb_if_h.htrans                        ),
    .hsize_i                      ( ahb_if_h.hsize                         ),
    .hresp_o                      ( ahb_if_h.hresp[0]                      ),
    .hreadyout_o                  ( ahb_if_h.hreadyout[0]                  ),
    .hrdata_o                     ( ahb_if_h.hrdata[0][ahb_data_width-1:0] ),

    .otp_en_entropy_src_fw_read_i ( mubi8_t'(otp_en_es_fw_read) ),
    .otp_en_entropy_src_fw_over_i ( mubi8_t'(otp_en_es_fw_over) ),

    // Not connected: port unused in caliptra_top
    .rng_fips_o                   (),

    .entropy_src_hw_if_o          ( {csrng_if.ack,
                                     csrng_if.d_data[entropy_src_pkg::CSRNG_BUS_WIDTH-1:0],
                                     csrng_if.d_data[entropy_src_pkg::CSRNG_BUS_WIDTH]} ),
    .entropy_src_hw_if_i          ( csrng_if.req ),

    .entropy_src_rng_o            ( rng_if.ready                  ),
    .entropy_src_rng_i            ( {rng_if.valid, rng_if.h_data} ),

    .cs_aes_halt_o                ( aes_halt_if.req ),
    .cs_aes_halt_i                ( aes_halt_if.ack ),

    // External health test ports not connected: feature is unused in caliptra_top.
    .entropy_src_xht_o            (),
    .entropy_src_xht_i            ( entropy_src_xht_rsp_t'(0) ),

    // Alert interface ports not connected: feature is unused in caliptra_top.
    .alert_rx_i                   ( {caliptra_prim_alert_pkg::ALERT_RX_DEFAULT,
                                     caliptra_prim_alert_pkg::ALERT_RX_DEFAULT} ),
    .alert_tx_o                   (),

    // Interrupt pins not connected: feature is unused in caliptra_top
    .intr_es_entropy_valid_o      (),
    .intr_es_health_test_failed_o (),
    .intr_es_observe_fifo_ready_o (),
    .intr_es_fatal_err_o          ()
  );

  bind caliptra_prim_packer_fifo : dut.u_entropy_src_core.u_caliptra_prim_packer_fifo_precon
    entropy_subsys_fifo_exception_if #(
      .IsPackerFifo(1)
    ) u_fifo_exc_if (
      .clk_i,
      .rst_ni,
      .wready_o,
      .wvalid_i,
      .rready_i,
      .rvalid_o,
      .full_o (1'b0) // unused for Packer FIFO
    );

  bind caliptra_prim_packer_fifo : dut.u_entropy_src_core.u_caliptra_prim_packer_fifo_bypass
    entropy_subsys_fifo_exception_if #(
      .IsPackerFifo(1)
     ) u_fifo_exc_if (
      .clk_i,
      .rst_ni,
      .wready_o,
      .wvalid_i,
      .rready_i,
      .rvalid_o,
      .full_o (1'b0) // unused for Packer FIFO
    );

  bind caliptra_prim_sparse_fsm_flop : dut.u_entropy_src_core.u_entropy_src_main_sm.u_state_regs
    entropy_src_fsm_cov_if u_fsm_cov_if (.clk_i, .state_i, .state_o);

  entropy_src_tb_assertion_if assertion_if ();

  initial begin
    // Drive clk and rst_n from clk_if
    // Set interfaces in config_db

    // Drive clk from clk_rst_if but leave rst_n driven by reset_if (which is controlled by an agent
    // in the environment)
    clk_rst_if.set_active(.drive_clk_val(1), .drive_rst_n_val(0));
    csrng_rst_if.set_active();

    uvm_config_db#(virtual reset_if)::set(null, "*.env", "reset_vif", reset_if);
    uvm_config_db#(virtual clk_rst_if)::set(null, "*.env", "clk_rst_vif",   clk_rst_if);
    uvm_config_db#(virtual clk_rst_if)::set(null, "*.env", "csrng_rst_vif", csrng_rst_if);

    uvm_config_db#(virtual ahb_if)::set(null, "*.env", "ahb_vif", ahb_if_h);

    uvm_config_db#(virtual entropy_src_cov_if)::set(null, "*.env", "entropy_src_cov_if",
                                                    dut.u_entropy_src_cov_if);

    uvm_config_db#(virtual pins_if#(8))::set(null, "*.env", "otp_en_es_fw_read_vif",
                                             otp_en_es_fw_read_if);
    uvm_config_db#(virtual pins_if#(8))::set(null, "*.env", "otp_en_es_fw_over_vif",
                                             otp_en_es_fw_over_if);

    uvm_config_db#(virtual entropy_subsys_fifo_exception_if#(1))::
        set(null, "*.env", "precon_fifo_vif",
            dut.u_entropy_src_core.u_caliptra_prim_packer_fifo_precon.u_fifo_exc_if);
    uvm_config_db#(virtual entropy_subsys_fifo_exception_if#(1))::
        set(null, "*.env", "bypass_fifo_vif",
            dut.u_entropy_src_core.u_caliptra_prim_packer_fifo_bypass.u_fifo_exc_if);

    uvm_config_db#(virtual entropy_src_fsm_cov_if)::
        set(null, "*.env", "main_sm_cov_vif",
            dut.u_entropy_src_core.u_entropy_src_main_sm.u_state_regs.u_fsm_cov_if);

    uvm_config_db#(virtual entropy_src_path_if)::set(null, "*.env", "entropy_src_path_vif",
                                                     entropy_src_path_if);
    uvm_config_db#(virtual entropy_src_assertion_if)::set(null, "*.env", "assertion_vif",
                                                          assertion_if.u_assertion_if);

    uvm_config_db#(virtual push_pull_if#(.HostDataWidth(entropy_src_pkg::RNG_BUS_WIDTH)))::
        set(null, "*.env.m_rng_agent*", "vif", rng_if);
    uvm_config_db#(virtual push_pull_if#(.HostDataWidth(entropy_src_pkg::FIPS_CSRNG_BUS_WIDTH)))::
        set(null, "*.env.m_csrng_agent*", "vif", csrng_if);
    uvm_config_db#(virtual push_pull_if#(.HostDataWidth(0)))::
        set(null, "*.env.m_aes_halt_agent*", "vif", aes_halt_if);

    // In the block-level environment, there is one subordinate on the AHB: the sha3_ctrl instance,
    // with index 0.
    uvm_config_db#(int unsigned)::set(null, "*.env", "ahb_subordinate_index", 0);

    // The rng_if (which mimics the AST RNG) is expected to drop RNG inputs even if the
    // DUT is not ready.
    $assertoff(0, tb.rng_if.H_DataStableWhenValidAndNotReady_A);
    $assertoff(0, tb.rng_if.ValidHighUntilReady_A);

    $timeformat(-12, 0, " ps", 12);
    run_test();
  end

endmodule
