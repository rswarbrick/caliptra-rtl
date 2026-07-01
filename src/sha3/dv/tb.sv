// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`include "uvm_macros.svh"
`include "dv_macros.svh"

module tb;
  import uvm_pkg::*;
  import dv_utils_pkg::*;
  import sha3_ctrl_test_pkg::sha3_ctrl_base_test;

  wire clk, rst_n;
  clk_rst_if clk_rst_if(.clk(clk), .rst_n(rst_n));

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
    ahb_if_h.addr_width        = 32;
    ahb_if_h.hburst_width      = 0;
    ahb_if_h.hprot_width       = 0;
    ahb_if_h.data_width        = 32;
    ahb_if_h.has_write_strobes = 0;
    ahb_if_h.num_subordinates  = 1;
  end

  wire busy;

  sha3_intr_if intr_if(.clk_i(clk), .rst_ni(rst_n));
  kmac_intr_if kmac_intr_if();

  pins_if #(.Width(1)) busy_if(busy);

  sha3_ctrl #(
    .AHB_DATA_WIDTH(32),
    .AHB_ADDR_WIDTH(32)
  ) dut (
    .clk                             ( clk                      ),
    .reset_n                         ( rst_n                    ),

    // TODO: Not yet any power-management agent in DV. Tie low.
    .cptra_pwrgood                   ( 1'b0                     ),

    .haddr_i                         ( ahb_if_h.haddr[31:0]     ),
    .hwdata_i                        ( ahb_if_h.hwdata[31:0]    ),
    .hsel_i                          ( ahb_if_h.hsel[0]         ),
    .hwrite_i                        ( ahb_if_h.hwrite          ),
    .hready_i                        ( ahb_if_h.hready          ),
    .htrans_i                        ( ahb_if_h.htrans          ),
    .hsize_i                         ( ahb_if_h.hsize           ),
    .hresp_o                         ( ahb_if_h.hresp[0]        ),
    .hreadyout_o                     ( ahb_if_h.hreadyout[0]    ),
    .hrdata_o                        ( ahb_if_h.hrdata[0][31:0] ),

    .busy_o                          ( busy                     ),

    .error_intr                      ( intr_if.error            ),
    .notif_intr                      ( intr_if.notif            ),

    // TODO: no debug-unlock / scan-mode driver in DV. Tie low.
    .debugUnlock_or_scan_mode_switch ( 1'b0                     )
  );

  assign kmac_intr_if.kmac_done  = dut.u_sha_inst.intr_kmac_done_o;
  assign kmac_intr_if.fifo_empty = dut.u_sha_inst.intr_fifo_empty_o;
  assign kmac_intr_if.kmac_err   = dut.u_sha_inst.intr_kmac_err_o;

  initial begin
    // drive clk and rst_n from clk_if
    clk_rst_if.set_active();
    uvm_config_db#(virtual clk_rst_if)::set(null, "*.env", "clk_rst_vif", clk_rst_if);
    uvm_config_db#(virtual ahb_if)::set(null, "*.env", "ahb_vif", ahb_if_h);
    uvm_config_db#(virtual sha3_intr_if)::set(null, "*.env", "intr_vif", intr_if);
    uvm_config_db#(virtual kmac_intr_if)::set(null, "*.env", "kmac_intr_vif", kmac_intr_if);
    uvm_config_db#(virtual pins_if#(1))::set(null, "*.env", "busy_vif", busy_if);

    // In the block-level environment, there is one subordinate on the AHB: the sha3_ctrl instance,
    // with index 0.
    uvm_config_db#(int unsigned)::set(null, "*.env", "ahb_subordinate_index", 0);

    // Tell the environment the HDL path to the sha3_ctrl instance. This will allow it to construct
    // HDL paths for back-door accesses in the generated reg_block.
    uvm_config_db#(string)::set(null, "*.env", "hdl_path", "tb.dut");

    $timeformat(-12, 0, " ps", 12);
    run_test();
  end

endmodule
