"""
E-Commerce Analytics Platform — Streamlit Dashboard
=====================================================
Run with:  streamlit run app.py

Requires a running PostgreSQL instance loaded via src/etl/load_data.py.
Connection settings are read from environment variables (see bottom of
this docstring) or from a .streamlit/secrets.toml file.

Environment variables (fallback if secrets.toml is not present):
    DB_HOST      (default: localhost)
    DB_PORT      (default: 5432)
    DB_NAME      (default: ecommerce_analytics)
    DB_USER      (default: postgres)
    DB_PASSWORD  (default: postgres)

secrets.toml example:
    [postgres]
    host = "localhost"
    port = 5432
    dbname = "ecommerce_analytics"
    user = "postgres"
    password = "postgres"
"""

import os
from datetime import date

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st
from sqlalchemy import create_engine, text

# ============================================================
# PAGE CONFIG & STYLING
# ============================================================
st.set_page_config(
    page_title="E-Commerce Analytics Platform",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded",
)

CUSTOM_CSS = """
<style>
    .stMetric {
        background-color: #f8f9fb;
        border: 1px solid #e6e6e6;
        border-radius: 10px;
        padding: 12px 16px;
    }
    .stMetric label {
        font-weight: 600;
        color: #555;
    }
    div[data-testid="stMetricValue"] {
        font-size: 1.6rem;
        color: #1f2937;
    }
    h1, h2, h3 {
        color: #1f2937;
    }
    .section-divider {
        margin-top: 0.5rem;
        margin-bottom: 1.2rem;
        border-bottom: 1px solid #eaeaea;
    }
</style>
"""
st.markdown(CUSTOM_CSS, unsafe_allow_html=True)


# ============================================================
# DATABASE CONNECTION
# ============================================================
@st.cache_resource(show_spinner=False)
@st.cache_resource(show_spinner=False)
def get_engine():
    try:
        cfg = st.secrets["postgres"]

        host = cfg["host"]
        port = str(cfg["port"])
        dbname = cfg["dbname"]
        user = cfg["user"]
        password = cfg["password"]

    except Exception:
        host = os.getenv("DB_HOST", "localhost")
        port = os.getenv("DB_PORT", "5432")
        dbname = os.getenv("DB_NAME", "ecommerce_db")
        user = os.getenv("DB_USER", "postgres")
        password = os.getenv("DB_PASSWORD", "hamza2002")

    print("HOST:", repr(host))
    print("PORT:", repr(port))
    print("DB:", repr(dbname))
    print("USER:", repr(user))
    print("PASSWORD:", repr(password))

    conn_str = (
        f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{dbname}"
    )

    print("CONN:", conn_str.replace(password, "***"))

    return create_engine(conn_str, pool_pre_ping=True)

@st.cache_data(ttl=600, show_spinner=False)
def run_query(sql, params=None):
    engine = get_engine()
    with engine.connect() as conn:
        return pd.read_sql(text(sql), conn, params=params or {})


@st.cache_data(ttl=600, show_spinner=False)
def get_filter_bounds():
    df = run_query("SELECT MIN(order_time) AS min_d, MAX(order_time) AS max_d FROM orders;")
    if df.empty or pd.isna(df.loc[0, "min_d"]):
        return date(2023, 1, 1), date.today()
    return df.loc[0, "min_d"].date(), df.loc[0, "max_d"].date()


@st.cache_data(ttl=600, show_spinner=False)
def get_distinct(col, table):
    df = run_query(f"SELECT DISTINCT {col} FROM {table} WHERE {col} IS NOT NULL ORDER BY {col};")
    return df[col].tolist()


# ============================================================
# SIDEBAR FILTERS
# ============================================================
st.sidebar.title("📊 Filters")

min_date, max_date = get_filter_bounds()

date_range = st.sidebar.date_input(
    "Order date range",
    value=(min_date, max_date),
    min_value=min_date,
    max_value=max_date,
)
if isinstance(date_range, tuple) and len(date_range) == 2:
    start_date, end_date = date_range
else:
    start_date, end_date = min_date, max_date

