/*
================================================================================
OLIST E-COMMERCE ANALYSIS - SQL DOCUMENTATION
================================================================================
This document converts all analyses from the Olist Project Jupyter notebooks
into SQL queries for reproducible, documented analysis.

Notebook Sources:
  1. 01_data_overview.ipynb - Data structure and summaries
  2. 02_quality_checks.ipynb - Data quality validation
  3. 03_eda.ipynb - Exploratory data analysis
  4. 04_metrics.ipynb - Key metrics and aggregations

================================================================================
PART 1: DATA OVERVIEW QUERIES
================================================================================
*/

-- ============================================================================
-- 1.1 ORDERS DATASET OVERVIEW
-- ============================================================================

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

-- ============================================================================
-- 1.2 CUSTOMERS DATASET OVERVIEW
-- ============================================================================

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

-- ============================================================================
-- 1.3 PRODUCTS DATASET OVERVIEW
-- ============================================================================

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

-- ============================================================================
-- 1.4 ORDER ITEMS DATASET OVERVIEW
-- ============================================================================

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

-- ============================================================================
-- 1.5 REVIEWS DATASET OVERVIEW
-- ============================================================================

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

/*
================================================================================
PART 2: DATA QUALITY CHECKS
================================================================================
*/

-- ============================================================================
-- 2.1 ORDERS DATASET QUALITY CHECKS
-- ============================================================================

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

-- ============================================================================
-- 2.2 ORDER ITEMS DATASET QUALITY CHECKS
-- ============================================================================

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

-- ============================================================================
-- 2.3 CUSTOMERS DATASET QUALITY CHECKS
-- ============================================================================

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

-- ============================================================================
-- 2.4 ORDER PAYMENTS DATASET QUALITY CHECKS
-- ============================================================================

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

-- ============================================================================
-- 2.5 SELLERS DATASET QUALITY CHECKS
-- ============================================================================

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

-- ============================================================================
-- 2.6 ORDER REVIEWS DATASET QUALITY CHECKS
-- ============================================================================

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

-- ============================================================================
-- 2.7 PRODUCTS DATASET QUALITY CHECKS
-- ============================================================================

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

/*
================================================================================
PART 3: EXPLORATORY DATA ANALYSIS (EDA) QUERIES
================================================================================
*/

-- ============================================================================
-- 3.1 PRODUCT PERFORMANCE ANALYSIS
-- ============================================================================

-- Top 10 Most Sold Product Categories
SELECT 
    p.product_category_name_english AS product_category,
    COUNT(*) AS units_sold,
    ROUND(COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM staging.order_items) * 100, 2) AS pct_of_total
FROM staging.order_items oi
JOIN analytics.dim_products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name_english
ORDER BY units_sold DESC
LIMIT 10;

-- Top 10 Least Sold Product Categories
SELECT 
    p.product_category_name_english AS product_category,
    COUNT(*) AS units_sold,
    ROUND(COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM staging.order_items) * 100, 2) AS pct_of_total
FROM staging.order_items oi
JOIN analytics.dim_products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name_english
ORDER BY units_sold ASC
LIMIT 10;

-- Top 10 Products by Revenue
SELECT 
    p.product_category_name_english AS product_category,
    COUNT(*) AS units_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS product_revenue,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2) AS freight_revenue,
    ROUND((SUM(oi.price) + SUM(oi.freight_value))::NUMERIC, 2) AS total_revenue
FROM staging.order_items oi
JOIN analytics.dim_products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;

-- Top 10 Products by Revenue (Least)
SELECT 
    p.product_category_name_english AS product_category,
    COUNT(*) AS units_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS product_revenue,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2) AS freight_revenue,
    ROUND((SUM(oi.price) + SUM(oi.freight_value))::NUMERIC, 2) AS total_revenue
FROM staging.order_items oi
JOIN analytics.dim_products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name_english
ORDER BY total_revenue ASC
LIMIT 10;

-- ============================================================================
-- 3.2 REGIONAL PERFORMANCE ANALYSIS
-- ============================================================================

-- Customer Distribution by State
SELECT 
    c.customer_state AS state,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT CASE WHEN o.order_id IS NOT NULL THEN c.customer_id END) AS customers_with_orders
FROM staging.customers c
LEFT JOIN staging.orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_state
ORDER BY total_customers DESC;

-- Top 10 States by Number of Orders
SELECT 
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_revenue
FROM staging.orders o
JOIN staging.customers c ON o.customer_id = c.customer_id
JOIN staging.order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY total_orders DESC
LIMIT 10;

