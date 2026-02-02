BEGIN;

-- Drop/clean existing data to allow for idempotent runs
TRUNCATE TABLE
  raw.orders,
  raw.order_items,
  raw.payments,
  raw.customers,
  raw.products,
  raw.sellers,
  raw.category_translation
RESTART IDENTITY;

-- COPY from files mounted at /data
COPY raw.orders
FROM '/data/olist_orders_dataset.csv'
WITH (FORMAT csv, HEADER true);

COPY raw.order_items
FROM '/data/olist_order_items_dataset.csv'
WITH (FORMAT csv, HEADER true);

COPY raw.payments
FROM '/data/olist_order_payments_dataset.csv'
WITH (FORMAT csv, HEADER true);

COPY raw.customers
FROM '/data/olist_customers_dataset.csv'
WITH (FORMAT csv, HEADER true);

COPY raw.products
FROM '/data/olist_products_dataset.csv'
WITH (FORMAT csv, HEADER true);

COPY raw.sellers
FROM '/data/olist_sellers_dataset.csv'
WITH (FORMAT csv, HEADER true);

COPY raw.category_translation
FROM '/data/product_category_name_translation.csv'
WITH (FORMAT csv, HEADER true);

COMMIT;
