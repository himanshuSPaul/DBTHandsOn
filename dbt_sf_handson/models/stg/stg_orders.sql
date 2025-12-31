{{ config(
  materialized='incremental',
  unique_key='ORDER_ID',
  on_schema_change='fail',
  incremental_strategy='merge'
) }}

-- STAGING LAYER: stg_orders (INCREMENTAL)
-- Purpose: Clean and standardize raw order data
-- Optimization: Only process new orders (faster incremental builds)

WITH RAW_ORDERS AS (
SELECT * FROM {{ source('raw', 'raw_orders') }}
)

SELECT  
    ID as ORDER_ID, 
    CUSTOMER as ORDER_CUSTOMER, 
    ORDERED_AT, 
    STORE_ID AS ORDER_STORE_ID, 
    SUBTOTAL AS ORDER_SUBTOTAL, 
    TAX_PAID AS ORDER_TAX_PAID, 
    ORDER_TOTAL 
FROM RAW_ORDERS
WHERE ID IS NOT NULL

-- INCREMENTAL FILTER: Only process new orders on subsequent runs
{% if execute_macros %}
  {% if is_incremental() %}
    AND ORDERED_AT >= (SELECT COALESCE(MAX(ORDERED_AT), '1900-01-01') FROM {{ this }})
  {% endif %}
{% endif %}
