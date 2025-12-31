-- Custom Test: Verify tax rates are reasonable
-- Purpose: Flag orders with unusual tax rates that may indicate data quality issues
-- Severity: WARNING - High tax rates may be valid but should be monitored

SELECT 
  order_id,
  order_total,
  tax_rate_percent,
  'WARNING: High tax rate - verify this is correct' AS note
FROM {{ ref('mart_orders') }}
WHERE tax_rate_percent IS NOT NULL
  AND (tax_rate_percent < 0 OR tax_rate_percent > 15)
ORDER BY tax_rate_percent DESC
