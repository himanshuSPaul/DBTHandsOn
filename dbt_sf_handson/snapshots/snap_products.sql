{% snapshot snap_products %}
  {{ config(
    unique_key='sku',
    strategy='check',
    check_cols='all'
  ) }}
  
  -- SNAPSHOT: snap_products
  -- Purpose: Track historical changes to product catalog data (SCD Type 2)
  -- Grain: One row per product per version
  -- Strategy: Check (detects product changes like price updates)
  -- Key Use Cases:
  --   ✓ Track product pricing changes over time
  --   ✓ What was the price of product Y on date Z?
  --   ✓ Historical pricing for revenue reconciliation
  --   ✓ Analyze product catalog evolution
  --
  -- Metadata Columns (auto-added by dbt):
  --   dbt_scd_id: Unique identifier for each SCD record
  --   dbt_updated_at: When dbt processed the change
  --   dbt_valid_from: When this version became active
  --   dbt_valid_to: When this version ended (NULL = current)
  --   dbt_is_deleted: TRUE if product was deleted from source
  --
  -- Refresh Frequency: Daily (captures price/catalog changes)
  -- Documentation: See SNAPSHOTS_GUIDE.md
  
  SELECT 
    SKU,
    NAME,
    TYPE,
    PRICE,
    DESCRIPTION
  FROM {{ source('raw', 'raw_products') }}
  WHERE SKU IS NOT NULL
  
  {% endsnapshot %}
