{#
  ADVANCED JINJA TEMPLATING - CONDITIONALS & CONTROL FLOW
  
  Demonstrates:
  - If/elif/else statements
  - Nested conditionals
  - Ternary operators
  - Boolean logic
  - Early returns
  - Context-aware branching
  
  Use Cases:
  - Environment-specific SQL generation
  - Feature flags
  - Performance optimization paths
  - Conditional column inclusion
  - Dynamic materialization
#}

{# ========== MACRO 1: Environment-Specific SQL ========== #}

{% macro environment_aware_select(environment='dev') %}
{#
  Generates different SQL based on environment.
  
  Usage:
    {{ environment_aware_select(environment='prod') }}
  
  Output (dev):
    SELECT TOP 1000 * FROM raw_table
    
  Output (prod):
    SELECT * FROM raw_table WHERE is_active = true
#}
  SELECT
    {%- if environment == 'dev' %}
      TOP 1000
    {%- endif %}
    *
  FROM raw_table
  
  {%- if environment == 'prod' %}
    WHERE is_active = true
      AND created_date >= CURRENT_DATE - INTERVAL 30 DAY
    ORDER BY created_date DESC
  {%- elif environment == 'staging' %}
    WHERE created_date >= CURRENT_DATE - INTERVAL 7 DAY
    ORDER BY created_date DESC
  {%- else %}
    -- Development environment
    ORDER BY created_date DESC
    LIMIT 100
  {%- endif %}
{% endmacro %}


{# ========== MACRO 2: Feature Flag Conditionals ========== #}

{% macro feature_flagged_query(include_metrics=false, include_segments=false) %}
{#
  Conditionally includes features based on flags.
  
  Usage:
    {{ feature_flagged_query(include_metrics=true, include_segments=true) }}
  
  Output varies based on flags enabled.
#}
  SELECT
    customer_id,
    customer_name,
    {%- if include_metrics %}
      -- Metrics columns
      lifetime_value,
      purchase_count,
      avg_order_value,
    {%- endif %}
    {%- if include_segments %}
      -- Segment columns
      customer_segment,
      segment_priority,
      segment_updated_date,
    {%- endif %}
    created_date
  FROM customers
{% endmacro %}


{# ========== MACRO 3: Ternary Operator Pattern ========== #}

{% macro apply_conditional_sorting(sort_order='ASC') %}
{#
  Uses inline ternary logic.
  
  Usage:
    {{ apply_conditional_sorting(sort_order='DESC') }}
  
  Output:
    ORDER BY revenue DESC
#}
  SELECT * FROM orders
  ORDER BY revenue {{ sort_order if sort_order in ['ASC', 'DESC'] else 'ASC' }}
{% endmacro %}


{# ========== MACRO 4: Nested Conditionals - Multi-Level Logic ========== #}

{% macro complex_conditional_logic(data_type='sales', include_details=true, time_window='30d') %}
{#
  Demonstrates nested if statements.
  
  Usage:
    {{ complex_conditional_logic(data_type='sales', include_details=true, time_window='7d') }}
#}
  SELECT
    *
    {%- if data_type == 'sales' %}
      {%- if include_details %}
        , product_category
        , region
        , salesperson_name
      {%- endif %}
      , transaction_amount
      , transaction_date
      FROM sales_transactions
      {%- if time_window == '7d' %}
        WHERE transaction_date >= CURRENT_DATE - 7
      {%- elif time_window == '30d' %}
        WHERE transaction_date >= CURRENT_DATE - 30
      {%- elif time_window == '90d' %}
        WHERE transaction_date >= CURRENT_DATE - 90
      {%- endif %}
    
    {%- elif data_type == 'inventory' %}
      {%- if include_details %}
        , warehouse_location
        , bin_number
      {%- endif %}
      , quantity_on_hand
      FROM inventory
      {%- if quantity_on_hand < 100 %}
        WHERE quantity_on_hand < 100
      {%- endif %}
    
    {%- else %}
      FROM unknown_table
    {%- endif %}
{% endmacro %}


{# ========== MACRO 5: Boolean Logic - Multiple Conditions ========== #}

{% macro multi_condition_filter(is_active=true, is_verified=true, has_recent_activity=true) %}
{#
  Combines multiple boolean conditions.
  
  Usage:
    {{ multi_condition_filter(is_active=true, is_verified=true, has_recent_activity=false) }}
#}
  SELECT * FROM customers
  WHERE 1=1
    {%- if is_active %} AND status = 'active'{% endif %}
    {%- if is_verified %} AND email_verified = true{% endif %}
    {%- if has_recent_activity %} AND last_activity_date >= CURRENT_DATE - 30{% endif %}
{% endmacro %}


{# ========== MACRO 6: Early Return - Short Circuit Logic ========== #}

{% macro validate_and_select(table_name) %}
{#
  Returns early if conditions aren't met.
  
  Usage:
    {{ validate_and_select(table_name='customers') }}
#}
  {%- if not table_name or table_name|length == 0 %}
    -- ERROR: table_name is required
    SELECT 'ERROR: Invalid table name' AS error_message
  {%- elif table_name == 'customers' %}
    SELECT * FROM {{ ref('stg_customers') }}
  {%- elif table_name == 'orders' %}
    SELECT * FROM {{ ref('stg_orders') }}
  {%- elif table_name == 'products' %}
    SELECT * FROM {{ ref('stg_products') }}
  {%- else %}
    SELECT 'ERROR: Unknown table' AS error_message
  {%- endif %}
{% endmacro %}


{# ========== MACRO 7: Conditional Column Ordering ========== #}

{% macro conditional_column_order(is_detailed=false) %}
{#
  Changes column selection based on flag.
  
  Usage:
    {{ conditional_column_order(is_detailed=true) }}
#}
  SELECT
    {%- if is_detailed %}
      -- Detailed view
      customer_id,
      customer_name,
      customer_email,
      customer_phone,
      customer_address,
      customer_city,
      customer_state,
      customer_zip,
      segment,
      lifetime_value,
      last_purchase_date
    {%- else %}
      -- Summary view
      customer_id,
      customer_name,
      segment,
      lifetime_value
    {%- endif %}
  FROM customers
{% endmacro %}


{# ========== MACRO 8: Conditional Materialization ========== #}

{% macro smart_materialization(row_count_threshold=1000000) %}
{#
  Determines materialization type based on data size.
  
  Usage in dbt model config:
    {{ config(materialized = smart_materialization(row_count_threshold=500000)) }}
  
  Note: This would need to be combined with execute blocks in practice.
#}
  {%- if execute %}
    {%- set row_count = run_query("SELECT COUNT(*) AS cnt FROM source_table").columns[0][0] %}
    {%- if row_count > row_count_threshold %}
      table
    {%- else %}
      view
    {%- endif %}
  {%- else %}
    view
  {%- endif %}
{% endmacro %}


{# ========== MACRO 9: Conditional Test Generation ========== #}

{% macro conditional_test_generation(columns, enable_uniqueness=true, enable_not_null=true) %}
{#
  Generates test YAML conditionally.
  
  Usage in YAML test config:
    {{ conditional_test_generation(
        columns=['id', 'email'],
        enable_uniqueness=true,
        enable_not_null=true
    ) }}
#}
  {%- for col in columns %}
  - name: {{ col }}
    description: "Column: {{ col }}"
    {%- if enable_not_null %}
    tests:
      - not_null
    {%- endif %}
    {%- if enable_uniqueness and col == 'id' or col == 'email' %}
      {%- if enable_not_null %}
      {% else %}
    tests:
      {% endif %}
      - unique
    {%- endif %}
  {%- endfor %}
{% endmacro %}


{# ========== MACRO 10: Conditional Performance Hints ========== #}

{% macro add_performance_optimization(is_large_table=false, should_index=false) %}
{#
  Adds optimization hints conditionally.
  
  Usage:
    {{ add_performance_optimization(is_large_table=true, should_index=true) }}
#}
  {%- if is_large_table %}
    -- Large table optimization
    SELECT /*+ PARALLEL(8) */ * FROM table_name
    {%- if should_index %}
      WITH indexed_data AS (
        SELECT * FROM table_name
        -- Query uses indexed columns
      )
    {%- endif %}
  {%- else %}
    -- Standard query
    SELECT * FROM table_name
  {%- endif %}
{% endmacro %}


{# ========== MACRO 11: Dictionary-Based Case Statement ========== #}

{% macro case_from_dict(column_name, mapping_dict) %}
{#
  Generates CASE statement from dictionary.
  
  Usage:
    {{ case_from_dict(
        column_name='status_code',
        mapping_dict={
          '1': 'Active',
          '2': 'Inactive',
          '3': 'Pending'
        }
    ) }}
  
  Output:
    CASE status_code
      WHEN '1' THEN 'Active'
      WHEN '2' THEN 'Inactive'
      WHEN '3' THEN 'Pending'
      ELSE 'Unknown'
    END
#}
  CASE {{ column_name }}
  {%- for code, label in mapping_dict.items() %}
    WHEN '{{ code }}' THEN '{{ label }}'
  {%- endfor %}
    ELSE 'Unknown'
  END
{% endmacro %}


{# ========== MACRO 12: Conditional Window Function ========== #}

{% macro conditional_window_partition(partition_by='customer_id', order_by='order_date') %}
{#
  Conditionally applies window functions.
  
  Usage:
    {{ conditional_window_partition(partition_by='region', order_by='revenue DESC') }}
#}
  SELECT
    *,
    ROW_NUMBER() OVER (
      {%- if partition_by %}
        PARTITION BY {{ partition_by }}
      {%- endif %}
      ORDER BY {{ order_by }}
    ) AS row_num
  FROM orders
{% endmacro %}
