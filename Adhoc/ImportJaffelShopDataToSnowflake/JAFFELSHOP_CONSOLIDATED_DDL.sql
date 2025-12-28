/**
================================================================================
JAFFLE SHOP - CONSOLIDATED DDL WITH PRIMARY AND FOREIGN KEYS
================================================================================
This file contains all table definitions for the Jaffle Shop database
with explicit Primary Key (PK) and Foreign Key (FK) constraints.

Database: JAFFELSHOP_ECOM
Schema: RAW

Relationships:
  1. RAW_ORDERS.CUSTOMER → RAW_CUSTOMERS.ID
  2. RAW_ORDERS.STORE_ID → RAW_STORES.ID
  3. RAW_ITEMS.ORDER_ID → RAW_ORDERS.ID
  4. RAW_ITEMS.SKU → RAW_PRODUCTS.SKU
  5. RAW_SUPPLIES.SKU → RAW_PRODUCTS.SKU
  6. RAW_TWEETS.USER_ID → RAW_CUSTOMERS.ID
================================================================================
*/

-- ============================================================================
-- 1. RAW_CUSTOMERS - Customer Master Data
-- ============================================================================
-- Description: Stores customer information
-- Primary Key: ID
-- Referenced by: RAW_ORDERS (CUSTOMER), RAW_TWEETS (USER_ID)

CREATE TABLE IF NOT EXISTS JAFFELSHOP_ECOM.RAW.RAW_CUSTOMERS (
    ID VARCHAR NOT NULL PRIMARY KEY,
    NAME VARCHAR NOT NULL
)
COMMENT = 'Customer Master Data - Jaffle Shop customers';


-- ============================================================================
-- 2. RAW_STORES - Store Location Master Data
-- ============================================================================
-- Description: Stores information about Jaffle Shop locations
-- Primary Key: ID
-- Referenced by: RAW_ORDERS (STORE_ID)

CREATE TABLE IF NOT EXISTS JAFFELSHOP_ECOM.RAW.RAW_STORES (
    ID VARCHAR NOT NULL PRIMARY KEY,
    NAME VARCHAR NOT NULL,
    OPENED_AT VARCHAR,
    TAX_RATE NUMBER(5, 4)
)
COMMENT = 'Store Master Data - Jaffle Shop store locations';


-- ============================================================================
-- 3. RAW_PRODUCTS - Product/Menu Master Data
-- ============================================================================
-- Description: Product and menu item catalog
-- Primary Key: SKU
-- Referenced by: RAW_ITEMS (SKU), RAW_SUPPLIES (SKU)

CREATE TABLE IF NOT EXISTS JAFFELSHOP_ECOM.RAW.RAW_PRODUCTS (
    SKU VARCHAR NOT NULL PRIMARY KEY,
    NAME VARCHAR NOT NULL,
    TYPE VARCHAR,
    PRICE NUMBER(10, 2),
    DESCRIPTION VARCHAR
)
COMMENT = 'Product Master Data - Menu items and products';


-- ============================================================================
-- 4. RAW_ORDERS - Customer Orders (Transaction Header)
-- ============================================================================
-- Description: Store customer order transactions
-- Primary Key: ID
-- Foreign Keys:
--   - CUSTOMER → RAW_CUSTOMERS.ID
--   - STORE_ID → RAW_STORES.ID
-- Referenced by: RAW_ITEMS (ORDER_ID)

CREATE TABLE IF NOT EXISTS JAFFELSHOP_ECOM.RAW.RAW_ORDERS (
    ID VARCHAR NOT NULL PRIMARY KEY,
    CUSTOMER VARCHAR NOT NULL,
    ORDERED_AT VARCHAR,
    STORE_ID VARCHAR NOT NULL,
    SUBTOTAL INTEGER,
    TAX_PAID INTEGER,
    ORDER_TOTAL INTEGER,
    
    -- Foreign Key Constraints
    CONSTRAINT FK_ORDERS_CUSTOMER 
        FOREIGN KEY (CUSTOMER) 
        REFERENCES JAFFELSHOP_ECOM.RAW.RAW_CUSTOMERS(ID),
    
    CONSTRAINT FK_ORDERS_STORE 
        FOREIGN KEY (STORE_ID) 
        REFERENCES JAFFELSHOP_ECOM.RAW.RAW_STORES(ID)
)
COMMENT = 'Order Transaction Data - Customer orders at stores';


