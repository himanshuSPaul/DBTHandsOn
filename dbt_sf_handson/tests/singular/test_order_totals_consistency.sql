-- Singular Test: Verify order totals are consistent
-- Purpose: Ensure ORDER_TOTAL = SUBTOTAL + TAX_PAID
-- Scope: Tests raw order data integrity

SELECT 
    id as order_id,
    subtotal,
    tax_paid,
    order_total,
    (subtotal + tax_paid) as calculated_total
FROM {{ source('raw', 'raw_orders') }}
WHERE order_total != (subtotal + tax_paid)
-- If this query returns rows, the test fails
