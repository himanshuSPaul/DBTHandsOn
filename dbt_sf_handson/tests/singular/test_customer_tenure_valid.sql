-- Custom Test: Verify customer tenure is logical (non-negative)
-- Purpose: Validate that customer_tenure_days doesn't have nonsensical negative values
-- Severity: ERROR - Negative tenure indicates data quality issues

SELECT 
  customer_id,
  customer_name,
  customer_tenure_days
FROM {{ ref('mart_customers') }}
WHERE customer_tenure_days < 0
