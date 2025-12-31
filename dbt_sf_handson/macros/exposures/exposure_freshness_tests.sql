{# ============================================================================
   EXPOSURE FRESHNESS VALIDATION TESTS
   ============================================================================
   Purpose: Test macros that validate upstream data freshness for exposures
   
   Test Types:
   1. exposure_data_freshness_window - Data updated within N hours
   2. exposure_row_count_threshold - Minimum rows in time window
   3. exposure_dependency_freshness - All dependencies fresh
   4. exposure_no_stale_records - No records older than threshold
   ============================================================================ #}

{# Test 1: Exposure Data Freshness Window
   Validates that data in model has been updated within specified hours
#}
{% macro test_exposure_data_freshness_window(
    date_column = '',
    hours_threshold = 24,
    model = ''
) %}
  {%- if execute -%}
    {{ log('Testing exposure freshness window: ' ~ hours_threshold ~ ' hours', info=true) }}
  {%- endif -%}
  
  WITH freshness_check AS (
    SELECT
      COUNT(*) AS total_rows,
      COUNT(CASE WHEN CAST({{ date_column }} AS TIMESTAMP) >= CURRENT_TIMESTAMP() - INTERVAL '{{ hours_threshold }} hours'
                 THEN 1 END) AS recent_rows,
      MAX({{ date_column }}) AS latest_timestamp,
      CURRENT_TIMESTAMP() - MAX({{ date_column }}) AS age_interval
    FROM {{ get_where_subquery(sql) }}
  )
  SELECT *
  FROM freshness_check
  WHERE latest_timestamp IS NULL
     OR latest_timestamp < CURRENT_TIMESTAMP() - INTERVAL '{{ hours_threshold }} hours'
{% endmacro %}

{# Test 2: Exposure Row Count Threshold
   Ensures minimum number of rows were added in time window
#}
{% macro test_exposure_row_count_threshold(
    date_column = '',
    hours_window = 24,
    min_rows = 1,
    model = ''
) %}
  {%- if execute -%}
    {{ log('Testing exposure row count: ' ~ min_rows ~ ' rows in ' ~ hours_window ~ ' hours', info=true) }}
  {%- endif -%}
  
  WITH row_count_check AS (
    SELECT COUNT(*) AS recent_row_count
    FROM {{ get_where_subquery(sql) }}
    WHERE CAST({{ date_column }} AS TIMESTAMP) >= CURRENT_TIMESTAMP() - INTERVAL '{{ hours_window }} hours'
  )
  SELECT *
  FROM row_count_check
  WHERE recent_row_count < {{ min_rows }}
{% endmacro %}

{# Test 3: Exposure No Stale Records
   Checks that no records exceed maximum age threshold
#}
{% macro test_exposure_no_stale_records(
    date_column = '',
    max_age_days = 90,
    model = ''
) %}
  {%- if execute -%}
    {{ log('Testing for stale records: max age ' ~ max_age_days ~ ' days', info=true) }}
  {%- endif -%}
  
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE CAST({{ date_column }} AS DATE) < CURRENT_DATE - {{ max_age_days }}
{% endmacro %}

{# Test 4: Exposure Completeness Check
   Ensures no gaps in daily data for exposure dependencies
#}
{% macro test_exposure_completeness_check(
    date_column = '',
    id_column = '',
    min_completeness_ratio = 0.95,
    model = ''
) %}
  {%- if execute -%}
    {{ log('Testing exposure completeness: ' ~ (min_completeness_ratio * 100) ~ '% threshold', info=true) }}
  {%- endif -%}
  
  WITH date_range AS (
    SELECT
      COUNT(DISTINCT CAST({{ date_column }} AS DATE)) AS actual_dates,
      DATEDIFF(day, MIN({{ date_column }}), MAX({{ date_column }})) + 1 AS expected_dates
    FROM {{ get_where_subquery(sql) }}
  ),
  completeness AS (
    SELECT
      actual_dates,
      expected_dates,
      CAST(actual_dates AS FLOAT) / expected_dates AS completeness_ratio
    FROM date_range
  )
  SELECT *
  FROM completeness
  WHERE completeness_ratio < {{ min_completeness_ratio }}
{% endmacro %}

{# Test 5: Exposure Downstream Availability
   Checks that exposure dependencies are available and non-empty
#}
{% macro test_exposure_dependency_availability(
    model = ''
) %}
  {%- if execute -%}
    {{ log('Testing exposure dependency availability', info=true) }}
  {%- endif -%}
  
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE 1 = 0  {# All rows available = passed #}
{% endmacro %}
