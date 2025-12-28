#!/usr/bin/env python3
"""
import_snowflake_table.py

Import table data and DDL from exported folder into Snowflake.
Reads DDL from .sql file and data from compressed CSV (.gzip) file.
The exported folder is expected to contain:
  - *.ddl.sql - Table DDL definition
  - *.csv.gzip - Compressed CSV data file

Usage:
  python import_snowflake_table.py \
    --config ./config.ini \
    --folder ./LINEITEM \
    --schema TARGET_SCHEMA \
    --replace-table


Example commands:
cd .\Adhoc\ImportJaffelShopDataToSnowflake\

python import_snowflake_table.py --config ./config.ini --folder "./HistoryData/RAW_CUSTOMERS/" --database JAFFELSHOP_ECOM --schema RAW --replace-table

python import_snowflake_table.py --config ./config.ini --folder "./HistoryData/RAW_ITEMS/" --database JAFFELSHOP_ECOM --schema RAW --replace-table

python import_snowflake_table.py --config ./config.ini --folder "./HistoryData/RAW_ORDERS/" --database JAFFELSHOP_ECOM --schema RAW --replace-table

python import_snowflake_table.py --config ./config.ini --folder "./HistoryData/RAW_PRODUCTS/" --database JAFFELSHOP_ECOM --schema RAW --replace-table

python import_snowflake_table.py --config ./config.ini --folder "./HistoryData/RAW_STORES/" --database JAFFELSHOP_ECOM --schema RAW --replace-table

python import_snowflake_table.py --config ./config.ini --folder "./HistoryData/RAW_SUPPLIES/" --database JAFFELSHOP_ECOM --schema RAW --replace-table

python import_snowflake_table.py --config ./config.ini --folder "./HistoryData/RAW_TWEETS/" --database JAFFELSHOP_ECOM --schema RAW --replace-table





Dependencies:
  - snowflake-connector-python
  - pandas (for data loading)
"""
from __future__ import annotations

import argparse
import configparser
import gzip
import logging
import os
import sys
import time
from pathlib import Path
from io import StringIO

try:
    import snowflake.connector
except Exception:
    print("snowflake-connector-python is required. Install with: pip install snowflake-connector-python")
    raise

try:
    import pandas as pd
except Exception:
    print("pandas is required. Install with: pip install pandas")
    raise

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s: %(message)s")


def parse_args():
    p = argparse.ArgumentParser(description="Import Snowflake table from exported folder containing DDL and CSV data")
    p.add_argument("--config", default="config.ini", help="Path to config.ini (default: ./config.ini)")
    p.add_argument("--folder", required=True, help="Folder containing exported table files (*.ddl.sql and *.csv.gzip)")
    p.add_argument("--database", required=True, help="Target Snowflake database to import table into")
    p.add_argument("--schema", required=True, help="Target Snowflake schema to import table into")
    p.add_argument("--replace-table", action="store_true", help="Drop and recreate table if it exists (default: append data)")
    return p.parse_args()


def read_config(path: str) -> dict:
    config = configparser.ConfigParser()
    read_files = config.read(path)
    if not read_files:
        logging.warning("Config file %s not found or unreadable. Falling back to environment variables where available.", path)

    section = "snowflake"
    cfg = {}
    keys = ["account", "user", "password", "warehouse", "database", "schema", "role"]
    for k in keys:
        val = None
        if config.has_section(section) and config.has_option(section, k):
            val = config.get(section, k)
        else:
            env_var = f"SNOWFLAKE_{k.upper()}"
            val = os.getenv(env_var)
        if val:
            cfg[k] = val
    return cfg


def get_conn_from_config(cfg: dict):
    required = ["account", "user", "password"]
    missing = [r for r in required if r not in cfg]
    if missing:
        logging.warning("Missing required Snowflake connection items in config/env: %s", missing)
    conn_args = {k: v for k, v in cfg.items() if v}
    logging.info(
        "Connecting to Snowflake account=%s user=%s database=%s schema=%s",
        conn_args.get("account"), conn_args.get("user"), conn_args.get("database"), conn_args.get("schema"),
    )
    return snowflake.connector.connect(**conn_args)