-- Top 10 Cities by Number of Orders
SELECT 
    c.customer_city AS city,
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_revenue
FROM staging.orders o
JOIN staging.customers c ON o.customer_id = c.customer_id
JOIN staging.order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_city, c.customer_state
ORDER BY total_orders DESC
LIMIT 10;

-- ============================================================================
-- 3.3 SALES OVERTIME ANALYSIS
-- ============================================================================

-- Orders by Hour of Day
SELECT 
    EXTRACT(HOUR FROM o.order_purchase_timestamp)::INT AS hour_of_day,
    COUNT(DISTINCT o.order_id) AS orders_count,
    ROUND(COUNT(DISTINCT o.order_id)::NUMERIC / 
        (SELECT COUNT(DISTINCT order_id) FROM staging.orders) * 100, 2) AS pct_of_total
FROM staging.orders o
GROUP BY EXTRACT(HOUR FROM o.order_purchase_timestamp)
ORDER BY hour_of_day;

-- Orders by Day of Week
SELECT 
    CASE EXTRACT(DOW FROM o.order_purchase_timestamp)::INT
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_of_week,
    COUNT(DISTINCT o.order_id) AS orders_count,
    ROUND(COUNT(DISTINCT o.order_id)::NUMERIC / 
        (SELECT COUNT(DISTINCT order_id) FROM staging.orders) * 100, 2) AS pct_of_total
FROM staging.orders o
GROUP BY EXTRACT(DOW FROM o.order_purchase_timestamp)
ORDER BY EXTRACT(DOW FROM o.order_purchase_timestamp);

-- Orders by Month
SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS month,
    COUNT(DISTINCT o.order_id) AS orders_count,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_revenue
FROM staging.orders o
JOIN staging.order_items oi ON o.order_id = oi.order_id
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month;

-- Orders by Year and Month
SELECT 
    EXTRACT(YEAR FROM o.order_purchase_timestamp)::INT AS year,
    EXTRACT(MONTH FROM o.order_purchase_timestamp)::INT AS month,
    COUNT(DISTINCT o.order_id) AS orders_count,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_revenue
FROM staging.orders o
JOIN staging.order_items oi ON o.order_id = oi.order_id
GROUP BY EXTRACT(YEAR FROM o.order_purchase_timestamp), 
         EXTRACT(MONTH FROM o.order_purchase_timestamp)
ORDER BY year, month;

-- ============================================================================
-- 3.4 REVIEWS ANALYSIS
-- ============================================================================

-- Average Review Score by Product Category
SELECT 
    p.product_category_name_english AS product_category,
    COUNT(DISTINCT ar.review_id) AS review_count,
    ROUND(AVG(ar.review_score)::NUMERIC, 2) AS avg_review_score,
    MIN(ar.review_score) AS min_score,
    MAX(ar.review_score) AS max_score
FROM analytics.order_reviews ar
JOIN staging.order_items oi ON ar.order_id = oi.order_id
JOIN analytics.dim_products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name_english
ORDER BY avg_review_score DESC;

-- Top 10 Best Reviewed Products
SELECT 
    p.product_category_name_english AS product_category,
    COUNT(DISTINCT ar.review_id) AS review_count,
    ROUND(AVG(ar.review_score)::NUMERIC, 2) AS avg_review_score
FROM analytics.order_reviews ar
JOIN staging.order_items oi ON ar.order_id = oi.order_id
JOIN analytics.dim_products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name_english
HAVING COUNT(DISTINCT ar.review_id) >= 10  -- Filter for categories with at least 10 reviews
ORDER BY avg_review_score DESC
LIMIT 10;

-- Top 10 Worst Reviewed Products
SELECT 
    p.product_category_name_english AS product_category,
    COUNT(DISTINCT ar.review_id) AS review_count,
    ROUND(AVG(ar.review_score)::NUMERIC, 2) AS avg_review_score
FROM analytics.order_reviews ar
JOIN staging.order_items oi ON ar.order_id = oi.order_id
JOIN analytics.dim_products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name_english
HAVING COUNT(DISTINCT ar.review_id) >= 10  -- Filter for categories with at least 10 reviews
ORDER BY avg_review_score ASC
LIMIT 10;

-- Review Score Distribution
SELECT 
    ar.review_score AS score,
    COUNT(*) AS count,
    ROUND(COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM analytics.order_reviews) * 100, 2) AS pct
FROM analytics.order_reviews ar
GROUP BY ar.review_score
ORDER BY ar.review_score DESC;

