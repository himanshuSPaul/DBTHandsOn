{% snapshot emp_dept_snapshot_demo_3 %}
    {{
    config(
        target_database= "SNAPSHOT_DEMO",
        target_schema='snapshots_tables',
        alias = "emp_dept_snapshot_demo_3",
        unique_key='EMP_ID',
        strategy='timestamp',
        updated_at='LAST_UPDATE_ON',
        pre_hook=[
                "INSERT INTO SNAPSHOT_DEMO.snapshots_tables.snapshot_audit_log (SNAPSHOT_NAME, EVENT,EVENT_TIME)
                VALUES ('emp_dept_snapshot_demo_3','SNAPSHOT START', CURRENT_TIMESTAMP);"
                ],
        post_hook=[
                    "INSERT INTO SNAPSHOT_DEMO.snapshots_tables.snapshot_audit_log (SNAPSHOT_NAME, EVENT,EVENT_TIME)
                    VALUES ('emp_dept_snapshot_demo_3','SNAPSHOT END', CURRENT_TIMESTAMP);"
                ]
        )
    }}
    select * from {{ source('snapshot_demo', 'emp_dept') }}
{% endsnapshot %}

