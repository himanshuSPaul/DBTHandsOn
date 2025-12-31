{% snapshot snap_orders %}
  {{ config(
    unique_key='id',
    strategy='check',
    check_cols='all'
  ) }}
  
  -- SNAPSHOT: snap_orders
  -- Purpose: Track historical changes to order data (SCD Type 2)
  -- Grain: One row per order per version
  -- Strategy: Check (detects order updates)
  -- Key Use Cases:
  --   ✓ Track order changes over time
  --   ✓ What was order state on specific date?
  --   ✓ Analyze order fulfillment changes
  --   ✓ Historical order metrics
  --
  -- Metadata Columns (auto-added by dbt):
  --   dbt_scd_id: Unique identifier for each SCD record
  --   dbt_updated_at: When dbt processed the change
  --   dbt_valid_from: When this version became active
  --   dbt_valid_to: When this version ended (NULL = current)
  --   dbt_is_deleted: TRUE if order was deleted from source
  --
  -- Refresh Frequency: Daily (captures order updates)
  -- Documentation: See SNAPSHOTS_GUIDE.md
  
  SELECT 
    ID,
    CUSTOMER,
    ORDERED_AT,
    STORE_ID,
    SUBTOTAL,
    TAX_PAID,
    ORDER_TOTAL
  FROM {{ source('raw', 'raw_orders') }}
  WHERE ID IS NOT NULL
  
  {% endsnapshot %}
