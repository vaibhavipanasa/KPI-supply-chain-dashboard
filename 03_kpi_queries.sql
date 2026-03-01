-- ============================================================
-- Supply Chain KPI Dashboard
-- Script 03: KPI Calculation Queries
-- Author: Vaibhavi Panasa
-- ============================================================

-- ============================================================
-- KPI 1: ON-TIME DELIVERY RATE (Overall & by Region)
-- ============================================================

-- Overall On-Time Delivery Rate
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN s.delivery_status = 'Shipping on time' THEN 1 ELSE 0 END) AS on_time_orders,
    SUM(CASE WHEN s.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) AS late_orders,
    ROUND(
        SUM(CASE WHEN s.delivery_status = 'Shipping on time' THEN 1 ELSE 0 END)::NUMERIC
        / COUNT(*)::NUMERIC * 100, 2
    ) AS on_time_delivery_rate_pct,
    ROUND(
        SUM(CASE WHEN s.delivery_status = 'Late delivery' THEN 1 ELSE 0 END)::NUMERIC
        / COUNT(*)::NUMERIC * 100, 2
    ) AS late_delivery_rate_pct
FROM orders o
JOIN shipping s ON o.order_item_id = s.order_item_id
WHERE o.is_return = FALSE AND o.is_outlier = FALSE;

-- On-Time Delivery Rate by Region
SELECT
    o.order_region,
    COUNT(*) AS total_orders,
    ROUND(
        SUM(CASE WHEN s.delivery_status = 'Shipping on time' THEN 1 ELSE 0 END)::NUMERIC
        / COUNT(*)::NUMERIC * 100, 2
    ) AS on_time_rate_pct,
    ROUND(AVG(s.delivery_delay_days), 1) AS avg_delay_days
FROM orders o
JOIN shipping s ON o.order_item_id = s.order_item_id
WHERE o.is_return = FALSE
GROUP BY o.order_region
ORDER BY on_time_rate_pct DESC;


-- ============================================================
-- KPI 2: REVENUE & PROFIT BY CATEGORY
-- ============================================================

SELECT
    p.category_name,
    COUNT(o.order_item_id) AS total_orders,
    ROUND(SUM(o.sales)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(o.order_profit)::NUMERIC, 2) AS total_profit,
    ROUND(AVG(o.profit_margin)::NUMERIC, 2) AS avg_profit_margin_pct,
    ROUND(SUM(o.shipping_cost)::NUMERIC, 2) AS total_shipping_cost,
    ROUND(
        SUM(o.shipping_cost)::NUMERIC / SUM(o.sales)::NUMERIC * 100, 2
    ) AS shipping_cost_to_revenue_pct
FROM orders o
JOIN products p ON o.product_card_id = p.product_card_id
WHERE o.is_return = FALSE
GROUP BY p.category_name
ORDER BY total_revenue DESC;


-- ============================================================
-- KPI 3: SHIPPING MODE PERFORMANCE
-- ============================================================

SELECT
    o.shipping_mode,
    COUNT(*) AS total_orders,
    ROUND(AVG(o.shipping_cost)::NUMERIC, 2) AS avg_shipping_cost,
    ROUND(AVG(s.days_for_shipment_real)::NUMERIC, 1) AS avg_actual_ship_days,
    ROUND(AVG(s.days_for_shipment_scheduled)::NUMERIC, 1) AS avg_scheduled_ship_days,
    ROUND(
        SUM(CASE WHEN s.is_late THEN 1 ELSE 0 END)::NUMERIC
        / COUNT(*)::NUMERIC * 100, 2
    ) AS late_delivery_rate_pct,
    ROUND(AVG(s.delivery_delay_days)::NUMERIC, 1) AS avg_delay_days
FROM orders o
JOIN shipping s ON o.order_item_id = s.order_item_id
WHERE o.is_return = FALSE
GROUP BY o.shipping_mode
ORDER BY late_delivery_rate_pct ASC;


-- ============================================================
-- KPI 4: MONTHLY REVENUE TREND
-- ============================================================

