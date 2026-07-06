// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A virtual sequence that reads and writes various interrupt-related registers, checking that they
// behave as expected.
//
// To use it, call add_reg_triple() for each set of interrupt enable/state/test registers. The test
// running the sequence should call report_reset() if it sees that a reset has been asserted.
//
// Note that this is a virtual class: it doesn't have an implementation of peek_interrupt_pins. The
// class extending this for a given block will need to implement that, and will therefore probably
// need some "set interrupt interface" function too. That, in turn, will need to be called by the
// user.

virtual class intr_test_vseq extends uvm_sequence;
  // A triple of interrupt registers (enable, state and test).
  typedef struct {
    dv_base_reg intr_en;
    dv_base_reg intr_state;
    dv_base_reg intr_test;
  } intr_reg_triple_t;

  // An enum that describes the "type" of an interrupt register (enable, state or test)
  typedef enum bit [1:0] {
    IntrEnableReg = 0,
    IntrStateReg  = 1,
    IntrTestReg   = 2
  } intr_reg_type_e;

  // A register, together with an intr_reg_type_e (which says what sort of interrupt register it
  // is), an "lsb", which says the number of interrupts in registers that came before it, and the
  // full set of registers associated with the relevant interrupt.
  typedef struct {
    // The interrupt register itself
    dv_base_reg       register;

    // What sort of interrupt register is this? (enable, state or test)
    intr_reg_type_e   intr_reg_type;

    // What is the bit position of this interrupt in the state vector?
    int unsigned      lsb;

    // A handle to the enable / state / test triple for the associated interrupt (one of which will
    // be register)
    intr_reg_triple_t triple;
  } tagged_intr_reg_t;

  // A queue of register triples that will be exercised
  local intr_reg_triple_t m_intr_triples[$];

  // The number of times to access each interrupt register. This defaults to 1 but can be overridden
  // by calling set_num_times().
  local int unsigned m_num_times = 1;

  // A flag that gets set by calling report_reset(). This causes the sequence to finish.
  local bit          m_seen_reset;

  extern function new(string name="");
  extern task body();

  // Teach the sequence about a triple of interrupt registers (enable, state and test). Call this to
  // configure the sequence before running it.
  extern function void add_reg_triple(dv_base_reg intr_en,
                                      dv_base_reg intr_state,
                                      dv_base_reg intr_test);

  // Set the value of m_num_times (the value must be positive).
  extern function void set_num_times(int unsigned num_times);

  // Report that a reset has been asserted and the sequence should finish.
  extern function void report_reset();

  // Return the current state of the interrupt pins.
  //
  // For each register triple that has been added, this is laid out the same as the intr_state
  // register (with the first triple added at the LSB).
  pure virtual function logic[63:0] peek_interrupt_pins();

  // Run a single iteration of the main body
  extern local task run_iteration();

  // Add each of the registers from m_intr_triples to intr_regs
  extern local function void add_intr_regs_to_queue(ref tagged_intr_reg_t intr_regs[$]);

  // Return the sum of the widths of fields in register
  extern static local function int unsigned sum_reg_field_widths(uvm_reg register);
endclass

function intr_test_vseq::new(string name="");
  super.new(name);
endfunction

task intr_test_vseq::body();
  if (!m_intr_triples.size()) begin
    `uvm_error(get_full_name(), "Cannot run sequence: we don't know any interrupt regs.")
    return;
  end

  for (int i = 0; i < m_num_times; i++) begin
    `uvm_info(get_full_name(),
              $sformatf("Running intr_test iteration %0d / %0d.", i + 1, m_num_times),
              UVM_LOW)
    run_iteration();
    if (m_seen_reset) return;
  end
endtask

