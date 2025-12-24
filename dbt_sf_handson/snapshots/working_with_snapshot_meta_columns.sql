{% snapshot snapshot_metacolumns_demo_sql %}
    {{
    config(
        target_database= "SNAPSHOT_DEMO",
        target_schema='snapshots_tables',
        alias = "snapshot_meta_columns_demo_sql",
        unique_key='EMP_ID',
        strategy='timestamp',
        updated_at='LAST_UPDATE_ON',
        snapshot_meta_column_names={
                                    "dbt_valid_from": "row_valid_from",
                                    "dbt_valid_to": "row_valid_till",
                                    "dbt_scd_id": "row_scd_id",
                                    "dbt_updated_at": "row_last_updated_at",
                                    "dbt_is_deleted": "row_is_deleted",
                                }

        )
    }}
    select * from {{ source('snapshot_demo', 'emp_dept') }}
{% endsnapshot %}
