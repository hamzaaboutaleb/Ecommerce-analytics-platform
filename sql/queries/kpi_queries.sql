-- =====================================================================
-- KPI QUERIES: Revenue, AOV, Conversion Rate
-- FIX: ROUND(double precision, int) → cast to numeric
-- =====================================================================

-- -----------------------------------------------------------------
-- 1. TOTAL REVENUE (all-time)
-- -----------------------------------------------------------------
SELECT
    ROUND(SUM(total_usd)::numeric, 2) AS total_revenue_usd,
    COUNT(*) AS total_orders
FROM orders;

-- -----------------------------------------------------------------
-- 2. MONTHLY REVENUE TREND
-- -----------------------------------------------------------------
SELECT
    DATE_TRUNC('month', order_time) AS order_month,
    COUNT(*) AS num_orders,
    ROUND(SUM(total_usd)::numeric, 2) AS revenue_usd,
    ROUND(AVG(total_usd)::numeric, 2) AS avg_order_value
FROM orders
GROUP BY 1
ORDER BY 1;

-- -----------------------------------------------------------------
-- 3. AVERAGE ORDER VALUE (AOV) — overall and by segment
-- -----------------------------------------------------------------

-- Overall AOV
SELECT
    ROUND(AVG(total_usd)::numeric, 2) AS overall_aov
FROM orders;

-- AOV by country
SELECT
    country,
    COUNT(*) AS num_orders,
    ROUND(AVG(total_usd)::numeric, 2) AS aov,
    ROUND(SUM(total_usd)::numeric, 2) AS total_revenue
FROM orders
GROUP BY country
ORDER BY total_revenue DESC;

-- AOV by device
SELECT
    device,
    COUNT(*) AS num_orders,
    ROUND(AVG(total_usd)::numeric, 2) AS aov
FROM orders
GROUP BY device
ORDER BY aov DESC;

-- AOV by payment method
SELECT
    payment_method,
    COUNT(*) AS num_orders,
    ROUND(AVG(total_usd)::numeric, 2) AS aov,
    ROUND(SUM(total_usd)::numeric, 2) AS total_revenue
FROM orders
GROUP BY payment_method
ORDER BY total_revenue DESC;

-- -----------------------------------------------------------------
-- 4. CONVERSION RATE (session → order within 1 day)
-- -----------------------------------------------------------------
WITH session_orders AS (
    SELECT
        s.session_id,
        s.customer_id,
        s.start_time,
        CASE WHEN EXISTS (
            SELECT 1
            FROM orders o
            WHERE o.customer_id = s.customer_id
              AND o.order_time >= s.start_time
              AND o.order_time < s.start_time + INTERVAL '1 day'
        ) THEN 1 ELSE 0 END AS converted
    FROM sessions s
)
SELECT
    COUNT(*) AS total_sessions,
    SUM(converted) AS converted_sessions,
    ROUND(100.0 * SUM(converted) / NULLIF(COUNT(*), 0), 2) AS conversion_rate_pct
FROM session_orders;

-- -----------------------------------------------------------------
-- 5. CONVERSION RATE BY TRAFFIC SOURCE
-- -----------------------------------------------------------------
WITH session_orders AS (
    SELECT
        s.session_id,
        s.customer_id,
        s.source,
        s.start_time,
        CASE WHEN EXISTS (
            SELECT 1
            FROM orders o
            WHERE o.customer_id = s.customer_id
              AND o.order_time >= s.start_time
              AND o.order_time < s.start_time + INTERVAL '1 day'
        ) THEN 1 ELSE 0 END AS converted
    FROM sessions s
)
SELECT
    source,
    COUNT(*) AS total_sessions,
    SUM(converted) AS converted_sessions,
    ROUND(100.0 * SUM(converted) / NULLIF(COUNT(*), 0), 2) AS conversion_rate_pct
FROM session_orders
GROUP BY source
ORDER BY conversion_rate_pct DESC;

-- -----------------------------------------------------------------
-- 6. REVENUE BY PRODUCT CATEGORY
-- -----------------------------------------------------------------
SELECT
    p.category,
    COUNT(DISTINCT oi.order_id) AS num_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.line_total_usd)::numeric, 2) AS revenue_usd,
    ROUND(SUM((p.price_usd - p.cost_usd) * oi.quantity)::numeric, 2) AS gross_margin_usd
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY revenue_usd DESC;

-- -----------------------------------------------------------------
-- 7. TOP 10 PRODUCTS BY REVENUE
-- -----------------------------------------------------------------
SELECT
    p.product_id,
    p.name,
    p.category,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.line_total_usd)::numeric, 2) AS revenue_usd
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_id, p.name, p.category
ORDER BY revenue_usd DESC
LIMIT 10;

-- -----------------------------------------------------------------
-- 8. DISCOUNT IMPACT ON REVENUE
-- -----------------------------------------------------------------
SELECT
    CASE
        WHEN discount_pct = 0 THEN 'No Discount'
        WHEN discount_pct <= 10 THEN '1-10%'
        WHEN discount_pct <= 25 THEN '11-25%'
        ELSE '25%+'
    END AS discount_band,
    COUNT(*) AS num_orders,
    ROUND(AVG(total_usd)::numeric, 2) AS aov,
    ROUND(SUM(total_usd)::numeric, 2) AS revenue_usd
FROM orders
GROUP BY 1
ORDER BY 1;