-- ============================================================================
-- 5. RAW_ITEMS - Order Line Items (Transaction Details)
-- ============================================================================
-- Description: Individual line items within each order
-- Primary Key: ID
-- Foreign Keys:
--   - ORDER_ID → RAW_ORDERS.ID
--   - SKU → RAW_PRODUCTS.SKU

CREATE TABLE IF NOT EXISTS JAFFELSHOP_ECOM.RAW.RAW_ITEMS (
    ID VARCHAR NOT NULL PRIMARY KEY,
    ORDER_ID VARCHAR NOT NULL,
    SKU VARCHAR NOT NULL,
    QUANTITY INTEGER,
    PRICE NUMBER(10, 2),
    
    -- Foreign Key Constraints
    CONSTRAINT FK_ITEMS_ORDER 
        FOREIGN KEY (ORDER_ID) 
        REFERENCES JAFFELSHOP_ECOM.RAW.RAW_ORDERS(ID),
    
    CONSTRAINT FK_ITEMS_PRODUCT 
        FOREIGN KEY (SKU) 
        REFERENCES JAFFELSHOP_ECOM.RAW.RAW_PRODUCTS(SKU)
)
COMMENT = 'Order Line Items - Individual items within each order';


-- ============================================================================
-- 6. RAW_SUPPLIES - Supply/Ingredient Master Data
-- ============================================================================
-- Description: Inventory of supplies and ingredients used to make products
-- Primary Key: ID
-- Foreign Keys:
--   - SKU → RAW_PRODUCTS.SKU

CREATE TABLE IF NOT EXISTS JAFFELSHOP_ECOM.RAW.RAW_SUPPLIES (
    ID VARCHAR NOT NULL PRIMARY KEY,
    NAME VARCHAR NOT NULL,
    COST NUMBER(10, 2),
    PERISHABLE VARCHAR,
    SKU VARCHAR NOT NULL,
    
    -- Foreign Key Constraints
    CONSTRAINT FK_SUPPLIES_PRODUCT 
        FOREIGN KEY (SKU) 
        REFERENCES JAFFELSHOP_ECOM.RAW.RAW_PRODUCTS(SKU)
)
COMMENT = 'Supply Master Data - Ingredients and supplies used in products';


-- ============================================================================
-- 7. RAW_TWEETS - Customer Tweets/Social Media Data
-- ============================================================================
-- Description: Customer social media interactions and reviews
-- Primary Key: ID
-- Foreign Keys:
--   - USER_ID → RAW_CUSTOMERS.ID

CREATE TABLE IF NOT EXISTS JAFFELSHOP_ECOM.RAW.RAW_TWEETS (
    ID VARCHAR NOT NULL PRIMARY KEY,
    USER_ID VARCHAR NOT NULL,
    TWEETED_AT VARCHAR,
    CONTENT VARCHAR,
    
    -- Foreign Key Constraints
    CONSTRAINT FK_TWEETS_CUSTOMER 
        FOREIGN KEY (USER_ID) 
        REFERENCES JAFFELSHOP_ECOM.RAW.RAW_CUSTOMERS(ID)
)
COMMENT = 'Tweet Data - Customer social media posts and interactions';


