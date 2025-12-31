-- ============================================================================
-- QUICK SQL SNIPPETS FOR COMMON AD-HOC ANALYSES
-- Copy and paste these snippets, modify filters as needed
-- ============================================================================

-- ============================================================================
-- CUSTOMER QUICK QUERIES
-- ============================================================================

-- Find a specific customer's order history
SELECT * FROM {{ ref('mart_orders_by_customer') }}
WHERE CUSTOMER_NAME LIKE '%[CUSTOMER_NAME]%'
ORDER BY ORDERED_AT DESC;

-- Calculate customer revenue in last 30 days
SELECT 
    CUSTOMER_ID,
    CUSTOMER_NAME,
    COUNT(*) as orders_last_30_days,
    SUM(ORDER_TOTAL) as revenue_last_30_days
FROM {{ ref('mart_orders_by_customer') }}
WHERE ORDERED_AT >= DATEADD(DAY, -30, CURRENT_DATE())
GROUP BY CUSTOMER_ID, CUSTOMER_NAME
ORDER BY revenue_last_30_days DESC;

-- Get customers who haven't purchased in 60+ days
SELECT 
    CUSTOMER_ID,
    CUSTOMER_NAME,
    LAST_ORDER_DATE,
    CUSTOMER_LIFETIME_VALUE,
    TOTAL_ORDERS
FROM {{ ref('mart_customers') }}
WHERE RECENCY_DAYS >= 60
  AND TOTAL_ORDERS > 1
ORDER BY LAST_ORDER_DATE ASC;

-- Count new customers this month
SELECT 
    COUNT(DISTINCT CUSTOMER_ID) as new_customers,
    ROUND(SUM(CUSTOMER_LIFETIME_VALUE), 2) as initial_revenue
FROM {{ ref('mart_customers') }}
WHERE FIRST_ORDER_DATE >= DATE_TRUNC(MONTH, CURRENT_DATE());

-- Find customers who bought exactly X products
SELECT 
    CUSTOMER_ID,
    CUSTOMER_NAME,
    COUNT(DISTINCT ITEM_SKU) as unique_products,
    COUNT(*) as total_items
FROM {{ ref('mart_orders_by_customer') }}
GROUP BY CUSTOMER_ID, CUSTOMER_NAME
HAVING COUNT(DISTINCT ITEM_SKU) = 1;

-- ============================================================================
-- SALES QUICK QUERIES
-- ============================================================================

-- Today's sales summary
SELECT 
    DATE(CURRENT_DATE()) as today,
    COUNT(DISTINCT ORDER_ID) as orders,
    SUM(ORDER_TOTAL) as revenue,
    ROUND(AVG(ORDER_TOTAL), 2) as avg_order_value,
    SUM(ITEMS_IN_ORDER) as items_sold
FROM {{ ref('mart_orders') }}
WHERE ORDER_DATE = CURRENT_DATE();

-- Last 7 days revenue
SELECT 
    ORDER_DATE,
    COUNT(*) as orders,
    SUM(ORDER_TOTAL) as daily_revenue
FROM {{ ref('mart_orders') }}
WHERE ORDER_DATE >= DATEADD(DAY, -7, CURRENT_DATE())
GROUP BY ORDER_DATE
ORDER BY ORDER_DATE DESC;

-- Top selling day this month
SELECT 
    ORDER_DATE,
    COUNT(*) as orders,
    SUM(ORDER_TOTAL) as revenue
FROM {{ ref('mart_orders') }}
WHERE ORDER_YEAR = YEAR(CURRENT_DATE())
  AND ORDER_MONTH = MONTH(CURRENT_DATE())
GROUP BY ORDER_DATE
ORDER BY revenue DESC
LIMIT 1;

-- Revenue by time of day
SELECT 
    CASE 
        WHEN ORDER_HOUR < 6 THEN 'Night'
        WHEN ORDER_HOUR < 12 THEN 'Morning'
        WHEN ORDER_HOUR < 18 THEN 'Afternoon'
        ELSE 'Evening'
    END as time_of_day,
    SUM(ORDER_TOTAL) as revenue
