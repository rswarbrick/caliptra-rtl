// SPDX-License-Identifier: Apache-2.0
//
// Caliptra DV utility helpers. Built on native UVM RAL primitives only — no dependency on
// csr_utils_pkg or any dv_base_reg_* class. Add helpers here only when there is no clean native
// UVM equivalent.

package caliptra_dv_utils_pkg;
  import uvm_pkg::*;

  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  // Slice the bits of `value` corresponding to `field`'s position/width out of a raw word. Useful
  // in scoreboards where the bus write data is observed before the RAL has predicted/mirrored it.
  function automatic uvm_reg_data_t get_field_val(uvm_reg_field field, uvm_reg_data_t value);
    uvm_reg_data_t mask  = (1 << field.get_n_bits()) - 1;
    int unsigned   shift = field.get_lsb_pos();
    return (value >> shift) & mask;
  endfunction

  typedef enum int {
    RalCmpEq,
    RalCmpNe,
    RalCmpGt,
    RalCmpGe,
    RalCmpLt,
    RalCmpLe
  } ral_cmp_e;

  // Poll a uvm_reg or uvm_reg_field until its read value satisfies `cmp` against `exp`, or fail
  // after `timeout_ns`.
  //
  // `ptr` must be a uvm_reg or uvm_reg_field handle. Reads go through the default frontdoor on
  // whichever map the reg/field is configured to use. If reset-abort behaviour is needed, the
  // caller should wrap this in fork/join_any with a reset-wait process and disable fork — this
  // helper deliberately knows nothing about reset state.
  task automatic ral_spinwait(input  uvm_object     ptr,
                              input  uvm_reg_data_t exp,
                              input  ral_cmp_e      cmp                 = RalCmpEq,
                              input  int unsigned   poll_delay_ns       = 0,
                              input  int unsigned   timeout_ns          = 10_000_000,
                              input  uvm_verbosity  verbosity           = UVM_HIGH);
    uvm_reg        csr;
    uvm_reg_field  fld;
    string         full_name;

    if (!$cast(csr, ptr) && !$cast(fld, ptr)) begin
      `uvm_fatal("ral_spinwait",
                 $sformatf("ptr %0s is neither uvm_reg nor uvm_reg_field", ptr.get_full_name()))
    end
    full_name = ptr.get_full_name();

    fork begin : iso_fork
      fork
        begin
          uvm_status_e   status;
          uvm_reg_data_t read_data;
          forever begin
            if (poll_delay_ns) #(poll_delay_ns * 1ns);
            if (csr != null) csr.read(status, read_data, .parent(null));
            else             fld.read(status, read_data, .parent(null));
            `uvm_info("ral_spinwait",
                      $sformatf("%0s == 0x%0h (exp %0s 0x%0h)",
                                full_name, read_data, cmp.name, exp),
                      verbosity)
            case (cmp)
              RalCmpEq: if (read_data == exp) break;
              RalCmpNe: if (read_data != exp) break;
              RalCmpGt: if (read_data >  exp) break;
              RalCmpGe: if (read_data >= exp) break;
              RalCmpLt: if (read_data <  exp) break;
              RalCmpLe: if (read_data <= exp) break;
              default: `uvm_fatal("ral_spinwait",
                                  $sformatf("invalid cmp %0s", cmp.name))
            endcase
          end
        end
        begin
          #(timeout_ns * 1ns);
          `uvm_error("ral_spinwait",
                     $sformatf("timeout after %0d ns waiting for %0s %0s 0x%0h",
                               timeout_ns, full_name, cmp.name, exp))
        end
      join_any
      disable fork;
    end : iso_fork join
  endtask

endpackage