countries = get_distinct("country", "orders")
sources = get_distinct("source", "orders")
devices = get_distinct("device", "orders")

sel_countries = st.sidebar.multiselect("Country", countries, default=[])
sel_sources = st.sidebar.multiselect("Source", sources, default=[])
sel_devices = st.sidebar.multiselect("Device", devices, default=[])

st.sidebar.markdown("---")
st.sidebar.caption("Data refreshes every 10 minutes. Use the button below to force a refresh.")
if st.sidebar.button("🔄 Refresh data"):
    st.cache_data.clear()
    st.rerun()

# Build a reusable WHERE clause fragment + params for orders-based queries
where_clauses = ["order_time BETWEEN :start_date AND :end_date"]
params = {"start_date": start_date, "end_date": end_date}

if sel_countries:
    where_clauses.append("country = ANY(:countries)")
    params["countries"] = sel_countries
if sel_sources:
    where_clauses.append("source = ANY(:sources)")
    params["sources"] = sel_sources
if sel_devices:
    where_clauses.append("device = ANY(:devices)")
    params["devices"] = sel_devices

WHERE_SQL = " AND ".join(where_clauses)


# ============================================================
# HEADER
# ============================================================
st.title("🛒 E-Commerce Analytics Platform")
st.caption(f"Showing data from **{start_date}** to **{end_date}**")

tab_overview, tab_cohort, tab_rfm, tab_funnel, tab_marketing = st.tabs(
    ["📈 Overview", "👥 Cohort Retention", "🎯 RFM Segments", "🔻 Funnel", "📣 Marketing"]
)

# ============================================================
# TAB 1 — OVERVIEW / KPIs
# ============================================================
with tab_overview:
    kpi_sql = f"""
        SELECT
            COUNT(*) AS num_orders,
            COALESCE(SUM(total_usd), 0) AS revenue,
            COALESCE(AVG(total_usd), 0) AS aov,
            COUNT(DISTINCT customer_id) AS unique_customers
        FROM orders
        WHERE {WHERE_SQL};
    """
    kpi_df = run_query(kpi_sql, params)
    row = kpi_df.iloc[0]

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Total Revenue", f"${row['revenue']:,.0f}")
    c2.metric("Total Orders", f"{int(row['num_orders']):,}")
    c3.metric("Avg. Order Value", f"${row['aov']:,.2f}")
    c4.metric("Unique Customers", f"{int(row['unique_customers']):,}")

    st.markdown('<div class="section-divider"></div>', unsafe_allow_html=True)

    col_left, col_right = st.columns((2, 1))

    with col_left:
        st.subheader("Revenue Trend")
        trend_sql = f"""
            SELECT DATE_TRUNC('day', order_time) AS d, SUM(total_usd) AS revenue, COUNT(*) AS orders
            FROM orders
            WHERE {WHERE_SQL}
            GROUP BY 1 ORDER BY 1;
        """
        trend_df = run_query(trend_sql, params)
        if not trend_df.empty:
            fig = go.Figure()
            fig.add_trace(go.Scatter(x=trend_df["d"], y=trend_df["revenue"],
                                      mode="lines", name="Revenue", fill="tozeroy",
                                      line=dict(color="#4C6EF5", width=2)))
            fig.update_layout(height=350, margin=dict(l=10, r=10, t=10, b=10),
                               yaxis_title="Revenue (USD)", xaxis_title="")
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No orders in the selected range.")

    with col_right:
        st.subheader("Revenue by Category")
        cat_sql = f"""
            SELECT p.category, SUM(oi.line_total_usd) AS revenue
            FROM order_items oi
            JOIN products p ON p.product_id = oi.product_id
            JOIN orders o ON o.order_id = oi.order_id
            WHERE {WHERE_SQL}
            GROUP BY p.category
            ORDER BY revenue DESC;
        """
        cat_df = run_query(cat_sql, params)
        if not cat_df.empty:
            fig = px.pie(cat_df, names="category", values="revenue", hole=0.5)
            fig.update_layout(height=350, margin=dict(l=10, r=10, t=10, b=10))
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No category data available.")

    col_a, col_b = st.columns(2)

    with col_a:
        st.subheader("Top 10 Products")
        top_sql = f"""
            SELECT p.name, SUM(oi.quantity) AS units, SUM(oi.line_total_usd) AS revenue
            FROM order_items oi
            JOIN products p ON p.product_id = oi.product_id
            JOIN orders o ON o.order_id = oi.order_id
            WHERE {WHERE_SQL}
            GROUP BY p.name
            ORDER BY revenue DESC
            LIMIT 10;
        """
        top_df = run_query(top_sql, params)
        if not top_df.empty:
            fig = px.bar(top_df.sort_values("revenue"), x="revenue", y="name", orientation="h",
                         labels={"revenue": "Revenue (USD)", "name": ""}, color_discrete_sequence=["#4C6EF5"])
            fig.update_layout(height=380, margin=dict(l=10, r=10, t=10, b=10))
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No product data available.")

    with col_b:
        st.subheader("AOV by Device")
        dev_sql = f"""
            SELECT device, AVG(total_usd) AS aov, COUNT(*) AS num_orders
            FROM orders
            WHERE {WHERE_SQL}
            GROUP BY device
            ORDER BY aov DESC;
        """
        dev_df = run_query(dev_sql, params)
        if not dev_df.empty:
            fig = px.bar(dev_df, x="device", y="aov", color="device",
                         labels={"aov": "AOV (USD)", "device": ""})
            fig.update_layout(height=380, margin=dict(l=10, r=10, t=10, b=10), showlegend=False)
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No device data available.")


