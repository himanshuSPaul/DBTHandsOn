-- Version 1: Legacy stg_customers (DEPRECATED)
-- Purpose: Basic customer data with name splitting
-- Status: Deprecated - will be removed June 30, 2025
-- Replacement: Use stg_customers.sql (v2) for new projects
-- See VERSIONING_GUIDE.md for migration path

{{ config(
  meta={
    'version': 1,
    'status': 'deprecated',
    'deprecation_date': '2025-06-30',
    'description': 'Legacy version - basic name splitting'
  }
) }}

WITH CUSTOMERS AS (
    SELECT 
        CUSTOMER_ID,
        CUSTOMER_NAME
    FROM {{ source('raw', 'raw_customers') }}
)

SELECT  
    CUSTOMER_ID,
    CUSTOMER_NAME,
    SPLIT_PART(CUSTOMER_NAME, ' ', 1) as FIRST_NAME,
    CASE 
        WHEN ARRAY_SIZE(SPLIT(CUSTOMER_NAME, ' ')) = 3 THEN SPLIT_PART(CUSTOMER_NAME, ' ', 2)
        ELSE NULL
    END as MIDDLE_NAME,
    SPLIT_PART(CUSTOMER_NAME, ' ', -1) as LAST_NAME,
    CURRENT_TIMESTAMP() as CREATED_AT
FROM CUSTOMERS
WHERE CUSTOMER_ID IS NOT NULL
