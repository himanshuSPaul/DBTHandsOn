-- Singular Test: Verify stg_customers name splitting produces valid names
-- Purpose: Ensure FIRST_NAME, MIDDLE_NAME, LAST_NAME are populated correctly
-- Scope: Staging layer transformation validation

SELECT 
    customer_id,
    customer_name,
    first_name,
    middle_name,
    last_name,
    (first_name IS NULL OR first_name = '') as invalid_first,
    (last_name IS NULL OR last_name = '') as invalid_last
FROM {{ ref('stg_customers') }}
WHERE first_name IS NULL OR first_name = ''
   OR last_name IS NULL OR last_name = ''
-- If this query returns rows, the test fails (invalid name parts)
