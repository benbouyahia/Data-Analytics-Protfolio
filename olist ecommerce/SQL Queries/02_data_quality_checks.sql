
-- ORDERS DATASET QUALITY CHECKS

-- Check for missing values in orders
SELECT 
    'order_id' AS column_name,
    COUNT(*) - COUNT(order_id) AS null_count
FROM staging.orders
UNION ALL
SELECT 'customer_id', COUNT(*) - COUNT(customer_id) FROM staging.orders
UNION ALL
SELECT 'order_status', COUNT(*) - COUNT(order_status) FROM staging.orders
UNION ALL
SELECT 'order_purchase_timestamp', COUNT(*) - COUNT(order_purchase_timestamp) FROM staging.orders
UNION ALL
SELECT 'order_delivered_customer_date', COUNT(*) - COUNT(order_delivered_customer_date) FROM staging.orders;

-- Check for duplicates in orders
SELECT 
    'Total Orders' AS check_name,
    COUNT(*) AS count
FROM staging.orders
UNION ALL
SELECT 
    'Unique order_id',
    COUNT(DISTINCT order_id)
FROM staging.orders;

-- Orphan check: Order items without matching orders
SELECT 
    COUNT(DISTINCT oi.order_id) AS order_items_without_orders
FROM staging.order_items oi
WHERE oi.order_id NOT IN (SELECT order_id FROM staging.orders);

-- Reverse orphan check: Orders without items
SELECT 
    COUNT(DISTINCT o.order_id) AS orders_without_items
FROM staging.orders o
WHERE o.order_id NOT IN (SELECT DISTINCT order_id FROM staging.order_items);

-- Join cardinality check: Orders vs Order Items
SELECT 
    (SELECT COUNT(DISTINCT order_id) FROM staging.orders) AS unique_orders,
    (SELECT COUNT(DISTINCT order_id) FROM staging.order_items) AS unique_orders_with_items,
    (SELECT COUNT(DISTINCT order_id) FROM staging.orders 
     WHERE order_id IN (SELECT DISTINCT order_id FROM staging.order_items)) AS orders_with_items_count;

-- ORDER ITEMS DATASET QUALITY CHECKS

-- Check missing values in order_items
SELECT 
    'order_id' AS column_name,
    COUNT(*) - COUNT(order_id) AS null_count
FROM staging.order_items
UNION ALL
SELECT 'product_id', COUNT(*) - COUNT(product_id) FROM staging.order_items
UNION ALL
SELECT 'seller_id', COUNT(*) - COUNT(seller_id) FROM staging.order_items
UNION ALL
SELECT 'price', COUNT(*) - COUNT(price) FROM staging.order_items;

-- Check for duplicates (expected: order_id can be duplicated, but order_id + order_item_id should be unique)
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, order_item_id)) AS unique_combinations
FROM staging.order_items;

-- Orphan check: Products without items
SELECT 
    COUNT(DISTINCT p.product_id) AS products_without_items
FROM staging.products p
WHERE p.product_id NOT IN (SELECT product_id FROM staging.order_items);

-- Orphan check: Sellers without items
SELECT 
    COUNT(DISTINCT s.seller_id) AS sellers_without_items
FROM staging.sellers s
WHERE s.seller_id NOT IN (SELECT seller_id FROM staging.order_items);

-- Reverse orphan check: Items without products
SELECT 
    COUNT(DISTINCT oi.product_id) AS items_without_products
FROM staging.order_items oi
WHERE oi.product_id NOT IN (SELECT product_id FROM staging.products);

-- Reverse orphan check: Items without sellers
SELECT 
    COUNT(DISTINCT oi.seller_id) AS items_without_sellers
FROM staging.order_items oi
WHERE oi.seller_id NOT IN (SELECT seller_id FROM staging.sellers);

-- CUSTOMERS DATASET QUALITY CHECKS

-- Check missing values
SELECT 
    'customer_id' AS column_name,
    COUNT(*) - COUNT(customer_id) AS null_count
FROM staging.customers
UNION ALL
SELECT 'customer_unique_id', COUNT(*) - COUNT(customer_unique_id) FROM staging.customers
UNION ALL
SELECT 'customer_city', COUNT(*) - COUNT(customer_city) FROM staging.customers
UNION ALL
SELECT 'customer_state', COUNT(*) - COUNT(customer_state) FROM staging.customers;

-- Check for repeat customers (customers with multiple customer_id)
SELECT 
    customer_unique_id,
    COUNT(DISTINCT customer_id) AS customer_id_count
FROM staging.customers
GROUP BY customer_unique_id
HAVING COUNT(DISTINCT customer_id) > 1
ORDER BY customer_id_count DESC
LIMIT 20;

-- ORDER PAYMENTS DATASET QUALITY CHECKS

-- Check missing values in payments
SELECT 
    'order_id' AS column_name,
    COUNT(*) - COUNT(order_id) AS null_count
