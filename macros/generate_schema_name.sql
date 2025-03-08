-- The macro below tells dbt to use the default schema from the profile or if a custom schema is specified, use that exact name (instead of trying to create a new one)
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
