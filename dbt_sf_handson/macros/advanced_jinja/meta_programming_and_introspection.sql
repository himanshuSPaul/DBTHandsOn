{#
  ADVANCED JINJA TEMPLATING - META-PROGRAMMING & INTROSPECTION
  
  Demonstrates:
  - Execute blocks for runtime data querying
  - Dynamic SQL generation based on database state
  - Introspection of database objects
  - Context variables (execute, compile_time, etc.)
  - Macro composition and nesting
  
  Use Cases:
  - Schema discovery at build time
  - Column auto-detection
  - Dynamic test generation
  - Adaptive SQL based on database state
  - Metadata-driven transformations
#}

{# ========== MACRO 1: Execute Block - Query Database at Build Time ========== #}

{% macro get_column_info_at_build_time(table_name) %}
{#
  Queries database during dbt compile to get column info.
  
  Usage:
    {{ get_column_info_at_build_time('SNOWFLAKE.INFORMATION_SCHEMA.TABLES') }}
  
  Note: Only executes during dbt run/parse, not during dbt parse-only.
#}
  {% if execute %}
    -- Executing at build time
    {% set columns = run_query("
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_NAME = '" + table_name | upper + "'
      ORDER BY ORDINAL_POSITION
    ") %}
    
    {% set column_list = [] %}
    {% for row in columns.rows %}
      {% set _ = column_list.append(row[0]) %}
    {% endfor %}
    
    -- Found {{ column_list | length }} columns:
    {% for col in column_list %}
    SELECT '{{ col }}' AS column_name
    {% if not loop.last %}UNION ALL{% endif %}
    {% endfor %}
  {% else %}
    -- During parsing only (execute=false)
    SELECT 'PARSING_PHASE' AS phase
  {% endif %}
{% endmacro %}


{# ========== MACRO 2: Dynamic Column List from Source ========== #}

{% macro get_all_columns_from_source(source_name, table_name) %}
{#
  Dynamically gets columns from dbt source definition.
  
  Usage:
    {{ get_all_columns_from_source('raw', 'customers') }}
#}
  {% set columns = source(source_name, table_name).columns | keys() | list %}
  
  SELECT
    {%- for col in columns %}
    {{ col }}
    {%- if not loop.last %},{% endif %}
    {%- endfor %}
  FROM {{ source(source_name, table_name) }}
{% endmacro %}


{# ========== MACRO 3: Conditional Macro Composition ========== #}

{% macro call_appropriate_macro(operation_type, data) %}
{#
  Determines which macro to call based on input.
  
  Usage:
    {{ call_appropriate_macro(
        operation_type='normalize',
        data='  test string  '
    ) }}
#}
  {%- if operation_type == 'normalize' %}
    {{ data | trim | upper }}
  {%- elif operation_type == 'reverse' %}
    {{ data | reverse }}
  {%- elif operation_type == 'sanitize' %}
    {{ data | regex_replace('[^a-zA-Z0-9]', '') }}
  {%- else %}
    {{ data }}
  {%- endif %}
{% endmacro %}


{# ========== MACRO 4: Recursive-like Macro Nesting ========== #}

{% macro process_nested_structure(data, depth=0, max_depth=5) %}
{#
  Demonstrates nested macro calls with depth control.
  
  Usage:
    {{ process_nested_structure(data=my_complex_object, depth=0, max_depth=3) }}
#}
  {%- if depth > max_depth %}
    -- Max depth reached
  {%- else %}
    {%- for key, value in data.items() %}
      {%- if value is mapping %}
        -- Nested object at depth {{ depth }}
        {{ process_nested_structure(data=value, depth=depth+1, max_depth=max_depth) }}
      {%- else %}
        -- Key: {{ key }}, Value: {{ value }}
      {%- endif %}
    {%- endfor %}
  {%- endif %}
{% endmacro %}


{# ========== MACRO 5: Context-Aware SQL Generation ========== #}

{% macro generate_context_aware_query() %}
{#
  Generates different SQL based on execution context.
  
  Usage:
    {{ generate_context_aware_query() }}
#}
  SELECT
    {%- if execute %}
      '{{ sql_macro_namespace.table_name }}' AS table_name,
    {%- endif %}
    *,
    {%- if flags.FULL_REFRESH %}
      'FULL_REFRESH_MODE' AS execution_mode
    {%- else %}
      'INCREMENTAL_MODE' AS execution_mode
    {%- endif %}
  FROM source_table
{% endmacro %}


{# ========== MACRO 6: Dynamic Test Generator ========== #}

{% macro generate_tests_for_columns(table_ref, columns, test_type='not_null') %}
{#
  Generates test YAML dynamically.
  
  Usage:
    {{ generate_tests_for_columns(
        table_ref=ref('stg_customers'),
        columns=['id', 'email'],
        test_type='not_null'
    ) }}
#}
  {%- set columns_info = get_ref_columns(table_ref) %}
  
  {%- for col in columns %}
    {%- if col in columns_info %}
  - name: {{ col }}
    tests:
      - {{ test_type }}
    {%- endif %}
  {%- endfor %}
{% endmacro %}


{# ========== MACRO 7: Introspect Model Dependencies ========== #}

{% macro introspect_model_deps(model_name) %}
{#
  Analyzes dependencies of a model.
  
  Usage:
    {{ introspect_model_deps('stg_orders') }}
#}
  {% if execute %}
    {%- set upstream = [] %}
    {%- for parent in graph.get_node_by_name(model_name).depends_on.nodes %}
      {%- if 'model' in parent or 'source' in parent %}
        {%- set _ = upstream.append(parent.split('.')[-1]) %}
      {%- endif %}
    {%- endfor %}
    
    -- Dependencies for {{ model_name }}:
    {% for dep in upstream %}
    -- {{ dep }}
    {% endfor %}
  {% endif %}
{% endmacro %}


{# ========== MACRO 8: Build Dynamic FROM Clause ========== #}

{% macro dynamic_from_clause(use_current=true, fallback_table='history') %}
{#
  Chooses table based on availability.
  
  Usage:
    {{ dynamic_from_clause(use_current=true, fallback_table='backup') }}
#}
  FROM
  {%- if use_current %}
    {%- if execute %}
      {# Check if table exists #}
      current_table
    {%- else %}
      current_table
    {%- endif %}
  {%- else %}
    {{ fallback_table }}
  {%- endif %}
{% endmacro %}


{# ========== MACRO 9: State-Based SQL Generation ========== #}

{% macro generate_state_aware_sql() %}
{#
  Generates different SQL based on dbt state.
  
  Usage:
    {{ generate_state_aware_sql() }}
#}
  SELECT * FROM {{ ref('base_model') }}
  
  {%- if state.newer_than('2025-12-31') %}
    -- Only process recent changes
    WHERE updated_at > '2025-12-31'
  {%- endif %}
  
  {%- if flags.STORE_FAILURES %}
    -- Store test failures for analysis
  {%- endif %}
{% endmacro %}


{# ========== MACRO 10: Metadata-Driven Column Selection ========== #}

{% macro select_columns_by_metadata(table_ref, include_tags=[]) %}
{#
  Selects columns based on dbt metadata tags.
  
  Usage:
    {{ select_columns_by_metadata(
        table_ref=ref('stg_customers'),
        include_tags=['pii', 'core']
    ) }}
#}
  {% set columns = get_ref_columns(table_ref) %}
  
  SELECT
    {%- for col in columns %}
      {%- set col_meta = columns[col] %}
      {%- if not include_tags or (col_meta.tags | intersect(include_tags) | length > 0) %}
        {{ col }}
        {%- if not loop.last %},{% endif %}
      {%- endif %}
    {%- endfor %}
  FROM {{ table_ref }}
{% endmacro %}


{# ========== MACRO 11: Graph Introspection ========== #}

{% macro introspect_project_graph() %}
{#
  Analyzes dbt project graph structure.
  
  Usage:
    {{ introspect_project_graph() }}
#}
  {% if execute %}
    {%- set models = graph.nodes.values() | selectattr('resource_type', 'equalto', 'model') | list %}
    {%- set tests = graph.nodes.values() | selectattr('resource_type', 'equalto', 'test') | list %}
    {%- set sources = graph.sources.values() | list %}
    
    -- Project Statistics
    -- Models: {{ models | length }}
    -- Tests: {{ tests | length }}
    -- Sources: {{ sources | length }}
    
    {%- for model in models | first(3) %}
    -- Model: {{ model.name }}
    {%- endfor %}
  {% endif %}
{% endmacro %}


{# ========== MACRO 12: Adaptive Configuration Generation ========== #}

{% macro adaptive_materialization(expected_rows=1000000) %}
{#
  Determines best materialization strategy.
  
  Usage in model config:
    materialized = 'table' if execute and get_row_count() > 1000000 else 'view'
#}
  {%- if execute %}
    {%- set row_count = run_query("SELECT COUNT(*) as cnt FROM source_data").rows[0][0] %}
    {%- if row_count > expected_rows %}
      table
    {%- else %}
      view
    {%- endif %}
  {%- else %}
    view
  {%- endif %}
{% endmacro %}
