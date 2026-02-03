BEGIN;

CREATE SCHEMA IF NOT EXISTS bi;

-- DIM DATE (ranging from min to max purchase_date of delivered orders)
CREATE OR REPLACE VIEW bi.dim_date AS
WITH bounds AS (
  SELECT
    MIN(purchase_date) AS min_date,
    MAX(purchase_date) AS max_date
  FROM clean.orders
  WHERE order_status = 'delivered'
)
SELECT
  (EXTRACT(YEAR FROM d)::int * 10000
   + EXTRACT(MONTH FROM d)::int * 100
   + EXTRACT(DAY FROM d)::int) AS date_key,
  d::date AS date,
  EXTRACT(YEAR FROM d)::int AS year,
  EXTRACT(MONTH FROM d)::int AS month,
  TO_CHAR(d, 'Mon') AS month_name,
  EXTRACT(QUARTER FROM d)::int AS quarter,
  EXTRACT(WEEK FROM d)::int AS iso_week
FROM bounds b,
     generate_series(b.min_date, b.max_date, interval '1 day') AS gs(d);

-- DIM PRODUCT (including English category names)
CREATE OR REPLACE VIEW bi.dim_product AS
SELECT
  p.product_id,
  p.product_category_name,
  COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category_en
FROM raw.products p
LEFT JOIN raw.category_translation t
  ON t.product_category_name = p.product_category_name;

-- DIM CUSTOMER (mapped by customer_unique_id)
-- Get the "latest" location from order history (to handle address changes over time)
CREATE OR REPLACE VIEW bi.dim_customer AS
WITH ranked AS (
  SELECT
    customer_unique_id,
    customer_state,
    customer_city,
    ROW_NUMBER() OVER (
      PARTITION BY customer_unique_id
      ORDER BY order_purchase_timestamp DESC
    ) AS rn
  FROM clean.orders
)
SELECT
  customer_unique_id AS customer_key,
  customer_state,
  customer_city
FROM ranked
WHERE rn = 1;

-- DIM SELLER
CREATE OR REPLACE VIEW bi.dim_seller AS
SELECT
  seller_id,
  seller_state,
  seller_city
FROM raw.sellers;

-- FACT ORDERS (order-grain)
CREATE OR REPLACE VIEW bi.fact_orders AS
WITH order_totals AS (
  SELECT
    order_id,
    SUM(price) AS items_gmv,
    SUM(freight_value) AS freight_total
  FROM raw.order_items
  GROUP BY order_id
),
payments AS (
  SELECT
    order_id,
    SUM(payment_value) AS payment_total
  FROM raw.payments
  GROUP BY order_id
)
SELECT
  o.order_id,
  o.customer_unique_id AS customer_key,
  (EXTRACT(YEAR FROM o.purchase_date)::int * 10000
   + EXTRACT(MONTH FROM o.purchase_date)::int * 100
   + EXTRACT(DAY FROM o.purchase_date)::int) AS date_key,
  o.purchase_date,
  o.customer_state,
  o.order_status,
  ot.items_gmv,
  ot.freight_total,
  (ot.items_gmv + ot.freight_total) AS gmv_plus_freight,
  p.payment_total
FROM clean.orders o
LEFT JOIN order_totals ot USING (order_id)
LEFT JOIN payments p USING (order_id)
WHERE o.order_status = 'delivered';

-- FACT ORDER ITEMS (item-grain)
CREATE OR REPLACE VIEW bi.fact_order_items AS
SELECT
  si.order_id,
  si.order_item_id,
  fo.customer_key,
  fo.date_key,
  si.product_id,
  si.seller_id,
  si.item_price,
  si.freight_value,
  si.gmv_plus_freight
FROM clean.sales_item si
JOIN bi.fact_orders fo ON fo.order_id = si.order_id;

COMMIT;
