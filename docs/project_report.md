# Project Report: E-Commerce Analytics Platform

## 1. Executive Summary

This report documents the design, build, and analytical output of the E-Commerce Analytics Platform — an end-to-end data pipeline and business intelligence dashboard built on a simulated e-commerce dataset. The project covers the full analytics lifecycle: raw data ingestion, database modeling, ETL, SQL-based analysis, and interactive visualization.

> 📸 **Screenshot placeholder** — add a title-slide style screenshot of the dashboard here as the report's visual anchor.
> `![Dashboard cover](screenshots/cover.png)`

---

## 2. Objectives

The platform was built to answer five core business questions:

1. **Revenue performance** — How is revenue trending, and what drives AOV differences across countries, devices, and payment methods?
2. **Customer retention** — How well does each monthly signup cohort retain over time?
3. **Customer value** — Which customers are most valuable, and how should they be segmented for targeted marketing (RFM)?
4. **Conversion behavior** — Where in the browsing-to-purchase journey do customers drop off?
5. **Marketing efficiency** — Which acquisition channels generate the most revenue per session?

---

## 3. Data Sources

Seven raw CSV files formed the foundation of the platform:

| File | Grain | Purpose |
|---|---|---|
| `customers.csv` | 1 row per customer | Demographics, signup date, marketing opt-in |
| `products.csv` | 1 row per product | Catalog, pricing, cost, margin |
| `sessions.csv` | 1 row per browsing session | Device, traffic source, country |
| `orders.csv` | 1 row per order | Order-level totals, payment, discount |
| `order_items.csv` | 1 row per line item | Product-level detail within an order |
| `events.csv` | 1 row per clickstream event | Page views, cart adds, checkouts, purchases |
| `reviews.csv` | 1 row per review | Post-purchase product ratings/feedback |

Full column-level definitions are in [`data_dictionary.md`](data_dictionary.md).

---

## 4. Architecture & Design Decisions

### 4.1 Why PostgreSQL
PostgreSQL was chosen over a flat-file/pandas-only approach because:
- It enforces a relational schema (primary keys, types) that catches data quality issues early.
- Window functions (`NTILE`, `LAG`, cumulative sums) make cohort and RFM analysis far cleaner in SQL than in pandas.
- It mirrors what a production analytics stack would actually look like, which matters for portfolio purposes.

### 4.2 Schema Design
The schema is a straightforward **star-like model** centered on `orders` and `order_items`, with `customers`, `products`, and `sessions` as dimension-like reference tables, and `events` capturing pre-purchase behavior. `reviews` links back to both `orders` and `products` for post-purchase sentiment.

Key relationships:
- `orders.customer_id → customers.customer_id`
- `order_items.order_id → orders.order_id`
- `order_items.product_id → products.product_id`
- `sessions.customer_id → customers.customer_id`
- `events.session_id → sessions.session_id`
- `reviews.order_id → orders.order_id`, `reviews.product_id → products.product_id`

> 📸 **Screenshot placeholder** — if you generated an ER diagram (e.g. via pgAdmin's ERD tool or dbdiagram.io), add it here.
> `![Entity relationship diagram](screenshots/erd.png)`

### 4.3 ETL Approach
The ETL pipeline (`src/etl/load_data.py`) follows a simple, transparent pattern rather than a heavyweight orchestration tool, since the project runs as a one-off/scheduled batch load rather than a continuous pipeline:

1. **Extract** — read each CSV with pandas.
2. **Transform** — parse dates, coerce types, handle nulls/duplicates, standardize categorical values (e.g. device names, country codes).
3. **Load** — write to PostgreSQL via `to_sql()`, table by table, respecting foreign key order (dimension tables first, fact tables after).

---

## 5. Analytical Methodology

### 5.1 KPI Analysis
Core commerce metrics (revenue, AOV, conversion rate) were computed both in aggregate and cut by country, device, and payment method to surface where performance varies.

### 5.2 Cohort Retention
Customers were grouped into monthly cohorts by `signup_date`. Retention at month offset *N* is defined as the percentage of a cohort that placed **at least one order** in the *N*th month after signup. This is the standard approach for subscription/repeat-purchase retention analysis.

### 5.3 RFM Segmentation
Each customer was scored 1–5 on three dimensions using quintiles (`NTILE(5)`):
- **Recency** — days since last order (lower = better, scored inversely)
- **Frequency** — number of distinct orders
- **Monetary** — total lifetime spend

Scores were combined into rule-based segments (Champions, Loyal Customers, At Risk, Lost, etc.) — a widely used, interpretable alternative to clustering for this kind of segmentation.

### 5.4 Funnel Analysis
The `events` table was used to reconstruct a session-level funnel across four stages: **view → add to cart → checkout → purchase**. Conversion rate was calculated stage-to-stage and cumulatively from the first stage.

### 5.5 Marketing Performance
Sessions and orders were joined by acquisition `source` to compute conversion rate and **revenue per session** — a more channel-agnostic efficiency metric than AOV alone, since it accounts for channels that drive high traffic but low conversion.

---

## 6. Dashboard

The Streamlit dashboard (`dashboard/app.py`) exposes all five analyses interactively, with global filters for date range, country, source, and device. Design choices:
- **Plotly** was used over static matplotlib charts for hover tooltips and zoom/pan, which matter for exploratory analysis.
- Queries are parameterized (not string-concatenated) to avoid SQL injection and to allow safe caching per filter combination.
- `st.cache_data` with a 10-minute TTL balances responsiveness against database load.

> 📸 **Screenshot placeholder** — add 1 screenshot per dashboard tab (Overview, Cohort, RFM, Funnel, Marketing).
> `![Overview](screenshots/overview.png)`
> `![Cohort retention](screenshots/cohort.png)`
> `![RFM segments](screenshots/rfm.png)`
> `![Funnel](screenshots/funnel.png)`
> `![Marketing](screenshots/marketing.png)`

---

## 7. Key Findings

See [`insights.md`](insights.md) for the full write-up. Summary placeholder — replace with your actual numbers once the dashboard is populated:

- Total revenue: **[fill in]**
- Best-performing cohort: **[fill in]**
- Largest customer segment by revenue: **[fill in]**
- Biggest funnel drop-off stage: **[fill in]**
- Most efficient marketing channel: **[fill in]**

---

## 8. Limitations

- Session-to-order attribution uses a same-day heuristic in the absence of a direct `session_id → order_id` link in the schema; a production system would track this explicitly.
- RFM segment thresholds are rule-based rather than statistically validated (e.g. via clustering) — reasonable for a first pass, but worth revisiting with more data.
- The dataset is static/simulated, so trends should be read as illustrative rather than reflecting real seasonal effects.

---

## 9. Future Improvements

- Add a direct `session_id` foreign key to `orders` for exact conversion attribution.
- Automate the ETL with a scheduler (e.g. `cron`, Airflow) for recurring loads.
- Add predictive modeling (churn prediction, CLV forecasting) as a next-phase extension.
- Add authentication to the dashboard if deployed beyond local/portfolio use.

---

## 10. Conclusion

The platform demonstrates a complete, reproducible analytics workflow — from raw CSVs to a decision-ready dashboard — using an industry-standard stack (PostgreSQL, SQL, Python, Streamlit). It's structured so each layer (schema, ETL, SQL, dashboard) can be extended independently as the dataset or business questions grow.
