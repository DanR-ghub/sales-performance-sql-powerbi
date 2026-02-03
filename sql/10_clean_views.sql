BEGIN;

CREATE SCHEMA IF NOT EXISTS clean;

-- Orders joined with customer_unique_id and timestamps
CREATE OR REPLACE VIEW clean.orders AS
SELECT
  o.order_id,
  o.customer_id,
  c.customer_unique_id,
  c.customer_city,
  c.customer_state,
  o.order_status,
  o.order_purchase_timestamp,
  (o.order_purchase_timestamp::date) AS purchase_date,
  (date_trunc('month', o.order_purchase_timestamp)::date) AS purchase_month,
  o.order_approved_at,
  o.order_delivered_carrier_date,
  o.order_delivered_customer_date,
  o.order_estimated_delivery_date,
  CASE
    WHEN o.order_delivered_customer_date IS NOT NULL
    THEN (o.order_delivered_customer_date::date - o.order_purchase_timestamp::date)
  END AS delivery_days,
  CASE
    WHEN o.order_delivered_customer_date IS NOT NULL
     AND o.order_estimated_delivery_date IS NOT NULL
    THEN (o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date)
  END AS delivery_vs_estimated_days
FROM raw.orders o
JOIN raw.customers c ON c.customer_id = o.customer_id;

-- Payments aggregated by order_id (to avoid duplicating installment-based rows)
CREATE OR REPLACE VIEW clean.payments_order AS
SELECT
  order_id,
  SUM(payment_value) AS payment_total,
  COUNT(*) AS payment_rows
FROM raw.payments
GROUP BY order_id;

-- Items enriched with English categories and seller geolocation
CREATE OR REPLACE VIEW clean.order_items_enriched AS
SELECT
  oi.order_id,
  oi.order_item_id,
  oi.product_id,
  oi.seller_id,
  oi.shipping_limit_date,
  oi.price,
  oi.freight_value,
  p.product_category_name,
  COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category_en,
  s.seller_city,
  s.seller_state
FROM raw.order_items oi
LEFT JOIN raw.products p ON p.product_id = oi.product_id
LEFT JOIN raw.category_translation t ON t.product_category_name = p.product_category_name
LEFT JOIN raw.sellers s ON s.seller_id = oi.seller_id;

-- Final "flat" item-level view 
-- Note: payment_total is order-level and will repeat across items
CREATE OR REPLACE VIEW clean.sales_item AS
SELECT
  oi.order_id,
  oi.order_item_id,
  o.customer_unique_id,
  o.customer_state,
  o.customer_city,
  oi.product_id,
  oi.category_en,
  oi.seller_id,
  oi.seller_state,
  o.order_status,
  o.purchase_date,
  o.purchase_month,
  oi.price AS item_price,
  oi.freight_value,
  (oi.price + oi.freight_value) AS gmv_plus_freight,
  po.payment_total
FROM clean.order_items_enriched oi
JOIN clean.orders o ON o.order_id = oi.order_id
LEFT JOIN clean.payments_order po ON po.order_id = oi.order_id;

COMMIT;
