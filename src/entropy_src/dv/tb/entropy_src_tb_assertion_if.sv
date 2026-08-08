// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// An interface that can be used to control assertions in the design RTL.
//
// Because $asserton/$assertoff can't use relative hierarchical references, this interface needs to
// know the actual structure of the testbench. As such, this interface operates by absolute
// hierarchical references (and has no ports).
//
// The interface communicates with the environment through an entropy_src_assertion_if which it
// instantiates inside it (and which the tb can register with the environment).

`define DUT_PATH    tb.dut

`define CORE_PATH   `DUT_PATH.u_entropy_src_core
`define REPCNT_PATH `CORE_PATH.u_entropy_src_repcnt_ht.u_prim_max_tree_rep_cntr_max
`define BUCKET_PATH `CORE_PATH.u_entropy_src_bucket_ht.u_prim_max_tree_bin_cntr_max

`define CONTROL_ASSERTION(should_disable, name)                           \
  if ((should_disable)) $assertoff(0, (name)); else $asserton(0, (name));

interface entropy_src_tb_assertion_if ();
  bit no_asserts;

  always @(no_asserts) begin
    import uvm_pkg::*;

    `uvm_info($sformatf("%m"),
              $sformatf("%0sabling error assertions in design.", no_asserts ? "Dis" : "En"),
              UVM_HIGH)

    // Assertions that have been defined in the RTL code might have been discarded at pre-processor
    // time if CLP_ASSERT_ON was not defined. If it *was* defined, the assertions exist and should
    // be controlled.
`ifdef CLP_ASSERT_ON
    `CONTROL_ASSERTION(no_asserts, `DUT_PATH.AlertTxKnownO_A)
    `CONTROL_ASSERTION(no_asserts, `DUT_PATH.IntrEsFifoErrKnownO_A)
    `CONTROL_ASSERTION(no_asserts, `DUT_PATH.EsHwIfEsAckKnownO_A)
    `CONTROL_ASSERTION(no_asserts, `DUT_PATH.EsHwIfEsBitsKnownO_A)
    `CONTROL_ASSERTION(no_asserts, `DUT_PATH.EsHwIfEsFipsKnownO_A)
    `CONTROL_ASSERTION(no_asserts, `DUT_PATH.EsXhtEntropyBitKnownO_A)
    `CONTROL_ASSERTION(no_asserts, `DUT_PATH.IntrEsEntropyValidKnownO_A)
    `CONTROL_ASSERTION(no_asserts, `DUT_PATH.IntrEsHealthTestFailedKnownO_A)
    `CONTROL_ASSERTION(no_asserts, `DUT_PATH.tlul_assert_device.dKnown_A)
    `CONTROL_ASSERTION(no_asserts, `DUT_PATH.tlul_assert_device.gen_device.dDataKnown_A)
    `CONTROL_ASSERTION(no_asserts, `DUT_PATH.gen_alert_tx[0].u_prim_alert_sender.AlertPKnownO_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.AtReset_ValidRngBitsPushedIntoEsrngFifo_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.Final_ValidRngBitsPushedIntoEsrngFifo_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.AtReset_EsrngFifoPushedIntoEsbitOrPosthtFifos_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.Final_EsrngFifoPushedIntoEsbitOrPosthtFifos_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.AtReset_EsbitFifoPushedIntoPosthtFifo_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.Final_EsbitFifoPushedIntoPosthtFifo_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.AtReset_PosthtFifoPushedFromEsbitOrEsrngFifos_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.Final_PosthtFifoPushedFromEsbitOrEsrngFifos_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.AtReset_PosthtFifoPushedIntoDistrFifo_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.Final_PosthtFifoPushedIntoDistrFifo_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.AtReset_DistrFifoPushedIntoPreconFifo_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.Final_DistrFifoPushedIntoPreconFifo_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.AtReset_EsfinalFifoPushed_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.Final_EsfinalFifoPushed_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.AtReset_EsfinalFifoPushedPostStartup_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.Final_EsfinalFifoPushedPostStartup_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.AtReset_PreconFifoPushedPostStartup_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.Final_PreconFifoPushedPostStartup_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.u_sha3.FsmKnown_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.u_sha3.MuxSelKnown_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.u_entropy_src_main_sm.u_state_regs_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.u_entropy_src_ack_sm.u_state_regs_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.u_prim_fifo_sync_esfinal.DepthKnown_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.u_prim_fifo_sync_esfinal.RvalidKnown_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.u_prim_fifo_sync_esfinal.WreadyKnown_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.u_prim_fifo_sync_esrng.DataKnown_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.u_entropy_src_adaptp_ht.u_sum.SumComputation_A)
    `CONTROL_ASSERTION(no_asserts, `CORE_PATH.u_entropy_src_markov_ht.u_sum.SumComputation_A)
    `CONTROL_ASSERTION(no_asserts,
                       `CORE_PATH.u_entropy_src_adaptp_ht.u_min.ValidInImpliesValidOut_A)
    `CONTROL_ASSERTION(no_asserts,
                       `CORE_PATH.u_entropy_src_adaptp_ht.u_max.ValidInImpliesValidOut_A)
    `CONTROL_ASSERTION(no_asserts,
                       `CORE_PATH.u_entropy_src_markov_ht.u_min.ValidInImpliesValidOut_A)
    `CONTROL_ASSERTION(no_asserts,
                       `CORE_PATH.u_entropy_src_markov_ht.u_max.ValidInImpliesValidOut_A)
    `CONTROL_ASSERTION(no_asserts,
                       `CORE_PATH.u_sha3.u_keccak.gen_unmask_st_chk.UnmaskValidStates_A)
    `CONTROL_ASSERTION(no_asserts, `REPCNT_PATH.ValidInImpliesValidOut_A)
    `CONTROL_ASSERTION(no_asserts, `BUCKET_PATH.ValidInImpliesValidOut_A)
`endif // CLP_ASSERT_ON
  end

  entropy_src_assertion_if u_assertion_if (.disable_assertions_o(no_asserts));
endinterface

`undef CONTROL_ASSERTION
`undef CORE_PATH
`undef REPCNT_PATH
`undef BUCKET_PATH
`undef DUT_PATH
