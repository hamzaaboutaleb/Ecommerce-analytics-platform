-- =====================================================================
-- RFM SEGMENTATION: Recency, Frequency, Monetary
-- =====================================================================

-- -----------------------------------------------------------------
-- 1. RAW RFM VALUES PER CUSTOMER
-- -----------------------------------------------------------------
WITH ref_date AS (
    SELECT MAX(order_time) AS max_date
    FROM orders
),
rfm_raw AS (
    SELECT
        o.customer_id,
        EXTRACT(DAY FROM (rd.max_date - MAX(o.order_time))) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(o.total_usd)::numeric, 2) AS monetary
    FROM orders o
    CROSS JOIN ref_date rd
    GROUP BY o.customer_id, rd.max_date
)
SELECT *
FROM rfm_raw
ORDER BY monetary DESC;

-- -----------------------------------------------------------------
-- 2. RFM SCORES (1-5 scale using quintiles via NTILE)
-- -----------------------------------------------------------------
WITH ref_date AS (
    SELECT MAX(order_time) AS max_date
    FROM orders
),
rfm_raw AS (
    SELECT
        o.customer_id,
        EXTRACT(DAY FROM (rd.max_date - MAX(o.order_time))) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(o.total_usd) AS monetary
    FROM orders o
    CROSS JOIN ref_date rd
    GROUP BY o.customer_id, rd.max_date
),
rfm_scored AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_raw
)
SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary::numeric, 2) AS monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score) AS rfm_total,
    CONCAT(r_score, f_score, m_score) AS rfm_code
FROM rfm_scored
ORDER BY rfm_total DESC;

-- -----------------------------------------------------------------
-- 3. CUSTOMER SEGMENTS BASED ON RFM SCORE
-- -----------------------------------------------------------------
WITH ref_date AS (
    SELECT MAX(order_time) AS max_date
    FROM orders
),
rfm_raw AS (
    SELECT
        o.customer_id,
        EXTRACT(DAY FROM (rd.max_date - MAX(o.order_time))) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(o.total_usd) AS monetary
    FROM orders o
    CROSS JOIN ref_date rd
    GROUP BY o.customer_id, rd.max_date
),
rfm_scored AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_raw
)
SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary::numeric, 2) AS monetary,
    r_score,
    f_score,
    m_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
        WHEN r_score >= 3 AND m_score >= 4 THEN 'Big Spenders'
        ELSE 'Needs Attention'
    END AS customer_segment
FROM rfm_scored
ORDER BY customer_segment, monetary DESC;

-- -----------------------------------------------------------------
-- 4. SEGMENT SUMMARY (counts & revenue contribution)
-- -----------------------------------------------------------------
WITH ref_date AS (
    SELECT MAX(order_time) AS max_date
    FROM orders
),
rfm_raw AS (
    SELECT
        o.customer_id,
        EXTRACT(DAY FROM (rd.max_date - MAX(o.order_time))) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(o.total_usd) AS monetary
    FROM orders o
    CROSS JOIN ref_date rd
    GROUP BY o.customer_id, rd.max_date
),
rfm_scored AS (
    SELECT
        customer_id,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_raw
),
segmented AS (
    SELECT
        customer_id,
        monetary,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
            WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
            WHEN r_score >= 3 AND m_score >= 4 THEN 'Big Spenders'
            ELSE 'Needs Attention'
        END AS customer_segment
    FROM rfm_scored
)
SELECT
    customer_segment,
    COUNT(*) AS num_customers,
    ROUND(SUM(monetary)::numeric, 2) AS total_revenue,
    ROUND(
        (100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER ())::numeric,
        2
    ) AS pct_of_total_revenue
FROM segmented
GROUP BY customer_segment
ORDER BY total_revenue DESC;