{% snapshot order_status_snapshot_ts_strategy_sql_hd_invalidate %}
    {{
    config(
        target_database= "SNAPSHOT_DEMO",
        target_schema='snapshots_tables',
        alias = "order_status_snapshot_ts_strategy_sql_hd_invalidate",
        unique_key='ORD_ID',
        strategy='timestamp',
        updated_at='ORD_STATUS_UPDATE_TS',
        hard_deletes='invalidate'
         )
    }}
    select * from {{ source('snapshot_demo', 'ord_status') }}
{% endsnapshot %}