#!/usr/bin/env python3
"""
Incremental data loader for Snowflake - Advanced Version.
Loads daily folders sequentially with automatic table creation and validation.
Includes comprehensive audit logging to INGESTION_AUDIT_LOG table.
"""

import subprocess
import json
import os
import logging
from pathlib import Path
from datetime import datetime
import snowflake.connector
from configparser import ConfigParser
import sys
import time
import uuid

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

class IncrementalLoader:
    def __init__(self, config_path='./config.ini', database='EDWH', schema='RAW'):
        """Initialize loader with Snowflake connection."""
        self.config_path = config_path
        self.database = database
        self.schema = schema
        self.conn = None
        self.cursor = None
        self.load_stats = []
        self.table_type = None  # Track which table type is being loaded
        
        # Load config
        self.config = ConfigParser()
        self.config.read(config_path)
        
        # Connect to Snowflake
        self._connect()
    
    def _connect(self):
        """Connect to Snowflake."""
        try:
            self.conn = snowflake.connector.connect(
                user=self.config.get('snowflake', 'user'),
                password=self.config.get('snowflake', 'password'),
                account=self.config.get('snowflake', 'account'),
                database=self.database,
                schema=self.schema
            )
            self.cursor = self.conn.cursor()
            print("[OK] Connected to Snowflake")
        except Exception as e:
            print(f"[ERROR] Failed to connect to Snowflake: {e}")
            sys.exit(1)
    
    def _create_table_from_ddl(self, ddl_file):
        """Create table using DDL file."""
        try:
            with open(ddl_file, 'r') as f:
                ddl = f.read()
            
            self.cursor.execute(ddl)
            return True
        except Exception as e:
            print(f"  ⚠️  DDL execution: {str(e)[:100]}")
            return False
    
    def _get_row_count(self, table_name):
        """Get current row count in table."""
        try:
            self.cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
            return self.cursor.fetchone()[0]
        except:
            return None
    
    def _create_audit_table(self):
        """Create OPS schema and audit log table if they don't exist."""
        try:
            # Create OPS schema if it doesn't exist
            create_schema_sql = "CREATE SCHEMA IF NOT EXISTS JAFFELSHOP_ECOM.OPS"
            self.cursor.execute(create_schema_sql)
            logging.info("OPS schema created or already exists")
            
            # Create audit table in OPS schema
            audit_ddl = """
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
            """
            self.cursor.execute(audit_ddl)
            logging.info("Audit table created or already exists in JAFFELSHOP_ECOM.OPS.INGESTION_AUDIT_LOG")
        except Exception as e:
            logging.warning(f"Could not create audit table: {e}")
    
    def _log_audit(self, audit_data):
        """Insert audit log entry into Snowflake OPS schema."""
        try:
            # Escape single quotes in string fields
            def escape_sql(val):
                if val is None:
                    return 'NULL'
                return str(val).replace("'", "''")
            
            audit_insert = f"""
            INSERT INTO JAFFELSHOP_ECOM.OPS.INGESTION_AUDIT_LOG 
            (LOAD_ID, TARGET_DATABASE, TARGET_SCHEMA, TARGET_TABLE, LOAD_TYPE, SOURCE_DATA_DIR,
             TOTAL_FILES_LOADED, TOTAL_ROWS_LOADED, STARTING_ROW_COUNT, ENDING_ROW_COUNT, 
             ROWS_INSERTED, LOAD_START_DATE, LOAD_END_DATE, DATE_RANGE_START, DATE_RANGE_END,
             SUCCESSFUL_LOADS, FAILED_LOADS, DURATION_MINUTES, LOAD_STATUS, ERROR_MESSAGE)
            VALUES (
                '{escape_sql(audit_data['load_id'])}',
                '{escape_sql(audit_data['database'])}',
                '{escape_sql(audit_data['schema'])}',
                '{escape_sql(audit_data['target_table'])}',
                '{escape_sql(audit_data['load_type'])}',
                '{escape_sql(audit_data['source_dir'])}',
                {audit_data['total_files']},
                {audit_data['total_rows']},
                {audit_data['start_count']},
                {audit_data['end_count']},
                {audit_data['rows_inserted']},
                '{escape_sql(audit_data['load_start'])}',
                '{escape_sql(audit_data['load_end'])}',
                '{escape_sql(audit_data['date_range_start'])}',
                '{escape_sql(audit_data['date_range_end'])}',
                {audit_data['successful']},
                {audit_data['failed']},
                {audit_data['duration_minutes']},
                '{escape_sql(audit_data['status'])}',
                {f"'{escape_sql(audit_data['error_message'])}'" if audit_data['error_message'] else 'NULL'}
            )
            """
            self.cursor.execute(audit_insert)
            logging.info(f"Audit log entry inserted with LOAD_ID: {audit_data['load_id']}")
        except Exception as e:
            logging.error(f"Failed to insert audit log: {e}")
    
    def _count_csv_rows(self, folder_path):
        """Count rows in CSV file."""
        csv_file = None
        if Path(folder_path, 'RAW_ORDERS.csv').exists():
            csv_file = Path(folder_path, 'RAW_ORDERS.csv')
        elif Path(folder_path, 'RAW_ITEMS.csv').exists():
            csv_file = Path(folder_path, 'RAW_ITEMS.csv')
        
        if not csv_file:
            return 0
        
        try:
            with open(csv_file, 'r', encoding='utf-8', errors='ignore') as f:
                return sum(1 for _ in f) - 1  # Subtract 1 for header
        except:
            return 0
    
    def load_day(self, folder_path, table_name, is_first_load=False):
        """Load a single daily folder."""
        folder = Path(folder_path)
        date_str = folder.name
        
        try:
            # Use sys.executable to run in same environment
            cmd = [
                sys.executable,
                'import_snowflake_table.py',
                '--config', self.config_path,
                '--folder', str(folder),
                '--database', self.database,
                '--schema', self.schema
            ]
            
            # Use --replace-table only for first load
            if is_first_load:
                cmd.append('--replace-table')
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=300
            )
            
            if result.returncode != 0:
                return False, f"Load failed: {result.stderr[:100]}"
            
            # Count rows in CSV
            csv_rows = self._count_csv_rows(folder)
            
            # Get current table count
            db_rows = self._get_row_count(table_name)
            
            self.load_stats.append({
                'date': date_str,
                'csv_rows': csv_rows,
                'cumulative_rows': db_rows,
                'status': 'success',
                'timestamp': datetime.now().isoformat()
            })
            
            return True, None
            
        except subprocess.TimeoutExpired:
            return False, "Timeout (>5 mins)"
        except Exception as e:
            return False, str(e)
    
    def load_incremental(self, data_dir, table_type='ORDERS', start_date=None, end_date=None, delay=0):
        """
        Load incremental data from daily folders.
        
        Args:
            data_dir: Directory containing daily folders (e.g., 'RAW_DAILY_ORDERS')
            table_type: 'ORDERS' or 'ITEMS'
            start_date: Start date (YYYYMMDD format), optional
            end_date: End date (YYYYMMDD format), optional
            delay: Delay between loads (seconds), optional
        """
        
        # Generate unique load ID for audit tracking
        load_id = f"{table_type}_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{str(uuid.uuid4())[:8]}"
        
        self.table_type = table_type  # Store table_type for validation
        table_name = f"RAW_{table_type}"
        data_path = Path(data_dir)
        
        # Initialize audit data
        audit_data = {
            'load_id': load_id,
            'database': self.database,
            'schema': self.schema,
            'target_table': table_name,
            'source_dir': str(data_path.resolve()).replace('\\', '/'),
            'load_type': 'INCREMENTAL',
            'total_files': 0,
            'total_rows': 0,
            'start_count': 0,
            'end_count': 0,
            'rows_inserted': 0,
            'load_start': datetime.now().isoformat(),
            'load_end': None,
            'date_range_start': None,
            'date_range_end': None,
            'successful': 0,
            'failed': 0,
            'duration_minutes': 0,
            'status': 'IN_PROGRESS',
            'error_message': None
        }
        
        if not data_path.exists():
            print(f"[ERROR] Directory not found: {data_dir}")
            audit_data['status'] = 'FAILED'
            audit_data['error_message'] = f"Directory not found: {data_dir}"
            audit_data['load_end'] = datetime.now().isoformat()
            self._log_audit(audit_data)
            return
        
        # Get all daily folders
        folders = sorted([f for f in data_path.iterdir() if f.is_dir()])
        
        # Filter by date range if provided
        if start_date:
            folders = [f for f in folders if f.name >= start_date]
        if end_date:
            folders = [f for f in folders if f.name <= end_date]
        
        if not folders:
            print(f"[ERROR] No folders found in {data_dir}")
            audit_data['status'] = 'FAILED'
            audit_data['error_message'] = f"No folders found in {data_dir}"
            audit_data['load_end'] = datetime.now().isoformat()
            self._log_audit(audit_data)
            return
        
        print(f"\n{'='*80}")
        print(f"[LOAD] INCREMENTAL LOAD: {table_type}")
        print(f"[ID]   Load ID: {load_id}")
        print(f"{'='*80}")
        print(f"Loading {len(folders):,} daily folders")
        print(f"Date range: {folders[0].name} to {folders[-1].name}")
        if delay > 0:
            print(f"Delay between loads: {delay}s")
        print(f"{'='*80}\n")
        
        # Update audit data with date range
        audit_data['date_range_start'] = folders[0].name
        audit_data['date_range_end'] = folders[-1].name
        audit_data['total_files'] = len(folders)
        
        # Get starting row count
        start_count = self._get_row_count(table_name)
        if start_count is None:
            print(f"Table {table_name} doesn't exist yet (will create on first load)")
            start_count = 0
            audit_data['load_type'] = 'FULL_LOAD'
        else:
            print(f"Starting row count: {start_count:,}")
            audit_data['load_type'] = 'INCREMENTAL'
        
        audit_data['start_count'] = start_count
        print()
        
        start_time = datetime.now()
        successful = 0
        failed = 0
        total_rows = 0
        
        # Load each day
        for idx, folder in enumerate(folders, 1):
            date_str = folder.name
            progress = f"[{idx:>4,}/{len(folders):,}]"
            is_first_load = (idx == 1)  # Use --replace-table for first load
            
            # Load the day
            success, error = self.load_day(str(folder), table_name, is_first_load)
            
            if success:
                successful += 1
                csv_rows = self._count_csv_rows(str(folder))
                total_rows += csv_rows
                db_rows = self.load_stats[-1].get('cumulative_rows', 0)
                
                if db_rows and db_rows > 0:
                    print(f"  {progress} [OK] {date_str}: {csv_rows:>6,} rows -> {db_rows:>10,} cumulative")
                else:
                    print(f"  {progress} [WARN] {date_str}: {csv_rows:>6,} rows (rows not counted in DB)")
            else:
                failed += 1
                print(f"  {progress} [FAIL] {date_str}: {error}")
            
            # Delay between loads (to simulate real-time ingestion)
            if delay > 0 and idx < len(folders):
                time.sleep(delay)
        
        # Print summary
        end_time = datetime.now()
        duration = end_time - start_time
        final_count = self._get_row_count(table_name)
        rows_loaded = final_count - start_count if final_count and start_count else final_count or 0
        
        print(f"\n{'='*80}")
        print(f"[SUMMARY] LOAD SUMMARY: {table_type}")
        print(f"{'='*80}")
        print(f"Load ID:         {load_id}")
        print(f"Total days:      {len(folders):,}")
        print(f"Successful:      {successful:,}")
        print(f"Failed:          {failed:,}")
        print(f"Duration:        {duration.total_seconds()/60:.1f} minutes")
        print(f"Starting rows:   {start_count:>10,}")
        print(f"Final rows:      {final_count:>10,}")
        print(f"Rows loaded:     {rows_loaded:>10,}")
        print(f"{'='*80}\n")
        
        # Update audit data
        audit_data['total_rows'] = total_rows
        audit_data['end_count'] = final_count if final_count else 0
        audit_data['rows_inserted'] = rows_loaded
        audit_data['successful'] = successful
        audit_data['failed'] = failed
        audit_data['duration_minutes'] = duration.total_seconds() / 60
        audit_data['load_end'] = datetime.now().isoformat()
        audit_data['status'] = 'SUCCESS' if failed == 0 else 'PARTIAL_SUCCESS'
        
        # Log audit entry
        self._log_audit(audit_data)
        
        return successful, failed
    
    def validate_load(self):
        """Validate loaded data for the specific table type that was loaded."""
        print(f"\n{'='*80}")
        print("[VALIDATION] VALIDATION REPORT")
        print(f"{'='*80}\n")
        
        if not self.table_type:
            print("[ERROR] No table type loaded. Cannot validate.")
            return
        
        try:
            table_name = f"RAW_{self.table_type}"
            
            if self.table_type == 'ORDERS':
                # Check ORDERS
                self.cursor.execute("SELECT COUNT(*) FROM RAW_ORDERS")
                result = self.cursor.fetchone()
                orders_count = result[0] if result else 0
                
                # Expected counts
                expected_orders = 1_475_508
                orders_pct = (orders_count / expected_orders * 100) if expected_orders > 0 else 0
                
                print(f"ORDERS:  {orders_count:>10,} / {expected_orders:>10,} ({orders_pct:>5.1f}%)")
                
                # Check for duplicates
                self.cursor.execute("""
                    SELECT COUNT(*) 
                    FROM (
                        SELECT ID, COUNT(*) as cnt
                        FROM RAW_ORDERS
                        GROUP BY ID
                        HAVING COUNT(*) > 1
                    )
                """)
                orders_dups = self.cursor.fetchone()[0]
                print(f"\nDuplicates in ORDERS: {orders_dups}")
                
                # Check date range
                self.cursor.execute("SELECT MIN(ORDERED_AT), MAX(ORDERED_AT) FROM RAW_ORDERS")
                result = self.cursor.fetchone()
                if result:
                    min_date, max_date = result
                    print(f"\nDate range:")
                    print(f"  ORDERS: {min_date} to {max_date}")
            
            elif self.table_type == 'ITEMS':
                # Check ITEMS
                self.cursor.execute("SELECT COUNT(*) FROM RAW_ITEMS")
                result = self.cursor.fetchone()
                items_count = result[0] if result else 0
                
                # Expected counts
                expected_items = 2_207_518
                items_pct = (items_count / expected_items * 100) if expected_items > 0 else 0
                
                print(f"ITEMS:   {items_count:>10,} / {expected_items:>10,} ({items_pct:>5.1f}%)")
                
                # Check for duplicates
                self.cursor.execute("""
                    SELECT COUNT(*) 
                    FROM (
                        SELECT ID, COUNT(*) as cnt
                        FROM RAW_ITEMS
                        GROUP BY ID
                        HAVING COUNT(*) > 1
                    )
                """)
                items_dups = self.cursor.fetchone()[0]
                print(f"\nDuplicates in ITEMS: {items_dups}")
            
            print(f"\n{'='*80}\n")
            
        except Exception as e:
            print(f"[ERROR] Validation error: {e}\n")
    
    def save_stats(self, output_file='load_stats.json'):
        """Save load statistics to JSON."""
        with open(output_file, 'w') as f:
            json.dump(self.load_stats, f, indent=2)
        print(f"[INFO] Stats saved to {output_file}")
    
    def close(self):
        """Close Snowflake connection."""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()


