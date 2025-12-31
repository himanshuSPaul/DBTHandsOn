{{ config(materialized='view') }}

-- INTERMEDIATE LAYER: int_customer_orders
-- Purpose: Aggregate customer-level order metrics for mart layer consumption
-- Business Logic: Create customer summary with order counts, totals, and behavior metrics

WITH STAG_CUSTOMERS AS (
    SELECT * FROM {{ ref('stg_customers') }}
),
STAG_ORDERS AS (
    SELECT * FROM {{ ref('stg_orders') }}
),
ORDERS_AGG AS (
    SELECT  
        ORDER_CUSTOMER,
        COUNT(DISTINCT ORDER_ID) as TOTAL_ORDERS,
        SUM(ORDER_TOTAL) as CUSTOMER_LIFETIME_VALUE,
        AVG(ORDER_TOTAL) as AVG_ORDER_VALUE,
        MIN(ORDERED_AT) as FIRST_ORDER_DATE,
        MAX(ORDERED_AT) as LAST_ORDER_DATE,
        DATEDIFF(DAY, MIN(ORDERED_AT), MAX(ORDERED_AT)) as DAYS_SINCE_FIRST_ORDER,
        DATEDIFF(DAY, MAX(ORDERED_AT), CURRENT_DATE()) as DAYS_SINCE_LAST_ORDER
    FROM STAG_ORDERS
    GROUP BY ORDER_CUSTOMER
)

SELECT  
    c.CUSTOMER_ID,
    c.CUSTOMER_NAME,
    c.FIRST_NAME,
    c.MIDDLE_NAME,
    c.LAST_NAME,
    o.TOTAL_ORDERS,
    o.CUSTOMER_LIFETIME_VALUE,
    o.AVG_ORDER_VALUE,
    o.FIRST_ORDER_DATE,
    o.LAST_ORDER_DATE,
    o.DAYS_SINCE_FIRST_ORDER,
    o.DAYS_SINCE_LAST_ORDER,
    CASE 
        WHEN o.DAYS_SINCE_LAST_ORDER <= 30 THEN 'Active'
        WHEN o.DAYS_SINCE_LAST_ORDER <= 90 THEN 'At Risk'
        ELSE 'Inactive'
    END as CUSTOMER_STATUS,
    CASE 
        WHEN o.TOTAL_ORDERS >= 10 THEN 'High Value'
        WHEN o.TOTAL_ORDERS >= 5 THEN 'Medium Value'
        ELSE 'Low Value'
    END as CUSTOMER_SEGMENT,
    CURRENT_TIMESTAMP() as PROCESSED_AT
FROM STAG_CUSTOMERS c
LEFT JOIN ORDERS_AGG o ON c.CUSTOMER_ID = o.ORDER_CUSTOMER
