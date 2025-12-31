-- Custom Test: Verify order segments are valid
-- Purpose: Ensure all orders have been assigned correct value and type segments
-- Severity: ERROR - Invalid segments could affect analytics and reporting

SELECT 
  order_id,
  order_value_segment,
  order_type
FROM {{ ref('mart_orders') }}
WHERE (order_value_segment NOT IN ('High Value', 'Medium Value', 'Low Value') 
       OR order_value_segment IS NULL)
   OR (order_type NOT IN ('Bulk Order', 'Multi-Item', 'Single Item')
       OR order_type IS NULL)
