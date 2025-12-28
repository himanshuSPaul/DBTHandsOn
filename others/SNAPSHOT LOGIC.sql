create or replace temporary table "SNAPSHOT_DEMO"."SNAPSHOTS_TABLES"."ORDER_STATUS_SNAPSHOT__dbt_tmp"
as (
    with snapshot_query as (
        select * from SNAPSHOT_DEMO.PUBLIC.order_status
    ),

    snapshotted_data as (
        select *, 
        ORD_ID as dbt_unique_key
        from "SNAPSHOT_DEMO"."SNAPSHOTS_TABLES"."ORDER_STATUS_SNAPSHOT"
        where dbt_valid_to is null
        ),

    insertions_source_data as (
        select  *, 
                ORD_ID as dbt_unique_key,
                ORD_STATUS_UPDATE_TS as dbt_updated_at,
                ORD_STATUS_UPDATE_TS as dbt_valid_from,
                coalesce(nullif(ORD_STATUS_UPDATE_TS, ORD_STATUS_UPDATE_TS), null) as dbt_valid_to,
                md5(coalesce(cast(ORD_ID as varchar ), '') || '|' || coalesce(cast(ORD_STATUS_UPDATE_TS as varchar ), '') ) as dbt_scd_id
        from snapshot_query
        ),

    updates_source_data as (
        select  *, 
                ORD_ID as dbt_unique_key,
				ORD_STATUS_UPDATE_TS as dbt_updated_at,
				ORD_STATUS_UPDATE_TS as dbt_valid_from,
				ORD_STATUS_UPDATE_TS as dbt_valid_to
        from snapshot_query
    ),

    deletes_source_data as (
        select  *, 
				ORD_ID as dbt_unique_key
        from snapshot_query
    ),
    
    insertions as (
				select  'insert' as dbt_change_type,
						source_data.*
				from insertions_source_data as source_data
				left outer join snapshotted_data on 
				snapshotted_data.dbt_unique_key = source_data.dbt_unique_key
				where  snapshotted_data.dbt_unique_key is null 
				   or ( snapshotted_data.dbt_unique_key is not null 
						and snapshotted_data.dbt_valid_from < source_data.ORD_STATUS_UPDATE_TS
					  )
                 ),

    updates as  (
				select  'update' as dbt_change_type,
						source_data.*,
						snapshotted_data.dbt_scd_id
				from updates_source_data as source_data
				join snapshotted_data on 
				snapshotted_data.dbt_unique_key = source_data.dbt_unique_key
				where (snapshotted_data.dbt_valid_from < source_data.ORD_STATUS_UPDATE_TS)
				) ,
				
    deletes as (
				select 'delete' as dbt_change_type,
						source_data.*,
						to_timestamp_ntz(convert_timezone('UTC', current_timestamp())) as dbt_valid_from,
						to_timestamp_ntz(convert_timezone('UTC', current_timestamp())) as dbt_updated_at,
						to_timestamp_ntz(convert_timezone('UTC', current_timestamp())) as dbt_valid_to,
						snapshotted_data.dbt_scd_id
				from snapshotted_data
				left join deletes_source_data as source_data on 
				snapshotted_data.dbt_unique_key = source_data.dbt_unique_key
				where source_data.dbt_unique_key is null
				)

    select * from insertions
    union all
    select * from updates
    union all
    select * from deletes

    )
;