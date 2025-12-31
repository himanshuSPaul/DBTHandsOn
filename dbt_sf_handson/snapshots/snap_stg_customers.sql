{% snapshot snap_stg_customers %}
  {{ config(
    unique_key='customer_id',
    strategy='check',
    check_cols='all',
    tags=['snapshot', 'customer', 'critical']
  ) }}
  
  -- SNAPSHOT: snap_stg_customers
  -- Purpose: Track historical changes to staged customer profile data (SCD Type 2)
  -- Grain: One row per customer per version
  -- Strategy: Check (detects any column value changes)
  -- Data Source: Staged customer data (stg_customers)
  -- 
  -- Key Use Cases:
  --   ✓ When did customer X change their name?
  --   ✓ How has customer data quality evolved (valid_name changes)?
  --   ✓ Historical customer profile analysis
  --   ✓ Track customer data lineage through transformation
  --   ✓ Audit trail for data governance
  --
  -- Metadata Columns (auto-added by dbt):
  --   dbt_scd_id: Unique identifier for each SCD record
  --   dbt_updated_at: When dbt processed the change
  --   dbt_valid_from: When this version became active
  --   dbt_valid_to: When this version ended (NULL = current)
  --   dbt_is_deleted: TRUE if customer was deleted from source
  --
  -- Example Query:
  -- SELECT 
  --   customer_id,
  --   customer_name,
  --   first_name,
  --   last_name,
  --   is_valid_name,
  --   dbt_valid_from,
  --   dbt_valid_to
  -- FROM snap_stg_customers
  -- WHERE customer_id = 123
  -- ORDER BY dbt_valid_from DESC
  --
  -- Documentation: See SNAPSHOTS_GUIDE.md
  
  SELECT 
    customer_id,
    customer_name,
    customer_name_length,
    first_name,
    middle_name,
    last_name,
    is_valid_name,
    created_at,
    updated_at
  FROM {{ ref('stg_customers') }}
  WHERE customer_id IS NOT NULL

{% endsnapshot %}
