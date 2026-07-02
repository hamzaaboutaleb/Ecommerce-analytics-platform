-- =====================================================================
-- FUNNEL ANALYSIS: Clickstream to Purchase
-- Assumes events.event_type contains values such as:
-- 'view', 'add_to_cart', 'checkout', 'purchase'
-- Adjust the literal values below to match your actual event_type
-- values (run the "event type audit" query first if unsure).
-- =====================================================================

-- -----------------------------------------------------------------
-- 0. EVENT TYPE AUDIT — run this first to confirm actual labels
-- -----------------------------------------------------------------
SELECT event_type, COUNT(*) AS num_events
FROM events
GROUP BY event_type
ORDER BY num_events DESC;

-- -----------------------------------------------------------------
-- 1. OVERALL FUNNEL COUNTS (distinct sessions at each stage)
-- -----------------------------------------------------------------
WITH funnel AS (
    SELECT
        session_id,
        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event_type = 'checkout' THEN 1 ELSE 0 END) AS checked_out,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY session_id
)
SELECT
    SUM(viewed) AS stage_1_view,
    SUM(added_to_cart) AS stage_2_add_to_cart,
    SUM(checked_out) AS stage_3_checkout,
    SUM(purchased) AS stage_4_purchase
FROM funnel;

-- -----------------------------------------------------------------
-- 2. FUNNEL CONVERSION RATES BETWEEN STAGES
-- -----------------------------------------------------------------
WITH funnel AS (
    SELECT
        session_id,
        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event_type = 'checkout' THEN 1 ELSE 0 END) AS checked_out,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY session_id
),
totals AS (
    SELECT
        SUM(viewed) AS n_view,
        SUM(added_to_cart) AS n_cart,
        SUM(checked_out) AS n_checkout,
        SUM(purchased) AS n_purchase
    FROM funnel
)
SELECT
    n_view,
    n_cart,
    n_checkout,
    n_purchase,
    ROUND(100.0 * n_cart / NULLIF(n_view, 0), 2) AS view_to_cart_pct,
    ROUND(100.0 * n_checkout / NULLIF(n_cart, 0), 2) AS cart_to_checkout_pct,
    ROUND(100.0 * n_purchase / NULLIF(n_checkout, 0), 2) AS checkout_to_purchase_pct,
    ROUND(100.0 * n_purchase / NULLIF(n_view, 0), 2) AS overall_view_to_purchase_pct
FROM totals;

-- -----------------------------------------------------------------
-- 3. FUNNEL BY DEVICE (join sessions to get device)
-- -----------------------------------------------------------------
WITH funnel AS (
    SELECT
        e.session_id,
        s.device,
        MAX(CASE WHEN e.event_type = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN e.event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN e.event_type = 'checkout' THEN 1 ELSE 0 END) AS checked_out,
        MAX(CASE WHEN e.event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
    FROM events e
    JOIN sessions s ON s.session_id = e.session_id
    GROUP BY e.session_id, s.device
)
SELECT
    device,
    SUM(viewed) AS n_view,
    SUM(added_to_cart) AS n_cart,
    SUM(checked_out) AS n_checkout,
    SUM(purchased) AS n_purchase,
    ROUND(100.0 * SUM(purchased) / NULLIF(SUM(viewed), 0), 2) AS view_to_purchase_pct
FROM funnel
GROUP BY device
ORDER BY view_to_purchase_pct DESC;

-- -----------------------------------------------------------------
-- 4. DROP-OFF BY PRODUCT (which products get abandoned most after cart add)
-- -----------------------------------------------------------------
WITH cart_adds AS (
    SELECT session_id, product_id
    FROM events
    WHERE event_type = 'add_to_cart'
),
purchases AS (
    SELECT session_id, product_id
    FROM events
    WHERE event_type = 'purchase'
)
SELECT
    p.name AS product_name,
    p.category,
    COUNT(DISTINCT ca.session_id) AS num_cart_adds,
    COUNT(DISTINCT pu.session_id) AS num_purchases,
    ROUND(100.0 * (COUNT(DISTINCT ca.session_id) - COUNT(DISTINCT pu.session_id))
        / NULLIF(COUNT(DISTINCT ca.session_id), 0), 2) AS abandonment_rate_pct
FROM cart_adds ca
JOIN products p ON p.product_id = ca.product_id
LEFT JOIN purchases pu
    ON pu.session_id = ca.session_id AND pu.product_id = ca.product_id
GROUP BY p.name, p.category
ORDER BY abandonment_rate_pct DESC;

-- -----------------------------------------------------------------
-- 5. TIME TO CONVERT (avg minutes from first view to purchase, per session)
-- -----------------------------------------------------------------
WITH session_times AS (
    SELECT
        session_id,
        MIN(timestamp) FILTER (WHERE event_type = 'view') AS first_view,
        MIN(timestamp) FILTER (WHERE event_type = 'purchase') AS purchase_time
    FROM events
    GROUP BY session_id
)
SELECT
    ROUND(AVG(EXTRACT(EPOCH FROM (purchase_time - first_view)) / 60.0), 2) AS avg_minutes_to_purchase
FROM session_times
WHERE first_view IS NOT NULL AND purchase_time IS NOT NULL;
