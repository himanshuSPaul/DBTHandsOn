{# ============================================================================
   GENERIC TEST NAMESPACE REGISTRY
   ============================================================================
   Purpose: Centralized registry and management of custom test namespaces
   
   This macro provides:
   - Test namespace definitions and organization
   - Metadata about available test namespaces
   - Namespace discovery capabilities
   - Documentation linkage
   
   Namespace Organization:
   - data_quality: Basic data validation (null, type, format)
   - referential: Cross-table relationships (foreign keys, references)
   - business_logic: Domain-specific business rules (ratios, conditions)
   - temporal: Time-series and date-based validation
   
   Usage Pattern:
   - Import namespaced tests: `{{ ref.test_namespace.test_name }}`
   - Call with namespace: `- custom.data_quality.test_name`
   - Query registry: `SELECT * FROM namespace_registry`
   ============================================================================ #}

{# ============================================================================
   MACRO: Get namespace metadata
   Returns detailed information about all available test namespaces
   ============================================================================ #}
{% macro get_test_namespace_metadata() %}
  {%- set namespaces = [
    {
      'namespace': 'data_quality',
      'description': 'Basic data validation and format checks',
      'tests': [
        'test_non_negative',
        'test_not_empty',
        'test_value_between',
        'test_max_value',
        'test_min_value',
        'test_not_future_date',
        'test_positive_values',
        'test_accepted_values'
      ],
      'file_location': 'macros/tests/custom_generic_tests.sql',
      'use_cases': [
        'Validate numeric ranges (non-negative, positive)',
        'Ensure required fields are populated',
        'Check value boundaries and limits',
        'Temporal validation (no future dates)',
        'Enumeration validation (allowed values)'
      ],
      'query_example': 'SELECT customer_id FROM stg_customers WHERE age < 0'
    },
    {
      'namespace': 'referential',
      'description': 'Cross-table relationships and foreign key validation',
      'tests': [
        'test_advanced_referential_integrity',
        'test_advanced_cardinality'
      ],
      'file_location': 'macros/tests/advanced_yaml_tests.sql',
      'use_cases': [
        'Validate foreign key relationships across tables',
        'Ensure reference tables have expected cardinality',
        'Check dimension table completeness',
        'Validate join key existence'
      ],
      'query_example': 'SELECT * FROM stg_items WHERE item_order_id NOT IN (SELECT order_id FROM stg_orders)'
    },
    {
      'namespace': 'business_logic',
      'description': 'Domain-specific business rule validation',
      'tests': [
        'test_advanced_ratio_constraint',
        'test_advanced_covariance',
        'test_advanced_conditional_uniqueness'
      ],
      'file_location': 'macros/tests/advanced_yaml_tests.sql',
      'use_cases': [
        'Validate column ratios (discount ≤ 20% of total)',
        'Check multi-column business rules (IF priority=HIGH THEN method=EXPEDITED)',
        'Enforce conditional uniqueness (active customers unique by email)',
        'Validate calculated fields and derived logic'
      ],
      'query_example': 'SELECT * FROM stg_orders WHERE order_tax_paid > order_subtotal * 0.20'
    },
    {
      'namespace': 'temporal',
      'description': 'Time-series and data recency validation',
      'tests': [
        'test_advanced_freshness_window',
        'test_advanced_time_gap',
        'test_advanced_regex_match'
      ],
      'file_location': 'macros/tests/advanced_yaml_tests.sql',
      'use_cases': [
        'Validate data freshness (last 24 hours must have N rows)',
        'Check time continuity (no gaps > 30 days)',
        'Pattern validation (email format, phone numbers)',
        'Recency thresholds and staleness detection'
      ],
      'query_example': 'SELECT * FROM stg_orders WHERE order_date < CURRENT_DATE - 30 AND next_order_date IS NULL'
    }
  ] -%}
  {{ return(namespaces) }}
{% endmacro %}

{# ============================================================================
   MACRO: Check if test exists in namespace
   ============================================================================ #}
{% macro test_exists_in_namespace(namespace_name, test_name) %}
  {%- set namespaces = get_test_namespace_metadata() -%}
  {%- set matching_ns = namespaces | selectattr('namespace', 'equalto', namespace_name) | list -%}
  
  {%- if matching_ns | length == 0 -%}
    {{ log('ERROR: Namespace "' ~ namespace_name ~ '" not found', info=true) }}
    {{ return(false) }}
  {%- else -%}
    {%- set ns = matching_ns[0] -%}
    {%- if test_name in ns.tests -%}
      {{ return(true) }}
    {%- else -%}
      {{ log('WARNING: Test "' ~ test_name ~ '" not found in namespace "' ~ namespace_name ~ '"', info=true) }}
      {{ return(false) }}
    {%- endif -%}
  {%- endif -%}
{% endmacro %}

{# ============================================================================
   MACRO: Get all tests in a namespace
   ============================================================================ #}
{% macro get_tests_in_namespace(namespace_name) %}
  {%- set namespaces = get_test_namespace_metadata() -%}
  {%- set matching_ns = namespaces | selectattr('namespace', 'equalto', namespace_name) | list -%}
  
  {%- if matching_ns | length > 0 -%}
    {{ return(matching_ns[0].tests) }}
  {%- else -%}
    {{ return([]) }}
  {%- endif -%}
{% endmacro %}

{# ============================================================================
   MACRO: List all available namespaces
   ============================================================================ #}
{% macro list_available_namespaces() %}
  {%- set namespaces = get_test_namespace_metadata() -%}
  
  {{ log('
╔════════════════════════════════════════════════════════════════╗
║          AVAILABLE TEST NAMESPACES                             ║
╚════════════════════════════════════════════════════════════════╝

' ~ namespaces | map(attribute='namespace') | join(', ') ~ '

Use: dbt test --select "test_namespace:data_quality"', info=true) }}
  
  {{ return(namespaces | map(attribute='namespace') | list) }}
{% endmacro %}

{# ============================================================================
   MACRO: Get namespace statistics
   Returns count of tests per namespace
   ============================================================================ #}
{% macro get_namespace_statistics() %}
  {%- set namespaces = get_test_namespace_metadata() -%}
  {%- set stats = [] -%}
  
  {%- for ns in namespaces -%}
    {%- set stat = {
      'namespace': ns.namespace,
      'test_count': ns.tests | length,
      'description': ns.description
    } -%}
    {%- set _ = stats.append(stat) -%}
  {%- endfor -%}
  
  {{ return(stats) }}
{% endmacro %}

{# ============================================================================
   MACRO: Log namespace details
   Displays comprehensive information about a specific namespace
   ============================================================================ #}
{% macro log_namespace_details(namespace_name) %}
  {%- set namespaces = get_test_namespace_metadata() -%}
  {%- set matching_ns = namespaces | selectattr('namespace', 'equalto', namespace_name) | list -%}
  
  {%- if matching_ns | length > 0 -%}
    {%- set ns = matching_ns[0] -%}
    {{ log('
╔════════════════════════════════════════════════════════════════╗
║          NAMESPACE DETAILS: ' ~ ns.namespace | upper ~ '
╚════════════════════════════════════════════════════════════════╝

Description:  ' ~ ns.description ~ '
File:         ' ~ ns.file_location ~ '
Test Count:   ' ~ ns.tests | length ~ '

Tests:
' ~ ns.tests | map('indent', '  - ') | join('') ~ '

Use Cases:
' ~ ns.use_cases | map('indent', '  • ') | join('') ~ '

Example Query:
' ~ ns.query_example, info=true) }}
  {%- else -%}
    {{ log('ERROR: Namespace "' ~ namespace_name ~ '" not found', info=true) }}
  {%- endif -%}
{% endmacro %}
