
CREATE OR REPLACE PROCEDURE SNAPSHOT_DEMO.snapshots_tables.insert_snapshot_audit_log(
    event_type STRING,
    source_table_fq STRING,
    snapshot_table_fq STRING
)
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
// Helper to parse fully qualified table name into db, schema, table
function parse_fq_table(fq_table) {
    var parts = fq_table.split('.');
    if (parts.length !== 3) {
        throw `Invalid table reference: ${fq_table}`;
    }
    return {db: parts[0], schema: parts[1], table: parts[2]};
}

function get_row_count(fq_table) {
    var t = parse_fq_table(fq_table);
    var sql_check = `SELECT COUNT(*) AS count
                     FROM ${t.db}.INFORMATION_SCHEMA.TABLES
                     WHERE TABLE_SCHEMA = '${t.schema}'
                       AND TABLE_NAME = UPPER('${t.table}')`;
    var stmt_check = snowflake.createStatement({sqlText: sql_check});
    var result_check = stmt_check.execute();
    result_check.next();
    var exists = result_check.getColumnValue('COUNT') > 0;
    if (exists) {
        var sql_count = `SELECT COUNT(*) AS rc FROM ${t.db}.${t.schema}.${t.table}`;
        var stmt_count = snowflake.createStatement({sqlText: sql_count});
        var result_count = stmt_count.execute();
        result_count.next(); 
        return result_count.getColumnValue('RC');
    } else {
        return 0;
    }
}

var audit_log = 'SNAPSHOT_DEMO.snapshots_tables.snapshot_audit_log';
var source_table = SOURCE_TABLE_FQ;
var snapshot_table = SNAPSHOT_TABLE_FQ; 
var source_count = get_row_count(source_table);
var snapshot_count = get_row_count(snapshot_table);

var sql_insert = `INSERT INTO ${audit_log}
                  SELECT 'order_status_snapshot_sql', '${EVENT_TYPE}', CURRENT_TIMESTAMP(), ${source_count}, ${snapshot_count}`;
var stmt_insert = snowflake.createStatement({sqlText: sql_insert});
stmt_insert.execute();

return 'Audit log inserted with source_count: ' + source_count + ', snapshot_count: ' + snapshot_count;
$$;