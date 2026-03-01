-- ============================================================
-- Supply Chain KPI Dashboard
-- Script 01: Create Tables & Schema
-- Author: Vaibhavi Panasa
-- Database: PostgreSQL
-- ============================================================

-- Drop tables if they exist (for clean re-runs)
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS shipping CASCADE;

-- ============================================================
-- 1. CUSTOMERS TABLE
-- ============================================================
CREATE TABLE customers (
    customer_id       VARCHAR(20) PRIMARY KEY,
    customer_fname    VARCHAR(100),
    customer_lname    VARCHAR(100),
    customer_email    VARCHAR(200),
    customer_segment  VARCHAR(50),       -- Consumer, Corporate, Home Office
    customer_city     VARCHAR(100),
    customer_state    VARCHAR(100),
    customer_country  VARCHAR(100),
    customer_zipcode  VARCHAR(20),
    market            VARCHAR(50)        -- LATAM, Europe, Pacific Asia, etc.
);

-- ============================================================
-- 2. PRODUCTS TABLE
-- ============================================================
CREATE TABLE products (
    product_card_id     SERIAL PRIMARY KEY,
    product_category_id INT,
    category_name       VARCHAR(100),     -- Technology, Furniture, Office Supplies
    product_name        VARCHAR(500),
    product_price       DECIMAL(10,2),
    product_status      INT DEFAULT 0     -- 0 = Active, 1 = Discontinued
);

-- ============================================================
-- 3. ORDERS TABLE (Fact Table)
-- ============================================================
CREATE TABLE orders (
    order_id            VARCHAR(30),
    order_item_id       SERIAL PRIMARY KEY,
    order_date          TIMESTAMP,
    order_status        VARCHAR(50),      -- COMPLETE, PENDING, CLOSED, etc.
    order_priority      VARCHAR(20),      -- Critical, High, Medium, Low
    customer_id         VARCHAR(20) REFERENCES customers(customer_id),
    product_card_id     INT REFERENCES products(product_card_id),
    order_quantity      INT,
    sales               DECIMAL(12,2),
    order_profit        DECIMAL(12,2),
    discount_rate       DECIMAL(5,4),
    shipping_mode       VARCHAR(50),      -- Standard Class, Second Class, First Class, Same Day
    shipping_cost       DECIMAL(10,2),
    order_region        VARCHAR(100),
    order_country       VARCHAR(100),
    order_city          VARCHAR(100)
);

-- ============================================================
-- 4. SHIPPING TABLE
-- ============================================================
CREATE TABLE shipping (
    order_item_id       INT REFERENCES orders(order_item_id),
    shipping_date       TIMESTAMP,
    scheduled_delivery  TIMESTAMP,
    actual_delivery     TIMESTAMP,
    delivery_status     VARCHAR(50),      -- Advance shipping, Late delivery, Shipping on time, Shipping canceled
    days_for_shipment_scheduled INT,
    days_for_shipment_real      INT,
    late_delivery_risk  INT DEFAULT 0     -- 1 = at risk, 0 = not at risk
);

-- ============================================================
-- INDEXES for query performance
-- ============================================================
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_region ON orders(order_region);
CREATE INDEX idx_orders_priority ON orders(order_priority);
CREATE INDEX idx_shipping_status ON shipping(delivery_status);
CREATE INDEX idx_products_category ON products(category_name);

-- ============================================================
-- VERIFY
-- ============================================================
SELECT 'Schema created successfully!' AS status;