-- ============================================================================
-- 3.5 DELIVERY ANALYSIS
-- ============================================================================

-- Delivery Performance: Estimated vs Actual
SELECT 
    o.order_id,
    o.order_purchase_timestamp,
    o.order_estimated_delivery_date,
    o.order_delivered_customer_date,
    (o.order_delivered_customer_date - o.order_estimated_delivery_date) AS delivery_delay,
    EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date))::INT AS delay_days,
    CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status
FROM staging.orders o
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
LIMIT 20;

-- Delivery Delay Statistics (for delivered orders)
SELECT 
    'Total Delivered Orders' AS metric,
    COUNT(DISTINCT o.order_id)::TEXT AS value
FROM staging.orders o
WHERE o.order_status = 'delivered'
UNION ALL
SELECT 
    'On-Time Deliveries',
    COUNT(DISTINCT o.order_id)::TEXT
FROM staging.orders o
WHERE o.order_status = 'delivered' 
  AND o.order_delivered_customer_date <= o.order_estimated_delivery_date
UNION ALL
SELECT 
    'Late Deliveries',
    COUNT(DISTINCT o.order_id)::TEXT
FROM staging.orders o
WHERE o.order_status = 'delivered' 
  AND o.order_delivered_customer_date > o.order_estimated_delivery_date
UNION ALL
SELECT 
    'Average Delay (Days)',
    ROUND(AVG(EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)))::NUMERIC, 2)::TEXT
FROM staging.orders o
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
UNION ALL
SELECT 
    'Median Delay (Days)',
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)))::TEXT
FROM staging.orders o
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL;

-- Purchase to Delivery Time
SELECT 
    EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))::INT AS delivery_days,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(COUNT(DISTINCT o.order_id)::NUMERIC / 
        (SELECT COUNT(DISTINCT order_id) FROM staging.orders WHERE order_status = 'delivered') * 100, 2) AS pct
FROM staging.orders o
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))
ORDER BY delivery_days;

-- Average Delivery Time by State
SELECT 
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(AVG(EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)))::NUMERIC, 2) AS avg_delivery_days,
    ROUND(AVG(EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)))::NUMERIC, 2) AS avg_delay_days
FROM staging.orders o
JOIN staging.customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;

/*
================================================================================
PART 4: KEY METRICS & AGGREGATIONS
================================================================================
*/

-- ============================================================================
-- 4.1 OVERALL BUSINESS METRICS
-- ============================================================================

-- Key Business Metrics Summary
SELECT 
    'Total Revenue' AS metric,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2)::TEXT AS value
FROM staging.order_items oi
UNION ALL
SELECT 
    'Total Orders',
    COUNT(DISTINCT o.order_id)::TEXT
FROM staging.orders o
UNION ALL
SELECT 
    'Total Order Items',
    COUNT(*)::TEXT
FROM staging.order_items
UNION ALL
SELECT 
    'Average Order Value',
    ROUND((SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id))::NUMERIC, 2)::TEXT
FROM staging.orders o
JOIN staging.order_items oi ON o.order_id = oi.order_id
UNION ALL
SELECT 
    'Total Customers',
    COUNT(DISTINCT customer_id)::TEXT
FROM staging.customers
UNION ALL
SELECT 
    'Total Sellers',
    COUNT(DISTINCT seller_id)::TEXT
FROM staging.sellers
UNION ALL
SELECT 
    'Total Product Categories',
    COUNT(DISTINCT product_category_name_english)::TEXT
FROM analytics.dim_products;

-- ============================================================================
-- 4.2 SELLER PERFORMANCE METRICS
-- ============================================================================

-- Top 10 Sellers by Revenue
SELECT 
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS total_items,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS total_sales,
    ROUND(SUM(oi.freight_value)::NUMERIC, 2) AS total_freight,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_item_price
FROM staging.order_items oi
JOIN staging.sellers s ON oi.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY total_sales DESC
LIMIT 10;

-- Top 10 Sellers by Number of Orders
SELECT 
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_revenue
FROM staging.order_items oi
JOIN staging.sellers s ON oi.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY total_orders DESC
LIMIT 10;

-- ============================================================================
-- 4.3 PAYMENT METHOD ANALYSIS
-- ============================================================================

-- Payment Type Distribution
SELECT 
    op.payment_type,
    COUNT(DISTINCT op.order_id) AS order_count,
    ROUND(SUM(op.payment_value)::NUMERIC, 2) AS total_value,
    ROUND(AVG(op.payment_value)::NUMERIC, 2) AS avg_value,
    ROUND(COUNT(DISTINCT op.order_id)::NUMERIC / 
        (SELECT COUNT(DISTINCT order_id) FROM staging.order_payments) * 100, 2) AS pct_of_orders
