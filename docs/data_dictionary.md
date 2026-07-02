# Data Dictionary

This document defines every table and column in the `ecommerce_analytics` database. Types reflect the PostgreSQL schema in `sql/schema/create_tables.sql`.

---

## 1. `customers`
One row per registered customer.

| Column | Type | Description |
|---|---|---|
| `customer_id` | VARCHAR(50), PK | Unique identifier for the customer |
| `name` | VARCHAR(100) | Customer full name |
| `email` | VARCHAR(100) | Customer email address |
| `country` | VARCHAR(50) | Customer's country |
| `age` | INT | Customer age at signup |
| `signup_date` | DATE | Date the customer created an account |
| `marketing_opt_in` | BOOLEAN | Whether the customer opted into marketing communications |

---

## 2. `products`
One row per product in the catalog.

| Column | Type | Description |
|---|---|---|
| `product_id` | VARCHAR(50), PK | Unique identifier for the product |
| `category` | VARCHAR(80) | Product category (e.g. Electronics, Apparel) |
| `name` | VARCHAR(200) | Product display name |
| `price_usd` | DECIMAL(12,2) | Retail price in USD |
| `cost_usd` | DECIMAL(12,2) | Cost of goods sold in USD |
| `margin_usd` | DECIMAL(12,2) | Gross margin (`price_usd - cost_usd`) in USD |

---

## 3. `sessions`
One row per browsing session, regardless of whether it led to a purchase.

| Column | Type | Description |
|---|---|---|
| `session_id` | VARCHAR(50), PK | Unique identifier for the session |
| `customer_id` | VARCHAR(50), FK → `customers.customer_id` | Customer who owns the session (may be null for anonymous visitors, depending on source data) |
| `start_time` | TIMESTAMP | Session start timestamp |
| `device` | VARCHAR(30) | Device type (e.g. desktop, mobile, tablet) |
| `source` | VARCHAR(50) | Acquisition/traffic source (e.g. organic, paid_search, email, social) |
| `country` | VARCHAR(50) | Country the session originated from |

---

## 4. `orders`
One row per completed order (order-level totals).

| Column | Type | Description |
|---|---|---|
| `order_id` | VARCHAR(50), PK | Unique identifier for the order |
| `customer_id` | VARCHAR(50), FK → `customers.customer_id` | Customer who placed the order |
| `order_time` | TIMESTAMP | Timestamp the order was placed |
| `payment_method` | VARCHAR(30) | Payment method used (e.g. credit_card, paypal) |
| `discount_pct` | DECIMAL(5,2) | Discount applied to the order, as a percentage |
| `subtotal_usd` | DECIMAL(12,2) | Order subtotal before discount, in USD |
| `total_usd` | DECIMAL(12,2) | Final order total after discount, in USD |
| `country` | VARCHAR(50) | Shipping/billing country for the order |
| `device` | VARCHAR(30) | Device used to place the order |
| `source` | VARCHAR(50) | Acquisition source attributed to the order |

---

## 5. `order_items`
One row per product line item within an order (child of `orders`).

| Column | Type | Description |
|---|---|---|
| `order_id` | VARCHAR(50), FK → `orders.order_id` | Order this line item belongs to |
| `product_id` | VARCHAR(50), FK → `products.product_id` | Product purchased |
| `unit_price_usd` | DECIMAL(12,2) | Price per unit at time of purchase, in USD |
| `quantity` | INT | Quantity of the product purchased |
| `line_total_usd` | DECIMAL(12,2) | Total for this line (`unit_price_usd * quantity`), in USD |

---

## 6. `events`
One row per clickstream event captured during a session (pre- and at-purchase behavior).

| Column | Type | Description |
|---|---|---|
| `event_id` | VARCHAR(50) | Unique identifier for the event |
| `session_id` | VARCHAR(50), FK → `sessions.session_id` | Session the event occurred in |
| `timestamp` | TIMESTAMP | When the event occurred |
| `event_type` | VARCHAR(50) | Type of event (e.g. `view`, `add_to_cart`, `checkout`, `purchase` — confirm exact values in your data) |
| `product_id` | VARCHAR(50), FK → `products.product_id` | Product associated with the event, if applicable |
| `qty` | INT | Quantity involved in the event (e.g. items added to cart) |
| `cart_size` | INT | Number of items in the cart at the time of the event |
| `payment` | VARCHAR(50) | Payment method, populated for checkout/purchase events |
| `discount_pct` | DECIMAL(5,2) | Discount applied, populated for checkout/purchase events |
| `amount_usd` | DECIMAL(12,2) | Monetary amount associated with the event, if applicable |

> ⚠️ **Note:** `event_type` values should be confirmed against your actual data (run the event-type audit query in `sql/queries/funnel_analysis.sql`) before relying on the funnel logic, since exact labels can vary by data source.

---

## 7. `reviews`
One row per product review submitted after a purchase.

| Column | Type | Description |
|---|---|---|
| `review_id` | VARCHAR(50) | Unique identifier for the review |
| `order_id` | VARCHAR(50), FK → `orders.order_id` | Order the review is associated with |
| `product_id` | VARCHAR(50), FK → `products.product_id` | Product being reviewed |
| `rating` | INT | Star rating given (typically 1–5) |
| `review_text` | TEXT | Free-text review content |
| `review_time` | TIMESTAMP | When the review was submitted |

---

## Entity Relationships Summary

```
customers ─┬─< orders ─┬─< order_items >─ products
           │            │
           └─< sessions ─< events >─ products (optional)
                          
orders ─< reviews >─ products
```

`─<` denotes a one-to-many relationship (e.g. one customer has many orders).

> 📸 **Screenshot placeholder** — if you built a visual ERD (e.g. in pgAdmin or dbdiagram.io), add it here.
> `![ERD](screenshots/erd.png)`
