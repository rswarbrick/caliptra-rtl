{# -----------------------------------------------------------------------------
   Project-local PeakRDL-UVM template: sample() / sample_values() method-body
   pack. See tools/templates/rdl/cov/main.sv for the full rationale: upstream
   peakrdl-uvm has no register-coverage emission mode, so this file (plus its
   cov/ sibling and the uvm/ overrides) is the project's way of layering one
   on. The same upstream change would let both files be retired.

   We gate emission on class_needs_definition(node) to dedupe by register
   *type* (peakrdl-uvm's exporter records each emitted class name in a
   namespace_db on first call). Without the guard, an RDL reg type
   instantiated at multiple addresses produced two
   `function void <type>::sample(...)` bodies and SV elaboration failed with
   a redefinition error. The cov/ template carries the matching guard.
-#}
{%- import 'uvm_reg.sv' as uvm_reg with context -%}
{%- macro top() -%}
{%- for node in top_node.descendants(in_post_order=True) -%}
    {{child_smp(node)}}
{%- endfor -%}
{%- endmacro -%}

{%- macro child_smp(node) -%}
    {%- if isinstance(node, RegNode) -%}
        {% if not node.is_virtual and class_needs_definition(node) %}
{{"/*-----------------------"}} {{get_class_name(node)|upper}} {{"SAMPLE FUNCTIONS -----------------------*/"}}
{{uvm_reg.function_sample_def(node)}}
{{uvm_reg.function_sample_values_def(node)}}
        {%- endif %}
    {%- endif -%}
{%- endmacro %}
