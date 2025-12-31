WITH ITEMS AS (
SELECT 
    ITEM_ID,
    ITEM_ORDER_ID,
    ITEM_PRODUCT_SKU
FROM {{ source('raw', 'raw_items') }}
)

select 
    it.ITEM_ID,
    it.ITEM_ORDER_ID,
    it.ITEM_PRODUCT_SKU as ITEM_SKU
from ITEMS it
WHERE it.ITEM_ID IS NOT NULL