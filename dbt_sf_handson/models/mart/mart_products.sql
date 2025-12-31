{{ config(materialized='view') }}

-- MART LAYER: mart_products
-- Purpose: Product analytics for inventory, sales, and merchandising teams
-- Business Logic: Complete product performance view with rankings and KPIs
-- Key Metrics: Sales, revenue, popularity, performance rankings

SELECT  
    ITEM_SKU,
    PRODUCT_NAME,
    PRODUCT_TYPE,
    PRODUCT_PRICE,
    ORDERS_CONTAINING_PRODUCT,
    TOTAL_ITEMS_SOLD,
    PRODUCT_REVENUE,
    AVG_SELLING_PRICE,
    MIN_SELLING_PRICE,
    MAX_SELLING_PRICE,
    AVG_REVENUE_PER_UNIT,
    REVENUE_RANK,
    POPULARITY_RANK,
    -- Additional business metrics
    CASE 
        WHEN REVENUE_RANK <= 10 THEN 'Top Performer'
        WHEN REVENUE_RANK <= 50 THEN 'Strong Performer'
        WHEN REVENUE_RANK <= 100 THEN 'Average Performer'
        ELSE 'Low Performer'
    END as PRODUCT_PERFORMANCE_TIER,
    CASE 
        WHEN TOTAL_ITEMS_SOLD >= 100 THEN 'Star Product'
        WHEN TOTAL_ITEMS_SOLD >= 50 THEN 'Popular'
        WHEN TOTAL_ITEMS_SOLD >= 20 THEN 'Moderate'
        ELSE 'Niche'
    END as PRODUCT_POPULARITY_TIER,
    ROUND(PRODUCT_REVENUE / NULLIF(ORDERS_CONTAINING_PRODUCT, 0), 2) as AVG_REVENUE_PER_ORDER,
    CASE 
        WHEN (AVG_SELLING_PRICE > 0) 
            THEN ROUND(((AVG_SELLING_PRICE - PRODUCT_PRICE) / PRODUCT_PRICE) * 100, 2)
        ELSE 0
    END as PRICE_VARIANCE_PERCENT,
    CALCULATED_AT as LAST_CALCULATED
FROM {{ ref('int_product_performance') }}
WHERE ITEM_SKU IS NOT NULL
ORDER BY REVENUE_RANK ASC
