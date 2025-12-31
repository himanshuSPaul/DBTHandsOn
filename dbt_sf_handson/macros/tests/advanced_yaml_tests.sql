{# ============================================================================
   ADVANCED YAML-BASED CUSTOM TESTS - dbt 1.8+ FEATURES
   ============================================================================
   Purpose: Modern parameterized generic tests using dbt 1.8+ capabilities
   
   Features Demonstrated:
   - Advanced parameterization with multiple arguments
   - Conditional test logic with Jinja2 control flow
   - Cross-table validation with model references
   - Cardinality constraints and freshness checks
   - Regex pattern matching and string validation
   - Ratio and proportionality constraints
   
   Note: All macros include 'model' parameter for dbt compatibility
   ============================================================================ #}

{# ============================================================================
   TEST 1: Advanced Ratio Constraint (Parameterized Column Ratio)
   ============================================================================
   Description: Validates the ratio between two numeric columns
   Parameters:
     - column_name: Column being tested (auto-injected by dbt)
     - numerator: First column for ratio calculation
     - denominator: Second column for ratio calculation
     - min_ratio: Minimum acceptable ratio (inclusive)
     - max_ratio: Maximum acceptable ratio (inclusive)
     - model: Model context (auto-injected by dbt)
   
   Example Use Case: Ensure discount never exceeds 50% of order total
   ============================================================================ #}
{% macro test_advanced_ratio_constraint(
    column_name = '',
    numerator = '',
    denominator = '',
    min_ratio = 0.0,
    max_ratio = 1.0,
    model = ''
) %}
  
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

{# ============================================================================
   TEST 2: Advanced Regex Pattern Matching (Modern String Validation)
   ============================================================================
   Description: Validates column values match a regex pattern
   Parameters:
     - column_name: Column to validate
     - pattern: Regex pattern (Snowflake POSIX regex syntax)
     - allow_null: Whether NULL values are acceptable (default: true)
     - model: Model context (auto-injected by dbt)
   
   Example Use Case: Validate email format, phone numbers, postal codes
   ============================================================================ #}
{% macro test_advanced_regex_match(
    column_name = '',
    pattern = '',
    allow_null = true,
    model = ''
) %}
  
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE 1=1
    {% if not allow_null %}
      AND {{ column_name }} IS NOT NULL
    {% endif %}
    AND {{ column_name }} IS NOT NULL
    AND NOT REGEXP_LIKE({{ column_name }}, '{{ pattern }}')
  
{% endmacro %}

{# ============================================================================
   TEST 3: Advanced Cross-Table Referential Integrity
   ============================================================================
   Description: Validates column values exist in referenced table
   Parameters:
     - column_name: Foreign key column in current model
     - ref_model: Referenced model name
     - ref_column: Primary key column in referenced model
     - allow_null: Whether NULL values are acceptable
     - model: Model context (auto-injected by dbt)
   
   Example Use Case: Ensure all order_ids in stg_items exist in stg_orders
   ============================================================================ #}
{% macro test_advanced_referential_integrity(
    column_name = '',
    ref_model = '',
    ref_column = '',
    allow_null = true,
    model = ''
) %}
  
  SELECT
    current.{{ column_name }},
    COUNT(*) as violation_count
  FROM {{ get_where_subquery(sql) }} current
  LEFT JOIN {{ ref(ref_model) }} reference
    ON current.{{ column_name }} = reference.{{ ref_column }}
  WHERE 
    {% if allow_null %}
      (current.{{ column_name }} IS NOT NULL 
       AND reference.{{ ref_column }} IS NULL)
    {% else %}
      reference.{{ ref_column }} IS NULL
    {% endif %}
  GROUP BY current.{{ column_name }}
  
{% endmacro %}

{# ============================================================================
   TEST 4: Advanced Cardinality Validation (Distinct Value Constraints)
   ============================================================================
   Description: Validates the number of distinct values in a column
   Parameters:
     - column_name: Column to check
     - max_cardinality: Maximum acceptable distinct values
     - min_cardinality: Minimum acceptable distinct values (optional)
     - model: Model context (auto-injected by dbt)
   
   Example Use Case: Ensure customer_segment has only 4-5 expected segments
   ============================================================================ #}
{% macro test_advanced_cardinality(
    column_name = '',
    max_cardinality = 1000,
    min_cardinality = 1,
    model = ''
) %}
  
  WITH cardinality_check AS (
    SELECT 
      COUNT(DISTINCT {{ column_name }}) as distinct_count
    FROM {{ get_where_subquery(sql) }}
    WHERE {{ column_name }} IS NOT NULL
  )
  SELECT * 
  FROM cardinality_check
  WHERE distinct_count < {{ min_cardinality }}
    OR distinct_count > {{ max_cardinality }}
  
{% endmacro %}

{# ============================================================================
   TEST 5: Advanced Temporal Constraint (Freshness Window Validation)
   ============================================================================
   Description: Validates that data exists within a specific time window
   Parameters:
     - column_name: Timestamp column to check (auto-injected by dbt)
     - days_back: How many days of data to require (default: 7)
     - row_count_threshold: Minimum rows expected (optional)
     - model: Model context (auto-injected by dbt)
   
   Example Use Case: Ensure daily order data is updated within last 24 hours
   ============================================================================ #}
{% macro test_advanced_freshness_window(
    column_name = '',
    days_back = 7,
    row_count_threshold = 1,
    model = ''
) %}
  
  WITH freshness_check AS (
    SELECT 
      COUNT(*) as recent_row_count,
      MAX({{ column_name }}) as max_date,
      CURRENT_TIMESTAMP() as check_time
    FROM {{ get_where_subquery(sql) }}
    WHERE {{ column_name }} >= DATEADD(day, -{{ days_back }}, CURRENT_TIMESTAMP())
  )
  SELECT *
  FROM freshness_check
  WHERE recent_row_count < {{ row_count_threshold }}
  
{% endmacro %}

{# ============================================================================
   TEST 6: Advanced Column Covariance (Multi-Column Business Logic)
   ============================================================================
   Description: Validates business rules involving multiple columns
   Parameters:
     - column_name: Column to check (auto-injected by dbt)
     - expected_value_column: Column with expected values
     - condition: SQL condition joining the columns
     - model: Model context (auto-injected by dbt)
   
   Example Use Case: Ensure high-priority orders always have expedited shipping
   ============================================================================ #}
{% macro test_advanced_covariance(
    column_name = '',
    expected_value_column = '',
    condition = '',
    model = ''
) %}
  
  SELECT *
  FROM {{ get_where_subquery(sql) }}
  WHERE NOT ({{ condition }})
    AND {{ column_name }} IS NOT NULL
    AND {{ expected_value_column }} IS NOT NULL
  
{% endmacro %}

{# ============================================================================
   TEST 7: Advanced Time-Gap Detection (Sequence Continuity Validation)
   ============================================================================
   Description: Validates continuity in time-series data without large gaps
   Parameters:
     - column_name: Timestamp column to check (auto-injected by dbt)
     - id_column: Entity identifier (e.g., customer_id, store_id)
     - max_gap_days: Maximum acceptable gap between records
     - model: Model context (auto-injected by dbt)
   
   Example Use Case: Ensure customer transactions don't have unexpected gaps
   ============================================================================ #}
{% macro test_advanced_time_gap(
    column_name = '',
    id_column = '',
    max_gap_days = 30,
    model = ''
) %}
  
  WITH ordered_data AS (
    SELECT
      {{ id_column }},
      {{ column_name }},
      LAG({{ column_name }}) OVER (
        PARTITION BY {{ id_column }} 
        ORDER BY {{ column_name }}
      ) as prev_date,
      DATEDIFF(day, 
        LAG({{ column_name }}) OVER (
          PARTITION BY {{ id_column }} 
          ORDER BY {{ column_name }}
        ),
        {{ column_name }}
      ) as days_gap
    FROM {{ get_where_subquery(sql) }}
  )
  SELECT *
  FROM ordered_data
  WHERE days_gap > {{ max_gap_days }}
    AND days_gap IS NOT NULL
  
{% endmacro %}

{# ============================================================================
   TEST 8: Advanced Conditional Uniqueness (Selective Uniqueness Constraints)
   ============================================================================
   Description: Validates uniqueness only for certain rows
   Parameters:
     - column_name: Column to check (auto-injected by dbt)
     - unique_columns: List of columns that should be unique
     - where_clause: Optional WHERE clause to filter rows checked
     - model: Model context (auto-injected by dbt)
   
   Example Use Case: Ensure no duplicate active customers
   ============================================================================ #}
{% macro test_advanced_conditional_uniqueness(
    column_name = '',
    unique_columns = [],
    where_clause = '1=1',
    model = ''
) %}
  
  WITH uniqueness_check AS (
    SELECT
      {% for col in unique_columns -%}
        {{ col }},
      {% endfor %}
      COUNT(*) as occurrence_count
    FROM {{ get_where_subquery(sql) }}
    WHERE {{ where_clause }}
    GROUP BY {% for col in unique_columns -%}{{ col }}{{ "," if not loop.last else "" }}{%- endfor %}
  )
  SELECT *
  FROM uniqueness_check
  WHERE occurrence_count > 1
  
{% endmacro %}
