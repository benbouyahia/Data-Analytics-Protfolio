-- 1.1 ORDERS DATASET OVERVIEW

-- View first 10 orders
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM staging.orders
LIMIT 10;

-- Orders summary statistics
SELECT 
    'Total Orders' AS metric,
    COUNT(DISTINCT order_id) AS value
FROM staging.orders
UNION ALL
SELECT 
    'Total Delivered Orders',
    COUNT(DISTINCT CASE WHEN order_status = 'delivered' THEN order_id END)
FROM staging.orders
UNION ALL
SELECT 
    'Total Cancelled Orders',
    COUNT(DISTINCT CASE WHEN order_status = 'cancelled' THEN order_id END)
FROM staging.orders
UNION ALL
SELECT 
    'Date Range (First Order)',
    MIN(DATE(order_purchase_timestamp))::TEXT
FROM staging.orders
UNION ALL
SELECT 
    'Date Range (Last Order)',
    MAX(DATE(order_purchase_timestamp))::TEXT
FROM staging.orders;

-- 1.2 CUSTOMERS DATASET OVERVIEW

-- View first 10 customers
SELECT 
    customer_id,
    customer_unique_id,
    customer_city,
    customer_state,
    customer_zip_code_prefix
FROM staging.customers
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
SELECT 
    product_id,
    product_category_name,
    product_category_name_english,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM analytics.dim_products
LIMIT 10;

-- Product statistics
SELECT 
    'Total Products' AS metric,
    COUNT(DISTINCT product_id) AS value
FROM analytics.dim_products
UNION ALL
SELECT 
    'Product Categories',
    COUNT(DISTINCT product_category_name)
FROM analytics.dim_products;

-- 1.4 ORDER ITEMS DATASET OVERVIEW

-- View first 10 order items
SELECT 
    order_id,
    order_item_id,
    product_id,
    seller_id,
    price,
    freight_value,
    order_purchase_timestamp
FROM analytics.fact_order_items
LIMIT 10;

-- Order items statistics
SELECT 
    'Total Order Items' AS metric,
    COUNT(*) AS value
FROM analytics.fact_order_items
UNION ALL
SELECT 
    'Unique Orders with Items',
    COUNT(DISTINCT order_id)
FROM analytics.fact_order_items
UNION ALL
SELECT 
    'Unique Sellers',
    COUNT(DISTINCT seller_id)
FROM analytics.fact_order_items;

-- 1.5 REVIEWS DATASET OVERVIEW

-- View first 10 reviews
SELECT 
    review_id,
    order_id,
    review_score,
    review_creation_date,
    review_comment_title,
    review_comment_message,
    review_answer_timestamp
FROM analytics.order_reviews
LIMIT 10;

-- Reviews statistics
SELECT 
    'Total Reviews' AS metric,
    COUNT(*) AS value
FROM analytics.order_reviews
UNION ALL
SELECT 
    'Unique Orders with Reviews',
    COUNT(DISTINCT order_id)
FROM analytics.order_reviews
UNION ALL
SELECT 
    'Average Review Score',
    ROUND(AVG(review_score)::NUMERIC, 2)::TEXT
FROM analytics.order_reviews;