FROM staging.order_payments
UNION ALL
SELECT 'payment_sequential', COUNT(*) - COUNT(payment_sequential) FROM staging.order_payments
UNION ALL
SELECT 'payment_type', COUNT(*) - COUNT(payment_type) FROM staging.order_payments
UNION ALL
SELECT 'payment_installments', COUNT(*) - COUNT(payment_installments) FROM staging.order_payments
UNION ALL
SELECT 'payment_value', COUNT(*) - COUNT(payment_value) FROM staging.order_payments;

-- Check for duplicates: Orders with multiple payments
SELECT 
    order_id,
    COUNT(*) AS payment_count
FROM staging.order_payments
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY payment_count DESC
LIMIT 20;

-- Count of orders with multiple payments
SELECT 
    COUNT(DISTINCT CASE WHEN payment_count > 1 THEN order_id END) AS orders_with_multiple_payments
FROM (
    SELECT order_id, COUNT(*) AS payment_count
    FROM staging.order_payments
    GROUP BY order_id
) subq;

-- Orphan check: Payments without orders
SELECT 
    COUNT(DISTINCT op.order_id) AS payments_without_orders
FROM staging.order_payments op
WHERE op.order_id NOT IN (SELECT order_id FROM staging.orders);

-- Reverse orphan check: Orders without payments
SELECT 
    COUNT(DISTINCT o.order_id) AS orders_without_payments
FROM staging.orders o
WHERE o.order_id NOT IN (SELECT DISTINCT order_id FROM staging.order_payments);

-- SELLERS DATASET QUALITY CHECKS

-- Check missing values
SELECT 
    'seller_id' AS column_name,
    COUNT(*) - COUNT(seller_id) AS null_count
FROM staging.sellers
UNION ALL
SELECT 'seller_city', COUNT(*) - COUNT(seller_city) FROM staging.sellers
UNION ALL
SELECT 'seller_state', COUNT(*) - COUNT(seller_state) FROM staging.sellers;

-- Check for duplicates
SELECT 
    COUNT(*) AS total_sellers,
    COUNT(DISTINCT seller_id) AS unique_sellers
FROM staging.sellers;

-- Sellers without items
SELECT 
    COUNT(DISTINCT s.seller_id) AS sellers_without_items
FROM staging.sellers s
WHERE s.seller_id NOT IN (SELECT seller_id FROM staging.order_items);

-- ORDER REVIEWS DATASET QUALITY CHECKS

-- Check missing values
SELECT 
    'review_id' AS column_name,
    COUNT(*) - COUNT(review_id) AS null_count
FROM analytics.order_reviews
UNION ALL
SELECT 'order_id', COUNT(*) - COUNT(order_id) FROM analytics.order_reviews
UNION ALL
SELECT 'review_score', COUNT(*) - COUNT(review_score) FROM analytics.order_reviews
UNION ALL
SELECT 'review_comment_title', COUNT(*) - COUNT(review_comment_title) FROM analytics.order_reviews
UNION ALL
SELECT 'review_comment_message', COUNT(*) - COUNT(review_comment_message) FROM analytics.order_reviews;

-- Check for duplicates
SELECT 
    COUNT(*) AS total_reviews,
    COUNT(DISTINCT review_id) AS unique_reviews
FROM analytics.order_reviews;

-- Orders with multiple reviews
SELECT 
    order_id,
    COUNT(*) AS review_count
FROM analytics.order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY review_count DESC
LIMIT 20;

-- Orphan check: Reviews without orders
SELECT 
    COUNT(DISTINCT ar.order_id) AS reviews_without_orders
FROM analytics.order_reviews ar
WHERE ar.order_id NOT IN (SELECT order_id FROM staging.orders);

-- PRODUCTS DATASET QUALITY CHECKS

-- Check missing values
SELECT 
    'product_id' AS column_name,
    COUNT(*) - COUNT(product_id) AS null_count
FROM analytics.dim_products
UNION ALL
SELECT 'product_category_name', COUNT(*) - COUNT(product_category_name) FROM analytics.dim_products
UNION ALL
SELECT 'product_weight_g', COUNT(*) - COUNT(product_weight_g) FROM analytics.dim_products
UNION ALL
SELECT 'product_length_cm', COUNT(*) - COUNT(product_length_cm) FROM analytics.dim_products
UNION ALL
SELECT 'product_height_cm', COUNT(*) - COUNT(product_height_cm) FROM analytics.dim_products
UNION ALL
SELECT 'product_width_cm', COUNT(*) - COUNT(product_width_cm) FROM analytics.dim_products;

-- Products without order items
SELECT 
    COUNT(DISTINCT dp.product_id) AS products_without_items
FROM analytics.dim_products dp
WHERE dp.product_id NOT IN (SELECT product_id FROM staging.order_items);
