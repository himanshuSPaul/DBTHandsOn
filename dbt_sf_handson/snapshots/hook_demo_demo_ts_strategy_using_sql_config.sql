{% snapshot hook_in_snapshot_demo_sql %}
    {{
    config(
        target_database= "SNAPSHOT_DEMO",
        target_schema='snapshots_tables',
        alias = "hook_in_snapshot_demo_sql",
        unique_key='ORD_ID',
        strategy='timestamp',
        updated_at='ORD_STATUS_UPDATE_TS',
        pre_hook=[
            "insert into SNAPSHOT_DEMO.snapshots_tables.snapshot_audit_log  
            select 'order_status_snapshot_sql', 'snapshot_start', current_timestamp(), count(*) from {{ this }}",
        ],
        post_hook=[
            "insert into SNAPSHOT_DEMO.snapshots_tables.snapshot_audit_log  
            select 'order_status_snapshot_sql', 'snapshot_end', current_timestamp(), count(*) from {{ this }}"
        ]
    )
    }}
    select * from {{ source('snapshot_demo', 'ord_status') }}
{% endsnapshot %}