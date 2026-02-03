BEGIN;

-- Monthly KPIs (calculated from fact_orders)
CREATE OR REPLACE VIEW bi.kpi_monthly AS
SELECT
  date_trunc('month', purchase_date)::date AS month,
  COUNT(DISTINCT order_id) AS orders,
  COUNT(DISTINCT customer_key) AS customers,
  SUM(items_gmv) AS gmv,
  SUM(freight_total) AS freight,
  SUM(payment_total) AS total_paid,
  (SUM(items_gmv) / NULLIF(COUNT(DISTINCT order_id), 0)) AS aov_gmv,
  (SUM(payment_total) / NULLIF(COUNT(DISTINCT order_id), 0)) AS aov_paid
FROM bi.fact_orders
GROUP BY 1
ORDER BY 1;

-- Top categories per month using window functions
CREATE OR REPLACE VIEW bi.top_categories_monthly AS
WITH cat_month AS (
  SELECT
    date_trunc('month', d.date)::date AS month,
    p.category_en,
    SUM(foi.item_price) AS gmv
  FROM bi.fact_order_items foi
  JOIN bi.dim_date d ON d.date_key = foi.date_key
  JOIN bi.dim_product p ON p.product_id = foi.product_id
  GROUP BY 1,2
)
SELECT
  month,
  category_en,
  gmv,
  DENSE_RANK() OVER (PARTITION BY month ORDER BY gmv DESC) AS rnk
FROM cat_month;

-- Market share by region (customer_state)
CREATE OR REPLACE VIEW bi.region_monthly AS
SELECT
  date_trunc('month', purchase_date)::date AS month,
  customer_state,
  SUM(items_gmv) AS gmv,
  COUNT(DISTINCT order_id) AS orders
FROM bi.fact_orders
GROUP BY 1,2
ORDER BY 1,4 DESC;

COMMIT;