FROM {{ ref('mart_orders') }}
WHERE ORDER_HOUR IS NOT NULL
GROUP BY time_of_day
ORDER BY revenue DESC;

-- Orders above/below average value
SELECT 
    CASE 
        WHEN ORDER_TOTAL > (SELECT AVG(ORDER_TOTAL) FROM {{ ref('mart_orders') }}) THEN 'Above Average'
        ELSE 'Below Average'
    END as order_category,
    COUNT(*) as order_count,
    ROUND(AVG(ORDER_TOTAL), 2) as avg_value
FROM {{ ref('mart_orders') }}
GROUP BY order_category;

-- ============================================================================
-- PRODUCT QUICK QUERIES
-- ============================================================================

-- Top 5 products today
SELECT TOP 5
    ITEM_SKU,
    PRODUCT_NAME,
    COUNT(*) as orders_today,
    SUM(ITEM_AMOUNT) as revenue_today
FROM {{ ref('int_orders_items_joined') }}
WHERE DATE(ORDERED_AT) = CURRENT_DATE()
GROUP BY ITEM_SKU, PRODUCT_NAME
ORDER BY revenue_today DESC;

-- Products not sold in last 30 days
SELECT DISTINCT
    p.ITEM_SKU,
    p.PRODUCT_NAME,
    p.TOTAL_ITEMS_SOLD,
    p.PRODUCT_REVENUE
FROM {{ ref('mart_products') }} p
WHERE p.ITEM_SKU NOT IN (
    SELECT DISTINCT ITEM_SKU
    FROM {{ ref('int_orders_items_joined') }}
    WHERE ORDERED_AT >= DATEADD(DAY, -30, CURRENT_DATE())
)
ORDER BY p.PRODUCT_REVENUE DESC;

-- Products with highest margin (compare price to selling price)
SELECT 
    ITEM_SKU,
    PRODUCT_NAME,
    PRODUCT_PRICE,
    AVG_SELLING_PRICE,
    ROUND(AVG_SELLING_PRICE - PRODUCT_PRICE, 2) as margin_per_unit
FROM {{ ref('mart_products') }}
WHERE PRODUCT_PRICE > 0
ORDER BY margin_per_unit DESC;

-- Most frequently co-purchased products
SELECT 
    oi1.ITEM_SKU as product_a,
    oi1.PRODUCT_NAME as product_a_name,
    oi2.ITEM_SKU as product_b,
    oi2.PRODUCT_NAME as product_b_name,
    COUNT(DISTINCT oi1.ORDER_ID) as times_together
FROM {{ ref('int_orders_items_joined') }} oi1
JOIN {{ ref('int_orders_items_joined') }} oi2
    ON oi1.ORDER_ID = oi2.ORDER_ID
    AND oi1.ITEM_SKU < oi2.ITEM_SKU
GROUP BY oi1.ITEM_SKU, oi1.PRODUCT_NAME, oi2.ITEM_SKU, oi2.PRODUCT_NAME
ORDER BY times_together DESC
LIMIT 10;

-- Product performance week-over-week
WITH weekly_products AS (
    SELECT 
        DATE_TRUNC(WEEK, ORDERED_AT) as week,
        ITEM_SKU,
        PRODUCT_NAME,
        SUM(ITEM_AMOUNT) as weekly_revenue
    FROM {{ ref('int_orders_items_joined') }}
    GROUP BY DATE_TRUNC(WEEK, ORDERED_AT), ITEM_SKU, PRODUCT_NAME
)
SELECT 
    ITEM_SKU,
    PRODUCT_NAME,
    LAG(weekly_revenue) OVER (PARTITION BY ITEM_SKU ORDER BY week) as prev_week,
    weekly_revenue as curr_week,
    ROUND(100.0 * (weekly_revenue - LAG(weekly_revenue) OVER (PARTITION BY ITEM_SKU ORDER BY week)) 
        / NULLIF(LAG(weekly_revenue) OVER (PARTITION BY ITEM_SKU ORDER BY week), 0), 2) as growth_percent
