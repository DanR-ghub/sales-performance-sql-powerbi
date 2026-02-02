BEGIN;

CREATE SCHEMA IF NOT EXISTS raw;

-- ORDERS (core)
CREATE TABLE IF NOT EXISTS raw.orders (
  order_id                      TEXT PRIMARY KEY,
  customer_id                   TEXT,
  order_status                  TEXT,
  order_purchase_timestamp      TIMESTAMP,
  order_approved_at             TIMESTAMP,
  order_delivered_carrier_date  TIMESTAMP,
  order_delivered_customer_date TIMESTAMP,
  order_estimated_delivery_date TIMESTAMP
);

-- ORDER ITEMS (line-level revenue)
CREATE TABLE IF NOT EXISTS raw.order_items (
  order_id            TEXT,
  order_item_id       INT,
  product_id          TEXT,
  seller_id           TEXT,
  shipping_limit_date TIMESTAMP,
  price               NUMERIC(12,2),
  freight_value       NUMERIC(12,2),
  PRIMARY KEY (order_id, order_item_id)
);

-- PAYMENTS (order_total often approximated here)
CREATE TABLE IF NOT EXISTS raw.payments (
  order_id              TEXT,
  payment_sequential    INT,
  payment_type          TEXT,
  payment_installments  INT,
  payment_value         NUMERIC(12,2),
  PRIMARY KEY (order_id, payment_sequential)
);

-- CUSTOMERS (for geography + unique customer tracking)
CREATE TABLE IF NOT EXISTS raw.customers (
  customer_id              TEXT PRIMARY KEY,
  customer_unique_id       TEXT,
  customer_zip_code_prefix TEXT,
  customer_city            TEXT,
  customer_state           TEXT
);

-- PRODUCTS (category + attributes)
CREATE TABLE IF NOT EXISTS raw.products (
  product_id                 TEXT PRIMARY KEY,
  product_category_name      TEXT,
  product_name_length        INT,
  product_description_length INT,
  product_photos_qty         INT,
  product_weight_g           INT,
  product_length_cm          INT,
  product_height_cm          INT,
  product_width_cm           INT
);

-- SELLERS (seller geography)
CREATE TABLE IF NOT EXISTS raw.sellers (
  seller_id              TEXT PRIMARY KEY,
  seller_zip_code_prefix TEXT,
  seller_city            TEXT,
  seller_state           TEXT
);

-- CATEGORY TRANSLATION (PT -> EN)
CREATE TABLE IF NOT EXISTS raw.category_translation (
  product_category_name         TEXT PRIMARY KEY,
  product_category_name_english TEXT
);

COMMIT;
