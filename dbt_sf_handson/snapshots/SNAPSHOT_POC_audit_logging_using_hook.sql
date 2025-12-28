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
            "CALL SNAPSHOT_DEMO.snapshots_tables.insert_snapshot_audit_log(\
                'snapshot_start',\
                '{{ source('snapshot_demo', 'ord_status') }}',\
                '{{ this }}'\
            )"
        ],
        post_hook=[
            "CALL SNAPSHOT_DEMO.snapshots_tables.insert_snapshot_audit_log(\
                'snapshot_end',\
                '{{ source('snapshot_demo', 'ord_status') }}',\
                '{{ this }}'\
            )"
        ]
    )
    }}
    select * from {{ source('snapshot_demo', 'ord_status') }}
{% endsnapshot %}

