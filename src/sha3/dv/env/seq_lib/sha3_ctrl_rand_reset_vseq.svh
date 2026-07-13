// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// An virtual sequence that runs multiple iterations of sha3_ctrl_stress_all_vseq in conjunction
// with rand_reset_vseq (which will cause a reset to interrupt each iteration).
//
// To use this sequence:
//
//    - Use set_reset_sequencer() to supply the sequencer that the reset sequence should use.
//
//    - Configure the notional clock frequency by calling set_clk_freq_mhz(). This allows the
//      sequence that injects resets not to wait too long.

class sha3_ctrl_rand_reset_vseq extends sha3_ctrl_base_vseq;
  `uvm_object_utils(sha3_ctrl_rand_reset_vseq)

  // The number of iterations to run (with a reset each time). Constrained by num_iterations_c.
  rand int unsigned m_num_iterations;

  // The sequencer that will be used to run the reset sequence. Set this with set_reset_sequencer.
  local reset_sequencer_t m_reset_sequencer;

  // The assumed clock frequency in MHz, which is used to configure how long to wait before applying
  // resets. This defaults to 100, but set this with set_clk_freq_mhz().
  local int unsigned m_clk_freq_mhz = 100;

  // An upper bound for the number of cycles to simulate before applying a reset. This is combined
  // with m_clk_freq_mhz to give a time-based upper bound that is used when randomizing the
  // with_rand_reset_vseq_pkg.
  //
  // The default value is 1e5, which gives 1ms with the default clock frequency of 100MHz. The
  // (protected) value should be overridden by classes that extend this one and know they want to
  // wait a different amount of time.
  protected int unsigned m_max_reset_delay_cycles = 100_000;

  extern function new(string name="");
  extern task body();

  // Set the sequencer that will be used to run the reset sequnce.
  extern function void set_reset_sequencer(reset_sequencer_t sequencer);

  // Set the notional clock frequency in MHz
  extern function void set_clk_freq_mhz(int unsigned clk_freq_mhz);

  // Run a single iteration in body.
  extern local task run_iteration();

  // Create, configure and randomise the sequence that will be run (and then interrupted by a
  // reset). This is a virtual function so that classes can extend this one and supply a different
  // sequence to be interrupted.
  extern protected virtual function uvm_sequence create_main_sequence();

  // Constrain the number of iterations to be large enough that we actually test that things get
  // cleared up by reset, but small enough that the test won't take very long.
  extern constraint num_iterations_c;
endclass

function sha3_ctrl_rand_reset_vseq::new(string name="");
  super.new(name);
endfunction

task sha3_ctrl_rand_reset_vseq::body();
  for (int unsigned iteration = 0; iteration < m_num_iterations; iteration++) begin
    `uvm_info(get_full_name(),
              $sformatf("Iteration %0d / %0d", iteration + 1, m_num_iterations),
              UVM_LOW)
    run_iteration();
  end
endtask

function void sha3_ctrl_rand_reset_vseq::set_reset_sequencer(reset_sequencer_t sequencer);
  m_reset_sequencer = sequencer;
endfunction

function void sha3_ctrl_rand_reset_vseq::set_clk_freq_mhz(int unsigned clk_freq_mhz);
  if (!clk_freq_mhz) `uvm_fatal(get_full_name(), "clk_freq_mhz cannot be zero.")
  m_clk_freq_mhz = clk_freq_mhz;
endfunction

task sha3_ctrl_rand_reset_vseq::run_iteration();
  import with_rand_reset_vseq_pkg::with_rand_reset_vseq;

  uvm_sequence         main_sequence;
  with_rand_reset_vseq reset_vseq;
  sha3_ctrl_base_vseq  main_vseq;
  uvm_sequencer_base   main_sequencer;

  main_sequence = create_main_sequence();

  // If main_sequence happens to be an instance of dv_base_vseq, it expects to run on a
  // dv_base_virtual_sequencer and we should provide our p_sequencer when we call
  // main_sequence.start(). If not, pass null and treat it as a more conventional virtual sequence.
  if ($cast(main_vseq, main_sequence)) begin
    $display("Setting main sequencer");
    main_sequencer = p_sequencer;
  end

  reset_vseq = with_rand_reset_vseq::type_id::create("reset_vseq");
  reset_vseq.set_reset_sequencer(m_reset_sequencer);
  reset_vseq.set_main_sequence(main_sequence);

  // Before randomising reset_vseq, set the upper bound for the delay in ns. We can compute this
  // from m_clk_freq_mhz and m_max_reset_delay_cycles.
  reset_vseq.m_reset_seq.m_max_delay_ns = (1000 * m_max_reset_delay_cycles) / m_clk_freq_mhz;

  if (!reset_vseq.randomize()) `uvm_fatal(get_full_name(), "Failed to randomise reset_vseq.")

  fork
    main_sequence.start(main_sequencer);
    reset_vseq.start(null);
  join
endtask

function uvm_sequence sha3_ctrl_rand_reset_vseq::create_main_sequence();
  sha3_ctrl_stress_all_vseq stress_vseq;

  stress_vseq = sha3_ctrl_stress_all_vseq::type_id::create("stress_vseq");
  stress_vseq.do_apply_reset = 0;
  stress_vseq.set_sequencer(p_sequencer);
  stress_vseq.set_ahb_sequencer(m_ahb_sequencer);

  if (!stress_vseq.randomize()) `uvm_fatal(get_full_name(), "Failed to randomise stress_vseq.")

  // Override the num_trans value in stress_vseq with something large. This guarantees that the
  // sequence won't manage to complete before the reset is injected.
  stress_vseq.num_trans = 20;

  return stress_vseq;
endfunction

constraint sha3_ctrl_rand_reset_vseq::num_iterations_c {
  5 <= m_num_iterations;
  m_num_iterations <= 10;
}
