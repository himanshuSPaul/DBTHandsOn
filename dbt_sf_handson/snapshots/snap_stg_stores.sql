{% snapshot snap_stg_stores %}
  {{ config(
    unique_key='store_id',
    strategy='check',
    check_cols='all',
    tags=['snapshot', 'stores', 'critical']
  ) }}
  
  -- SNAPSHOT: snap_stg_stores
  -- Purpose: Track historical changes to staged store master data (SCD Type 2)
  -- Grain: One row per store per version
  -- Strategy: Check (detects any column value changes)
  -- Data Source: Staged store data (stg_stores)
  -- 
  -- Key Use Cases:
  --   ✓ When did store X open or change location?
  --   ✓ Historical tax rate changes per store
  --   ✓ Store master data lineage tracking
  --   ✓ Store operating hours history
  --   ✓ Store attributes audit trail
  --
  -- Metadata Columns (auto-added by dbt):
  --   dbt_scd_id: Unique identifier for each SCD record
  --   dbt_updated_at: When dbt processed the change
  --   dbt_valid_from: When this version became active
  --   dbt_valid_to: When this version ended (NULL = current)
  --   dbt_is_deleted: TRUE if store was deleted from source
  --
  -- Example Query (Tax rate history for a store):
  -- SELECT 
  --   store_id,
  --   store_name,
  --   store_tax_rate,
  --   dbt_valid_from,
  --   dbt_valid_to
  -- FROM snap_stg_stores
  -- WHERE store_id = 1
  -- ORDER BY dbt_valid_from DESC
  --
  -- Example Query (Which stores changed in last 30 days):
  -- SELECT 
  --   store_id,
  --   store_name,
  --   dbt_valid_from,
  --   dbt_updated_at
  -- FROM snap_stg_stores
  -- WHERE dbt_updated_at >= CURRENT_DATE - 30
  -- ORDER BY dbt_updated_at DESC
  --
  -- Documentation: See SNAPSHOTS_GUIDE.md
  
  SELECT 
    store_id,
    store_name,
    store_opened_at,
    store_tax_rate
  FROM {{ ref('stg_stores') }}
  WHERE store_id IS NOT NULL

{% endsnapshot %}