FROM weekly_products
WHERE week >= DATEADD(WEEK, -2, CURRENT_DATE())
ORDER BY week DESC, growth_percent DESC;

-- ============================================================================
-- COMPARISON QUICK QUERIES
-- ============================================================================

-- This month vs last month revenue
SELECT 
    'This Month' as period,
    SUM(ORDER_TOTAL) as revenue
FROM {{ ref('mart_orders') }}
WHERE ORDER_MONTH = MONTH(CURRENT_DATE())
  AND ORDER_YEAR = YEAR(CURRENT_DATE())
UNION ALL
SELECT 
    'Last Month',
    SUM(ORDER_TOTAL)
FROM {{ ref('mart_orders') }}
WHERE ORDER_MONTH = MONTH(DATEADD(MONTH, -1, CURRENT_DATE()))
  AND ORDER_YEAR = YEAR(DATEADD(MONTH, -1, CURRENT_DATE()));

-- Same period last year comparison
SELECT 
    'This Year',
    SUM(ORDER_TOTAL) as revenue
FROM {{ ref('mart_orders') }}
WHERE ORDER_MONTH = MONTH(CURRENT_DATE())
  AND ORDER_YEAR = YEAR(CURRENT_DATE())
UNION ALL
SELECT 
    'Last Year',
    SUM(ORDER_TOTAL)
FROM {{ ref('mart_orders') }}
WHERE ORDER_MONTH = MONTH(CURRENT_DATE())
  AND ORDER_YEAR = YEAR(CURRENT_DATE()) - 1;

-- Compare top 5 stores
SELECT TOP 5
    ORDER_STORE_ID as store,
    COUNT(DISTINCT ORDER_ID) as orders,
    SUM(ORDER_TOTAL) as revenue,
    ROUND(AVG(ORDER_TOTAL), 2) as avg_order_value
FROM {{ ref('mart_orders') }}
GROUP BY ORDER_STORE_ID
ORDER BY revenue DESC;

-- ============================================================================
-- CUSTOMER SEGMENT QUICK QUERIES
-- ============================================================================

-- Count of customers by segment
SELECT 
    CUSTOMER_SEGMENT,
    CUSTOMER_STATUS,
    COUNT(*) as customer_count
FROM {{ ref('mart_customers') }}
GROUP BY CUSTOMER_SEGMENT, CUSTOMER_STATUS
ORDER BY CUSTOMER_SEGMENT, CUSTOMER_STATUS;

-- High-value customers who are at risk
SELECT 
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CUSTOMER_LIFETIME_VALUE,
    TOTAL_ORDERS,
    LAST_ORDER_DATE,
    RECENCY_DAYS
FROM {{ ref('mart_customers') }}
WHERE CUSTOMER_SEGMENT = 'High Value'
  AND CUSTOMER_STATUS = 'At Risk'
ORDER BY CUSTOMER_LIFETIME_VALUE DESC;

-- New customers performance (acquired last 30 days)
SELECT 
    COUNT(DISTINCT CUSTOMER_ID) as new_customers,
    ROUND(AVG(CUSTOMER_LIFETIME_VALUE), 2) as avg_first_30_days_value,
    ROUND(SUM(CUSTOMER_LIFETIME_VALUE), 2) as total_revenue_from_new,
    ROUND(AVG(TOTAL_ORDERS), 2) as avg_orders
FROM {{ ref('mart_customers') }}
WHERE FIRST_ORDER_DATE >= DATEADD(DAY, -30, CURRENT_DATE());

-- ============================================================================
-- ANOMALY & ALERT QUICK QUERIES
-- ============================================================================

