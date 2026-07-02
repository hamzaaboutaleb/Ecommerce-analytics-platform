# Key Insights

This document captures the headline findings from the E-Commerce Analytics Platform. It's written as a **template** — run the dashboard and SQL queries against your loaded data, then replace each `[fill in]` placeholder with your actual numbers and add the matching screenshot.

*Tip: keep each insight to 2–3 sentences — number, context, and a "so what." That's what makes this read like an analyst's findings rather than a raw data dump.*

---

## 1. Revenue & KPIs

> 📸 `![Overview tab](screenshots/overview.png)`

- **Total revenue:** $[fill in] across [fill in] orders, for an average order value of $[fill in].
- **Revenue trend:** [Describe the shape — growing, flat, seasonal spikes — and call out any notable month.]
- **Best-performing country:** [fill in] leads in both order volume and AOV.
- **Device split:** [Desktop/mobile] drives the highest AOV, while [the other] drives higher order volume — [note what this suggests about UX or checkout friction].
- **Discount sensitivity:** Orders with [X]% discount show [higher/lower] AOV than undiscounted orders, suggesting [interpretation].

---

## 2. Cohort Retention

> 📸 `![Cohort retention tab](screenshots/cohort.png)`

- **Month-1 retention:** On average, [fill in]% of a signup cohort places a second order within one month of signing up.
- **Retention decay:** Retention drops to roughly [fill in]% by month 3 and [fill in]% by month 6 — [describe whether this is a steep early drop-off or a gradual decline].
- **Best cohort:** The [month/year] cohort retains noticeably better than others — [hypothesize why, e.g. a promotion, seasonal buyer intent, product launch].
- **Takeaway:** [What would you recommend based on this — e.g. a 30-day re-engagement campaign, improving onboarding, etc.]

---

## 3. RFM Customer Segments

> 📸 `![RFM tab](screenshots/rfm.png)`

- **Segment sizes:** [fill in]% of customers are Champions, [fill in]% are Loyal Customers, [fill in]% are At Risk, [fill in]% are Lost.
- **Revenue concentration:** The top segment(s) — [fill in] — generate [fill in]% of total revenue despite being only [fill in]% of the customer base, illustrating a [strong/moderate] Pareto effect.
- **At-risk value:** Customers in the "At Risk" segment represent $[fill in] in historical spend — a natural target list for a win-back campaign.
- **Takeaway:** [Recommend an action per segment, e.g. loyalty perks for Champions, reactivation emails for At Risk/Lost.]

---

## 4. Funnel & Conversion

> 📸 `![Funnel tab](screenshots/funnel.png)`

- **Overall conversion:** [fill in]% of sessions that view a product ultimately complete a purchase.
- **Biggest drop-off:** The largest drop happens between [stage] and [stage], at [fill in]% — [hypothesize why, e.g. shipping cost surprise at checkout, complicated payment flow].
- **Device differences:** [Mobile/desktop] converts at a noticeably [higher/lower] rate — [note implication, e.g. mobile checkout UX needs work].
- **Takeaway:** [Recommend a specific test or fix, e.g. simplify the checkout form, add guest checkout, show shipping cost earlier.]

---

## 5. Marketing Channel Performance

> 📸 `![Marketing tab](screenshots/marketing.png)`

- **Highest revenue channel:** [fill in] generates the most total revenue, at $[fill in].
- **Most efficient channel:** [fill in] has the highest revenue-per-session at $[fill in], even though it doesn't drive the most raw traffic — meaning it converts more efficiently than volume alone would suggest.
- **Underperforming channel:** [fill in] drives significant session volume but a comparatively low conversion rate of [fill in]%, suggesting [traffic quality issue / landing page mismatch / etc.].
- **New vs. returning:** [fill in]% of revenue from [channel] comes from new customers vs. [fill in]% from returning — [interpretation, e.g. this channel is more of an acquisition engine than a retention one].
- **Takeaway:** [Recommend a budget reallocation or test based on the above.]

---

## 6. Overall Summary

Replace this paragraph with a 3-5 sentence executive summary once all sections above are filled in — written as if presenting to a stakeholder who only reads this section. Lead with the single most important number or finding, then the two or three actions you'd recommend based on the data.

---

## Appendix: How to Fill This In

1. Run `streamlit run dashboard\app.py` and step through each tab.
2. Screenshot each tab and save it to `docs\screenshots\` using the filenames referenced above (`overview.png`, `cohort.png`, `rfm.png`, `funnel.png`, `marketing.png`).
3. Pull the underlying numbers either straight from the dashboard metrics/tables, or by running the matching file in `sql\queries\` directly against PostgreSQL.
4. Replace every `[fill in]` placeholder in this document with your real figures.
