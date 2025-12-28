# Jaffle Shop Data Import to Snowflake

This directory contains Python scripts for importing Jaffle Shop data into Snowflake. There are two main scripts:

1. **import_snowflake_table.py** - Import a single data folder (DDL + CSV)
2. **incremental_loader.py** - Orchestrate loading of multiple daily data folders sequentially

Both scripts include automatic audit logging to track all load operations.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Configuration](#configuration)
3. [import_snowflake_table.py](#import_snowflake_tablepy)
   - [Options](#options)
   - [Examples](#examples)
4. [incremental_loader.py](#incremental_loaderpy)
   - [Options](#options-1)
   - [Examples](#examples-1)
5. [Data Folder Structure](#data-folder-structure)
6. [Audit Logging](#audit-logging)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Python Environment
- Python 3.7 or higher
- Virtual environment activated (recommended)

### Required Packages
```bash
pip install snowflake-connector-python pandas
```

### Snowflake Account
- Active Snowflake account with credentials
- Access to create/modify tables and schemas

### Configuration File
Create or update `config.ini` with your Snowflake credentials:

```ini
[snowflake]
account = your_account_id
user = your_username
password = your_password
warehouse = your_warehouse
database = JAFFELSHOP_ECOM
schema = RAW
role = your_role
```

---

## Configuration

### config.ini Example

```ini
[snowflake]
account = xdyidpl-ui11981
user = dbt_user
password = your_secure_password
warehouse = COMPUTE_WH
database = JAFFELSHOP_ECOM
schema = RAW
role = ANALYST
```

**Note:** Store passwords securely. Consider using environment variables instead:
```bash
export SNOWFLAKE_PASSWORD=your_password
```

---

## import_snowflake_table.py

### Purpose
Import a single data folder containing DDL and CSV files into Snowflake. Supports both full replace and incremental append modes.

### Options

```
--config PATH              Path to config.ini file (default: ./config.ini)
--folder PATH              Folder containing exported table files (*.ddl.sql and *.csv.gzip)
                          REQUIRED
--database DB_NAME        Target Snowflake database (default from config.ini)
                          REQUIRED
--schema SCHEMA_NAME      Target Snowflake schema (default from config.ini)
                          REQUIRED
--replace-table           Drop and recreate table if it exists (default: append data)
                          OPTIONAL
```

### Examples

#### Example 1: Load RAW_PRODUCTS (Full Replace)

```bash
python import_snowflake_table.py \
  --config ./config.ini \
  --folder "./HistoryData/RAW_PRODUCTS/" \
  --database JAFFELSHOP_ECOM \
  --schema RAW \
  --replace-table
```

**Output:**
```
2025-12-28 15:30:45 INFO: Script execution started
2025-12-28 15:30:45 INFO: Load ID: IMPORT_20251228_153045_a1b2c3d4
2025-12-28 15:30:46 INFO: Found DDL file: ./HistoryData/RAW_PRODUCTS/DDL_RAW_PRODUCTS.sql
2025-12-28 15:30:46 INFO: Found data file: ./HistoryData/RAW_PRODUCTS/RAW_PRODUCTS.csv.gzip
2025-12-28 15:30:47 INFO: Table RAW_PRODUCTS dropped
2025-12-28 15:30:48 INFO: Table RAW_PRODUCTS created from DDL
2025-12-28 15:30:49 INFO: Data loaded: 10 rows
2025-12-28 15:30:50 INFO: Audit log entry inserted with LOAD_ID: IMPORT_20251228_153045_a1b2c3d4
```

#### Example 2: Load RAW_CUSTOMERS (Incremental - Append)

```bash
python import_snowflake_table.py \
  --config ./config.ini \
  --folder "./HistoryData/RAW_CUSTOMERS/" \
  --database JAFFELSHOP_ECOM \
  --schema RAW
```

**Output:**
```
2025-12-28 15:35:12 INFO: Script execution started
2025-12-28 15:35:12 INFO: Load ID: IMPORT_20251228_153512_e5f6g7h8
2025-12-28 15:35:13 INFO: Found DDL file: ./HistoryData/RAW_CUSTOMERS/DDL_RAW_CUSTOMERS.sql
2025-12-28 15:35:13 INFO: Found data file: ./HistoryData/RAW_CUSTOMERS/RAW_CUSTOMERS.csv.gzip
2025-12-28 15:35:14 INFO: Table RAW_CUSTOMERS already exists (incremental load)
2025-12-28 15:35:15 INFO: Data loaded: 100 rows
2025-12-28 15:35:16 INFO: Audit log entry inserted with LOAD_ID: IMPORT_20251228_153512_e5f6g7h8
```

#### Example 3: Load from IncrementalData Folder

```bash
python import_snowflake_table.py \
  --config ./config.ini \
  --folder "./IncrementalData/RAW_DAILY_ORDERS/20220115/" \
  --database JAFFELSHOP_ECOM \
  --schema INCR_DATA_LOAD
```

#### Example 4: Minimal Command (Using Defaults from config.ini)

```bash
python import_snowflake_table.py \
  --folder "./HistoryData/RAW_STORES/"
```

---

## incremental_loader.py

### Purpose
Orchestrate loading of multiple daily data folders sequentially. Calls `import_snowflake_table.py` for each day and tracks all operations in a single audit entry.

### Options

```
--config PATH              Path to config.ini file (default: ./config.ini)
                          OPTIONAL
--database DB_NAME        Target Snowflake database
                          REQUIRED
--schema SCHEMA_NAME      Target Snowflake schema
                          REQUIRED
--type TABLE_TYPE         Table type to load: ORDERS or ITEMS
                          REQUIRED
--table TABLE_PATH        Path to parent data folder containing daily subfolders
                          Example: ./IncrementalData/RAW_DAILY_ORDERS
                          REQUIRED
--start-date YYYYMMDD     Start date (inclusive)
                          Format: YYYYMMDD (e.g., 20220101)
                          REQUIRED
--end-date YYYYMMDD       End date (inclusive)
                          Format: YYYYMMDD (e.g., 20220131)
                          REQUIRED
--validate                Run validation after load (optional)
                          OPTIONAL
```

### Examples

#### Example 1: Load 8 Days of ORDERS Data

```bash
python incremental_loader.py \
  --database JAFFELSHOP_ECOM \
  --schema INCR_DATA_LOAD \
  --type ORDERS \
  --table ./IncrementalData/RAW_DAILY_ORDERS \
  --start-date 20220101 \
  --end-date 20220108
```

**Output:**
```
[STARTING INCREMENTAL LOAD]
  Database:        JAFFELSHOP_ECOM
  Schema:          INCR_DATA_LOAD
  Table Type:      ORDERS
  Date Range:      20220101 - 20220108
  Total Days:      8

[LOADING DAY 1/8: 20220101]
  Files:  1
  Rows:   2,547

[LOADING DAY 2/8: 20220102]
  Files:  1
  Rows:   2,634

...

[LOAD SUMMARY]
  Load ID:         ORDERS_20251228_160145_x1y2z3a4
  Total days:      8
  Successful:      8
  Failed:          0
  Duration:        2.5 minutes
  Starting rows:   0
  Final rows:      20,816
  Rows loaded:     20,816
```

#### Example 2: Load 2 Days of ITEMS Data with Validation

```bash
python incremental_loader.py \
  --database JAFFELSHOP_ECOM \
  --schema INCR_DATA_LOAD \
  --type ITEMS \
  --table ./IncrementalData/RAW_DAILY_ITEMS \
  --start-date 20220115 \
  --end-date 20220116 \
  --validate
```

**Output:**
```
[STARTING INCREMENTAL LOAD]
  Database:        JAFFELSHOP_ECOM
  Schema:          INCR_DATA_LOAD
  Table Type:      ITEMS
  Date Range:      20220115 - 20220116
  Total Days:      2

[LOADING DAY 1/2: 20220115]
  Files:  1
  Rows:   1,234

[LOADING DAY 2/2: 20220116]
  Files:  1
  Rows:   1,456

[VALIDATION]
  Validating RAW_ITEMS in INCR_DATA_LOAD schema
  [OK] Table exists
  [OK] Row count: 2,690
  [OK] No NULL primary keys found

[LOAD SUMMARY]
  Load ID:         ITEMS_20251228_161530_p5q6r7s8
  Total days:      2
  Successful:      2
  Failed:          0
  Duration:        0.8 minutes
  Starting rows:   0
  Final rows:      2,690
  Rows loaded:     2,690
```

#### Example 3: Load One Week of ORDERS Data

```bash
python incremental_loader.py \
  --database JAFFELSHOP_ECOM \
  --schema INCR_DATA_LOAD \
  --type ORDERS \
  --table ./IncrementalData/RAW_DAILY_ORDERS \
  --start-date 20220101 \
  --end-date 20220107
```

#### Example 4: Load Full Month (Using Different Config)

```bash
python incremental_loader.py \
  --config ./config_prod.ini \
  --database JAFFELSHOP_ECOM \
  --schema INCR_DATA_LOAD \
  --type ORDERS \
  --table ./IncrementalData/RAW_DAILY_ORDERS \
  --start-date 20220101 \
  --end-date 20220131 \
  --validate
```

---

## Data Folder Structure

### HistoryData (Full Historical Load)

Used with `import_snowflake_table.py` for initial data load. Each table has its own folder:

```
HistoryData/
├── RAW_CUSTOMERS/
│   ├── DDL_RAW_CUSTOMERS.sql
│   └── RAW_CUSTOMERS.csv.gzip
├── RAW_ORDERS/
│   ├── DDL_RAW_ORDERS.sql
│   └── RAW_ORDERS.csv.gzip
├── RAW_ITEMS/
│   ├── DDL_RAW_ITEMS.sql
│   └── RAW_ITEMS.csv.gzip
├── RAW_PRODUCTS/
│   ├── DDL_RAW_PRODUCTS.sql
│   └── RAW_PRODUCTS.csv.gzip
├── RAW_STORES/
│   ├── DDL_RAW_STORES.sql
│   └── RAW_STORES.csv.gzip
├── RAW_SUPPLIES/
│   ├── DDL_RAW_SUPPLIES.sql
│   └── RAW_SUPPLIES.csv.gzip
└── RAW_TWEETS/
    ├── DDL_RAW_TWEETS.sql
    └── RAW_TWEETS.csv.gzip
```

### IncrementalData (Daily Incremental Load)

Used with `incremental_loader.py` for daily data loads. Organized by table type and date:

```
IncrementalData/
├── RAW_DAILY_ORDERS/
│   ├── 20220101/
│   │   ├── DDL_RAW_ORDERS.sql
│   │   └── RAW_ORDERS.csv.gzip
│   ├── 20220102/
│   │   ├── DDL_RAW_ORDERS.sql
│   │   └── RAW_ORDERS.csv.gzip
│   ├── 20220103/
│   │   └── (same structure)
│   └── ...
└── RAW_DAILY_ITEMS/
    ├── 20220101/
    │   ├── DDL_RAW_ITEMS.sql
    │   └── RAW_ITEMS.csv.gzip
    ├── 20220102/
    │   └── (same structure)
    └── ...
```

---

## Audit Logging

### Audit Table Location
```
Database: JAFFELSHOP_ECOM
Schema:   OPS
Table:    INGESTION_AUDIT_LOG
```

### Audit Table Columns

| Column | Description |
|--------|-------------|
| AUDIT_ID | Auto-incrementing unique identifier |
| LOAD_ID | Unique load identifier (format: TYPE_YYYYMMDD_HHMMSS_UUID) |
| TARGET_DATABASE | Target database name |
| TARGET_SCHEMA | Target schema name |
| TARGET_TABLE | Target table name |
| LOAD_TYPE | FULL_LOAD or INCREMENTAL |
| SOURCE_DATA_DIR | Path to source data directory |
| TOTAL_FILES_LOADED | Number of files loaded |
| TOTAL_ROWS_LOADED | Total rows from source files |
| STARTING_ROW_COUNT | Row count before load |
| ENDING_ROW_COUNT | Row count after load |
| ROWS_INSERTED | Net rows inserted (ENDING - STARTING) |
| LOAD_START_DATE | Load operation start timestamp |
| LOAD_END_DATE | Load operation end timestamp |
| DATE_RANGE_START | First date in load range |
| DATE_RANGE_END | Last date in load range |
| SUCCESSFUL_LOADS | Number of successful daily loads |
| FAILED_LOADS | Number of failed daily loads |
| DURATION_MINUTES | Total duration of load operation |
| LOAD_STATUS | SUCCESS or FAILED |
| ERROR_MESSAGE | Error details if load failed |
| CREATED_AT | Record creation timestamp |

### Query Recent Audit Logs

```sql
-- View most recent 10 load operations
SELECT 
    LOAD_ID,
    TARGET_TABLE,
    LOAD_TYPE,
    TOTAL_ROWS_LOADED,
    ROWS_INSERTED,
    DURATION_MINUTES,
    LOAD_STATUS,
    CREATED_AT
FROM JAFFELSHOP_ECOM.OPS.INGESTION_AUDIT_LOG
ORDER BY CREATED_AT DESC
LIMIT 10;
```

```sql
-- View all ORDERS loads for a specific date range
SELECT 
    LOAD_ID,
    LOAD_TYPE,
    DATE_RANGE_START,
    DATE_RANGE_END,
    TOTAL_ROWS_LOADED,
    LOAD_STATUS
FROM JAFFELSHOP_ECOM.OPS.INGESTION_AUDIT_LOG
WHERE TARGET_TABLE = 'RAW_ORDERS'
  AND CREATED_AT >= '2022-01-01'::TIMESTAMP_NTZ
ORDER BY CREATED_AT DESC;
```

```sql
-- View load performance metrics
SELECT 
    LOAD_ID,
    TOTAL_ROWS_LOADED,
    DURATION_MINUTES,
    ROUND(TOTAL_ROWS_LOADED / DURATION_MINUTES, 0) AS ROWS_PER_MINUTE,
    LOAD_STATUS
FROM JAFFELSHOP_ECOM.OPS.INGESTION_AUDIT_LOG
ORDER BY CREATED_AT DESC
LIMIT 20;
```

---

## Troubleshooting

### Issue: Connection Failed

**Error Message:**
```
Failed to connect to Snowflake using config ./config.ini
```

**Solutions:**
1. Verify `config.ini` exists and has correct credentials
2. Check Snowflake account name format (e.g., `xdyidpl-ui11981`)
3. Verify user has permission to connect
4. Test connection with SQL client first

---

### Issue: File Not Found

**Error Message:**
```
No DDL_*.sql or *.ddl.sql file found in /path/to/folder
No .csv.gzip or .csv file found in /path/to/folder
```

**Solutions:**
1. Verify folder path is correct (use absolute or correct relative path)
2. Confirm folder contains both DDL and CSV files
3. Check file naming conventions:
   - DDL files: `DDL_*.sql` or `*.ddl.sql`
   - Data files: `*.csv.gzip` or `*.csv`

---

### Issue: Table Already Exists

**Error Message:**
```
SQL compilation error: Object already exists
```

**Solutions:**
1. Use `--replace-table` flag to drop and recreate table
2. Or append to existing table (omit `--replace-table` flag)
3. Or specify different schema for new load

---

### Issue: Invalid Date Format

**Error Message:**
```
Invalid date format. Use YYYYMMDD format
```

**Solutions:**
1. Use correct format: `YYYYMMDD` (e.g., `20220115`)
2. Verify date folder exists in incremental data directory
3. Ensure start-date is before or equal to end-date

---

### Issue: Validation Errors

**Error Message:**
```
Found error records during validation
```

**Solutions:**
1. Check error log file generated (named `*_errors.log`)
2. Review data quality issues
3. Fix source data and retry load
4. Use `--replace-table` to reload with corrected data

---

### Issue: Schema Does Not Exist

**Error Message:**
```
SQL compilation error: Schema does not exist
```

**Solutions:**
1. Scripts automatically create OPS schema for audit logging
2. For target schemas, ensure they exist in Snowflake:
   ```sql
   CREATE SCHEMA IF NOT EXISTS JAFFELSHOP_ECOM.INCR_DATA_LOAD;
   ```
3. Verify schema name spelling (case-sensitive in Snowflake)

---

### Debug Mode: Verbose Logging

To see detailed operation logs:

```bash
# Run script and capture full output
python import_snowflake_table.py \
  --config ./config.ini \
  --folder "./HistoryData/RAW_PRODUCTS/" \
  --database JAFFELSHOP_ECOM \
  --schema RAW \
  --replace-table 2>&1 | tee load.log
```

---

## Common Workflows

### Workflow 1: Initial Full Data Load

Load all historical data from `HistoryData` folder:

```bash
# Load all raw tables
for table in RAW_CUSTOMERS RAW_PRODUCTS RAW_STORES RAW_SUPPLIES RAW_ORDERS RAW_ITEMS RAW_TWEETS
do
  echo "Loading $table..."
  python import_snowflake_table.py \
    --config ./config.ini \
    --folder "./HistoryData/$table/" \
    --database JAFFELSHOP_ECOM \
    --schema RAW \
    --replace-table
done
```

### Workflow 2: Daily Incremental Load

Load latest day of ORDERS data:

```bash
# Get today's date in YYYYMMDD format
TODAY=$(date +%Y%m%d)

python incremental_loader.py \
  --database JAFFELSHOP_ECOM \
  --schema INCR_DATA_LOAD \
  --type ORDERS \
  --table ./IncrementalData/RAW_DAILY_ORDERS \
  --start-date $TODAY \
  --end-date $TODAY \
  --validate
```

### Workflow 3: Weekly Load with Validation

```bash
python incremental_loader.py \
  --database JAFFELSHOP_ECOM \
  --schema INCR_DATA_LOAD \
  --type ORDERS \
  --table ./IncrementalData/RAW_DAILY_ORDERS \
  --start-date 20220101 \
  --end-date 20220107 \
  --validate
```

### Workflow 4: Check Load History

```bash
python -c "
import snowflake.connector
from configparser import ConfigParser

config = ConfigParser()
config.read('./config.ini')

conn = snowflake.connector.connect(
    user=config.get('snowflake', 'user'),
    password=config.get('snowflake', 'password'),
    account=config.get('snowflake', 'account'),
    database='JAFFELSHOP_ECOM',
    schema='OPS'
)

cursor = conn.cursor()
cursor.execute('''
SELECT LOAD_ID, TARGET_TABLE, TOTAL_ROWS_LOADED, LOAD_STATUS, CREATED_AT
FROM INGESTION_AUDIT_LOG
ORDER BY CREATED_AT DESC
LIMIT 10
''')

for row in cursor.fetchall():
    print(f'{row[0]:35} | {row[1]:15} | {row[2]:8.0f} rows | {row[3]:10} | {row[4]}')

cursor.close()
conn.close()
"
```

---

## Support

For issues or questions:
1. Check audit logs in `JAFFELSHOP_ECOM.OPS.INGESTION_AUDIT_LOG`
2. Review error logs (`*_errors.log` files)
3. Check generated `.log` files in script directory
4. Verify Snowflake connection and permissions
5. Review SQL error messages in console output

---

## Author

**Your Name**
- Date Created: December 28, 2025
- Email: your.email@example.com
- GitHub: your-github-handle

---

## License

Jaffle Shop Data Import Tools - All Rights Reserved
