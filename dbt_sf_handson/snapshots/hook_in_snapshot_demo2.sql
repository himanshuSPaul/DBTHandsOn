{% snapshot emp_dept_snapshot_demo_4 %}
    {{
    config(
        target_database= "SNAPSHOT_DEMO",
        target_schema='snapshots_tables',
        alias = "emp_dept_snapshot_demo_4",
        unique_key='EMP_ID',
        strategy='timestamp',
        updated_at='LAST_UPDATE_ON',
        post_hook=[
                    "
                    CALL SNAPSHOT_DEMO.snapshots_tables.insert_snapshot_audit_log( 'snapshot_end',
                        '{{ source('snapshot_demo', 'emp_dept') }}' ,
                        '{{this}}'
                    );
                    "
                    ]
        )
    }}
    select * from {{ source('snapshot_demo', 'emp_dept') }}
{% endsnapshot %}

