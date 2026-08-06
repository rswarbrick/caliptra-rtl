{#
  This extends uvm_reg_block-mem.sv, which is part of PeakRDL-uvm, so that memory nodes are
  instantiated with dv_base_mem (which derives from uvm_mem) instead of the base class.
#}
{% import "uvm_reg_block-mem.sv" as uvm_reg_block_mem with context %}

{#
  This macro is essentially uvm_reg_block_mem.class_definition, but tweaked to use dv_base_mem
  instead of uvm_mem.

  Some names (class_needs_definition, get_class_friendly_name, get_class_name, use_uvm_factory) are
  supplied by PeakRDL-uvm's exporter.py
#}
{% macro class_definition(node) -%}
{%- if class_needs_definition(node) %}
// {{get_class_friendly_name(node)}}
class {{get_class_name(node)}} extends uvm_reg_block;
{%- if use_uvm_factory %}
    `uvm_object_utils({{get_class_name(node)}})
{%- endif %}
    rand dv_base_mem m_mem;
    {{uvm_reg_block_mem.child_insts(node)|indent}}
    {{uvm_reg_block_mem.function_new(node)|indent}}

    {{uvm_reg_block_mem.function_build(node)|indent}}
endclass : {{get_class_name(node)}}
{% endif -%}
{%- endmacro %}

{#
  This is a wrapper around uvm_reg_block_mem.build_instance

  It expands to exactly the same contents, but this allows a register block to use this file
  (dv_base_mem.sv) without reasoning about the interaction between it and uvm_reg_block-mem.sv.
#}
{% macro build_instance(node) -%}
{{uvm_reg_block_mem.build_instance(node)}}
{%- endmacro %}
