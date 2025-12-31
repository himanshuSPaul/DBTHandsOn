{%- macro generate_alias_name(custom_alias_name=none, node=none) -%}
    {%- if execute -%}
        {%- set rel_name = custom_alias_name if custom_alias_name is not none else node.name -%}
        
        {%- if node is not none and node.resource_type == 'model' -%}
            {%- set parts = node.fqn -%}
            {%- if parts | length >= 2 -%}
                {%- set directory = parts[-2] -%}
                {%- set default_schema = directory -%}
            {%- else -%}
                {%- set default_schema = 'public' -%}
            {%- endif -%}
        {%- else -%}
            {%- set default_schema = 'public' -%}
        {%- endif -%}
        
        {{ rel_name | as_text }}
    {%- else -%}
        {{ custom_alias_name if custom_alias_name is not none else node.name }}
    {%- endif -%}
{%- endmacro -%}
