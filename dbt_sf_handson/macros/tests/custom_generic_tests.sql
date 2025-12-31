{# ============================================================================
   CUSTOM GENERIC TESTS MACROS - dbt 1.8+ (ENHANCED)
   ============================================================================
   Purpose: Define reusable custom test macros for business logic validation
   
   These macros follow dbt's custom test conventions where:
   - The model being tested is available in SQL context via the compiled table/view
   - The column_name parameter is passed when testing a specific column
   - Parameters should have defaults for flexibility
   
   Reference: https://docs.getdbt.com/docs/build/custom-generic-tests
   ============================================================================ #}

{# Test 1: Verify column contains only non-negative values (>= 0) #}
{% macro test_non_negative(column_name = '', model = '') %}
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE {{ column_name }} < 0
{% endmacro %}

{# Test 2: Verify numeric column values are within specified range (inclusive) #}
{% macro test_value_between(column_name = '', min_value = 0, max_value = 100, model = '') %}
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE {{ column_name }} < {{ min_value }}
     OR {{ column_name }} > {{ max_value }}
{% endmacro %}

{# Test 3: Verify column values are not empty strings or null #}
{% macro test_not_empty(column_name = '', model = '') %}
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE {{ column_name }} IS NULL
     OR LENGTH(TRIM({{ column_name }})) = 0
{% endmacro %}

{# Test 4: Verify date column is not in the future #}
{% macro test_not_future_date(column_name = '', model = '') %}
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE CAST({{ column_name }} AS TIMESTAMP) > CURRENT_TIMESTAMP()
{% endmacro %}

{# Test 5: Verify numeric column doesn't exceed a maximum threshold #}
{% macro test_max_value(column_name = '', max_value = 1000, model = '') %}
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE {{ column_name }} > {{ max_value }}
{% endmacro %}

{# Test 6: Verify numeric column doesn't go below a minimum threshold #}
{% macro test_min_value(column_name = '', min_value = 0, model = '') %}
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE {{ column_name }} < {{ min_value }}
{% endmacro %}

{# Test 7: Verify positive values (> 0) #}
{% macro test_positive_values(column_name = '', model = '') %}
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE {{ column_name }} <= 0
{% endmacro %}

{# Test 8: Verify column values are in a specific list #}
{% macro test_accepted_values(column_name = '', values = [], model = '') %}
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE {{ column_name }} NOT IN (
    {%- for value in values %}
      '{{ value }}'{{ "," if not loop.last else "" }}
    {%- endfor %}
  )
  AND {{ column_name }} IS NOT NULL
{% endmacro %}
