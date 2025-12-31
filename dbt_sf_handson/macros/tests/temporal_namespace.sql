{# ============================================================================
   TEMPORAL NAMESPACE - TIME-SERIES & DATE VALIDATION
   ============================================================================
   Purpose: Time-series validation, recency checks, and temporal constraints
   
   Tests in this namespace:
   1. test_tm_freshness_window             - Data within time window
   2. test_tm_time_gap_detection           - No gaps > threshold
   3. test_tm_no_duplicate_dates           - One record per period
   4. test_tm_temporal_ordering            - Chronological ordering
   5. test_tm_date_range_constraint        - Dates within bounds
   
   Namespace Prefix: 'temporal' or 'tm'
   File Location: macros/tests/temporal_namespace.sql
   ============================================================================ #}

{# Test TM.1: Freshness window - Data recency validation #}
{% macro test_tm_freshness_window(
    date_column = '',
    days_back = 1,
    row_count_threshold = 1,
    model = ''
) %}
  {%- if execute -%}
    {{ log('Running test: temporal.freshness_window - Must have ' ~ row_count_threshold ~ ' rows in last ' ~ days_back ~ ' day(s)', info=true) }}
  {%- endif -%}
  
  WITH recency_check AS (
    SELECT COUNT(*) AS recent_row_count
    FROM {{ get_where_subquery(sql) }}
    WHERE CAST({{ date_column }} AS DATE) >= CURRENT_DATE - {{ days_back }}
  )
  SELECT *
  FROM recency_check
  WHERE recent_row_count < {{ row_count_threshold }}
{% endmacro %}

{# Test TM.2: Time gap detection - No gaps exceeding threshold #}
{% macro test_tm_time_gap_detection(
    id_column = '',
    date_column = '',
    max_gap_days = 30,
    model = ''
) %}
  {%- if execute -%}
    {{ log('Running test: temporal.time_gap_detection - No gaps > ' ~ max_gap_days ~ ' days', info=true) }}
  {%- endif -%}
  
  WITH time_sequence AS (
    SELECT 
      {{ id_column }},
      {{ date_column }},
      LAG({{ date_column }}) OVER (
        PARTITION BY {{ id_column }} 
        ORDER BY {{ date_column }}
      ) AS prev_date,
      DATEDIFF(day, LAG({{ date_column }}) OVER (
        PARTITION BY {{ id_column }} 
        ORDER BY {{ date_column }}
      ), {{ date_column }}) AS days_gap
    FROM {{ get_where_subquery(sql) }}
  )
  SELECT *
  FROM time_sequence
  WHERE days_gap > {{ max_gap_days }}
{% endmacro %}

{# Test TM.3: No duplicate dates - Single record per period #}
{% macro test_tm_no_duplicate_dates(
    id_column = '',
    date_column = '',
    granularity = 'day',
    model = ''
) %}
  {%- if execute -%}
    {{ log('Running test: temporal.no_duplicate_dates - One record per ' ~ granularity ~ ' per ' ~ id_column, info=true) }}
  {%- endif -%}
  
  WITH date_counts AS (
    SELECT 
      {{ id_column }},
      {%- if granularity == 'day' %}
      CAST({{ date_column }} AS DATE) AS period
      {%- elif granularity == 'month' %}
      TRUNC({{ date_column }}, 'MONTH') AS period
      {%- elif granularity == 'year' %}
      TRUNC({{ date_column }}, 'YEAR') AS period
      {%- else %}
      CAST({{ date_column }} AS DATE) AS period
      {%- endif %},
      COUNT(*) AS record_count
    FROM {{ get_where_subquery(sql) }}
    GROUP BY {{ id_column }}, period
  )
  SELECT *
  FROM date_counts
  WHERE record_count > 1
{% endmacro %}

{# Test TM.4: Temporal ordering - Records in chronological order #}
{% macro test_tm_temporal_ordering(
    id_column = '',
    date_column = '',
    model = ''
) %}
  {%- if execute -%}
    {{ log('Running test: temporal.temporal_ordering - Records must be in chronological order within each ' ~ id_column, info=true) }}
  {%- endif -%}
  
  WITH temporal_check AS (
    SELECT 
      {{ id_column }},
      {{ date_column }},
      LAG({{ date_column }}) OVER (
        PARTITION BY {{ id_column }} 
        ORDER BY {{ date_column }}
      ) AS prev_date
    FROM {{ get_where_subquery(sql) }}
  )
  SELECT *
  FROM temporal_check
  WHERE {{ date_column }} < prev_date
{% endmacro %}

{# Test TM.5: Date range constraint - Dates within acceptable bounds #}
{% macro test_tm_date_range_constraint(
    date_column = '',
    min_date = '1900-01-01',
    max_date = 'CURRENT_DATE',
    model = ''
) %}
  {%- if execute -%}
    {{ log('Running test: temporal.date_range_constraint - Dates must be between ' ~ min_date ~ ' and ' ~ max_date, info=true) }}
  {%- endif -%}
  
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE CAST({{ date_column }} AS DATE) < CAST('{{ min_date }}' AS DATE)
     OR CAST({{ date_column }} AS DATE) > CAST({% if max_date == 'CURRENT_DATE' %}CURRENT_DATE{% else %}'{{ max_date }}'{% endif %} AS DATE)
{% endmacro %}
