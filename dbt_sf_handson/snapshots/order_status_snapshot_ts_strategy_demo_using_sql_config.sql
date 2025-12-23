{% snapshot order_status_snapshot_sql %}
    {{
    config(
        target_database= "SNAPSHOT_DEMO",
        target_schema='snapshots_tables',
        alias = "order_status_snapshot_ts_strategy_demo_sql",
        unique_key='ORD_ID',
        strategy='timestamp',
        updated_at='ORD_STATUS_UPDATE_TS'
         )
    }}
    select * from {{ source('snapshot_demo', 'ord_status') }}
{% endsnapshot %}