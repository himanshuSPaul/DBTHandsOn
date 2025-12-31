-- Macro to create audit log table if it doesn't exist
{% macro create_audit_log_table() %}
  {% set sql %}
    CREATE TABLE IF NOT EXISTS DBT_AUDIT_LOG (
      MODEL_NAME VARCHAR(255),
      EXECUTION_TIME TIMESTAMP_NTZ,
      STATUS VARCHAR(50),
      ROW_COUNT INT,
      BUILD_ID VARCHAR(255),
      CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
    )
  {% endset %}
  
  {% do run_query(sql) %}
{% endmacro %}

-- Macro to log model execution
{% macro log_model_audit(status) %}
  {% if execute %}
    {% set audit_query %}
      INSERT INTO DBT_AUDIT_LOG (MODEL_NAME, EXECUTION_TIME, STATUS, ROW_COUNT, BUILD_ID)
      SELECT 
        '{{ this.name }}',
        CURRENT_TIMESTAMP(),
        '{{ status }}',
        (SELECT COUNT(*) FROM {{ this }}),
        '{{ invocation_id }}'
    {% endset %}
    {% do run_query(audit_query) %}
  {% endif %}
{% endmacro %}

-- Macro to grant select permissions to roles
{% macro grant_select_on_model(roles) %}
  {% for role in roles %}
    {% set sql %}
      GRANT SELECT ON {{ this }} TO ROLE {{ role }}
    {% endset %}
    {% do run_query(sql) %}
  {% endfor %}
{% endmacro %}
