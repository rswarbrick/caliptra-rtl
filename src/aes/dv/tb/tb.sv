// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
module tb;
  import uvm_pkg::*;
  import dv_utils_pkg::*;
  import aes_env_pkg::*;
  import aes_test_pkg::*;

  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  wire                                    clk, rst_n;
  wire [$bits(lc_ctrl_pkg::lc_tx_t) : 0]  lc_escalate;
  wire                                    idle;

  ////////////////
  // Interfaces //
  ////////////////

  clk_rst_if clk_rst_if(.clk(clk), .rst_n(rst_n));

  pins_if #(1) idle_if (idle);

  // status_idle_o on the wrapper is a plain logic, drive the existing if directly.
  wire status_idle;
  assign idle = status_idle;

  // AHB host-side interface.
  //
  // This gets configured by an initial block to be in Host mode, meaning that an agent will drive
  // the manager side of the interface (which also includes a decoder and multiplexor).
  //
  // The subordinate side of the interface has a single subordinate, which is driven by continuous
  // assignments below.
  ahb_if ahb_if_h (.clk_i(clk), .rst_ni(rst_n));

  initial begin
    ahb_if_h.if_mode          = Host;
    ahb_if_h.addr_width       = 32;
    ahb_if_h.hburst_width     = 0;
    ahb_if_h.hprot_width      = 0;
    ahb_if_h.data_width       = 32;
    ahb_if_h.num_subordinates = 1;
  end

  // dut
  aes_clp_wrapper dut (
    .clk                              ( clk     ),
    .reset_n                          ( rst_n   ),
    // TODO: no power-management agent in DV; tie low.
    .cptra_pwrgood                    ( 1'b0    ),

    .haddr_i                          ( ahb_if_h.haddr[31:0]  ),
    .hwdata_i                         ( ahb_if_h.hwdata[31:0] ),
    .hsel_i                           ( ahb_if_h.hsel[0]      ),
    .hwrite_i                         ( ahb_if_h.hwrite       ),
    .hready_i                         ( ahb_if_h.hready       ),
    .htrans_i                         ( ahb_if_h.htrans       ),
    .hsize_i                          ( ahb_if_h.hsize        ),
    .hresp_o                          ( ahb_if_h.hresp[0]     ),
    .hreadyout_o                      ( ahb_if_h.hreadyout[0] ),
    .hrdata_o                         ( ahb_if_h.hrdata[0]    ),

    // TODO: no OCP-LOCK agent in DV; tie low.
    .ocp_lock_in_progress             ( 1'b0    ),
    .key_release_key_size             ( 16'b0   ),

    // status
    .input_ready_o                    (             ), // TODO: no DV consumer yet.
    .output_valid_o                   (             ), // TODO: no DV consumer yet.
    .status_idle_o                    ( status_idle ),

    // TODO: no DMA CIF agent in DV; tie inputs low, leave outputs open.
    .dma_req_dv                       ( 1'b0    ),
    .dma_req_write                    ( 1'b0    ),
    .dma_req_addr                     ( '0      ),
    .dma_req_wdata                    ( '0      ),
    .dma_req_hold                     (         ),
    .dma_req_error                    (         ),
    .dma_req_rdata                    (         ),

    // TODO: no KeyVault agent in DV; tie response inputs low, leave outputs open.
    .kv_read                          (         ),
    .kv_rd_resp                       ( '0      ),
    .kv_write                         (         ),
    .kv_wr_resp                       ( '0      ),

    // TODO: no DV consumer yet.
    .busy_o                           (         ),

    // TODO: no interrupt agent in DV; leave open.
    .error_intr                       (         ),
    .notif_intr                       (         ),

    // TODO: no debug-unlock / scan-mode driver in DV; tie low.
    .debugUnlock_or_scan_mode_switch  ( 1'b0    )
  );

  initial begin
    // Drive clk and rst_n from clk_if
    clk_rst_if.set_active();

    // Port Interfaces
    uvm_config_db#(virtual clk_rst_if)::set(     null, "*.env", "clk_rst_vif",      clk_rst_if);
    uvm_config_db#(virtual pins_if #(1))::set(   null, "*.env", "idle_vif",         idle_if);
    uvm_config_db#(virtual ahb_if)::set(         null, "*.env", "ahb_vif",          ahb_if_h);

    // In the block-level environment, there is one subordinate on the AHB: the aes_clp_wrapper,
    // with index 0.
    uvm_config_db#(int unsigned)::set(null, "*.env", "ahb_subordinate_index", 0);

    // White-Box DV Interfaces
    uvm_config_db#(virtual aes_cov_if)::set(   null, "*.env", "aes_cov_if",     dut.aes_inst.u_aes_cov_if);
    uvm_config_db#(virtual aes_reseed_if)::set(null, "*.env", "aes_reseed_vif", dut.aes_inst.u_aes_reseed_if);

    $timeformat(-12, 0, " ps", 12);
    run_test();
  end

  if (`EN_MASKING) begin : gen_aes_masking_reseed_vif
    initial begin
      uvm_config_db#(virtual aes_masking_reseed_if)::set(null, "*.env", "aes_masking_reseed_vif", dut.aes_inst.u_aes_masking_reseed_if);
    end
  end
endmodule