function void intr_test_vseq::add_reg_triple(dv_base_reg intr_en,
                                             dv_base_reg intr_state,
                                             dv_base_reg intr_test);
  m_intr_triples.push_back('{intr_en, intr_state, intr_test});
endfunction

function void intr_test_vseq::set_num_times(int unsigned num_times);
  if (!num_times) begin
    `uvm_error(get_full_name(), "Cannot set num_times to zero.")
    num_times = 1;
  end
  m_num_times = num_times;
endfunction

function void intr_test_vseq::report_reset();
  m_seen_reset = 1;
endfunction

task intr_test_vseq::run_iteration();
  tagged_intr_reg_t intr_regs[$];

  // Set intr_regs to the set of all interrupt registers
  add_intr_regs_to_queue(intr_regs);

  // Write a random value to each interrupt register (in a random order)
  intr_regs.shuffle();
  foreach (intr_regs[i]) begin
    uvm_reg_data_t wdata;
    uvm_status_e   txn_status;

    if (!std::randomize(wdata)) `uvm_fatal(get_full_name(), "Failed to randomize wdata")

    `uvm_info(get_full_name(),
              $sformatf("Writing 0x%0h to %0s", wdata, intr_regs[i].register.get_name()),
              UVM_MEDIUM)

    intr_regs[i].register.write(.status(txn_status), .value(wdata));
    if (m_seen_reset) return;
    if (txn_status != UVM_IS_OK) begin
      `uvm_error(get_full_name(),
                 $sformatf("Failed to write to %0s register.", intr_regs[i].register.get_name()))
    end
  end

  // Now read back every interrupt-related CSR (again, in a random order)
  intr_regs.shuffle();
  foreach (intr_regs[i]) begin
    string         reg_name = intr_regs[i].register.get_name();
    uvm_reg_data_t exp_val = intr_regs[i].register.get_mirrored_value();
    uvm_reg_data_t act_val;
    uvm_reg_data_t unpredictable_mask = '0;
    uvm_status_e   txn_status;

    // If this register is tagged as IntrStateReg, it shows the current status of the interrupt and
    // we can't predict the fields for that status. Mask out those bits.
    if (intr_regs[i].intr_reg_type == IntrStateReg) begin
      unpredictable_mask = intr_regs[i].register.get_ro_mask();
    end

    intr_regs[i].register.read(.status(txn_status), .value(act_val));
    if (m_seen_reset) return;
    if (txn_status != UVM_IS_OK) begin
      `uvm_error(get_full_name(), $sformatf("Failed to read %0s register", reg_name))
    end

    `uvm_info(get_full_name(),
              $sformatf("Read 0x%0h from %0s register.", act_val, reg_name),
              UVM_MEDIUM)

    if ((exp_val ^ act_val) & ~unpredictable_mask) begin
      `uvm_error(get_full_name(),
                 $sformatf({"Unexpected value in %0s register. ",
                            "After masking out 0x%0h, we predicted the register to contain 0x%0h, ",
                            "but the value read was 0x%0h."},
                           reg_name,
                           unpredictable_mask,
                           exp_val & ~unpredictable_mask,
                           act_val & ~unpredictable_mask))
    end

    // If the register is tagged as IntrStateReg, its value should match the pins we see from
    // peek_interrupt_pins, masking out any bits that are RO fields in the state register.
    //
    // Bits with RO fields in the state register are status-type interrupts that can't be predicted
    // in general, so we don't try to predict that one matches its corresponding interrupt line.
    if (intr_regs[i].intr_reg_type == IntrStateReg) begin
      logic [63:0] all_seen         = peek_interrupt_pins();
      int unsigned width            = sum_reg_field_widths(intr_regs[i].register);
      bit [63:0]   low_mask         = (64'd1 << width) - 1;
      logic [63:0] pins             = (all_seen >> intr_regs[i].lsb) & low_mask;
      bit [63:0]   intr_enable_mask = intr_regs[i].triple.intr_en.get_mirrored_value();
      bit [63:0]   status_intr_mask = intr_regs[i].register.get_ro_mask();
      bit [63:0]   comparison_mask  = intr_enable_mask & ~status_intr_mask;

      if (|((pins ^ act_val) & comparison_mask) !== 1'b0) begin
        `uvm_error(get_full_name(),
                   $sformatf({"After masking out disabled and status-type interrupts, the ",
                              "register %0s contains 0x%0h but those bits in the pins are 0x%0h"},
                             reg_name,
                             act_val & comparison_mask,
                             pins & comparison_mask ))
      end
    end
  end

  // Finally clear all the test bits by iterating over intr_regs again and only taking those with
  // intr_reg_type = IntrTestReg, then writing '0.
  foreach (intr_regs[i]) begin
    uvm_status_e   txn_status;

    if (intr_regs[i].intr_reg_type != IntrTestReg) continue;
    intr_regs[i].register.write(.status(txn_status), .value(0));
    if (m_seen_reset) return;
    if (txn_status != UVM_IS_OK) begin
      `uvm_error(get_full_name(), $sformatf("Failed to write 0 to %0s register",
                                            intr_regs[i].register.get_name()))
    end
  end
endtask

function void intr_test_vseq::add_intr_regs_to_queue(ref tagged_intr_reg_t intr_regs[$]);
  int unsigned lsb = 0;

  foreach (m_intr_triples[i]) begin
    intr_regs.push_back('{m_intr_triples[i].intr_en,    IntrEnableReg, lsb, m_intr_triples[i]});
    intr_regs.push_back('{m_intr_triples[i].intr_state, IntrStateReg,  lsb, m_intr_triples[i]});
    intr_regs.push_back('{m_intr_triples[i].intr_test,  IntrTestReg,   lsb, m_intr_triples[i]});

    // Add the widths of the fields in the intr_state register to lsb (which gives the index of the
    // lsb for each triple's state bits in the vector returned by peek_interrupt_pins).
    lsb += sum_reg_field_widths(m_intr_triples[i].intr_state);
  end
endfunction

function int unsigned intr_test_vseq::sum_reg_field_widths(uvm_reg register);
  uvm_reg_field fields[$];
  int unsigned  width;

  register.get_fields(fields);
  foreach(fields[i]) begin
    width += fields[i].get_n_bits();
  end

  return width;
endfunction
