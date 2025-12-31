-- Singular Test: Verify no negative amounts in orders
-- Purpose: Business rule - all monetary amounts should be >= 0
-- Scope: Raw order table validation

SELECT 
    id as order_id,
    customer,
    subtotal,
    tax_paid,
    order_total
FROM {{ source('raw', 'raw_orders') }}
WHERE subtotal < 0 
   OR tax_paid < 0 
   OR order_total < 0
-- If this query returns rows, the test fails (negative amounts exist)
