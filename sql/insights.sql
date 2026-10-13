

USE SCHEMA SALES_DW.ANALYTICS;

-- 1. Total sales revenue per product category.
WITH revenue_by_product AS (
    SELECT 
        product_id
        ,SUM(amount) AS revenue
    FROM fact_sales
    GROUP BY product_id
)
SELECT
    COALESCE(p.category, 'Unknown') AS category,
    SUM(r.revenue)                  AS revenue
FROM revenue_by_product r
    JOIN dim_products p ON p.product_id = r.product_id
GROUP BY 1
ORDER BY revenue DESC;

-- 2. Top 5 customers by total purchase amount.
WITH top_customers AS (
    SELECT customer_id, SUM(amount) AS total_purchase, COUNT(*) AS transactions
    FROM fact_sales
    GROUP BY customer_id
    ORDER BY total_purchase DESC, customer_id
    LIMIT 5
)
SELECT 
    t.customer_id
    ,c.name
    ,c.country
    ,t.transactions
    ,t.total_purchase
FROM top_customers t
JOIN dim_customers c ON c.customer_id = t.customer_id
ORDER BY t.total_purchase DESC, t.customer_id;

-- 3. Monthly sales trend for the last 12 complete months.

SELECT
    DATE_TRUNC('month', date_key) AS sales_month,
    COUNT(*) AS transactions,
    SUM(amount) AS revenue
FROM fact_sales
WHERE date_key >= DATEADD('month', -12, DATE_TRUNC('month', CURRENT_DATE()))
  AND date_key <  DATE_TRUNC('month', CURRENT_DATE())
GROUP BY 1
ORDER BY 1;
