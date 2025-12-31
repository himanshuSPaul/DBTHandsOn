{# ============================================================================
   BUSINESS LOGIC NAMESPACE - DOMAIN-SPECIFIC VALIDATION
   ============================================================================
   Purpose: Business rule validation specific to domain requirements
   
   Tests in this namespace:
   1. test_bl_ratio_constraint             - Column ratios within bounds
   2. test_bl_multi_column_rule            - Conditional logic across columns
   3. test_bl_selective_uniqueness         - Uniqueness with conditions
   4. test_bl_calculated_field_accuracy    - Derived field validation
   5. test_bl_proportionality_check        - Part-to-whole relationships
   
   Namespace Prefix: 'business_logic' or 'bl'
   File Location: macros/tests/business_logic_namespace.sql
   ============================================================================ #}

{# Test BL.1: Ratio constraint - Validate column ratios within acceptable bounds #}
{% macro test_bl_ratio_constraint(
    column_name = '',
    numerator = '',
    denominator = '',
    min_ratio = 0.0,
    max_ratio = 1.0,
    model = ''
) %}
  {%- if execute -%}
    {{ log('Running test: business_logic.ratio_constraint - Ratio must be between ' ~ min_ratio ~ ' and ' ~ max_ratio, info=true) }}
  {%- endif -%}
  
  SELECT
    *,
    CAST({{ numerator }} AS FLOAT) / 
    NULLIF(CAST({{ denominator }} AS FLOAT), 0) AS calculated_ratio
  FROM {{ get_where_subquery(sql) }}
  WHERE {{ denominator }} != 0
    AND (
      CAST({{ numerator }} AS FLOAT) / CAST({{ denominator }} AS FLOAT) < {{ min_ratio }}
      OR
      CAST({{ numerator }} AS FLOAT) / CAST({{ denominator }} AS FLOAT) > {{ max_ratio }}
    )
{% endmacro %}

{# Test BL.2: Multi-column business rule - Conditional logic across multiple columns #}
{% macro test_bl_multi_column_rule(
    rule_condition = '',
    rule_consequence = '',
    model = ''
) %}
  {%- if execute -%}
    {{ log('Running test: business_logic.multi_column_rule - IF (' ~ rule_condition ~ ') THEN (' ~ rule_consequence ~ ')', info=true) }}
  {%- endif -%}
  
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE ({{ rule_condition }})
    AND NOT ({{ rule_consequence }})
{% endmacro %}

{# Test BL.3: Selective uniqueness - Uniqueness constraint with WHERE clause #}
{% macro test_bl_selective_uniqueness(
    unique_columns = [],
    where_clause = '',
    model = ''
) %}
  {%- if execute -%}
    {{ log('Running test: business_logic.selective_uniqueness - Columns [' ~ unique_columns | join(', ') ~ '] must be unique WHERE ' ~ where_clause, info=true) }}
  {%- endif -%}
  
  WITH uniqueness_check AS (
    SELECT 
      {%- for col in unique_columns %}
      {{ col }},
      {%- endfor %}
      COUNT(*) AS occurrence_count
    FROM {{ get_where_subquery(sql) }}
    WHERE {{ where_clause }}
    GROUP BY {%- for col in unique_columns %} {{ col }}{{ "," if not loop.last else "" }} {%- endfor %}
  )
  SELECT *
  FROM uniqueness_check
  WHERE occurrence_count > 1
{% endmacro %}

{# Test BL.4: Calculated field accuracy - Validate derived/calculated columns #}
{% macro test_bl_calculated_field_accuracy(
    target_column = '',
    calculation_formula = '',
    tolerance = 0.01,
    model = ''
) %}
  {%- if execute -%}
    {{ log('Running test: business_logic.calculated_field_accuracy - ' ~ target_column ~ ' must equal (' ~ calculation_formula ~ ') within tolerance ' ~ tolerance, info=true) }}
  {%- endif -%}
  
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE ABS({{ target_column }} - ({{ calculation_formula }})) > {{ tolerance }}
{% endmacro %}

{# Test BL.5: Proportionality check - Validate part-to-whole relationships #}
{% macro test_bl_proportionality_check(
    part_column = '',
    whole_column = '',
    valid_proportion_min = 0.0,
    valid_proportion_max = 1.0,
    model = ''
) %}
  {%- if execute -%}
    {{ log('Running test: business_logic.proportionality_check - Part/Whole ratio in [' ~ valid_proportion_min ~ ', ' ~ valid_proportion_max ~ ']', info=true) }}
  {%- endif -%}
  
  SELECT
    *,
    CAST({{ part_column }} AS FLOAT) / 
    NULLIF(CAST({{ whole_column }} AS FLOAT), 0) AS proportion
  FROM {{ get_where_subquery(sql) }}
  WHERE {{ whole_column }} != 0
    AND (
      CAST({{ part_column }} AS FLOAT) / CAST({{ whole_column }} AS FLOAT) < {{ valid_proportion_min }}
      OR
      CAST({{ part_column }} AS FLOAT) / CAST({{ whole_column }} AS FLOAT) > {{ valid_proportion_max }}
    )
{% endmacro %}
