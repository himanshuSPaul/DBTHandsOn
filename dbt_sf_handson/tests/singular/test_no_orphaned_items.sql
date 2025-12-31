-- Singular Test: Verify no orphaned items (items without matching orders)
-- Purpose: Referential integrity check between orders and items
-- Scope: Data consistency across STG layer

SELECT 
    i.item_id,
    i.item_order_id,
    o.order_id,
    COUNT(*) as orphan_count
FROM {{ ref('stg_items') }} i
LEFT JOIN {{ ref('stg_orders') }} o ON i.item_order_id = o.order_id
WHERE o.order_id IS NULL
GROUP BY i.item_id, i.item_order_id, o.order_id
-- If this query returns rows, the test fails (orphaned items exist)