def find_files_in_folder(folder_path: str) -> tuple[str, str]:
    """
    Find DDL and CSV files in the folder (supports both .csv.gzip and .csv).
    Looks for DDL_<TableName>.sql pattern for DDL files.
    Returns: (ddl_file_path, data_file_path)
    """
    folder = Path(folder_path).resolve()  # Resolve to absolute path
    
    if not folder.exists() or not folder.is_dir():
        raise FileNotFoundError(f"Folder not found: {folder_path}")
    
    # Find DDL and CSV files with flexible matching
    ddl_files = []
    csv_files = []
    
    for file in folder.iterdir():
        if file.is_file():
            lower_name = file.name.lower()
            # Look for DDL_*.sql or *.ddl.sql patterns
            if (lower_name.startswith('ddl_') or lower_name.endswith('.ddl.sql')) and lower_name.endswith('.sql'):
                ddl_files.append(file)
            # Look for .csv.gzip or .csv files (but not .ddl.sql or .sql)
            elif (lower_name.endswith('.csv.gzip') or lower_name.endswith('.csv')) and not lower_name.endswith('.sql'):
                csv_files.append(file)
    
    if not ddl_files:
        raise FileNotFoundError(f"No DDL_*.sql or *.ddl.sql file found in {folder_path}")
    if not csv_files:
        raise FileNotFoundError(f"No .csv.gzip or .csv file found in {folder_path}")
    
    # Use the first one if multiple exist
    ddl_file = str(ddl_files[0])
    data_file = str(csv_files[0])
    
    logging.info("Found DDL file: %s", ddl_file)
    logging.info("Found data file: %s", data_file)
    
    return ddl_file, data_file


def get_directory_size(folder_path: str) -> int:
    """
    Calculate total size of all files in directory in bytes.
    """
    try:
        folder = Path(folder_path)
        if not folder.exists() or not folder.is_dir():
            logging.warning("Folder not found for size calculation: %s", folder_path)
            return 0
        
        total_size = 0
        for file_path in folder.rglob("*"):
            if file_path.is_file():
                total_size += file_path.stat().st_size
        
        logging.info("Directory size for %s: %d bytes", folder_path, total_size)
        return total_size
    except Exception as e:
        logging.warning("Could not calculate directory size: %s", str(e))
        return 0


