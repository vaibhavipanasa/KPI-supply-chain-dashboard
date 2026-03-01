-- ============================================================
-- Supply Chain KPI Dashboard
-- Script 02: Data Cleaning & Transformation
-- Author: Vaibhavi Panasa
-- ============================================================

-- ============================================================
-- STEP 1: Identify and Remove Duplicates
-- ============================================================

-- Check for duplicate orders
SELECT order_id, COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Remove exact duplicates (keep first occurrence)
DELETE FROM orders
WHERE order_item_id NOT IN (
    SELECT MIN(order_item_id)
    FROM orders
    GROUP BY order_id, customer_id, product_card_id, order_date
);

-- Verify: Count remaining records
SELECT COUNT(*) AS total_records_after_dedup FROM orders;


-- ============================================================
-- STEP 2: Handle Missing Values
-- ============================================================

-- Check NULL counts per column
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(customer_id) AS null_customer_id,
    COUNT(*) - COUNT(order_date) AS null_order_date,
    COUNT(*) - COUNT(sales) AS null_sales,
    COUNT(*) - COUNT(shipping_cost) AS null_shipping_cost,
    COUNT(*) - COUNT(order_profit) AS null_profit,
    COUNT(*) - COUNT(order_region) AS null_region,
    COUNT(*) - COUNT(shipping_mode) AS null_shipping_mode
FROM orders;

-- Remove rows where customer_id is NULL (critical field)
DELETE FROM orders WHERE customer_id IS NULL;

-- Fill missing shipping_cost with median by shipping_mode
UPDATE orders o
SET shipping_cost = sub.median_cost
FROM (
    SELECT shipping_mode,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY shipping_cost) AS median_cost
    FROM orders
    WHERE shipping_cost IS NOT NULL
    GROUP BY shipping_mode
) sub
WHERE o.shipping_mode = sub.shipping_mode
  AND o.shipping_cost IS NULL;


-- ============================================================
-- STEP 3: Standardize & Clean Data Types
-- ============================================================

-- Ensure dates are proper timestamps
ALTER TABLE orders ALTER COLUMN order_date TYPE TIMESTAMP USING order_date::TIMESTAMP;

-- Remove negative quantities (data entry errors)
DELETE FROM orders WHERE order_quantity <= 0;

-- Remove orders with negative sales (returns — analyze separately)
-- We'll flag them instead of deleting
ALTER TABLE orders ADD COLUMN IF NOT EXISTS is_return BOOLEAN DEFAULT FALSE;
UPDATE orders SET is_return = TRUE WHERE sales < 0;


-- ============================================================
-- STEP 4: Create Calculated Columns
-- ============================================================

-- Add delivery performance columns to shipping table
ALTER TABLE shipping ADD COLUMN IF NOT EXISTS delivery_delay_days INT;
ALTER TABLE shipping ADD COLUMN IF NOT EXISTS is_late BOOLEAN DEFAULT FALSE;

UPDATE shipping
SET delivery_delay_days = days_for_shipment_real - days_for_shipment_scheduled,
    is_late = CASE
        WHEN days_for_shipment_real > days_for_shipment_scheduled THEN TRUE
        ELSE FALSE
    END;

-- Add calculated columns to orders table
ALTER TABLE orders ADD COLUMN IF NOT EXISTS profit_margin DECIMAL(8,4);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipping_cost_per_unit DECIMAL(10,2);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS order_month INT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS order_year INT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS order_quarter VARCHAR(5);

UPDATE orders
SET profit_margin = CASE WHEN sales > 0 THEN (order_profit / sales) * 100 ELSE 0 END,
    shipping_cost_per_unit = CASE WHEN order_quantity > 0 THEN shipping_cost / order_quantity ELSE 0 END,
    order_month = EXTRACT(MONTH FROM order_date),
    order_year = EXTRACT(YEAR FROM order_date),
    order_quarter = 'Q' || EXTRACT(QUARTER FROM order_date)::TEXT;


-- ============================================================
-- STEP 5: Remove Outliers (Shipping Cost)
-- ============================================================

-- Identify outliers using 3 standard deviations
WITH stats AS (
    SELECT AVG(shipping_cost) AS avg_cost,
           STDDEV(shipping_cost) AS std_cost
    FROM orders
    WHERE shipping_cost IS NOT NULL
)
SELECT COUNT(*) AS outlier_count
FROM orders, stats
WHERE shipping_cost > avg_cost + (3 * std_cost)
   OR shipping_cost < avg_cost - (3 * std_cost);

-- Flag outliers (don't delete — flag for review)
ALTER TABLE orders ADD COLUMN IF NOT EXISTS is_outlier BOOLEAN DEFAULT FALSE;

WITH stats AS (
    SELECT AVG(shipping_cost) AS avg_cost,
           STDDEV(shipping_cost) AS std_cost
    FROM orders
)
UPDATE orders
SET is_outlier = TRUE
FROM stats
WHERE shipping_cost > avg_cost + (3 * std_cost)
   OR shipping_cost < avg_cost - (3 * std_cost);


-- ============================================================
-- STEP 6: Data Quality Report
-- ============================================================

SELECT
    'Total Records' AS metric, COUNT(*)::TEXT AS value FROM orders
UNION ALL
SELECT 'Date Range', MIN(order_date)::DATE || ' to ' || MAX(order_date)::DATE FROM orders
UNION ALL
SELECT 'Unique Customers', COUNT(DISTINCT customer_id)::TEXT FROM orders
UNION ALL
SELECT 'Unique Products', COUNT(DISTINCT product_card_id)::TEXT FROM orders
UNION ALL
SELECT 'Flagged Returns', COUNT(*)::TEXT FROM orders WHERE is_return = TRUE
UNION ALL
SELECT 'Flagged Outliers', COUNT(*)::TEXT FROM orders WHERE is_outlier = TRUE
UNION ALL
SELECT 'Regions Covered', COUNT(DISTINCT order_region)::TEXT FROM orders;
