{# ============================================================================
   REFERENTIAL NAMESPACE - FOREIGN KEY & RELATIONSHIP TESTS
   ============================================================================
   Purpose: Cross-table relationship validation and referential integrity
   
   Tests in this namespace:
   1. test_ref_foreign_key_exists        - FK exists in parent table
   2. test_ref_cardinality_constraint    - Expected count of distinct values
   3. test_ref_no_orphaned_records       - All FK references valid
   4. test_ref_join_completeness        - All joins have matches
   
   Namespace Prefix: 'referential' or 'ref'
   File Location: macros/tests/referential_namespace.sql
   ============================================================================ #}

{# Test REF.1: Foreign key validation - Check that all foreign key values exist in parent table #}
{% macro test_ref_foreign_key_exists(column_name = '', ref_model = '', ref_column = '', allow_null = false, model = '') %}
  {%- if execute -%}
    {{ log('Running test: referential.foreign_key_exists - FK "' ~ column_name ~ '" -> "' ~ ref_model ~ '"."' ~ ref_column ~ '"', info=true) }}
  {%- endif -%}
  
  {%- if allow_null -%}
    WITH fk_check AS (
      SELECT DISTINCT {{ column_name }}
      FROM {{ get_where_subquery(sql) }}
      WHERE {{ column_name }} IS NOT NULL
    ),
    parent_keys AS (
      SELECT DISTINCT {{ ref_column }}
      FROM {{ ref(ref_model) }}
    )
    SELECT fk_check.{{ column_name }} AS invalid_fk
    FROM fk_check
    LEFT JOIN parent_keys ON fk_check.{{ column_name }} = parent_keys.{{ ref_column }}
    WHERE parent_keys.{{ ref_column }} IS NULL
  {%- else -%}
    WITH fk_check AS (
      SELECT DISTINCT {{ column_name }}
      FROM {{ get_where_subquery(sql) }}
    ),
    parent_keys AS (
      SELECT DISTINCT {{ ref_column }}
      FROM {{ ref(ref_model) }}
    )
    SELECT fk_check.{{ column_name }} AS invalid_fk
    FROM fk_check
    LEFT JOIN parent_keys ON fk_check.{{ column_name }} = parent_keys.{{ ref_column }}
    WHERE parent_keys.{{ ref_column }} IS NULL
  {%- endif -%}
{% endmacro %}

{# Test REF.2: Cardinality constraint - Validate distinct value counts #}
{% macro test_ref_cardinality_constraint(
    column_name = '',
    min_cardinality = 0,
    max_cardinality = 10000,
    model = ''
) %}
  {%- if execute -%}
    {{ log('Running test: referential.cardinality_constraint - Column "' ~ column_name ~ '" must have ' ~ min_cardinality ~ '-' ~ max_cardinality ~ ' distinct values', info=true) }}
  {%- endif -%}
  
  WITH cardinality_check AS (
    SELECT COUNT(DISTINCT {{ column_name }}) AS distinct_count
    FROM {{ get_where_subquery(sql) }}
  )
  SELECT *
  FROM cardinality_check
  WHERE distinct_count < {{ min_cardinality }}
     OR distinct_count > {{ max_cardinality }}
{% endmacro %}

{# Test REF.3: No orphaned records - All foreign keys must have parent records #}
{% macro test_ref_no_orphaned_records(
    fk_column = '',
    parent_model = '',
    parent_key = '',
    model = ''
) %}
  {%- if execute -%}
    {{ log('Running test: referential.no_orphaned_records - Check "' ~ fk_column ~ '" matches "' ~ parent_model ~ '"."' ~ parent_key ~ '"', info=true) }}
  {%- endif -%}
  
  SELECT COUNT(*) AS orphaned_count
  FROM {{ get_where_subquery(sql) }} AS child
  LEFT JOIN {{ ref(parent_model) }} AS parent 
    ON child.{{ fk_column }} = parent.{{ parent_key }}
  WHERE parent.{{ parent_key }} IS NULL
    AND child.{{ fk_column }} IS NOT NULL
  HAVING orphaned_count > 0
{% endmacro %}

{# Test REF.4: Join completeness - Expected number of matches in join #}
{% macro test_ref_join_completeness(
    fk_column = '',
    join_model = '',
    join_key = '',
    expected_match_ratio = 0.95,
    model = ''
) %}
  {%- if execute -%}
    {{ log('Running test: referential.join_completeness - Expect ' ~ (expected_match_ratio * 100) ~ '% match rate', info=true) }}
  {%- endif -%}
  
  WITH join_analysis AS (
    SELECT 
      COUNT(*) AS total_rows,
      COUNT(CASE WHEN parent.{{ join_key }} IS NOT NULL THEN 1 END) AS matched_rows,
      COUNT(CASE WHEN parent.{{ join_key }} IS NOT NULL THEN 1 END) * 1.0 / 
      COUNT(*) AS match_ratio
    FROM {{ get_where_subquery(sql) }} AS child
    LEFT JOIN {{ ref(join_model) }} AS parent
      ON child.{{ fk_column }} = parent.{{ join_key }}
  )
  SELECT *
  FROM join_analysis
  WHERE match_ratio < {{ expected_match_ratio }}
{% endmacro %}