def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Incremental data loader for Snowflake',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Load all ORDERS incremental data
  python incremental_loader.py --type ORDERS --table RAW_DAILY_ORDERS
  
  # Load ITEMS with 2-second delay between days
  python incremental_loader.py --type ITEMS --table RAW_DAILY_ITEMS --delay 2
  
  # Load specific date range (first week)
  python incremental_loader.py --type ORDERS --table RAW_DAILY_ORDERS \\
    --start-date 20211231 --end-date 20220106
  
  # Load and validate
  python incremental_loader.py --type ORDERS --table RAW_DAILY_ORDERS --validate
  
  # Load with statistics saved
  python incremental_loader.py --type ORDERS --table RAW_DAILY_ORDERS \\
    --save-stats orders_load_stats.json
        """
    )
    
    parser.add_argument(
        '--type',
        choices=['ORDERS', 'ITEMS'],
        default='ORDERS',
        help='Data type to load (default: ORDERS)'
    )
    parser.add_argument(
        '--table',
        default='RAW_DAILY_ORDERS',
        help='Directory containing daily folders (default: RAW_DAILY_ORDERS)'
    )
    parser.add_argument(
        '--config',
        default='./config.ini',
        help='Path to config.ini (default: ./config.ini)'
    )
    parser.add_argument(
        '--database',
        default='EDWH',
        help='Snowflake database (default: EDWH)'
    )
    parser.add_argument(
        '--schema',
        default='RAW',
        help='Snowflake schema (default: RAW)'
    )
    parser.add_argument(
        '--start-date',
        help='Start date (YYYYMMDD format, optional)'
    )
    parser.add_argument(
        '--end-date',
        help='End date (YYYYMMDD format, optional)'
    )
    parser.add_argument(
        '--delay',
        type=int,
        default=0,
        help='Delay between loads in seconds (default: 0)'
    )
    parser.add_argument(
        '--validate',
        action='store_true',
        help='Validate loaded data after load'
    )
    parser.add_argument(
        '--save-stats',
        help='Save load statistics to JSON file (optional)'
    )
    
    args = parser.parse_args()
    
    # Create loader
    loader = IncrementalLoader(
        config_path=args.config,
        database=args.database,
        schema=args.schema
    )
    
    try:
        # Create audit table
        loader._create_audit_table()
        
        # Load incremental data
        loader.load_incremental(
            data_dir=args.table,
            table_type=args.type,
            start_date=args.start_date,
            end_date=args.end_date,
            delay=args.delay
        )
        
        # Validate if requested
        if args.validate:
            loader.validate_load()
        
        # Save stats if requested
        if args.save_stats:
            loader.save_stats(args.save_stats)
    
    finally:
        loader.close()


if __name__ == '__main__':
    main()
