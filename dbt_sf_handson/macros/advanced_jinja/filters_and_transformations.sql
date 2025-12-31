{#
  ADVANCED JINJA TEMPLATING - FILTERS & TRANSFORMATIONS
  
  Demonstrates:
  - Built-in filters (upper, lower, length, select, map, etc.)
  - Custom filters
  - Filter chaining
  - List/string transformations
  - Regular expression filters
  - Date/time filters
  
  Use Cases:
  - String normalization
  - List manipulation
  - Data type conversions
  - Pattern matching
  - Dynamic data cleaning
#}

{# ========== MACRO 1: String Transformation Filters ========== #}

{% macro normalize_strings(raw_string) %}
{#
  Demonstrates string filters: upper, lower, trim, replace.
  
  Usage:
    {{ normalize_strings(raw_string='  JOHN DOE  ') }}
  
  Output variations:
    JOHN DOE (upper)
    john doe (lower)
    JOHN DOE (trimmed)
#}
  -- Original: '{{ raw_string }}'
  -- Upper: '{{ raw_string | upper }}'
  -- Lower: '{{ raw_string | lower }}'
  -- Title: '{{ raw_string | title }}'
  -- Trimmed: '{{ raw_string | trim }}'
  -- First 10 chars: '{{ raw_string | first(10) }}'
  -- Length: {{ raw_string | length }}
{% endmacro %}


{# ========== MACRO 2: List Filters - Select & Map ========== #}

{% macro filter_list_items(all_items, min_length=3) %}
{#
  Filters list based on conditions using select.
  
  Usage:
    {{ filter_list_items(
        all_items=['a', 'ab', 'abc', 'abcd'],
        min_length=3
    ) }}
  
  Output:
    abc, abcd (only items with 3+ chars)
#}
  {%- set filtered = all_items | select('match', '^.{' + min_length | string + ',}$') | list %}
  {%- for item in filtered %}
    {{ item }}
    {%- if not loop.last %}, {% endif %}
  {%- endfor %}
{% endmacro %}


{# ========== MACRO 3: Map Filter - Transform All Items ========== #}

{% macro uppercase_all_columns(columns) %}
{#
  Maps upper() filter to all items in list.
  
  Usage:
    {{ uppercase_all_columns(['name', 'email', 'phone']) }}
  
  Output:
    NAME, EMAIL, PHONE
#}
  {%- set upper_cols = columns | map('upper') | list %}
  {%- for col in upper_cols %}
    {{ col }}
    {%- if not loop.last %}, {% endif %}
  {%- endfor %}
{% endmacro %}


{# ========== MACRO 4: Join & Split Filters ========== #}

{% macro manipulate_list_strings(column_list, separator=', ') %}
{#
  Demonstrates join and split filters.
  
  Usage:
    {{ manipulate_list_strings(['col1', 'col2', 'col3'], separator=' | ') }}
  
  Output:
    col1 | col2 | col3
#}
  -- As CSV: {{ column_list | join(',') }}
  -- With separator: {{ column_list | join(separator) }}
  -- Reversed then joined: {{ column_list | reverse | join(' -> ') }}
{% endmacro %}


{# ========== MACRO 5: Unique & Sort Filters ========== #}

{% macro deduplicate_and_sort(items) %}
{#
  Removes duplicates and sorts list.
  
  Usage:
    {{ deduplicate_and_sort(['c', 'a', 'b', 'a', 'c']) }}
  
  Output:
    a, b, c
#}
  {%- set unique_sorted = items | unique | sort | list %}
  {%- for item in unique_sorted %}
    {{ item }}
    {%- if not loop.last %}, {% endif %}
  {%- endfor %}
{% endmacro %}


{# ========== MACRO 6: Filter Chaining - Multiple Filters ========== #}

{% macro chained_string_filters(raw_string) %}
{#
  Chains multiple filters together.
  
  Usage:
    {{ chained_string_filters('  hello world  ') }}
  
  Output: HELLOWORLD
#}
  -- Original: '{{ raw_string }}'
  -- Trimmed + Upper + Replace spaces: '{{ raw_string | trim | upper | replace(' ', '') }}'
  -- Lower + Trim + Escape: '{{ raw_string | lower | trim | regex_replace('[^a-z0-9]', '_') }}'
{% endmacro %}


{# ========== MACRO 7: Type Conversion Filters ========== #}

{% macro convert_data_types(string_number, string_bool) %}
{#
  Converts between data types.
  
  Usage:
    {{ convert_data_types(string_number='123', string_bool='true') }}
#}
  -- String to number: '{{ string_number }}' to {{ string_number | int }}
  -- String to bool: '{{ string_bool }}' to {{ string_bool | lower == 'true' }}
  -- Number to string: {{ 123 | string }}
  -- Float conversion: {{ '3.14' | float }}
{% endmacro %}


{# ========== MACRO 8: Default & Conditional Filters ========== #}

{% macro apply_defaults(nullable_value, default_value='UNKNOWN') %}
{#
  Uses default filter for null values.
  
  Usage:
    {{ apply_defaults(nullable_value=null, default_value='N/A') }}
  
  Output:
    N/A (since nullable_value is null)
#}
  {%- set value = nullable_value | default(default_value) %}
  Selected value: {{ value }}
{% endmacro %}


{# ========== MACRO 9: First & Last Filters ========== #}

{% macro extract_list_boundaries(items) %}
{#
  Gets first and last items.
  
  Usage:
    {{ extract_list_boundaries(['a', 'b', 'c', 'd']) }}
  
  Output:
    First: a, Last: d
#}
  -- First: {{ items | first }}
  -- Last: {{ items | last }}
  -- First 2: {{ items | first(2) | list }}
  -- Last 2: {{ items | last(2) | list }}
{% endmacro %}


{# ========== MACRO 10: Reject & Select Filters ========== #}

{% macro selective_list_operations(items, exclude_pattern='test') %}
{#
  Rejects items matching pattern.
  
  Usage:
    {{ selective_list_operations(
        items=['prod_table', 'test_table', 'prod_view'],
        exclude_pattern='test'
    ) }}
  
  Output:
    prod_table, prod_view
#}
  {%- set filtered = items | reject('match', '^' + exclude_pattern) | list %}
  {%- for item in filtered %}
    {{ item }}
    {%- if not loop.last %}, {% endif %}
  {%- endfor %}
{% endmacro %}


{# ========== MACRO 11: Groupby Filter ========== #}

{% macro group_columns_by_prefix(columns) %}
{#
  Groups items by shared prefix.
  
  Usage:
    {{ group_columns_by_prefix([
        'customer_id', 'customer_name', 'product_id', 'product_name'
    ]) }}
#}
  {%- set grouped = {} %}
  {%- for col in columns %}
    {%- set prefix = col.split('_')[0] %}
    {%- if prefix not in grouped %}
      {%- set _ = grouped.update({prefix: []}) %}
    {%- endif %}
    {%- set _ = grouped[prefix].append(col) %}
  {%- endfor %}
  {%- for prefix, items in grouped.items() %}
    -- Group: {{ prefix }}
    {%- for item in items %}
      {{ item }}
      {%- if not loop.last %}, {% endif %}
    {%- endfor %}
  {%- endfor %}
{% endmacro %}


{# ========== MACRO 12: Dictsort Filter - Sort Dictionary ========== #}

{% macro sort_dict_by_values(input_dict) %}
{#
  Sorts dictionary by values or keys.
  
  Usage:
    {{ sort_dict_by_values({'z': 1, 'a': 5, 'm': 3}) }}
  
  Output:
    z: 1, m: 3, a: 5
#}
  {%- for key, value in input_dict | dictsort(by='value') %}
    {{ key }}: {{ value }}
    {%- if not loop.last %}, {% endif %}
  {%- endfor %}
{% endmacro %}
