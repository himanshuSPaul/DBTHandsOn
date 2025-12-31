{# ============================================================================
   EXPOSURE FRESHNESS MONITORING SYSTEM
   ============================================================================
   Purpose: Monitor data freshness for BI exposures and alert on staleness
   
   Features:
   - Freshness threshold definitions per exposure
   - Last update time tracking
   - Staleness detection
   - Alert generation
   - Dependency freshness cascading
   
   This system enables:
   1. Automatic freshness monitoring of upstream models
   2. Exposure-level SLA definitions
   3. Alert generation for stale data
   4. Dependency chain analysis
   ============================================================================ #}

{# ============================================================================
   MACRO: Get exposure freshness metadata
   Returns freshness requirements for all exposures
   ============================================================================ #}
{% macro get_exposure_freshness_metadata() %}
  {%- set exposures_freshness = [
    {
      'exposure_name': 'executive_dashboard',
      'exposure_type': 'dashboard',
      'freshness_threshold_hours': 1,
      'critical_freshness': true,
      'owner': 'Executive Sponsor',
      'owner_email': 'executive@company.com',
      'sla_window': '23:00-06:00 UTC',
      'dependencies': ['mart_customers', 'mart_orders', 'mart_products'],
      'alert_channel': 'slack:#critical-alerts',
      'description': 'Executive dashboard - must be fresh for hourly decisions'
    },
    {
      'exposure_name': 'sales_performance_dashboard',
      'exposure_type': 'dashboard',
      'freshness_threshold_hours': 0.5,
      'critical_freshness': true,
      'owner': 'Sales Operations Manager',
      'owner_email': 'sales-ops@company.com',
      'sla_window': '08:00-22:00 UTC',
      'dependencies': ['mart_orders', 'int_orders_items_joined'],
      'alert_channel': 'slack:#sales-alerts',
      'description': 'Sales dashboard - 30-minute refresh SLA'
    },
    {
      'exposure_name': 'customer_analytics_dashboard',
      'exposure_type': 'dashboard',
      'freshness_threshold_hours': 24,
      'critical_freshness': true,
      'owner': 'Customer Analytics Lead',
      'owner_email': 'cust-analytics@company.com',
      'sla_window': '06:00-08:00 UTC',
      'dependencies': ['mart_customers', 'mart_orders'],
      'alert_channel': 'slack:#analytics-alerts',
      'description': 'Customer dashboard - daily refresh SLA'
    }
  ] -%}
  {{ return(exposures_freshness) }}
{% endmacro %}

{# ============================================================================
   MACRO: Check exposure freshness status
   Determines if exposure data is fresh
   ============================================================================ #}
{% macro check_exposure_freshness(
    exposure_name = '',
    freshness_threshold_hours = 24
) %}
  {%- if execute -%}
    {{ log('Checking freshness for exposure: ' ~ exposure_name ~ ' (threshold: ' ~ freshness_threshold_hours ~ 'h)', info=true) }}
  {%- endif -%}
  
  {%- set exposures = get_exposure_freshness_metadata() -%}
  {%- set matching = exposures | selectattr('exposure_name', 'equalto', exposure_name) | list -%}
  
  {%- if matching | length > 0 -%}
    {%- set exposure = matching[0] -%}
    {%- set threshold = exposure.freshness_threshold_hours -%}
    
    FRESHNESS CHECK: {{ exposure_name }}
    Threshold: {{ threshold }} hours
    Status: {% if threshold <= 1 %}🔴 CRITICAL{% elif threshold <= 6 %}🟠 HIGH{% else %}🟡 STANDARD{% endif %}
    Owner: {{ exposure.owner }} ({{ exposure.owner_email }})
  {%- else -%}
    {{ log('WARNING: Exposure "' ~ exposure_name ~ '" not found in metadata', info=true) }}
  {%- endif -%}
{% endmacro %}

{# ============================================================================
   MACRO: Get exposure freshness status for all
   Returns freshness status matrix for all exposures
   ============================================================================ #}
{% macro get_all_exposures_freshness_status() %}
  {%- set exposures = get_exposure_freshness_metadata() -%}
  {%- set status_matrix = [] -%}
  
  {%- for exposure in exposures -%}
    {%- set status = {
      'exposure': exposure.exposure_name,
      'threshold_hours': exposure.freshness_threshold_hours,
      'criticality': 'CRITICAL' if exposure.critical_freshness else 'STANDARD',
      'owner': exposure.owner,
      'sla_window': exposure.sla_window,
      'dependencies_count': exposure.dependencies | length
    } -%}
    {%- set _ = status_matrix.append(status) -%}
  {%- endfor -%}
  
  {{ return(status_matrix) }}
{% endmacro %}

{# ============================================================================
   MACRO: List exposures by criticality
   Groups exposures by freshness criticality
   ============================================================================ #}
{% macro list_exposures_by_criticality() %}
  {%- set exposures = get_exposure_freshness_metadata() -%}
  {%- set critical = exposures | selectattr('critical_freshness', 'equalto', true) | list -%}
  {%- set standard = exposures | selectattr('critical_freshness', 'equalto', false) | list -%}
  
  {{ log('
╔════════════════════════════════════════════════════════════════╗
║          EXPOSURE FRESHNESS CRITICALITY BREAKDOWN              ║
╚════════════════════════════════════════════════════════════════╝

CRITICAL EXPOSURES (' ~ critical | length ~ '):
' ~ critical | map(attribute='exposure_name') | map('indent', '  🔴 ') | join('') ~ '

STANDARD EXPOSURES (' ~ standard | length ~ '):
' ~ standard | map(attribute='exposure_name') | map('indent', '  🟡 ') | join(''), info=true) }}
  
  {{ return({'critical': critical | length, 'standard': standard | length}) }}
{% endmacro %}

{# ============================================================================
   MACRO: Get exposure dependencies
   Returns upstream model dependencies for exposure
   ============================================================================ #}
{% macro get_exposure_dependencies(exposure_name) %}
  {%- set exposures = get_exposure_freshness_metadata() -%}
  {%- set matching = exposures | selectattr('exposure_name', 'equalto', exposure_name) | list -%}
  
  {%- if matching | length > 0 -%}
    {{ return(matching[0].dependencies) }}
  {%- else -%}
    {{ return([]) }}
  {%- endif -%}
{% endmacro %}

{# ============================================================================
   MACRO: Log exposure freshness details
   Displays comprehensive freshness information for exposure
   ============================================================================ #}
{% macro log_exposure_freshness_details(exposure_name) %}
  {%- set exposures = get_exposure_freshness_metadata() -%}
  {%- set matching = exposures | selectattr('exposure_name', 'equalto', exposure_name) | list -%}
  
  {%- if matching | length > 0 -%}
    {%- set exp = matching[0] -%}
    {{ log('
╔════════════════════════════════════════════════════════════════╗
║          EXPOSURE FRESHNESS DETAILS: ' ~ exp.exposure_name | upper ~ '
╚════════════════════════════════════════════════════════════════╝

Type:           ' ~ exp.exposure_type ~ '
Description:    ' ~ exp.description ~ '

FRESHNESS SLA:
  Threshold:    ' ~ exp.freshness_threshold_hours ~ ' hours
  Criticality:  ' ~ ('🔴 CRITICAL' if exp.critical_freshness else '🟡 STANDARD') ~ '
  SLA Window:   ' ~ exp.sla_window ~ '

OWNERSHIP:
  Owner:        ' ~ exp.owner ~ '
  Email:        ' ~ exp.owner_email ~ '
  Alert To:     ' ~ exp.alert_channel ~ '

UPSTREAM DEPENDENCIES (' ~ exp.dependencies | length ~ '):
' ~ exp.dependencies | map('indent', '  • ') | join('') ~ '

FRESHNESS REQUIREMENTS:
  - Check data recency every 15 minutes for critical exposures
  - Generate alerts if older than threshold
  - Daily summary reports
  - Escalate unresolved alerts after 30 minutes', info=true) }}
  {%- else -%}
    {{ log('ERROR: Exposure "' ~ exposure_name ~ '" not found', info=true) }}
  {%- endif -%}
{% endmacro %}

{# ============================================================================
   MACRO: Generate exposure freshness alert
   Creates alert payload for stale exposure data
   ============================================================================ #}
{% macro generate_exposure_freshness_alert(
    exposure_name = '',
    last_update_time = '',
    hours_stale = 0
) %}
  {%- set exposures = get_exposure_freshness_metadata() -%}
  {%- set matching = exposures | selectattr('exposure_name', 'equalto', exposure_name) | list -%}
  
  {%- if matching | length > 0 -%}
    {%- set exp = matching[0] -%}
    {%- set severity = 'CRITICAL' if hours_stale > exp.freshness_threshold_hours * 2 else 'WARNING' -%}
    
    {{ log('
╔════════════════════════════════════════════════════════════════╗
║          EXPOSURE FRESHNESS ALERT - ' ~ severity ~ '
╚════════════════════════════════════════════════════════════════╝

Exposure:       ' ~ exposure_name ~ '
Severity:       ' ~ severity ~ '
Current Time:   ' ~ now() ~ '
Last Update:    ' ~ last_update_time ~ '
Hours Stale:    ' ~ hours_stale ~ ' (threshold: ' ~ exp.freshness_threshold_hours ~ ')

Owner:          ' ~ exp.owner ~ ' (' ~ exp.owner_email ~ ')
Alert Channel:  ' ~ exp.alert_channel ~ '

REQUIRED ACTION:
  Investigate upstream data pipeline
  Check logs for model failures
  Verify Snowflake connection
  Monitor data warehouse load times
  
ESCALATION:
  If unresolved > 30 min: Escalate to ' ~ exp.owner ~ '
  If unresolved > 60 min: Escalate to Data Engineering Lead
  If unresolved > 120 min: Page on-call engineer', info=true) }}
  {%- else -%}
    {{ log('ERROR: Exposure "' ~ exposure_name ~ '" not found', info=true) }}
  {%- endif -%}
{% endmacro %}

{# ============================================================================
   MACRO: Get freshness SLA summary
   Returns summary table of all exposure freshness SLAs
   ============================================================================ #}
{% macro get_freshness_sla_summary() %}
  {%- set exposures = get_exposure_freshness_metadata() -%}
  {%- set summary = [] -%}
  
  {%- for exp in exposures -%}
    {%- set sla = {
      'exposure': exp.exposure_name,
      'threshold_hours': exp.freshness_threshold_hours,
      'criticality': '🔴 CRITICAL' if exp.critical_freshness else '🟡 STANDARD',
      'owner_email': exp.owner_email,
      'dependencies': exp.dependencies | join(', ')
    } -%}
    {%- set _ = summary.append(sla) -%}
  {%- endfor -%}
  
  {{ return(summary) }}
{% endmacro %}
