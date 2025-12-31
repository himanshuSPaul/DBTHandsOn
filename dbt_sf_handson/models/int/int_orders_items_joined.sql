{{ config(materialized='view') }}

-- INTERMEDIATE LAYER: int_orders_items_joined
-- Purpose: Join orders with their line items and products to create enriched order detail records
-- Business Logic: Combine order, item, and product information for deeper analysis

WITH STAG_ORDERS AS (
    SELECT * FROM {{ ref('stg_orders') }}
),
STAG_ITEMS AS (
    SELECT * FROM {{ ref('stg_items') }}
),
STAG_PRODUCTS AS (
    SELECT * FROM {{ ref('stg_products') }}
)

SELECT  
    o.ORDER_ID,
    o.ORDER_CUSTOMER,
    i.ITEM_ID,
    i.ITEM_SKU,
    p.PRODUCT_NAME,
    p.PRODUCT_TYPE,
    p.PRODUCT_PRICE,
    o.ORDERED_AT,
    o.ORDER_STORE_ID,
    o.ORDER_SUBTOTAL,
    o.ORDER_TAX_PAID,
    o.ORDER_TOTAL,
    -- Calculate item price (assuming price hasn't changed - use current product price as proxy)
    p.PRODUCT_PRICE as ITEM_PRICE,
    CASE 
        WHEN o.ORDER_SUBTOTAL > 0 THEN (CAST(i.ITEM_ID AS FLOAT) * p.PRODUCT_PRICE / NULLIF(o.ORDER_SUBTOTAL, 0))
        ELSE 0
    END as ITEM_AMOUNT,
    ROW_NUMBER() OVER (PARTITION BY o.ORDER_ID ORDER BY i.ITEM_ID) as ITEM_SEQUENCE
FROM STAG_ORDERS o
LEFT JOIN STAG_ITEMS i ON o.ORDER_ID = i.ITEM_ORDER_ID
LEFT JOIN STAG_PRODUCTS p ON i.ITEM_SKU = p.PRODUCT_SKU