-- ============================================================================
-- DATA MODEL SUMMARY
-- ============================================================================
/*

TABLE HIERARCHY & RELATIONSHIPS:

    RAW_CUSTOMERS
    ├── PK: ID
    ├── Referenced by RAW_ORDERS (CUSTOMER)
    └── Referenced by RAW_TWEETS (USER_ID)

    RAW_STORES
    ├── PK: ID
    └── Referenced by RAW_ORDERS (STORE_ID)

    RAW_PRODUCTS
    ├── PK: SKU
    ├── Referenced by RAW_ITEMS (SKU)
    └── Referenced by RAW_SUPPLIES (SKU)

    RAW_ORDERS (Transaction Header)
    ├── PK: ID
    ├── FK: CUSTOMER → RAW_CUSTOMERS.ID
    ├── FK: STORE_ID → RAW_STORES.ID
    └── Referenced by RAW_ITEMS (ORDER_ID)

    RAW_ITEMS (Transaction Detail)
    ├── PK: ID
    ├── FK: ORDER_ID → RAW_ORDERS.ID
    └── FK: SKU → RAW_PRODUCTS.SKU

    RAW_SUPPLIES (Inventory)
    ├── PK: ID
    └── FK: SKU → RAW_PRODUCTS.SKU

    RAW_TWEETS (Social Media)
    ├── PK: ID
    └── FK: USER_ID → RAW_CUSTOMERS.ID


KEY OBSERVATIONS:

1. MASTER TABLES (no dependencies):
   - RAW_CUSTOMERS: Customer information
   - RAW_STORES: Store locations
   - RAW_PRODUCTS: Product catalog

2. TRANSACTIONAL TABLES:
   - RAW_ORDERS: Order header (depends on CUSTOMERS, STORES)
   - RAW_ITEMS: Order details (depends on ORDERS, PRODUCTS)

3. OPERATIONAL TABLES:
   - RAW_SUPPLIES: Inventory management (depends on PRODUCTS)
   - RAW_TWEETS: Social media data (depends on CUSTOMERS)

4. LOADING ORDER:
   Step 1: Load master tables (CUSTOMERS, STORES, PRODUCTS)
   Step 2: Load transactional tables (ORDERS, ITEMS)
   Step 3: Load operational tables (SUPPLIES, TWEETS)

*/

-- ============================================================================
-- COLUMN DETAILS & DATA TYPES
-- ============================================================================
/*

RAW_CUSTOMERS:
  ID          VARCHAR  - Unique customer identifier (PK)
  NAME        VARCHAR  - Customer name

RAW_STORES:
  ID          VARCHAR  - Unique store identifier (PK)
  NAME        VARCHAR  - Store name/location
  OPENED_AT   VARCHAR  - Store opening date
  TAX_RATE    NUMBER   - Tax rate for this store (5,4) = 9999.9999

RAW_PRODUCTS:
  SKU         VARCHAR  - Stock Keeping Unit (PK)
  NAME        VARCHAR  - Product name
  TYPE        VARCHAR  - Product category/type
  PRICE       NUMBER   - Unit price (10,2) = 99999999.99
  DESCRIPTION VARCHAR  - Product description

RAW_ORDERS:
  ID          VARCHAR  - Unique order identifier (PK)
  CUSTOMER    VARCHAR  - Customer who placed order (FK → RAW_CUSTOMERS.ID)
  ORDERED_AT  VARCHAR  - Order timestamp
  STORE_ID    VARCHAR  - Store where order was placed (FK → RAW_STORES.ID)
  SUBTOTAL    INTEGER  - Order subtotal before tax
  TAX_PAID    INTEGER  - Tax amount
  ORDER_TOTAL INTEGER  - Total order amount

RAW_ITEMS:
  ID          VARCHAR  - Unique line item identifier (PK)
  ORDER_ID    VARCHAR  - Order this item belongs to (FK → RAW_ORDERS.ID)
  SKU         VARCHAR  - Product SKU (FK → RAW_PRODUCTS.SKU)
  QUANTITY    INTEGER  - Quantity ordered
  PRICE       NUMBER   - Unit price at time of order

RAW_SUPPLIES:
  ID          VARCHAR  - Unique supply identifier (PK)
  NAME        VARCHAR  - Supply/ingredient name
  COST        NUMBER   - Cost per unit
  PERISHABLE  VARCHAR  - Is supply perishable (Y/N)
  SKU         VARCHAR  - Associated product SKU (FK → RAW_PRODUCTS.SKU)

RAW_TWEETS:
  ID          VARCHAR  - Unique tweet identifier (PK)
  USER_ID     VARCHAR  - Customer who tweeted (FK → RAW_CUSTOMERS.ID)
  TWEETED_AT  VARCHAR  - Tweet timestamp
  CONTENT     VARCHAR  - Tweet text content

*/