# ============================================================
# TAB 2 — COHORT RETENTION
# ============================================================
with tab_cohort:
    st.subheader("Monthly Retention by Signup Cohort")
    st.caption("Percentage of each signup cohort that placed an order N months after signing up.")

    cohort_sql = """
        WITH cohorts AS (
            SELECT customer_id, DATE_TRUNC('month', signup_date) AS cohort_month
            FROM customers
        ),
        customer_orders AS (
            SELECT customer_id, DATE_TRUNC('month', order_time) AS order_month
            FROM orders
            GROUP BY customer_id, DATE_TRUNC('month', order_time)
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
            SELECT cohort_month, COUNT(*) AS cohort_size FROM cohorts GROUP BY cohort_month
        )
        SELECT
            ca.cohort_month,
            cs.cohort_size,
            ca.month_offset,
            ROUND(100.0 * COUNT(DISTINCT ca.customer_id) / NULLIF(cs.cohort_size, 0), 1) AS retention_pct
        FROM cohort_activity ca
        JOIN cohort_sizes cs ON cs.cohort_month = ca.cohort_month
        WHERE ca.month_offset BETWEEN 0 AND 11
        GROUP BY ca.cohort_month, cs.cohort_size, ca.month_offset
        ORDER BY ca.cohort_month, ca.month_offset;
    """
    cohort_df = run_query(cohort_sql)

    if cohort_df.empty:
        st.info("Not enough order history yet to build a retention matrix.")
    else:
        pivot = cohort_df.pivot(index="cohort_month", columns="month_offset", values="retention_pct")
        pivot.index = pivot.index.strftime("%Y-%m")
        fig = px.imshow(
            pivot,
            text_auto=".0f",
            color_continuous_scale="Blues",
            labels=dict(x="Months Since Signup", y="Signup Cohort", color="Retention %"),
            aspect="auto",
        )
        fig.update_layout(height=500, margin=dict(l=10, r=10, t=30, b=10))
        st.plotly_chart(fig, use_container_width=True)

        sizes = cohort_df[["cohort_month", "cohort_size"]].drop_duplicates()
        sizes["cohort_month"] = sizes["cohort_month"].dt.strftime("%Y-%m")
        st.caption("Cohort sizes:")
        st.dataframe(sizes.rename(columns={"cohort_month": "Cohort", "cohort_size": "Customers"}),
                     use_container_width=True, hide_index=True)


