{{ config(materialized='table') }}

-- MART LAYER: mart_customers
-- Purpose: Customer 360 view for business users and BI tools
-- Business Logic: Single source of truth for all customer analytics
-- Key Dimensions: Customer profile, purchase behavior, segmentation, lifetime value

SELECT  
    CUSTOMER_ID,
    CUSTOMER_NAME,
    FIRST_NAME,
    LAST_NAME,
    MIDDLE_NAME,
    TOTAL_ORDERS,
    CUSTOMER_LIFETIME_VALUE,
    AVG_ORDER_VALUE,
    FIRST_ORDER_DATE,
    LAST_ORDER_DATE,
    DAYS_SINCE_FIRST_ORDER as CUSTOMER_TENURE_DAYS,
    DAYS_SINCE_LAST_ORDER as RECENCY_DAYS,
    CUSTOMER_STATUS,
    CUSTOMER_SEGMENT,
    -- Additional business metrics
    CASE 
        WHEN TOTAL_ORDERS > 0 THEN CUSTOMER_LIFETIME_VALUE / TOTAL_ORDERS
        ELSE 0
    END as CUSTOMER_VALUE_PER_ORDER,
    CASE 
        WHEN DAYS_SINCE_FIRST_ORDER > 0 THEN TOTAL_ORDERS / (DAYS_SINCE_FIRST_ORDER / 365.0)
        ELSE 0
    END as CUSTOMER_ORDER_FREQUENCY_ANNUAL,
    PROCESSED_AT as LAST_UPDATED
FROM {{ ref('int_customer_orders') }}
WHERE CUSTOMER_ID IS NOT NULL
