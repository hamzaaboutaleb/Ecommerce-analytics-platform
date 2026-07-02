-- =====================================================================
-- COHORT ANALYSIS: Retention by Signup Month
-- =====================================================================

-- -----------------------------------------------------------------
-- 1. COHORT SIZE (customers by signup month)
-- -----------------------------------------------------------------
WITH cohorts AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', signup_date) AS cohort_month
    FROM customers
)
SELECT
    cohort_month,
    COUNT(*) AS num_customers
FROM cohorts
GROUP BY cohort_month
ORDER BY cohort_month;

-- -----------------------------------------------------------------
-- 2. MONTHLY RETENTION MATRIX
-- For each cohort (signup month), count how many customers placed
-- an order in each subsequent "month offset" (0 = signup month,
-- 1 = month after, etc.)
-- -----------------------------------------------------------------
WITH cohorts AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', signup_date) AS cohort_month
    FROM customers
),
customer_orders AS (
    SELECT
        o.customer_id,
        DATE_TRUNC('month', o.order_time) AS order_month
    FROM orders o
    GROUP BY o.customer_id, DATE_TRUNC('month', o.order_time)
),
cohort_activity AS (
    SELECT
        c.cohort_month,
        co.order_month,
        -- month offset between signup and order activity
        (EXTRACT(YEAR FROM co.order_month) - EXTRACT(YEAR FROM c.cohort_month)) * 12
          + (EXTRACT(MONTH FROM co.order_month) - EXTRACT(MONTH FROM c.cohort_month)) AS month_offset,
        c.customer_id
    FROM cohorts c
    JOIN customer_orders co ON co.customer_id = c.customer_id
    WHERE co.order_month >= c.cohort_month
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM cohorts
    GROUP BY cohort_month
)
SELECT
    ca.cohort_month,
    cs.cohort_size,
    ca.month_offset,
    COUNT(DISTINCT ca.customer_id) AS active_customers,
    ROUND(100.0 * COUNT(DISTINCT ca.customer_id) / NULLIF(cs.cohort_size, 0), 2) AS retention_pct
FROM cohort_activity ca
JOIN cohort_sizes cs ON cs.cohort_month = ca.cohort_month
GROUP BY ca.cohort_month, cs.cohort_size, ca.month_offset
ORDER BY ca.cohort_month, ca.month_offset;

-- -----------------------------------------------------------------
-- 3. RETENTION MATRIX PIVOTED (month offset 0-6 as columns)
-- Useful for feeding directly into a Streamlit heatmap
-- -----------------------------------------------------------------
WITH cohorts AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', signup_date) AS cohort_month
    FROM customers
),
customer_orders AS (
    SELECT
        o.customer_id,
        DATE_TRUNC('month', o.order_time) AS order_month
    FROM orders o
    GROUP BY o.customer_id, DATE_TRUNC('month', o.order_time)
),
cohort_activity AS (
    SELECT
        c.cohort_month,
        c.customer_id,
        (EXTRACT(YEAR FROM co.order_month) - EXTRACT(YEAR FROM c.cohort_month)) * 12
          + (EXTRACT(MONTH FROM co.order_month) - EXTRACT(MONTH FROM c.cohort_month)) AS month_offset
    FROM cohorts c
    JOIN customer_orders co ON co.customer_id = c.customer_id
    WHERE co.order_month >= c.cohort_month
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM cohorts
    GROUP BY cohort_month
)
SELECT
    ca.cohort_month,
    cs.cohort_size,
    ROUND(100.0 * COUNT(DISTINCT ca.customer_id) FILTER (WHERE ca.month_offset = 0) / NULLIF(cs.cohort_size,0), 2) AS m0,
    ROUND(100.0 * COUNT(DISTINCT ca.customer_id) FILTER (WHERE ca.month_offset = 1) / NULLIF(cs.cohort_size,0), 2) AS m1,
    ROUND(100.0 * COUNT(DISTINCT ca.customer_id) FILTER (WHERE ca.month_offset = 2) / NULLIF(cs.cohort_size,0), 2) AS m2,
    ROUND(100.0 * COUNT(DISTINCT ca.customer_id) FILTER (WHERE ca.month_offset = 3) / NULLIF(cs.cohort_size,0), 2) AS m3,
    ROUND(100.0 * COUNT(DISTINCT ca.customer_id) FILTER (WHERE ca.month_offset = 4) / NULLIF(cs.cohort_size,0), 2) AS m4,
    ROUND(100.0 * COUNT(DISTINCT ca.customer_id) FILTER (WHERE ca.month_offset = 5) / NULLIF(cs.cohort_size,0), 2) AS m5,
    ROUND(100.0 * COUNT(DISTINCT ca.customer_id) FILTER (WHERE ca.month_offset = 6) / NULLIF(cs.cohort_size,0), 2) AS m6
FROM cohort_activity ca
JOIN cohort_sizes cs ON cs.cohort_month = ca.cohort_month
GROUP BY ca.cohort_month, cs.cohort_size
ORDER BY ca.cohort_month;
