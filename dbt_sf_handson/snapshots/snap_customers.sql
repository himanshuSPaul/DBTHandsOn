{% snapshot snap_customers %}
  {{ config(
    unique_key='customer_id',
    strategy='check',
    check_cols='all'
  ) }}
  
  -- SNAPSHOT: snap_customers
  -- Purpose: Track historical changes to customer profile data (SCD Type 2)
  -- Grain: One row per customer per version
  -- Strategy: Check (detects any column value changes)
  -- Key Use Cases:
  --   ✓ When did customer X change their name?
  --   ✓ What was customer email at time of purchase?
  --   ✓ Historical customer profile analysis
  -- 
  -- Metadata Columns (auto-added by dbt):
  --   dbt_scd_id: Unique identifier for each SCD record
  --   dbt_updated_at: When dbt processed the change
  --   dbt_valid_from: When this version became active
  --   dbt_valid_to: When this version ended (NULL = current)
  --   dbt_is_deleted: TRUE if customer was deleted from source
  --
  -- Documentation: See SNAPSHOTS_GUIDE.md
  
  SELECT 
    CUSTOMER_ID,
    CUSTOMER_NAME
  FROM {{ source('raw', 'raw_customers') }}
  WHERE CUSTOMER_ID IS NOT NULL
  
  {% endsnapshot %}
