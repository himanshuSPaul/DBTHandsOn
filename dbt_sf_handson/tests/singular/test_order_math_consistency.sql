-- Custom Test: Verify order math consistency (subtotal + tax = total)
-- Purpose: Financial validation to ensure no rounding errors or data corruption
-- Severity: CRITICAL - Orders with incorrect totals could impact financial reporting

SELECT 
  order_id,
  order_subtotal,
  order_tax_paid,
  order_total,
  (order_subtotal + order_tax_paid) AS calculated_total,
  ABS((order_subtotal + order_tax_paid) - order_total) AS difference
FROM {{ ref('mart_orders') }}
WHERE ABS((order_subtotal + order_tax_paid) - order_total) > 0.01
