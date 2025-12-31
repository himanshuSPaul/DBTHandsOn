{# ============================================================================
   DATA QUALITY NAMESPACE - BASIC VALIDATION TESTS
   ============================================================================
   Purpose: Core data validation patterns for basic data quality checks
   
   Tests in this namespace:
   1. test_nq_non_negative        - Numeric >= 0
   2. test_nq_positive_values     - Numeric > 0
   3. test_nq_value_between       - Range validation
   4. test_nq_max_value           - Upper bound
   5. test_nq_min_value           - Lower bound
   6. test_nq_not_empty           - Not NULL or empty string
   7. test_nq_not_future_date     - Date <= TODAY
   8. test_nq_accepted_values     - Enumeration validation
   
   Namespace Prefix: 'data_quality' or 'nq'
   File Location: macros/tests/data_quality_namespace.sql
   ============================================================================ #}

{# Test DQ.1: Non-negative values (>= 0) #}
{% macro test_nq_non_negative(column_name = '', model = '') %}
  {%- if execute -%}
    {{ log('Running test: data_quality.non_negative on column "' ~ column_name ~ '"', info=true) }}
  {%- endif -%}
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE {{ column_name }} < 0
{% endmacro %}

{# Test DQ.2: Positive values (> 0) #}
{% macro test_nq_positive_values(column_name = '', model = '') %}
  {%- if execute -%}
    {{ log('Running test: data_quality.positive_values on column "' ~ column_name ~ '"', info=true) }}
  {%- endif -%}
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE {{ column_name }} <= 0
{% endmacro %}

{# Test DQ.3: Value between range (inclusive) #}
{% macro test_nq_value_between(column_name = '', min_value = 0, max_value = 100, model = '') %}
  {%- if execute -%}
    {{ log('Running test: data_quality.value_between - Range [' ~ min_value ~ ', ' ~ max_value ~ '] on "' ~ column_name ~ '"', info=true) }}
  {%- endif -%}
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE {{ column_name }} < {{ min_value }}
     OR {{ column_name }} > {{ max_value }}
{% endmacro %}

{# Test DQ.4: Maximum value constraint #}
{% macro test_nq_max_value(column_name = '', max_value = 1000, model = '') %}
  {%- if execute -%}
    {{ log('Running test: data_quality.max_value <= ' ~ max_value ~ ' on "' ~ column_name ~ '"', info=true) }}
  {%- endif -%}
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE {{ column_name }} > {{ max_value }}
{% endmacro %}

{# Test DQ.5: Minimum value constraint #}
{% macro test_nq_min_value(column_name = '', min_value = 0, model = '') %}
  {%- if execute -%}
    {{ log('Running test: data_quality.min_value >= ' ~ min_value ~ ' on "' ~ column_name ~ '"', info=true) }}
  {%- endif -%}
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE {{ column_name }} < {{ min_value }}
{% endmacro %}

{# Test DQ.6: Not empty (not NULL and not empty string) #}
{% macro test_nq_not_empty(column_name = '', model = '') %}
  {%- if execute -%}
    {{ log('Running test: data_quality.not_empty on column "' ~ column_name ~ '"', info=true) }}
  {%- endif -%}
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE {{ column_name }} IS NULL
     OR LENGTH(TRIM({{ column_name }})) = 0
{% endmacro %}

{# Test DQ.7: Not future date #}
{% macro test_nq_not_future_date(column_name = '', model = '') %}
  {%- if execute -%}
    {{ log('Running test: data_quality.not_future_date on column "' ~ column_name ~ '"', info=true) }}
  {%- endif -%}
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE CAST({{ column_name }} AS TIMESTAMP) > CURRENT_TIMESTAMP()
{% endmacro %}

{# Test DQ.8: Accepted values (enumeration) #}
{% macro test_nq_accepted_values(column_name = '', values = [], model = '') %}
  {%- if execute -%}
    {{ log('Running test: data_quality.accepted_values on column "' ~ column_name ~ '" with ' ~ values | length ~ ' allowed values', info=true) }}
  {%- endif -%}
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE {{ column_name }} NOT IN (
    {%- for value in values -%}
      '{{ value }}'{{ "," if not loop.last else "" }}
    {%- endfor -%}
  )
{% endmacro %}
