-- 1.1 ORDERS DATASET OVERVIEW

-- View first 10 orders
SELECT * FROM staging.orders
LIMIT 10;

-- Orders summary statistics
SELECT 
    'Total Orders' AS metric, 
    COUNT(DISTINCT order_id)::TEXT AS value
FROM staging.orders

UNION ALL 

SELECT 
    'total delivered orders', 
    COUNT(DISTINCT CASE WHEN order_status = 'delivered' THEN order_id END)::TEXT
FROM staging.orders

UNION ALL 

SELECT 
    'Total Canceled Orders',
    COUNT(DISTINCT CASE WHEN order_status = 'canceled' THEN order_id END)::TEXT
FROM staging.orders

UNION ALL 

SELECT 
    'Date Range (First Order)',
    MIN(DATE(order_purchase_timestamp))::TEXT
FROM staging.orders;

UNION ALL 

SELECT 
	'Date Range (Last Order)', 
	MAX(Date(order_purchase_timestamp))::TEXT
FROM staging.orders

-- 1.2 CUSTOMERS DATASET OVERVIEW

-- View first 10 customers
SELECT * FROM staging.customers
LIMIT 10;

-- Customer statistics
SELECT 
    'Total Customers' AS metric,
    COUNT(DISTINCT customer_id) AS value
FROM staging.customers
UNION ALL
SELECT 
    'Unique Customers',
    COUNT(DISTINCT customer_unique_id)
FROM staging.customers
UNION ALL
SELECT 
    'Total States',
    COUNT(DISTINCT customer_state)
FROM staging.customers
UNION ALL
SELECT 
    'Total Cities',
    COUNT(DISTINCT customer_city)
FROM staging.customers;

-- 1.3 PRODUCTS DATASET OVERVIEW

-- View first 10 products
SELECT * FROM analytics.dim_products
LIMIT 10;

-- Product statistics
SELECT 
    'Total Products' AS metric,
    COUNT(DISTINCT product_id) AS value
FROM staging.products
UNION ALL
SELECT 
    'Product Categories',
    COUNT(DISTINCT product_category_name)
FROM staging.products;

-- 1.4 ORDER ITEMS DATASET OVERVIEW

-- View first 10 order items
SELECT * FROM analytics.fact_order_items
LIMIT 10;

-- Order items statistics
SELECT 
    'Total Order Items' AS metric,
    COUNT(*) AS value
FROM staging.order_items
UNION ALL
SELECT 
    'Unique Orders with Items',
    COUNT(DISTINCT order_id)
FROM staging.order_items
UNION ALL
SELECT 
    'Unique Sellers',
    COUNT(DISTINCT seller_id)
FROM staging.order_items;

-- 1.5 REVIEWS DATASET OVERVIEW

-- View first 10 reviews
SELECT * FROM analytics.order_reviews
LIMIT 10;

-- Reviews statistics
SELECT 
    'Total Reviews' AS metric,
    COUNT(*)::TEXT AS value
FROM staging.order_reviews
UNION ALL
SELECT 
    'Unique Orders with Reviews',
    COUNT(DISTINCT order_id)::TEXT
FROM staging.order_reviews
UNION ALL
SELECT 
    'Average Review Score',
    ROUND(AVG(review_score)::NUMERIC, 2)::TEXT
FROM staging.order_reviews;

