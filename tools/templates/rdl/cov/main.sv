{# -----------------------------------------------------------------------------
   Project-local PeakRDL-UVM template: covergroup pack
   -----------------------------------------------------------------------------
   Upstream PeakRDL-UVM (vendored in the caliptra-reg-gen Nix devshell) ships
   templates only for the UVM RAL itself; it constructs every uvm_reg with
   UVM_NO_COVERAGE and emits no per-register covergroups, no sample()/
   sample_values() bodies, and no _covergroups.svh / _sample.svh outputs. The
   project layers register-bit and field-value functional coverage on top by
   running three UVMExporter passes from reg_gen.py with different user
   template dirs:

     tools/templates/rdl/uvm/  -> RAL class definitions, with covergroup
                                  instance declarations and sample(...) /
                                  sample_values(...) externs woven in
     tools/templates/rdl/cov/  -> this file -- the covergroup definitions
                                  packaged into <stem>_covergroups.svh
     tools/templates/rdl/smp/  -> sample() / sample_values() method bodies
                                  packaged into <stem>_sample.svh

   What would need to be upstreamed to delete these templates:
   peakrdl-uvm would have to grow a first-class "emit register-level
   functional coverage" mode (UVM_CVR_REG_BITS / UVM_CVR_FIELD_VALS coverpoints
   keyed off uvm_reg::sample / sample_values), producing the equivalent
   per-class covergroup and sample-body files. Until that lands these
   templates stay, and any peakrdl-uvm version bump must be diffed against
   them.

   Bug fixed here vs. the naive descendants() walk:
   The walk visits every register *instance* in the address map, but
   get_class_name(node) is keyed off the register *type*. When an RDL reg
   type is instantiated at multiple addresses (e.g. kv_status_reg appears
   under both kv_read_ctrl_reg and kv_write_ctrl_reg in aes_clp_reg.rdl),
   a naive emit produced two `covergroup <type>_bit_cg` and two
   `covergroup <type>_fld_cg` definitions and the SV compile failed with a
   redefinition error. peakrdl-uvm already exposes class_needs_definition()
   for exactly this case (it dedupes by class type name and records each
   emitted name in a per-exporter namespace_db); the upstream templates
   gate every class_definition / vreg / reg_block-mem emission on it. We
   apply the same gate here. The smp/ template has the same shape and
   carries the matching guard.
-#}
{% import 'uvm_reg.sv' as uvm_reg with context %}
{%- macro top() %}
{%- for node in top_node.descendants(in_post_order=True) -%}
    {{child_cg(node)}}
{%- endfor -%}
{% endmacro -%}

{% macro child_cg(node) -%}
    {%- if isinstance(node, RegNode) -%}
        {%- if not node.is_virtual and class_needs_definition(node) -%}
            {{uvm_reg.cg_definition(node)}}
        {%- endif -%}
    {%- endif -%}
{%- endmacro %}