-- Orders significantly above average (potential errors or data quality issues)
WITH avg_order AS (
    SELECT AVG(ORDER_TOTAL) as avg_value FROM {{ ref('mart_orders') }}
)
SELECT 
    ORDER_ID,
    ORDER_CUSTOMER,
    ORDER_TOTAL,
    (SELECT avg_value FROM avg_order) as avg_order_value,
    ROUND(ORDER_TOTAL / (SELECT avg_value FROM avg_order), 2) as multiple_of_average
FROM {{ ref('mart_orders') }}
WHERE ORDER_TOTAL > (SELECT avg_value * 3 FROM avg_order)
ORDER BY ORDER_TOTAL DESC;

-- Days with zero sales
SELECT 
    d.calendar_date as date_with_no_sales
FROM (
    SELECT DISTINCT DATE(ORDERED_AT) as date_in_system
    FROM {{ ref('mart_orders') }}
) existing_dates
RIGHT JOIN (
    SELECT DATE_TRUNC(DAY, dateadd(day, -seq, current_date())) as calendar_date
    FROM (SELECT ROW_NUMBER() OVER () - 1 as seq FROM table(generator(rowcount => 90)))
) d ON d.calendar_date = existing_dates.date_in_system
WHERE existing_dates.date_in_system IS NULL
  AND d.calendar_date <= CURRENT_DATE()
ORDER BY d.calendar_date DESC
LIMIT 10;

-- Customers with unusual activity (spike in orders)
SELECT 
    CUSTOMER_ID,
    CUSTOMER_NAME,
    COUNT(*) as recent_orders,
    ROUND(AVG(ORDER_TOTAL), 2) as avg_value
FROM {{ ref('mart_orders_by_customer') }}
WHERE ORDERED_AT >= DATEADD(DAY, -7, CURRENT_DATE())
GROUP BY CUSTOMER_ID, CUSTOMER_NAME
HAVING COUNT(*) > 5
ORDER BY recent_orders DESC;

-- ============================================================================
-- EXPORT/REPORTING QUICK QUERIES
-- ============================================================================

-- Export: All active customers with contact strategy
SELECT 
    CUSTOMER_ID,
    CUSTOMER_NAME,
    FIRST_NAME,
    LAST_NAME,
    CUSTOMER_LIFETIME_VALUE,
    TOTAL_ORDERS,
    LAST_ORDER_DATE,
    CUSTOMER_SEGMENT,
    CUSTOMER_STATUS,
    CASE 
        WHEN CUSTOMER_SEGMENT = 'High Value' THEN 'VIP - Premium Support'
        WHEN CUSTOMER_SEGMENT = 'Medium Value' AND CUSTOMER_STATUS = 'Active' THEN 'Loyalty Program'
        WHEN CUSTOMER_STATUS = 'At Risk' THEN 'Win-Back Campaign'
        ELSE 'Standard Nurture'
    END as recommended_strategy
FROM {{ ref('mart_customers') }}
WHERE CUSTOMER_STATUS IN ('Active', 'At Risk')
ORDER BY CUSTOMER_LIFETIME_VALUE DESC;

-- Export: Product recommendations based on customer segment
SELECT DISTINCT
    c.CUSTOMER_SEGMENT,
    oi.PRODUCT_NAME,
    COUNT(*) as purchase_count,
    RANK() OVER (PARTITION BY c.CUSTOMER_SEGMENT ORDER BY COUNT(*) DESC) as product_rank
FROM {{ ref('mart_customers') }} c
JOIN {{ ref('mart_orders_by_customer') }} o ON c.CUSTOMER_ID = o.CUSTOMER_ID
JOIN {{ ref('int_orders_items_joined') }} oi ON o.ORDER_ID = oi.ORDER_ID
GROUP BY c.CUSTOMER_SEGMENT, oi.PRODUCT_NAME
HAVING COUNT(*) >= 2
ORDER BY c.CUSTOMER_SEGMENT, product_rank;
