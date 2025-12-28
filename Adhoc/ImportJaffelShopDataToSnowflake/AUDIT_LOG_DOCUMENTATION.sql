/**
================================================================================
INGESTION AUDIT LOG - SNOWFLAKE TABLE DOCUMENTATION
================================================================================
This table captures comprehensive audit information for all incremental data
loads performed using the incremental_loader.py script.

Table Location: JAFFELSHOP_ECOM.OPS.INGESTION_AUDIT_LOG
Schema: OPS (created automatically if it doesn't exist)
Created: Automatically on first load if it doesn't exist
================================================================================
*/

-- ============================================================================
-- TABLE STRUCTURE
-- ============================================================================

-- Create OPS schema (done automatically by incremental_loader.py)
CREATE SCHEMA IF NOT EXISTS JAFFELSHOP_ECOM.OPS;

-- Create audit table in OPS schema
CREATE TABLE IF NOT EXISTS JAFFELSHOP_ECOM.OPS.INGESTION_AUDIT_LOG (
    AUDIT_ID NUMBER AUTOINCREMENT,
    LOAD_ID VARCHAR NOT NULL,
    TARGET_DATABASE VARCHAR NOT NULL,
    TARGET_SCHEMA VARCHAR NOT NULL,
    TARGET_TABLE VARCHAR NOT NULL,
    LOAD_TYPE VARCHAR NOT NULL,
    SOURCE_DATA_DIR VARCHAR,
    TOTAL_FILES_LOADED NUMBER,
    TOTAL_ROWS_LOADED NUMBER,
    STARTING_ROW_COUNT NUMBER,
    ENDING_ROW_COUNT NUMBER,
    ROWS_INSERTED NUMBER,
    LOAD_START_DATE VARCHAR,
    LOAD_END_DATE VARCHAR,
    DATE_RANGE_START VARCHAR,
    DATE_RANGE_END VARCHAR,
    SUCCESSFUL_LOADS NUMBER,
    FAILED_LOADS NUMBER,
    DURATION_MINUTES NUMBER,
    LOAD_STATUS VARCHAR,
    ERROR_MESSAGE VARCHAR,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Audit log for data ingestion loads'
;

-- ============================================================================
-- COLUMN DESCRIPTIONS
-- ============================================================================

COLUMN DESCRIPTIONS:
  AUDIT_ID               - Unique auto-incrementing audit record ID
  LOAD_ID                - Unique load identifier (format: TABLE_TYPE_YYYYMMDD_HHMMSS_RANDOM)
  TARGET_DATABASE        - Snowflake database name (e.g., JAFFELSHOP_ECOM)
  TARGET_SCHEMA          - Snowflake schema name (e.g., RAW, INCR_DATA_LOAD)
  TARGET_TABLE           - Target table name (e.g., RAW_ORDERS, RAW_ITEMS)
  LOAD_TYPE              - Type of load: 'FULL_LOAD' (first load) or 'INCREMENTAL'
  SOURCE_DATA_DIR        - Source directory path containing daily folders
  TOTAL_FILES_LOADED     - Total number of daily folders/files loaded
  TOTAL_ROWS_LOADED      - Total rows from all CSV files
  STARTING_ROW_COUNT     - Row count in target table before load
  ENDING_ROW_COUNT       - Row count in target table after load
  ROWS_INSERTED          - Net rows inserted (ENDING - STARTING)
  LOAD_START_DATE        - Load start timestamp (ISO 8601 format)
  LOAD_END_DATE          - Load end timestamp (ISO 8601 format)
  DATE_RANGE_START       - Earliest date folder loaded (YYYYMMDD)
  DATE_RANGE_END         - Latest date folder loaded (YYYYMMDD)
  SUCCESSFUL_LOADS       - Number of successfully loaded daily folders
  FAILED_LOADS           - Number of failed daily folders
  DURATION_MINUTES       - Total load duration in minutes
  LOAD_STATUS            - Status: 'SUCCESS', 'PARTIAL_SUCCESS', or 'FAILED'
  ERROR_MESSAGE          - Error message if load failed (NULL if successful)
  CREATED_AT             - System timestamp when audit record was created


-- ============================================================================
-- EXAMPLE QUERIES
-- ============================================================================

-- View all load history
SELECT 
    AUDIT_ID,
    LOAD_ID,
    TARGET_TABLE,
    LOAD_TYPE,
    TOTAL_FILES_LOADED,
    TOTAL_ROWS_LOADED,
    ROWS_INSERTED,
    DURATION_MINUTES,
    LOAD_STATUS,
    CREATED_AT
FROM JAFFELSHOP_ECOM.OPS.INGESTION_AUDIT_LOG
ORDER BY CREATED_AT DESC;

-- Get summary statistics for ORDERS table
SELECT 
    TARGET_TABLE,
    COUNT(*) as total_loads,
    SUM(TOTAL_ROWS_LOADED) as total_rows_loaded,
    SUM(ROWS_INSERTED) as total_rows_inserted,
    SUM(CASE WHEN LOAD_STATUS = 'SUCCESS' THEN 1 ELSE 0 END) as successful_loads,
    SUM(CASE WHEN LOAD_STATUS != 'SUCCESS' THEN 1 ELSE 0 END) as failed_loads,
    AVG(DURATION_MINUTES) as avg_duration_minutes
FROM JAFFELSHOP_ECOM.OPS.INGESTION_AUDIT_LOG
WHERE TARGET_TABLE = 'RAW_ORDERS'
GROUP BY TARGET_TABLE;

-- Get recent loads with full details
SELECT 
    LOAD_ID,
    TARGET_TABLE,
    LOAD_TYPE,
    TOTAL_FILES_LOADED,
    TOTAL_ROWS_LOADED,
    DATE_RANGE_START,
    DATE_RANGE_END,
    SUCCESSFUL_LOADS,
    FAILED_LOADS,
    DURATION_MINUTES,
    LOAD_STATUS,
    ERROR_MESSAGE,
    CREATED_AT
FROM JAFFELSHOP_ECOM.OPS.INGESTION_AUDIT_LOG
WHERE CREATED_AT >= CURRENT_DATE - 7
ORDER BY CREATED_AT DESC;

-- Check failed loads
SELECT 
    LOAD_ID,
    TARGET_TABLE,
    LOAD_STATUS,
    ERROR_MESSAGE,
    CREATED_AT
FROM JAFFELSHOP_ECOM.OPS.INGESTION_AUDIT_LOG
WHERE LOAD_STATUS != 'SUCCESS'
ORDER BY CREATED_AT DESC;

-- Get row insertion history for a specific table
SELECT 
    LOAD_ID,
    LOAD_START_DATE,
    LOAD_END_DATE,
    STARTING_ROW_COUNT,
    ENDING_ROW_COUNT,
    ROWS_INSERTED,
    TOTAL_ROWS_LOADED,
    DURATION_MINUTES
FROM JAFFELSHOP_ECOM.OPS.INGESTION_AUDIT_LOG
WHERE TARGET_TABLE = 'RAW_ORDERS'
ORDER BY CREATED_AT DESC;


-- ============================================================================
-- USAGE EXAMPLE
-- ============================================================================

/*
When you run the incremental_loader.py script:

    python incremental_loader.py \
        --database JAFFELSHOP_ECOM \
        --schema INCR_DATA_LOAD \
        --type ORDERS \
        --table ./IncrementalData/RAW_DAILY_ORDERS \
        --start-date 20220108 \
        --end-date 20220110 \
        --validate

The following audit record will be created:

    AUDIT_ID:              1
    LOAD_ID:               ORDERS_20251228_191649_7514b7cd
    TARGET_DATABASE:       JAFFELSHOP_ECOM
    TARGET_SCHEMA:         INCR_DATA_LOAD
    TARGET_TABLE:          RAW_ORDERS
    LOAD_TYPE:             INCREMENTAL
    SOURCE_DATA_DIR:       /full/path/to/IncrementalData/RAW_DAILY_ORDERS
    TOTAL_FILES_LOADED:    3 (20220108, 20220109, 20220110)
    TOTAL_ROWS_LOADED:     3,064
    STARTING_ROW_COUNT:    12,396
    ENDING_ROW_COUNT:      3,064
    ROWS_INSERTED:         -9,332 (data was replaced with --replace-table)
    LOAD_START_DATE:       2025-12-28T19:16:49.000000
    LOAD_END_DATE:         2025-12-28T19:16:57.000000
    DATE_RANGE_START:      20220108
    DATE_RANGE_END:        20220110
    SUCCESSFUL_LOADS:      3
    FAILED_LOADS:          0
    DURATION_MINUTES:      0.13
    LOAD_STATUS:           SUCCESS
    ERROR_MESSAGE:         NULL
    CREATED_AT:            2025-12-28 19:16:57.000000

This record provides complete traceability of:
  - What data was loaded (LOAD_ID, TARGET_TABLE, SOURCE_DATA_DIR)
  - When it was loaded (LOAD_START_DATE, LOAD_END_DATE, CREATED_AT)
  - How much data (TOTAL_FILES_LOADED, TOTAL_ROWS_LOADED, ROWS_INSERTED)
  - Whether it succeeded (LOAD_STATUS, SUCCESSFUL_LOADS, FAILED_LOADS)
  - How long it took (DURATION_MINUTES)
  - Where it was stored (TARGET_DATABASE, TARGET_SCHEMA, TARGET_TABLE)
*/


-- ============================================================================
-- RETENTION POLICY (RECOMMENDED)
-- ============================================================================

-- Archive audit logs older than 1 year (optional)
ALTER TABLE JAFFELSHOP_ECOM.RAW.INGESTION_AUDIT_LOG
SET DATA_RETENTION_TIME_IN_DAYS = 365;

-- Delete very old audit logs (optional, after archiving)
DELETE FROM JAFFELSHOP_ECOM.RAW.INGESTION_AUDIT_LOG
WHERE CREATED_AT < CURRENT_DATE - 730;  -- Keep 2 years of history


-- ============================================================================
-- MONITORING QUERIES
-- ============================================================================

-- Daily load volume
SELECT 
    DATE(CREATED_AT) as load_date,
    TARGET_TABLE,
    COUNT(*) as num_loads,
    SUM(TOTAL_ROWS_LOADED) as total_rows,
    SUM(CASE WHEN LOAD_STATUS = 'SUCCESS' THEN 1 ELSE 0 END) as successful,
    SUM(CASE WHEN LOAD_STATUS != 'SUCCESS' THEN 1 ELSE 0 END) as failed
FROM JAFFELSHOP_ECOM.OPS.INGESTION_AUDIT_LOG
GROUP BY DATE(CREATED_AT), TARGET_TABLE
ORDER BY load_date DESC, TARGET_TABLE;

-- Load performance trends
SELECT 
    TARGET_TABLE,
    AVG(DURATION_MINUTES) as avg_duration,
    MIN(DURATION_MINUTES) as min_duration,
    MAX(DURATION_MINUTES) as max_duration,
    AVG(TOTAL_ROWS_LOADED / DURATION_MINUTES) as avg_rows_per_minute
FROM JAFFELSHOP_ECOM.OPS.INGESTION_AUDIT_LOG
WHERE CREATED_AT >= CURRENT_DATE - 30
GROUP BY TARGET_TABLE;