# ============================================================
# TAB 3 — RFM SEGMENTATION
# ============================================================
with tab_rfm:
    st.subheader("RFM Customer Segmentation")
    st.caption("Recency, Frequency, and Monetary scoring (1-5 quintiles) with rule-based segment labels.")

    rfm_sql = """
        WITH ref_date AS (SELECT MAX(order_time) AS max_date FROM orders),
        rfm_raw AS (
            SELECT
                o.customer_id,
                EXTRACT(DAY FROM (rd.max_date - MAX(o.order_time))) AS recency_days,
                COUNT(DISTINCT o.order_id) AS frequency,
                SUM(o.total_usd) AS monetary
            FROM orders o CROSS JOIN ref_date rd
            GROUP BY o.customer_id, rd.max_date
        ),
        rfm_scored AS (
            SELECT
                customer_id, recency_days, frequency, monetary,
                NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
                NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
                NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
            FROM rfm_raw
        )
        SELECT
            customer_id, recency_days, frequency, monetary, r_score, f_score, m_score,
            CASE
                WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
                WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
                WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
                WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
                WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
                WHEN r_score >= 3 AND m_score >= 4 THEN 'Big Spenders'
                ELSE 'Needs Attention'
            END AS segment
        FROM rfm_scored;
    """
    rfm_df = run_query(rfm_sql)

    if rfm_df.empty:
        st.info("No order data available to compute RFM segments.")
    else:
        seg_summary = (
            rfm_df.groupby("segment")
            .agg(customers=("customer_id", "count"), revenue=("monetary", "sum"))
            .reset_index()
            .sort_values("revenue", ascending=False)
        )

        col1, col2 = st.columns((1, 1))
        with col1:
            fig = px.bar(seg_summary, x="segment", y="customers", color="segment",
                         labels={"customers": "# Customers", "segment": ""})
            fig.update_layout(height=380, margin=dict(l=10, r=10, t=10, b=10), showlegend=False)
            st.plotly_chart(fig, use_container_width=True)
        with col2:
            fig = px.pie(seg_summary, names="segment", values="revenue", hole=0.45)
            fig.update_layout(height=380, margin=dict(l=10, r=10, t=10, b=10))
            st.plotly_chart(fig, use_container_width=True)

        st.markdown("#### Segment Detail")
        st.dataframe(
            seg_summary.rename(columns={"segment": "Segment", "customers": "Customers", "revenue": "Revenue (USD)"}),
            use_container_width=True, hide_index=True,
        )

        with st.expander("View raw customer-level RFM table"):
            st.dataframe(rfm_df, use_container_width=True, hide_index=True)


# ============================================================
# TAB 4 — FUNNEL ANALYSIS
# ============================================================
with tab_funnel:
    st.subheader("Clickstream → Purchase Funnel")

    stage_check_sql = "SELECT DISTINCT event_type FROM events;"
    stages_available = run_query(stage_check_sql)["event_type"].tolist()

    default_stages = [s for s in ["view", "add_to_cart", "checkout", "purchase"] if s in stages_available]
    if not default_stages:
        default_stages = stages_available[:4]

    chosen_stages = st.multiselect(
        "Funnel stages (in order)", options=stages_available, default=default_stages
    )

    if len(chosen_stages) >= 2:
        case_lines = ",\n".join(
            [f"MAX(CASE WHEN event_type = :stage_{i} THEN 1 ELSE 0 END) AS stage_{i}"
             for i in range(len(chosen_stages))]
        )
        stage_params = {f"stage_{i}": s for i, s in enumerate(chosen_stages)}

        funnel_sql = f"""
            WITH funnel AS (
                SELECT session_id, {case_lines}
                FROM events
                GROUP BY session_id
            )
            SELECT {", ".join([f"SUM(stage_{i}) AS stage_{i}" for i in range(len(chosen_stages))])}
            FROM funnel;
        """
        funnel_df = run_query(funnel_sql, stage_params)

        if not funnel_df.empty:
            values = [int(funnel_df.iloc[0][f"stage_{i}"]) for i in range(len(chosen_stages))]
            fig = go.Figure(go.Funnel(
                y=chosen_stages,
                x=values,
                textinfo="value+percent initial",
                marker=dict(color=["#4C6EF5", "#748FFC", "#91A7FF", "#BAC8FF", "#D0BFFF"][:len(chosen_stages)]),
            ))
            fig.update_layout(height=450, margin=dict(l=10, r=10, t=20, b=10))
            st.plotly_chart(fig, use_container_width=True)

            st.markdown("#### Stage-to-Stage Conversion")
            cols = st.columns(len(chosen_stages) - 1)
            for i in range(len(chosen_stages) - 1):
                pct = (values[i + 1] / values[i] * 100) if values[i] else 0
                cols[i].metric(f"{chosen_stages[i]} → {chosen_stages[i+1]}", f"{pct:.1f}%")
        else:
            st.info("No event data available for the chosen stages.")
    else:
        st.warning("Select at least two stages to build a funnel.")