SELECT
    o.order_year,
    o.order_month,
    TO_CHAR(o.order_date, 'Mon YYYY') AS month_label,
    COUNT(*) AS total_orders,
    ROUND(SUM(o.sales)::NUMERIC, 2) AS monthly_revenue,
    ROUND(SUM(o.order_profit)::NUMERIC, 2) AS monthly_profit,
    ROUND(SUM(o.shipping_cost)::NUMERIC, 2) AS monthly_shipping_cost,
    -- Month-over-month growth
    ROUND(
        (SUM(o.sales) - LAG(SUM(o.sales)) OVER (ORDER BY o.order_year, o.order_month))
        / NULLIF(LAG(SUM(o.sales)) OVER (ORDER BY o.order_year, o.order_month), 0)
        * 100, 2
    ) AS revenue_growth_pct
FROM orders o
WHERE o.is_return = FALSE
GROUP BY o.order_year, o.order_month, TO_CHAR(o.order_date, 'Mon YYYY')
ORDER BY o.order_year, o.order_month;


-- ============================================================
-- KPI 5: CUSTOMER SEGMENT ANALYSIS
-- ============================================================

SELECT
    c.customer_segment,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    COUNT(o.order_item_id) AS total_orders,
    ROUND(SUM(o.sales)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(o.sales)::NUMERIC, 2) AS avg_order_value,
    ROUND(SUM(o.order_profit)::NUMERIC, 2) AS total_profit,
    ROUND(
        SUM(CASE WHEN s.is_late THEN 1 ELSE 0 END)::NUMERIC
        / COUNT(*)::NUMERIC * 100, 2
    ) AS late_delivery_rate_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN shipping s ON o.order_item_id = s.order_item_id
WHERE o.is_return = FALSE
GROUP BY c.customer_segment
ORDER BY total_revenue DESC;


-- ============================================================
-- KPI 6: ORDER PRIORITY vs LATE DELIVERY RISK
-- ============================================================

SELECT
    o.order_priority,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN s.is_late THEN 1 ELSE 0 END) AS late_orders,
    ROUND(
        SUM(CASE WHEN s.is_late THEN 1 ELSE 0 END)::NUMERIC
        / COUNT(*)::NUMERIC * 100, 2
    ) AS late_rate_pct,
    ROUND(AVG(o.sales)::NUMERIC, 2) AS avg_order_value,
    ROUND(AVG(s.delivery_delay_days)::NUMERIC, 1) AS avg_delay_days
FROM orders o
JOIN shipping s ON o.order_item_id = s.order_item_id
WHERE o.is_return = FALSE
GROUP BY o.order_priority
ORDER BY late_rate_pct DESC;


-- ============================================================
-- KPI 7: TOP 10 CUSTOMERS BY LIFETIME VALUE
-- ============================================================

SELECT
    o.customer_id,
    c.customer_fname || ' ' || c.customer_lname AS customer_name,
    c.customer_segment,
    c.market,
    COUNT(o.order_item_id) AS total_orders,
    ROUND(SUM(o.sales)::NUMERIC, 2) AS lifetime_value,
    ROUND(AVG(o.sales)::NUMERIC, 2) AS avg_order_value,
    ROUND(SUM(o.order_profit)::NUMERIC, 2) AS total_profit,
    MIN(o.order_date)::DATE AS first_order,
    MAX(o.order_date)::DATE AS last_order
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.is_return = FALSE
GROUP BY o.customer_id, customer_name, c.customer_segment, c.market
ORDER BY lifetime_value DESC
LIMIT 10;


-- ============================================================
-- KPI 8: GEOGRAPHIC PERFORMANCE (Country-Level)
-- ============================================================

SELECT
    o.order_country,
    o.order_region,
    COUNT(*) AS total_orders,
    ROUND(SUM(o.sales)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(o.shipping_cost)::NUMERIC, 2) AS avg_shipping_cost,
    ROUND(
        SUM(CASE WHEN s.is_late THEN 1 ELSE 0 END)::NUMERIC
        / COUNT(*)::NUMERIC * 100, 2
    ) AS late_delivery_rate_pct,
    ROUND(AVG(s.delivery_delay_days)::NUMERIC, 1) AS avg_delay_days
FROM orders o
JOIN shipping s ON o.order_item_id = s.order_item_id
WHERE o.is_return = FALSE
GROUP BY o.order_country, o.order_region
HAVING COUNT(*) >= 100  -- Filter for meaningful sample sizes
ORDER BY total_revenue DESC
LIMIT 20;