FROM staging.order_payments op
GROUP BY op.payment_type
ORDER BY order_count DESC;

-- Payment Installments Analysis
SELECT 
    op.payment_installments AS installments,
    COUNT(DISTINCT op.order_id) AS order_count,
    ROUND(SUM(op.payment_value)::NUMERIC, 2) AS total_value,
    ROUND(AVG(op.payment_value)::NUMERIC, 2) AS avg_value
FROM staging.order_payments op
GROUP BY op.payment_installments
ORDER BY installments;

-- ============================================================================
-- 4.4 CUSTOMER METRICS
-- ============================================================================

-- Customer Order Frequency
SELECT 
    cu.customer_unique_id,
    COUNT(DISTINCT cu.customer_id) AS customer_ids,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS lifetime_value
FROM staging.customers cu
LEFT JOIN staging.orders o ON cu.customer_id = o.customer_id
LEFT JOIN staging.order_items oi ON o.order_id = oi.order_id
GROUP BY cu.customer_unique_id
HAVING COUNT(DISTINCT o.order_id) > 0
ORDER BY total_orders DESC
LIMIT 20;

-- Distribution of Customers by Number of Orders
SELECT 
    order_count,
    COUNT(*) AS num_customers
FROM (
    SELECT 
        cu.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM staging.customers cu
    LEFT JOIN staging.orders o ON cu.customer_id = o.customer_id
    GROUP BY cu.customer_unique_id
) subq
GROUP BY order_count
ORDER BY order_count DESC;

-- ============================================================================
-- 4.5 PRODUCT PERFORMANCE METRICS
-- ============================================================================

-- Product Category Performance Summary
SELECT 
    p.product_category_name_english,
    COUNT(DISTINCT oi.order_id) AS orders_containing_category,
    COUNT(*) AS units_sold,
    ROUND(SUM(oi.price)::NUMERIC, 2) AS product_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_price,
    ROUND(AVG(COALESCE(ar.review_score, 0))::NUMERIC, 2) AS avg_review_score,
    COUNT(DISTINCT ar.review_id) AS total_reviews
FROM staging.order_items oi
JOIN analytics.dim_products p ON oi.product_id = p.product_id
LEFT JOIN analytics.order_reviews ar ON oi.order_id = ar.order_id
GROUP BY p.product_category_name_english
ORDER BY product_revenue DESC;

-- ============================================================================
-- 4.6 ORDER STATUS DISTRIBUTION
-- ============================================================================

SELECT 
    o.order_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM staging.orders) * 100, 2) AS pct_of_total,
    ROUND(SUM(COALESCE(oi.price + oi.freight_value, 0))::NUMERIC, 2) AS total_value
FROM staging.orders o
LEFT JOIN staging.order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_status
ORDER BY order_count DESC;

-- ============================================================================
-- 4.7 SEASONALITY ANALYSIS
-- ============================================================================

-- Revenue by Quarter
SELECT 
    EXTRACT(YEAR FROM o.order_purchase_timestamp)::INT AS year,
    ('Q' || EXTRACT(QUARTER FROM o.order_purchase_timestamp)::INT) AS quarter,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_revenue
FROM staging.orders o
JOIN staging.order_items oi ON o.order_id = oi.order_id
GROUP BY EXTRACT(YEAR FROM o.order_purchase_timestamp), 
         EXTRACT(QUARTER FROM o.order_purchase_timestamp)
ORDER BY year, quarter;

-- Revenue by Month (across all years)
SELECT 
    EXTRACT(MONTH FROM o.order_purchase_timestamp)::INT AS month,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(oi.price + oi.freight_value)::NUMERIC, 2) AS avg_order_value
FROM staging.orders o
JOIN staging.order_items oi ON o.order_id = oi.order_id
GROUP BY EXTRACT(MONTH FROM o.order_purchase_timestamp)
ORDER BY month;

/*
================================================================================
END OF SQL DOCUMENTATION
================================================================================

SUMMARY OF ANALYSES CONVERTED:
✓ Data Overview - Basic statistics and structure validation
✓ Data Quality Checks - Null values, duplicates, orphan records, cardinality
✓ Exploratory Data Analysis - Products, regions, time series, reviews, delivery
✓ Key Metrics - Business KPIs, seller performance, customer analysis

All queries are optimized for PostgreSQL and use the staging/analytics schema structure
from the olist_analytics database.
*/