def read_ddl(ddl_file_path: str) -> str:
    """
    Read and parse DDL from file, removing comments.
    """
    logging.info("Reading DDL from %s", ddl_file_path)
    try:
        with open(ddl_file_path, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Remove SQL comments (lines starting with --)
        lines = content.split('\n')
        clean_lines = []
        for line in lines:
            # Remove inline comments
            if '--' in line:
                line = line[:line.index('--')]
            # Only keep non-empty lines
            if line.strip():
                clean_lines.append(line)
        
        ddl = '\n'.join(clean_lines)
        logging.info("DDL read successfully (%d characters)", len(ddl))
        logging.info("Cleaned DDL: %s", ddl)
        return ddl
    except Exception as e:
        logging.exception("Failed to read DDL from %s", ddl_file_path)
        raise


def read_csv_gzip(data_file_path: str) -> pd.DataFrame:
    """
    Read CSV file into a pandas DataFrame.
    Supports both gzip-compressed (.csv.gzip) and plain (.csv) formats.
    """
    logging.info("Reading data from %s", data_file_path)
    try:
        if data_file_path.endswith('.gzip') or data_file_path.endswith('.gz'):
            # Gzip compressed file
            logging.info("Detected gzip compressed file, decompressing...")
            with gzip.open(data_file_path, "rt", encoding="utf-8") as f:
                df = pd.read_csv(f)
        else:
            # Plain CSV file
            logging.info("Detected plain CSV file...")
            df = pd.read_csv(data_file_path, encoding="utf-8")
        
        logging.info("Data read successfully: %d rows, %d columns", len(df), len(df.columns))
        logging.info("Columns: %s", list(df.columns))
        return df
    except Exception as e:
        logging.exception("Failed to read data from %s", data_file_path)
        raise


def extract_table_name_from_ddl(ddl: str) -> str:
    """
    Extract table name from DDL statement.
    Looks for: CREATE TABLE ... (
    """
    import re
    match = re.search(r"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?([^\s(]+)", ddl, re.IGNORECASE)
    if match:
        return match.group(1).strip()
    raise ValueError("Could not extract table name from DDL")


def create_database_and_schema(conn, database: str, schema: str):
    """
    Create database and schema if they don't exist.
    """
    try:
        cur = conn.cursor()
        
        # Create database if not exists
        create_db_sql = f"CREATE DATABASE IF NOT EXISTS {database}"
        logging.info("Creating database if not exists: %s", database)
        cur.execute(create_db_sql)
        logging.info("Database %s ensured to exist", database)
        
        # Use the database
        use_db_sql = f"USE DATABASE {database}"
        logging.info("Using database: %s", database)
        cur.execute(use_db_sql)
        
        # Create schema if not exists
        create_schema_sql = f"CREATE SCHEMA IF NOT EXISTS {schema}"
        logging.info("Creating schema if not exists: %s", schema)
        cur.execute(create_schema_sql)
        logging.info("Schema %s ensured to exist", schema)
        
        cur.close()
        logging.info("Database and schema setup completed")
        
    except Exception as e:
        logging.exception("Failed to create database or schema")
        raise


def create_table_from_ddl(conn, ddl: str, database: str, schema: str, replace_table: bool = False):
    """
    Create table using DDL in the specified database and schema.
    If replace_table is True, drops existing table first.
    """
    logging.info("Executing DDL to create table in database %s schema %s", database, schema)
    
    # Extract table name
    table_name_from_ddl = extract_table_name_from_ddl(ddl)
    logging.info("Full table name extracted from DDL: %s", table_name_from_ddl)
    
    # Extract just the table name (last part if fully qualified)
    parts = table_name_from_ddl.split(".")
    table_name_only = parts[-1]  # Get just the table name, not the database or schema
    logging.info("Table name only: %s", table_name_only)
    
    # Build the fully qualified name with target database and schema
    fully_qualified_name = f"{database}.{schema}.{table_name_only}"
    logging.info("Using fully qualified table name: %s", fully_qualified_name)
    
    # Modify DDL to use the target database and schema
    # Replace the original fully-qualified name with the new one
    modified_ddl = ddl.replace(table_name_from_ddl, fully_qualified_name)
    
    # Ensure we use CREATE TABLE IF NOT EXISTS for idempotency
    if "CREATE TABLE IF NOT EXISTS" not in modified_ddl and "CREATE TABLE" in modified_ddl:
        modified_ddl = modified_ddl.replace("CREATE TABLE", "CREATE TABLE IF NOT EXISTS")
    
    # Drop table if replace_table is True
    if replace_table:
        try:
            cur = conn.cursor()
            drop_sql = f"DROP TABLE IF EXISTS {fully_qualified_name}"
            logging.info("Dropping existing table: %s", fully_qualified_name)
            cur.execute(drop_sql)
            cur.close()
            logging.info("Table dropped successfully")
        except Exception as e:
            logging.exception("Failed to drop table %s", fully_qualified_name)
            raise
    
    # Create table
    try:
        cur = conn.cursor()
        logging.info("=" * 80)
        logging.info("DDL STATEMENT TO BE EXECUTED:")
        logging.info("=" * 80)
        logging.info(modified_ddl)
        logging.info("=" * 80)
        cur.execute(modified_ddl)
        cur.close()
        
        # Verify table was created
        verify_cur = conn.cursor()
        verify_sql = f"SELECT COUNT(*) FROM {fully_qualified_name}"
        logging.info("Verifying table creation with query: %s", verify_sql)
        verify_cur.execute(verify_sql)
        row_count = verify_cur.fetchone()[0]
        verify_cur.close()
        logging.info("Table created successfully: %s (rows: %d)", fully_qualified_name, row_count)
        return fully_qualified_name
    except Exception as e:
        logging.exception("Failed to create table")
        raise


def load_data_into_table(conn, df: pd.DataFrame, database: str, schema: str, fully_qualified_table_name: str, input_dir_size: int = 0, input_folder_path: str = "", input_data_file_path: str = ""):
    """
    Load DataFrame data into Snowflake table using bulk COPY INTO.
    Captures error records to a separate file for debugging.
    Tracks timing for each step of the load process.
    """
    logging.info("Loading %d rows into %s using COPY INTO", len(df), fully_qualified_table_name)
    
    if len(df) == 0:
        logging.warning("DataFrame is empty, skipping data load")
        return
    
    import tempfile
    import os
    
    # Initialize timing dictionary
    timing = {}
    
    try:
        # Create a temporary CSV file
        step_start = time.time()
        with tempfile.NamedTemporaryFile(mode='w', suffix='.csv', delete=False, newline='') as tmp_file:
            df.to_csv(tmp_file, index=False, quoting=1)  # quoting=1 is csv.QUOTE_ALL
            tmp_file_path = tmp_file.name
        timing['create_temp_file'] = time.time() - step_start
        
        logging.info("Temporary CSV file created: %s", tmp_file_path)
        input_file_size = os.path.getsize(tmp_file_path)
        input_rows = len(df)
        logging.info("CSV file size: %d bytes, rows: %d", input_file_size, input_rows)
        
        # Extract table name and stage name
        table_parts = fully_qualified_table_name.split('.')
        table_name_only = table_parts[-1]
        stage_name = f"@~/{table_name_only}_stage"
        csv_filename = os.path.basename(tmp_file_path)
        
        try:
            cur = conn.cursor()
            
            # Convert Windows path to use forward slashes for Snowflake
            snowflake_file_path = tmp_file_path.replace('\\', '/')
            
            # PUT file to internal stage
            logging.info("Uploading file to Snowflake stage: %s", stage_name)
            put_sql = f"PUT 'file://{snowflake_file_path}' {stage_name} AUTO_COMPRESS=FALSE OVERWRITE=TRUE"
            logging.info("Executing PUT command with path: %s", snowflake_file_path)
            step_start = time.time()
            cur.execute(put_sql)
            timing['put_command'] = time.time() - step_start
            logging.info("File uploaded successfully to stage")
            
            # First, validate the file to get error details
            validation_sql = f"""
            COPY INTO {fully_qualified_table_name}
            FROM {stage_name}/{csv_filename}
            FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '\"')
            VALIDATION_MODE = 'RETURN_ERRORS'
            """
            logging.info("Running validation to identify potential errors...")
            step_start = time.time()
            cur.execute(validation_sql)
            timing['validation'] = time.time() - step_start
            
            # Fetch validation results (errors)
            validation_results = cur.fetchall()
            error_records = []
            for row in validation_results:
                error_records.append(row)
            
            if error_records:
                logging.warning("Found %d error records during validation", len(error_records))
                # Write errors to file
                error_file_path = tmp_file_path.replace('.csv', '_errors.log')
                with open(error_file_path, 'w', encoding='utf-8') as err_f:
                    err_f.write("Error Records from COPY INTO validation\n")
                    err_f.write("=" * 80 + "\n\n")
                    for idx, error_row in enumerate(error_records, 1):
                        err_f.write(f"Error #{idx}:\n")
                        err_f.write(f"  Details: {error_row}\n\n")
                logging.info("Error records written to: %s", error_file_path)
            else:
                logging.info("No validation errors found")
            
            # Now perform actual COPY INTO to load data
            copy_sql = f"""
            COPY INTO {fully_qualified_table_name}
            FROM {stage_name}/{csv_filename}
            FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '\"')
            ON_ERROR = 'CONTINUE'
            """
            logging.info("Loading data from stage to table using COPY INTO")
            step_start = time.time()
            cur.execute(copy_sql)
            timing['copy_into'] = time.time() - step_start
            
            # Get number of rows loaded
            copy_result = cur.fetchall()
            
            # Parse the result tuple
            load_summary = {}
            if copy_result and len(copy_result) > 0:
                result_tuple = copy_result[0]
                load_summary = {
                    'file': result_tuple[0] if len(result_tuple) > 0 else 'N/A',
                    'status': result_tuple[1] if len(result_tuple) > 1 else 'N/A',
                    'rows_parsed': result_tuple[2] if len(result_tuple) > 2 else 0,
                    'rows_loaded': result_tuple[3] if len(result_tuple) > 3 else 0,
                    'rows_unloaded': result_tuple[4] if len(result_tuple) > 4 else 0,
                }
            
            # Get stage file size
            list_sql = f"LIST {stage_name}"
            cur.execute(list_sql)
            stage_files = cur.fetchall()
            stage_file_size = 0
            if stage_files:
                # Stage file size is in bytes (typically the 2nd element in the tuple)
                stage_file_size = stage_files[0][1] if len(stage_files[0]) > 1 else 0
            
            # Get target table size from INFORMATION_SCHEMA
            table_size = 0
            rows_loaded = load_summary.get('rows_loaded', 0)
            try:
                table_size_sql = f"""
                SELECT ROUND(SUM(bytes) / 1024/1024, 2) AS size_mb
                FROM {database}.information_schema.tables
                WHERE table_name = '{table_name_only}'
                AND table_schema = '{schema}'
                AND table_catalog = '{database}'
                """
                logging.info("Querying table size from INFORMATION_SCHEMA")
                cur.execute(table_size_sql)
                table_size_result = cur.fetchone()
                if table_size_result and table_size_result[0] is not None:
                    # Convert MB to bytes
                    size_mb = float(table_size_result[0])
                    table_size = int(size_mb * 1024 * 1024)
                    logging.info("Target table size from INFORMATION_SCHEMA: %.2f MB", size_mb)
                else:
                    logging.warning("No size data found in INFORMATION_SCHEMA, trying estimation method")
                    # Fallback: estimate based on row count and avg row size
                    table_count_sql = f"SELECT COUNT(*) FROM {fully_qualified_table_name}"
                    cur.execute(table_count_sql)
                    table_row_count = cur.fetchone()[0]
                    if input_rows > 0 and rows_loaded > 0 and input_file_size > 0:
                        avg_row_size = input_file_size / input_rows
                        table_size = int(avg_row_size * table_row_count)
                        logging.info("Using estimated table size: %.2f bytes (rows: %d, avg row: %.2f bytes)", table_size, table_row_count, avg_row_size)
                    else:
                        table_size = 0
            except Exception as e:
                logging.warning("Could not retrieve table size from INFORMATION_SCHEMA: %s", str(e))
                # Fallback: estimate based on row count and avg row size
                try:
                    table_count_sql = f"SELECT COUNT(*) FROM {fully_qualified_table_name}"
                    cur.execute(table_count_sql)
                    table_row_count = cur.fetchone()[0]
                    if input_rows > 0 and rows_loaded > 0 and input_file_size > 0:
                        avg_row_size = input_file_size / input_rows
                        table_size = int(avg_row_size * table_row_count)
                        logging.info("Using estimated table size based on row count: %d", table_row_count)
                    else:
                        logging.warning("Not enough data to estimate table size (input_rows: %d, rows_loaded: %d, input_file_size: %d)", input_rows, rows_loaded, input_file_size)
                        table_size = 0
                except Exception as e2:
                    logging.warning("Could not estimate table size: %s", str(e2))
                    table_size = 0
            
            cur.close()
            
            # Get input data file size
            input_data_file_size = 0
            try:
                if input_data_file_path and os.path.isfile(input_data_file_path):
                    input_data_file_size = os.path.getsize(input_data_file_path)
            except Exception as e:
                logging.warning("Could not get input data file size: %s", str(e))
            
            # Print comprehensive summary with sizes and timing
            print_load_summary(
                table_name_only=table_name_only,
                input_file=csv_filename,
                stage_name=stage_name,
                target_table=fully_qualified_table_name,
                input_rows=input_rows,
                rows_parsed=load_summary.get('rows_parsed', 0),
                rows_loaded=load_summary.get('rows_loaded', 0),
                copy_command=copy_sql,
                input_file_size=input_file_size,
                temp_file_size=input_file_size,
                stage_file_size=stage_file_size,
                target_table_size=table_size,
                input_dir_size=input_dir_size,
                input_folder_path=input_folder_path,
                input_data_file_path=input_data_file_path,
                input_data_file_size=input_data_file_size,
                timing=timing
            )
            
            logging.info("Data load completed successfully using COPY INTO")
            
        except Exception as e:
            logging.exception("Failed to load data using COPY INTO")
            raise
        finally:
            # Remove temporary local file
            try:
                os.remove(tmp_file_path)
                logging.info("Temporary file cleaned up: %s", tmp_file_path)
            except Exception as e:
                logging.warning("Could not delete temporary file: %s", tmp_file_path)
                
    except Exception as e:
        logging.exception("Failed to load data")
        raise


def print_load_summary(table_name_only, input_file, stage_name, target_table, input_rows, rows_parsed, rows_loaded, copy_command, input_file_size=0, temp_file_size=0, stage_file_size=0, target_table_size=0, input_dir_size=0, input_folder_path="", input_data_file_path="", input_data_file_size=0, timing=None):
    """
    Print a comprehensive summary of the load operation with physical sizes and timing information.
    """
    if timing is None:
        timing = {}
    
    def format_bytes(bytes_size):
        """Convert bytes to human readable format"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_size < 1024.0:
                return f"{bytes_size:.2f} {unit}"
            bytes_size /= 1024.0
        return f"{bytes_size:.2f} PB"
    
    def format_time(seconds):
        """Convert seconds to HH:MM:SS format"""
        hours, remainder = divmod(seconds, 3600)
        minutes, secs = divmod(remainder, 60)
        return f"{int(hours):02d}:{int(minutes):02d}:{secs:05.2f}"
    
    summary = f"""
{'='*100}
                        DATA LOAD SUMMARY REPORT
{'='*100}

TABLE INFORMATION:
  Table Name (Source):          {table_name_only}
  Target Table (Full Path):     {target_table}
  
INPUT FOLDER DETAILS:
  Input Folder Path:            {input_folder_path}
  Input Folder Size:            {format_bytes(input_dir_size)}

INPUT FILE DETAILS:
  Input Data File Path:         {input_data_file_path}
  Input Data File Size:         {format_bytes(input_data_file_size)}
  Input File Name (Temp):       {input_file}
  Input Rows (DataFrame):       {input_rows:,}
  Temp File Size:               {format_bytes(input_file_size)}

STAGING INFORMATION:
  Stage Name:                   {stage_name}
  Stage File:                   {stage_name}/{input_file}
  Stage File Size:              {format_bytes(stage_file_size)}

LOAD RESULTS:
  Batch Size (Rows per Chunk):  {input_rows:,}
  Rows Parsed:                  {rows_parsed:,}
  Rows Successfully Loaded:     {rows_loaded:,}
  Rows Failed/Skipped:          {max(0, rows_parsed - rows_loaded):,}
  Load Success Rate:            {(rows_loaded/rows_parsed*100 if rows_parsed > 0 else 0):.2f}%

TARGET TABLE INFORMATION:
  Target Table Size:            {format_bytes(target_table_size)}
  Avg Row Size:                 {format_bytes(target_table_size/rows_loaded) if rows_loaded > 0 else 'N/A'}

EXECUTION TIMING:
  Create Temp File:             {format_time(timing.get('create_temp_file', 0))}
  Run PUT Command:              {format_time(timing.get('put_command', 0))}
  Data Validation:              {format_time(timing.get('validation', 0))}
  Run COPY INTO Command:        {format_time(timing.get('copy_into', 0))}
  Total Data Load Time:         {format_time(sum(timing.values()))}

COPY COMMAND USED:
{copy_command}

{'='*100}
"""
    print(summary)
    logging.info(summary)


def _load_data_sql_insert(conn, df: pd.DataFrame, fully_qualified_table_name: str):
    """
    Fallback method to load data using SQL INSERT statements.
    Expects fully qualified table name like: DATABASE.SCHEMA.TABLE
    """
    logging.info("Using SQL INSERT method to load data into %s", fully_qualified_table_name)
    
    try:
        cur = conn.cursor()
        
        # Build INSERT statement
        columns = ", ".join([f'\"{{col}}\"'.format(col=col) for col in df.columns])
        
        for idx, row in df.iterrows():
            values = ", ".join([f"'{{v}}'" .format(v=str(v).replace(chr(39), chr(39)+chr(39))) if pd.notna(v) else "NULL" 
                               for v in row])
            insert_sql = f"INSERT INTO {fully_qualified_table_name} ({columns}) VALUES ({values})"
            cur.execute(insert_sql)
        
        cur.close()
        logging.info("All %d rows inserted successfully", len(df))
        
    except Exception as e:
        logging.exception("Failed to insert data using SQL")
        raise


def main():
    start_time = time.time()
    logging.info("Script execution started at %s", time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(start_time)))
    
    args = parse_args()
    
    # Read config
    cfg = read_config(args.config)
    try:
        conn = get_conn_from_config(cfg)
    except Exception:
        logging.exception("Failed to connect to Snowflake using config %s", args.config)
        raise
    
    try:
        # Find DDL and data files in folder
        ddl_file, data_file = find_files_in_folder(args.folder)
        
        # Calculate input directory size
        input_dir_size = get_directory_size(args.folder)
        
        # Get absolute paths for reporting
        input_folder_path = os.path.abspath(args.folder)
        input_data_file_path = os.path.abspath(data_file)
        
        # Read DDL and data
        ddl = read_ddl(ddl_file)
        df = read_csv_gzip(data_file)
        
        # Create database and schema if they don't exist
        create_database_and_schema(conn, args.database, args.schema)
        
        # Create table in target database and schema
        fully_qualified_table_name = create_table_from_ddl(conn, ddl, args.database, args.schema, args.replace_table)
        
        # Load data into table
        load_data_into_table(conn, df, args.database, args.schema, fully_qualified_table_name, input_dir_size, input_folder_path, input_data_file_path)
        
        logging.info("Import completed successfully!")
        
    except Exception:
        logging.exception("Failed to import table")
        raise
    finally:
        try:
            conn.close()
        except Exception:
            pass
    
    end_time = time.time()
    elapsed_time = end_time - start_time
    hours, remainder = divmod(elapsed_time, 3600)
    minutes, seconds = divmod(remainder, 60)
    logging.info("Script execution completed at %s", time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(end_time)))
    logging.info("Total execution time: %02d:%02d:%05.2f (HH:MM:SS.ms)", int(hours), int(minutes), seconds)


if __name__ == "__main__":
    main()
