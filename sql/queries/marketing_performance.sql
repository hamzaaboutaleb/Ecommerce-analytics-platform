-- =====================================================================
-- MARKETING PERFORMANCE: Source / Channel Analysis
-- =====================================================================

-- -----------------------------------------------------------------
-- 1. SESSIONS, ORDERS & REVENUE BY SOURCE
-- -----------------------------------------------------------------
WITH source_sessions AS (
    SELECT
        source,
        COUNT(*) AS num_sessions
    FROM sessions
    GROUP BY source
),
source_orders AS (
    SELECT
        source,
        COUNT(*) AS num_orders,
        SUM(total_usd) AS revenue
    FROM orders
    GROUP BY source
)
SELECT
    COALESCE(ss.source, so.source) AS source,
    COALESCE(ss.num_sessions, 0) AS num_sessions,
    COALESCE(so.num_orders, 0) AS num_orders,
    ROUND(COALESCE(so.revenue, 0)::numeric, 2) AS revenue_usd,
    ROUND(
        (100.0 * COALESCE(so.num_orders, 0) / NULLIF(ss.num_sessions, 0))::numeric,
        2
    ) AS conversion_rate_pct,
    ROUND(
        (COALESCE(so.revenue, 0) / NULLIF(so.num_orders, 0))::numeric,
        2
    ) AS aov
FROM source_sessions ss
FULL OUTER JOIN source_orders so
    ON so.source = ss.source
ORDER BY revenue_usd DESC;

-- -----------------------------------------------------------------
-- 2. REVENUE PER SESSION (RPS) BY SOURCE — efficiency metric
-- -----------------------------------------------------------------
WITH source_sessions AS (
    SELECT
        source,
        COUNT(*) AS num_sessions
    FROM sessions
    GROUP BY source
),
source_revenue AS (
    SELECT
        source,
        SUM(total_usd) AS revenue
    FROM orders
    GROUP BY source
)
SELECT
    ss.source,
    ss.num_sessions,
    ROUND(COALESCE(sr.revenue, 0)::numeric, 2) AS revenue_usd,
    ROUND(
        (COALESCE(sr.revenue, 0) / NULLIF(ss.num_sessions, 0))::numeric,
        2
    ) AS revenue_per_session
FROM source_sessions ss
LEFT JOIN source_revenue sr
    ON sr.source = ss.source
ORDER BY revenue_per_session DESC;

-- -----------------------------------------------------------------
-- 3. NEW VS RETURNING CUSTOMER REVENUE BY SOURCE
-- -----------------------------------------------------------------
WITH first_orders AS (
    SELECT
        customer_id,
        order_id,
        order_time,
        source,
        total_usd,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_time
        ) AS order_seq
    FROM orders
)
SELECT
    source,
    CASE
        WHEN order_seq = 1 THEN 'New Customer'
        ELSE 'Returning Customer'
    END AS customer_type,
    COUNT(*) AS num_orders,
    ROUND(SUM(total_usd)::numeric, 2) AS revenue_usd
FROM first_orders
GROUP BY source, customer_type
ORDER BY source, customer_type;

-- -----------------------------------------------------------------
-- 4. MONTHLY TREND BY SOURCE
-- -----------------------------------------------------------------
SELECT
    DATE_TRUNC('month', order_time) AS order_month,
    source,
    COUNT(*) AS num_orders,
    ROUND(SUM(total_usd)::numeric, 2) AS revenue_usd
FROM orders
GROUP BY 1, 2
ORDER BY 1, 2;

-- -----------------------------------------------------------------
-- 5. SOURCE x DEVICE PERFORMANCE MATRIX
-- -----------------------------------------------------------------
SELECT
    source,
    device,
    COUNT(*) AS num_orders,
    ROUND(SUM(total_usd)::numeric, 2) AS revenue_usd,
    ROUND(AVG(total_usd)::numeric, 2) AS aov
FROM orders
GROUP BY source, device
ORDER BY revenue_usd DESC;

-- -----------------------------------------------------------------
-- 6. MARKETING OPT-IN IMPACT
-- -----------------------------------------------------------------
SELECT
    c.marketing_opt_in,
    COUNT(DISTINCT c.customer_id) AS num_customers,
    COUNT(o.order_id) AS num_orders,
    ROUND(COALESCE(SUM(o.total_usd), 0)::numeric, 2) AS total_revenue,
    ROUND(
        (
            COALESCE(SUM(o.total_usd), 0)
            / NULLIF(COUNT(DISTINCT c.customer_id), 0)
        )::numeric,
        2
    ) AS revenue_per_customer
FROM customers c
LEFT JOIN orders o
    ON o.customer_id = c.customer_id
GROUP BY c.marketing_opt_in
ORDER BY c.marketing_opt_in;