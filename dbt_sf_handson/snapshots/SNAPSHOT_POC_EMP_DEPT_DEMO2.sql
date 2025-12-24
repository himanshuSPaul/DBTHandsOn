{% snapshot emp_dept_snapshot_demo_2 %}
    {{
    config(
        target_database= "SNAPSHOT_DEMO",
        target_schema='snapshots_tables',
        alias = "emp_dept_snapshot_demo_2",
        unique_key='EMP_ID',
        strategy='timestamp',
        updated_at='LAST_UPDATE_ON'

    )
    }}
    select * from {{ source('snapshot_demo', 'emp_dept') }}
{% endsnapshot %}

