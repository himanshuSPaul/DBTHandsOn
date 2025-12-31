-- Custom Test: Verify all items reference valid orders
-- Purpose: Data referential integrity check  
-- Severity: CRITICAL - Orphaned items indicate data corruption

SELECT 
  i.item_id,
  i.item_order_id,
  i.item_sku
FROM {{ ref('stg_items') }} i
LEFT JOIN {{ ref('stg_orders') }} o ON i.item_order_id = o.order_id
WHERE o.order_id IS NULL