# ============================================================
# TAB 5 — MARKETING PERFORMANCE
# ============================================================
with tab_marketing:
    st.subheader("Channel & Source Performance")

    mkt_sql = f"""
        WITH source_sessions AS (
            SELECT source, COUNT(*) AS num_sessions FROM sessions GROUP BY source
        ),
        source_orders AS (
            SELECT source, COUNT(*) AS num_orders, SUM(total_usd) AS revenue
            FROM orders
            WHERE {WHERE_SQL}
            GROUP BY source
        )
        SELECT
            COALESCE(ss.source, so.source) AS source,
            COALESCE(ss.num_sessions, 0) AS num_sessions,
            COALESCE(so.num_orders, 0) AS num_orders,
            COALESCE(so.revenue, 0) AS revenue,

            ROUND(
    (100.0 * COALESCE(so.num_orders,0) / NULLIF(ss.num_sessions,0))::numeric,
    2
)AS conversion_rate_pct, 
            
            ROUND(
    (COALESCE(so.revenue,0) / NULLIF(so.num_orders,0))::numeric,
    2
) AS aov
        FROM source_sessions ss
        FULL OUTER JOIN source_orders so ON so.source = ss.source
        ORDER BY revenue DESC;
    """
    mkt_df = run_query(mkt_sql, params)

    if mkt_df.empty:
        st.info("No marketing data available for the selected filters.")
    else:
        col1, col2 = st.columns(2)
        with col1:
            fig = px.bar(mkt_df, x="source", y="revenue", color="source",
                         labels={"revenue": "Revenue (USD)", "source": ""})
            fig.update_layout(height=380, margin=dict(l=10, r=10, t=10, b=10), showlegend=False)
            st.plotly_chart(fig, use_container_width=True)
        with col2:
            fig = px.bar(mkt_df, x="source", y="conversion_rate_pct", color="source",
                         labels={"conversion_rate_pct": "Conversion Rate (%)", "source": ""})
            fig.update_layout(height=380, margin=dict(l=10, r=10, t=10, b=10), showlegend=False)
            st.plotly_chart(fig, use_container_width=True)

        st.markdown("#### Source Performance Table")
        st.dataframe(
            mkt_df.rename(columns={
                "source": "Source", "num_sessions": "Sessions", "num_orders": "Orders",
                "revenue": "Revenue (USD)", "conversion_rate_pct": "Conversion %", "aov": "AOV (USD)",
            }),
            use_container_width=True, hide_index=True,
        )

        st.markdown("#### Monthly Revenue Trend by Source")
        monthly_sql = f"""
            SELECT DATE_TRUNC('month', order_time) AS month, source, SUM(total_usd) AS revenue
            FROM orders
            WHERE {WHERE_SQL}
            GROUP BY 1, 2
            ORDER BY 1;
        """
        monthly_df = run_query(monthly_sql, params)
        if not monthly_df.empty:
            fig = px.line(monthly_df, x="month", y="revenue", color="source", markers=True,
                          labels={"revenue": "Revenue (USD)", "month": ""})
            fig.update_layout(height=400, margin=dict(l=10, r=10, t=10, b=10))
            st.plotly_chart(fig, use_container_width=True)


# ============================================================
# FOOTER
# ============================================================
st.markdown("---")
st.caption("E-Commerce Analytics Platform · Built with Streamlit, PostgreSQL & Plotly")
