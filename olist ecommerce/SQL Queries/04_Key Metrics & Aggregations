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
