{{ config(
  materialized='incremental',
  unique_key='ITEM_ID',
  on_schema_change='fail',
  incremental_strategy='merge'
) }}

-- STAGING LAYER: stg_items (INCREMENTAL)
-- Purpose: Clean and transform raw order items data
-- Optimization: Only process new items (faster incremental builds)

WITH ITEMS AS (
SELECT 
    ITEM_ID,
    ITEM_ORDER_ID,
    ITEM_PRODUCT_SKU
FROM {{ source('raw', 'raw_items') }}
)

SELECT 
    it.ITEM_ID,
    it.ITEM_ORDER_ID,
    it.ITEM_PRODUCT_SKU as ITEM_SKU
FROM ITEMS it
WHERE it.ITEM_ID IS NOT NULL

-- INCREMENTAL FILTER: Only process new items on subsequent runs
{% if execute_macros %}
  {% if is_incremental() %}
    AND it.ITEM_ID > (SELECT COALESCE(MAX(ITEM_ID), 0) FROM {{ this }})
  {% endif %}
{% endif %}