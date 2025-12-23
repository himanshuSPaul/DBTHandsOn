{% snapshot product_version_snapshot_check_strategy_sql %}
    {{
    config(
        target_database= "SNAPSHOT_DEMO",
        target_schema="snapshots_tables",
        alias = "product_version_snapshot_check_strategy_sql",
        unique_key='PRD_ID',
        strategy='check',
        check_cols=['prd_version','prd_price']
         )
    }}
    select * from {{ source('snapshot_demo', 'prd_version') }}
{% endsnapshot %}
