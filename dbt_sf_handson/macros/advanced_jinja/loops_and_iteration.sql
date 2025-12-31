{#
  ADVANCED JINJA TEMPLATING - LOOPS & ITERATION
  
  Demonstrates:
  - For loops with range()
  - Iteration with enumerate()
  - Loop variables (first, last, index, index0)
  - Nested loops
  - Conditional iteration
  - Dynamic table generation
  
  Use Cases:
  - Generating multiple SQL UNION statements
  - Creating dynamic column lists
  - Batch processing patterns
  - Dynamic partition ranges
#}

{# ========== MACRO 1: Generate UNION ALL from Multiple Tables ========== #}

{% macro generate_union_from_tables(table_list, key_column) %}
{#
  Generates a UNION ALL statement from multiple tables with metadata.
  
  Usage:
    {{ generate_union_from_tables(
        table_list=['table1', 'table2', 'table3'],
        key_column='id'
    ) }}
  
  Output:
    SELECT *, '_table1' AS source_table FROM table1
    UNION ALL
    SELECT *, '_table2' AS source_table FROM table2
    UNION ALL
    SELECT *, '_table3' AS source_table FROM table3
#}
  {% for table in table_list %}
    SELECT 
      *,
      '{{ table }}' AS source_table,
      CURRENT_TIMESTAMP AS loaded_at
    FROM {{ table }}
    
    {%- if not loop.last %}
      UNION ALL
    {% endif %}
  {% endfor %}
{% endmacro %}


{# ========== MACRO 2: Dynamic Column Creation ========== #}

{% macro create_column_list(columns, prefix='', data_type='VARCHAR') %}
{#
  Creates a dynamic list of column definitions.
  
  Usage:
    {{ create_column_list(
        columns=['name', 'email', 'phone'],
        prefix='customer_',
        data_type='VARCHAR'
    ) }}
  
  Output:
    customer_name VARCHAR,
    customer_email VARCHAR,
    customer_phone VARCHAR
#}
  {%- for col in columns -%}
    {{ prefix }}{{ col }} {{ data_type }}
    {%- if not loop.last %},{{ '\n' }}{% endif %}
  {%- endfor %}
{% endmacro %}


{# ========== MACRO 3: Generate Date Range Partitions ========== #}

{% macro generate_date_partitions(start_date, end_date, interval_days=30) %}
{#
  Generates SQL CASE statement for date partitions.
  
  Usage:
    {{ generate_date_partitions(
        start_date='2024-01-01',
        end_date='2024-12-31',
        interval_days=30
    ) }}
  
  Output:
    CASE
      WHEN order_date >= '2024-01-01' AND order_date < '2024-01-31' THEN 'jan_2024_w1'
      WHEN order_date >= '2024-01-31' AND order_date < '2024-02-29' THEN 'jan_2024_w2'
      ...
    END AS date_partition
#}
  CASE
    {%- set current_date = start_date %}
    {%- set day_count = 0 %}
    {%- for i in range(100) %}
      {%- if current_date < end_date %}
        WHEN order_date >= '{{ current_date }}'::DATE 
             AND order_date < ('{{ current_date }}'::DATE + INTERVAL '{{ interval_days }} days')
        THEN 'period_{{ i+1 }}'
        {%- set current_date = (current_date | as_datetime + execute_macro('get_days_offset', interval_days)) | string %}
      {% else %}
        {%- break %}
      {% endif %}
    {%- endfor %}
    ELSE 'unknown'
  END AS date_partition
{% endmacro %}


{# ========== MACRO 4: Nested Loop - Matrix Generation ========== #}

{% macro generate_column_matrix(row_headers, col_headers) %}
{#
  Generates a matrix of columns (nested loops).
  
  Usage:
    {{ generate_column_matrix(
        row_headers=['metric', 'value', 'ratio'],
        col_headers=['2024-Q1', '2024-Q2', '2024-Q3']
    ) }}
  
  Output:
    metric_q1, value_q1, ratio_q1,
    metric_q2, value_q2, ratio_q2,
    metric_q3, value_q3, ratio_q3
#}
  {%- for row in row_headers %}
    {%- for col in col_headers %}
      {{ row }}_{{ col }}
      {%- if not (loop.last and loop.first) %},{% endif %}
    {%- endfor %}
    {%- if not loop.last %},{{ '\n' }}{% endif %}
  {%- endfor %}
{% endmacro %}


{# ========== MACRO 5: Conditional Iteration - Skip Certain Items ========== #}

{% macro iterate_with_conditions(all_columns, exclude_columns=['id', 'created_at']) %}
{#
  Iterates through columns, conditionally skipping certain ones.
  
  Usage:
    {{ iterate_with_conditions(
        all_columns=['id', 'name', 'email', 'created_at', 'phone'],
        exclude_columns=['id', 'created_at']
    ) }}
  
  Output:
    name, email, phone
#}
  {%- set valid_columns = [] %}
  {%- for col in all_columns %}
    {%- if col not in exclude_columns %}
      {%- set _ = valid_columns.append(col) %}
    {% endif %}
  {%- endfor %}
  
  {%- for col in valid_columns %}
    {{ col }}
    {%- if not loop.last %}, {% endif %}
  {%- endfor %}
{% endmacro %}


{# ========== MACRO 6: Dynamic WHERE Clause from Dict ========== #}

{% macro build_where_clause(filters) %}
{#
  Builds WHERE clause from dictionary of filters.
  
  Usage:
    {{ build_where_clause({
        'customer_segment': 'premium',
        'order_status': 'completed',
        'year': 2024
    }) }}
  
  Output:
    WHERE customer_segment = 'premium'
      AND order_status = 'completed'
      AND year = 2024
#}
  {% if filters %}
    WHERE
    {%- for column, value in filters.items() %}
      {{ column }} = '{{ value }}'
      {%- if not loop.last %} AND{% endif %}
    {%- endfor %}
  {% endif %}
{% endmacro %}


{# ========== MACRO 7: Loop with Enumerate - Index Access ========== #}

{% macro generate_column_transformations(columns, transformations) %}
{#
  Uses enumerate to access index while iterating.
  
  Usage:
    {{ generate_column_transformations(
        columns=['revenue', 'cost', 'margin'],
        transformations=['SUM', 'SUM', 'AVG']
    ) }}
  
  Output:
    SUM(revenue) AS revenue_total,
    SUM(cost) AS cost_total,
    AVG(margin) AS margin_avg
#}
  {%- for col, transform in zip(columns, transformations) %}
    {{ transform }}({{ col }}) AS {{ col }}_{{ transform | lower }}
    {%- if not loop.last %},{{ '\n' }}{% endif %}
  {%- endfor %}
{% endmacro %}


{# ========== MACRO 8: Batch Processing - Loop with Chunks ========== #}

{% macro process_in_batches(items, batch_size=3) %}
{#
  Processes items in batches using loop variables.
  
  Usage:
    {{ process_in_batches(
        items=['col1', 'col2', 'col3', 'col4', 'col5'],
        batch_size=2
    ) }}
  
  Output:
    Batch 1: col1, col2
    Batch 2: col3, col4
    Batch 3: col5
#}
  {%- for item in items %}
    {%- if loop.index0 % batch_size == 0 %}
      -- Batch {{ (loop.index0 / batch_size) | int + 1 }}:
    {% endif %}
    {{ item }}
    {%- if not loop.last %}, {% endif %}
  {%- endfor %}
{% endmacro %}


{# ========== MACRO 9: First/Last Loop Variable Detection ========== #}

{% macro generate_field_validators(fields) %}
{#
  Uses loop.first, loop.last for special formatting.
  
  Usage:
    {{ generate_field_validators(['email', 'phone', 'address']) }}
  
  Output:
    IF email IS NOT NULL AND
    IF phone IS NOT NULL AND
    IF address IS NOT NULL THEN valid = true
#}
  {%- for field in fields %}
    {%- if loop.first %}IF {% else %}   {% endif %}{{ field }} IS NOT NULL
    {%- if not loop.last %} AND
    {% else %} THEN valid = true{% endif %}
  {%- endfor %}
{% endmacro %}


{# ========== MACRO 10: Reverse Loop - Process in Reverse Order ========== #}

{% macro reverse_column_order(columns) %}
{#
  Demonstrates reversing column order in loop.
  
  Usage:
    {{ reverse_column_order(['id', 'name', 'email', 'created_at']) }}
  
  Output:
    created_at, email, name, id
#}
  {%- for col in columns | reverse %}
    {{ col }}
    {%- if not loop.last %}, {% endif %}
  {%- endfor %}
{% endmacro %}
