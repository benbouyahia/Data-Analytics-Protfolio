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
