
# Snapshot Audit Logging POC Documentation

This folder contains a proof-of-concept (POC) for implementing audit logging for dbt snapshots in Snowflake. Two main approaches are demonstrated:

## 1. Audit Logging Using dbt Hooks

File: `SNAPSHOT_POC_audit_logging_using_hook.sql`

This approach uses dbt's `pre_hook` and `post_hook` configuration to insert audit log records before and after the snapshot operation. The hooks insert a row into the audit log table with the event type, timestamp, and row count from the snapshot table.

**Example snippet:**

```jinja
pre_hook=[
	"insert into SNAPSHOT_DEMO.snapshots_tables.snapshot_audit_log  \
	 select 'order_status_snapshot_sql', 'snapshot_start', current_timestamp(), count(*) from {{ this }}"
],
post_hook=[
	"insert into SNAPSHOT_DEMO.snapshots_tables.snapshot_audit_log  \
	 select 'order_status_snapshot_sql', 'snapshot_end', current_timestamp(), count(*) from {{ this }}"
]
```

**How it works:**
- `{{ this }}` refers to the current snapshot table.
- The hooks log the event type ('snapshot_start' or 'snapshot_end'), the current timestamp, and the row count in the snapshot table at each event.
- This approach is simple but only logs the snapshot table row count, and will error if the table does not exist on the first run.

## 2. Audit Logging Using a Snowflake Stored Procedure

File: `SNAPSHOT_POC_audit_logging_proc.sql`

This approach uses a dynamic and reusable Snowflake stored procedure to log audit information for both the source and snapshot tables. The procedure can be called from dbt hooks or manually.

**Procedure signature:**

```sql
CALL SNAPSHOT_DEMO.snapshots_tables.insert_snapshot_audit_log(
	event_type STRING,                -- e.g., 'snapshot_start' or 'snapshot_end'
	source_table_fq STRING,           -- fully qualified source table name (e.g., SNAPSHOT_DEMO.SRC_SCHEMA.SRC_TABLE)
	snapshot_table_fq STRING          -- fully qualified snapshot table name (e.g., SNAPSHOT_DEMO.SNAPSHOTS_TABLES.SNAPSHOT_TABLE)
);
```

**Key features:**
- Accepts fully qualified table names for both source and snapshot tables.
- Dynamically parses the table names to extract database, schema, and table.
- Checks if each table exists before counting rows (returns 0 if not found).
- Inserts an audit log row with event type, timestamp, source row count, and snapshot row count.

**Example dbt hook usage:**

```jinja
pre_hook=[
	"CALL SNAPSHOT_DEMO.snapshots_tables.insert_snapshot_audit_log(\
			'snapshot_start',\
			'{{ source('source_schema', 'source_table') }}',\
			'{{ this }}'\
	)"
]
```

**Benefits:**
- More robust and flexible than the direct SQL hook approach.
- Handles missing tables gracefully.
- Can be reused for any snapshot or table combination.

---

For more details, see the respective SQL files in this folder.
