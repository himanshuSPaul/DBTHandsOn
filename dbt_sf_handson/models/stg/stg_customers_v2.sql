-- Version 2: Enhanced stg_customers (CURRENT - RECOMMENDED)
-- Purpose: Customer data with improved name handling, validation, and metadata
-- Status: CURRENT - recommended for all new models and migrations
-- Features:
--   - Better name parsing (handles hyphens, apostrophes)
--   - Added customer_name_length for data quality
--   - Added is_valid_name flag for data validation
--   - Added metadata (updated_at tracking)
-- Migration Path: Existing models should update refs to version 2
-- See VERSIONING_GUIDE.md for implementation details

{{ config(
  meta={
    'version': 2,
    'status': 'current',
    'deprecation_date': None,
    'description': 'Enhanced name parsing with validation'
  }
) }}

WITH CUSTOMERS AS (
    SELECT 
        CUSTOMER_ID,
        CUSTOMER_NAME
    FROM {{ source('raw', 'raw_customers') }}
)

, PARSED_NAMES AS (
    SELECT  
        CUSTOMER_ID,
        CUSTOMER_NAME,
        LENGTH(CUSTOMER_NAME) as CUSTOMER_NAME_LENGTH,
        -- More robust name parsing that handles hyphens and apostrophes
        SPLIT_PART(REGEXP_REPLACE(CUSTOMER_NAME, '-', ' '), ' ', 1) as FIRST_NAME,
        CASE 
            WHEN ARRAY_SIZE(SPLIT(REGEXP_REPLACE(CUSTOMER_NAME, '-', ' '), ' ')) = 3 
                THEN SPLIT_PART(REGEXP_REPLACE(CUSTOMER_NAME, '-', ' '), ' ', 2)
            ELSE NULL
        END as MIDDLE_NAME,
        SPLIT_PART(REGEXP_REPLACE(CUSTOMER_NAME, '-', ' '), ' ', -1) as LAST_NAME,
        -- Data quality indicators
        CASE 
            WHEN CUSTOMER_ID IS NOT NULL 
                AND CUSTOMER_NAME IS NOT NULL 
                AND LENGTH(CUSTOMER_NAME) > 2
                AND LENGTH(SPLIT_PART(CUSTOMER_NAME, ' ', 1)) > 0
                AND LENGTH(SPLIT_PART(CUSTOMER_NAME, ' ', -1)) > 0
            THEN TRUE
            ELSE FALSE
        END as IS_VALID_NAME,
        CURRENT_TIMESTAMP() as CREATED_AT,
        CURRENT_TIMESTAMP() as UPDATED_AT
    FROM CUSTOMERS
)

SELECT  
    CUSTOMER_ID,
    CUSTOMER_NAME,
    FIRST_NAME,
    MIDDLE_NAME,
    LAST_NAME,
    CUSTOMER_NAME_LENGTH,
    IS_VALID_NAME,
    CREATED_AT,
    UPDATED_AT
FROM PARSED_NAMES
WHERE CUSTOMER_ID IS NOT NULL
