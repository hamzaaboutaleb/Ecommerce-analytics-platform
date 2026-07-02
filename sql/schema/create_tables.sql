-- 1. Customers
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    country VARCHAR(50),
    age INT,
    signup_date DATE,
    marketing_opt_in BOOLEAN
);

-- 2. Products
CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    category VARCHAR(80),
    name VARCHAR(200),
    price_usd DECIMAL(12,2),
    cost_usd DECIMAL(12,2),
    margin_usd DECIMAL(12,2)
);

-- 3. Sessions
CREATE TABLE sessions (
    session_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    start_time TIMESTAMP,
    device VARCHAR(30),
    source VARCHAR(50),
    country VARCHAR(50)
);

-- 4. Orders
CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_time TIMESTAMP,
    payment_method VARCHAR(30),
    discount_pct DECIMAL(5,2),
    subtotal_usd DECIMAL(12,2),
    total_usd DECIMAL(12,2),
    country VARCHAR(50),
    device VARCHAR(30),
    source VARCHAR(50)
);

-- 5. Order Items
CREATE TABLE order_items (
    order_id VARCHAR(50),
    product_id VARCHAR(50),
    unit_price_usd DECIMAL(12,2),
    quantity INT,
    line_total_usd DECIMAL(12,2)
);

-- 6. Events
CREATE TABLE events (
    event_id VARCHAR(50),
    session_id VARCHAR(50),
    timestamp TIMESTAMP,
    event_type VARCHAR(50),
    product_id VARCHAR(50),
    qty INT,
    cart_size INT,
    payment VARCHAR(50),
    discount_pct DECIMAL(5,2),
    amount_usd DECIMAL(12,2)
);

-- 7. Reviews
CREATE TABLE reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    product_id VARCHAR(50),
    rating INT,
    review_text TEXT,
    review_time TIMESTAMP
);