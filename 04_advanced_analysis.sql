-- ============================================================
-- Supply Chain KPI Dashboard
-- Script 04: Advanced Analysis (Window Functions, CTEs, Rankings)
-- Author: Vaibhavi Panasa
-- ============================================================

-- ============================================================
-- 1. RUNNING TOTAL REVENUE & CUMULATIVE GROWTH (Window Functions)
-- ============================================================

WITH monthly_revenue AS (
    SELECT
        order_year,
        order_month,
        ROUND(SUM(sales)::NUMERIC, 2) AS revenue
    FROM orders
    WHERE is_return = FALSE
    GROUP BY order_year, order_month
)
SELECT
    order_year,
    order_month,
    revenue,
    SUM(revenue) OVER (
        PARTITION BY order_year
        ORDER BY order_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS ytd_cumulative_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY order_year, order_month))
        / NULLIF(LAG(revenue) OVER (ORDER BY order_year, order_month), 0) * 100,
    2) AS mom_growth_pct,
    ROUND(AVG(revenue) OVER (
        ORDER BY order_year, order_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3m
FROM monthly_revenue
ORDER BY order_year, order_month;


-- ============================================================
-- 2. PRODUCT CATEGORY RANKING BY REGION (DENSE_RANK)
-- ============================================================

WITH category_region AS (
    SELECT
        o.order_region,
        p.category_name,
        ROUND(SUM(o.sales)::NUMERIC, 2) AS total_revenue,
        COUNT(*) AS order_count
    FROM orders o
    JOIN products p ON o.product_card_id = p.product_card_id
    WHERE o.is_return = FALSE
    GROUP BY o.order_region, p.category_name
)
SELECT
    order_region,
    category_name,
    total_revenue,
    order_count,
    DENSE_RANK() OVER (
        PARTITION BY order_region
        ORDER BY total_revenue DESC
    ) AS revenue_rank
FROM category_region
ORDER BY order_region, revenue_rank;


-- ============================================================
-- 3. LATE DELIVERY TREND — ROLLING 3-MONTH AVERAGE
-- ============================================================

WITH monthly_late AS (
    SELECT
        o.order_year,
        o.order_month,
        COUNT(*) AS total_orders,
        SUM(CASE WHEN s.is_late THEN 1 ELSE 0 END) AS late_orders,
        ROUND(
            SUM(CASE WHEN s.is_late THEN 1 ELSE 0 END)::NUMERIC
            / COUNT(*)::NUMERIC * 100, 2
        ) AS late_rate_pct
    FROM orders o
    JOIN shipping s ON o.order_item_id = s.order_item_id
    WHERE o.is_return = FALSE
    GROUP BY o.order_year, o.order_month
)
SELECT
    order_year,
    order_month,
    late_rate_pct,
    ROUND(AVG(late_rate_pct) OVER (
        ORDER BY order_year, order_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3m_avg_late_rate,
    late_rate_pct - LAG(late_rate_pct) OVER (
        ORDER BY order_year, order_month
    ) AS change_from_prev_month
FROM monthly_late
ORDER BY order_year, order_month;


-- ============================================================
-- 4. CUSTOMER COHORT ANALYSIS (First Purchase Month)
-- ============================================================

WITH customer_first_order AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
customer_orders AS (
    SELECT
        o.customer_id,
        cfo.cohort_month,
        DATE_TRUNC('month', o.order_date) AS order_month,
        EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', o.order_date), cfo.cohort_month))::INT AS months_since_first
    FROM orders o
    JOIN customer_first_order cfo ON o.customer_id = cfo.customer_id
    WHERE o.is_return = FALSE
)
SELECT
    cohort_month,
    months_since_first,
    COUNT(DISTINCT customer_id) AS active_customers,
    ROUND(
        COUNT(DISTINCT customer_id)::NUMERIC /
        FIRST_VALUE(COUNT(DISTINCT customer_id)) OVER (
            PARTITION BY cohort_month
            ORDER BY months_since_first
        )::NUMERIC * 100, 2
    ) AS retention_rate_pct
FROM customer_orders
WHERE months_since_first <= 12
GROUP BY cohort_month, months_since_first
ORDER BY cohort_month, months_since_first;


-- ============================================================
-- 5. PARETO ANALYSIS (80/20 Rule) — Top Products by Revenue
-- ============================================================

WITH product_revenue AS (
    SELECT
        p.product_name,
        p.category_name,
        ROUND(SUM(o.sales)::NUMERIC, 2) AS total_revenue,
        COUNT(*) AS order_count
    FROM orders o
    JOIN products p ON o.product_card_id = p.product_card_id
    WHERE o.is_return = FALSE
    GROUP BY p.product_name, p.category_name
),
ranked AS (
    SELECT
        product_name,
        category_name,
        total_revenue,
        order_count,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) AS cumulative_revenue,
        SUM(total_revenue) OVER () AS grand_total
    FROM product_revenue
)
SELECT
    product_name,
    category_name,
    total_revenue,
    order_count,
    ROUND(cumulative_revenue / grand_total * 100, 2) AS cumulative_revenue_pct,
    CASE
        WHEN cumulative_revenue / grand_total <= 0.80 THEN 'Top 80% Revenue'
        ELSE 'Bottom 20% Revenue'
    END AS pareto_group
FROM ranked
ORDER BY total_revenue DESC
LIMIT 50;


-- ============================================================
-- 6. SHIPPING COST ANOMALY DETECTION (Z-Score)
-- ============================================================

WITH shipping_stats AS (
    SELECT
        shipping_mode,
        AVG(shipping_cost) AS avg_cost,
        STDDEV(shipping_cost) AS std_cost
    FROM orders
    WHERE is_return = FALSE AND shipping_cost > 0
    GROUP BY shipping_mode
)
SELECT
    o.order_id,
    o.shipping_mode,
    o.shipping_cost,
    ss.avg_cost,
    ROUND(
        (o.shipping_cost - ss.avg_cost) / NULLIF(ss.std_cost, 0), 2
    ) AS z_score,
    CASE
        WHEN ABS((o.shipping_cost - ss.avg_cost) / NULLIF(ss.std_cost, 0)) > 3 THEN 'EXTREME ANOMALY'
        WHEN ABS((o.shipping_cost - ss.avg_cost) / NULLIF(ss.std_cost, 0)) > 2 THEN 'MODERATE ANOMALY'
        ELSE 'NORMAL'
    END AS anomaly_flag
FROM orders o
JOIN shipping_stats ss ON o.shipping_mode = ss.shipping_mode
WHERE o.is_return = FALSE
ORDER BY z_score DESC
LIMIT 25;


-- ============================================================
-- 7. YEAR-OVER-YEAR COMPARISON BY QUARTER
-- ============================================================

WITH quarterly AS (
    SELECT
        order_year,
        order_quarter,
        ROUND(SUM(sales)::NUMERIC, 2) AS revenue,
        COUNT(*) AS orders,
        ROUND(SUM(order_profit)::NUMERIC, 2) AS profit
    FROM orders
    WHERE is_return = FALSE
    GROUP BY order_year, order_quarter
)
SELECT
    q1.order_year,
    q1.order_quarter,
    q1.revenue AS current_revenue,
    q2.revenue AS prev_year_revenue,
    ROUND(
        (q1.revenue - q2.revenue) / NULLIF(q2.revenue, 0) * 100, 2
    ) AS yoy_revenue_growth_pct,
    q1.orders AS current_orders,
    q2.orders AS prev_year_orders,
    ROUND(
        (q1.orders - q2.orders)::NUMERIC / NULLIF(q2.orders, 0) * 100, 2
    ) AS yoy_order_growth_pct
FROM quarterly q1
LEFT JOIN quarterly q2
    ON q1.order_quarter = q2.order_quarter
    AND q1.order_year = q2.order_year + 1
ORDER BY q1.order_year, q1.order_quarter;


-- ============================================================
-- 8. MARKET BASKET — FREQUENTLY CO-ORDERED CATEGORIES
-- ============================================================

WITH order_categories AS (
    SELECT DISTINCT
        o.order_id,
        p.category_name
    FROM orders o
    JOIN products p ON o.product_card_id = p.product_card_id
    WHERE o.is_return = FALSE
)
SELECT
    a.category_name AS category_a,
    b.category_name AS category_b,
    COUNT(DISTINCT a.order_id) AS co_occurrence_count
FROM order_categories a
JOIN order_categories b
    ON a.order_id = b.order_id
    AND a.category_name < b.category_name  -- Avoid duplicates
GROUP BY a.category_name, b.category_name
ORDER BY co_occurrence_count DESC
LIMIT 10;
