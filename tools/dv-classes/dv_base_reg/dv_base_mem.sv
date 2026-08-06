// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Specialised version of uvm_mem for OpenTitan
//
// The specialised version adds the possibilities that a memory:
//
//  - might not support partial writes (even if the bus would otherwise support them).
//
//  - might store integrity data but not check it (merely passing it through to the next read).

class dv_base_mem extends uvm_mem;
  // If true, the memory supports partial writes. If not, any partial write will get an error
  // response (d_error=1 in TileLink).
  local bit mem_partial_write_support;

  // If true, mem stores integrity along with data but it won't check the data integrity
  local bit data_intg_passthru;

  // An extra access constraint set that applies as well as m_access. This can be set with
  // set_access() and exists to allow us to model write-only memories, which are not supported
  // directly by uvm_mem.
  local string m_access_constraint = "RW";

  // Create a new instance of the memory abstraction class.
  //
  // The only access types supported are RW, RO and WO.
  extern function new(string           name,
                      longint unsigned size,
                      int unsigned     n_bits,
                      string           access = "RW",
                      int              has_coverage = UVM_NO_COVERAGE);

  // Add an extra constraint to the access for this memory. This only supports "RW", "RO" and "WO"
  // and should be considered as an extra layer on top of the access defined by the underlying
  // uvm_mem.
  //
  // This is defined to allow an environment to constrain access to a memory after it has been
  // created (by auto-generated code). The underlying uvm_mem only supports access values of RW and
  // RO.
  extern function void set_access(string access);

  // Get the access for this memory through the given map (defaulting to the default map)
  //
  // This extends the implementation in uvm_mem, adding a possible extra access restriction from
  // m_access_constraint.
  extern function string get_access(uvm_reg_map map = null);

  extern function void set_mem_partial_write_support(bit enable);
  extern function bit get_mem_partial_write_support();

  extern function void set_data_intg_passthru(bit enable);
  extern function bit get_data_intg_passthru();

  // This overrides uvm_mem::configure (which is *not* a virtual function), removing the check that
  // the requested "access" is RW or RO, because we want to support WO as well.
  //
  // *That* check is now done in the constructor, where we can see the requested "access".
  extern function void configure(uvm_reg_block parent, string hdl_path="");
endclass

function dv_base_mem::new(string           name,
                          longint unsigned size,
                          int unsigned     n_bits,
                          string           access = "RW",
                          int              has_coverage = UVM_NO_COVERAGE);
  super.new(name, size, n_bits, access, has_coverage);
  if (!(access inside {"RW", "RO", "WO"}))
    `uvm_error(`gfn, $sformatf("Memory can only be RW, RO or WO (saw %s)", access))
endfunction

function void dv_base_mem::set_access(string access);
  if (! (access inside {"RW", "RO", "WO"})) begin
    `uvm_fatal("bad_access",
               $sformatf({"Cannot set access to '%0s': ",
                          "the only supported values are RW, RO and WO."},
                         access))
  end
  m_access_constraint = access;
endfunction

function string dv_base_mem::get_access(uvm_reg_map map = null);
  bit    can_read = 1;
  bit    can_write = 1;
  string from_base = super.get_access(map);
  string resolved;

  case (from_base)
    "RW": begin end
    "RO": can_write = 0;
    "WO": can_read = 0;
    default: `uvm_fatal("bad_access",
                        $sformatf("Base class returned unknown access value of %0s", from_base))
  endcase

  case (m_access_constraint)
    "RW": begin end
    "RO": can_write = 0;
    "WO": can_read = 0;
    default: `uvm_fatal("bad_access",
                        $sformatf("Invalid m_access_constraint: %0s", m_access_constraint))
  endcase

  case ({can_read, can_write})
    2'b01: return "WO";
    2'b10: return "RO";
    2'b11: return "RW";
    default:
      `uvm_fatal("bad_access",
                 $sformatf({"Memory has been confgured to be impossible to access. ",
                            "The uvm_mem and map together give access = %0s and ",
                            "m_access_constraint = %0s."},
                           from_base, m_access_constraint))
  endcase
endfunction

function void dv_base_mem::set_mem_partial_write_support(bit enable);
  mem_partial_write_support = enable;
endfunction

function bit dv_base_mem::get_mem_partial_write_support();
  return mem_partial_write_support;
endfunction

function void dv_base_mem::set_data_intg_passthru(bit enable);
  data_intg_passthru = enable;
endfunction

function bit dv_base_mem::get_data_intg_passthru();
  return data_intg_passthru;
endfunction

// Note: This is a copied version of uvm_mem::configure, but tweaked to remove the check on m_access
// (loosened slightly and now moved to the constructor)
function void dv_base_mem::configure(uvm_reg_block parent, string hdl_path="");
   if (parent == null)
     `uvm_fatal(`gfn, "configure: parent argument is null")

   set_parent(parent);

   begin
      uvm_mem_mam_cfg cfg = new;

      cfg.n_bytes      = ((get_n_bits() - 1) / 8) + 1;
      cfg.start_offset = 0;
      cfg.end_offset   = get_size() - 1;

      cfg.mode     = uvm_mem_mam::GREEDY;
      cfg.locality = uvm_mem_mam::BROAD;

      mam = new(get_full_name(), cfg, this);
   end

   parent.add_mem(this);

   if (hdl_path != "") add_hdl_path_slice(hdl_path, -1, -1);
endfunction
