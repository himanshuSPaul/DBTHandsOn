{% snapshot order_status_snapshot_ts_strategy_sql_hd_ignore %}
    {{
    config(
        target_database= "SNAPSHOT_DEMO",
        target_schema='snapshots_tables',
        alias = "order_status_snapshot_ts_strategy_sql_hd_ignore",
        unique_key='ORD_ID',
        strategy='timestamp',
        updated_at='ORD_STATUS_UPDATE_TS',
        hard_deletes='ignore'
        )
    }}
    select * from {{ source('snapshot_demo', 'ord_status') }}
{% endsnapshot %}