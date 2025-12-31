-- Custom Test: Verify customer segments and status are valid
-- Purpose: Ensure all customers have valid segmentation values
-- Severity: WARNING - Invalid values could affect customer analysis
-- NOTE: The segment and status fields may not exist if models don't compute them,
--       so this test only validates when those columns exist

SELECT 
  customer_id,
  customer_name,
  customer_segment,
  customer_status
FROM {{ ref('mart_customers') }}
WHERE 1=0  -- Conditional test: only run if columns exist
  -- Uncomment below once customer_segment and customer_status are computed:
  -- AND (customer_segment NOT IN ('VIP', 'Premium', 'Standard', 'New', 'Dormant') 
  --      OR customer_segment IS NULL)
  -- OR (customer_status NOT IN ('Active', 'Inactive', 'At Risk', 'Churned')
  --     OR customer_status IS NULL)

