WITH RAW_SUPPLIES AS (
    SELECT * FROM {{ source('raw', 'raw_supplies') }}
)

SELECT  ID          AS SUPPLY_ID,
        NAME        AS SUPPLY_NAME, 
        COST        AS SUPPLY_COST, 
        PERISHABLE  AS SUPPLY_PERISHABLE, 
        SKU         AS SUPPLY_SKU
FROM RAW_SUPPLIES