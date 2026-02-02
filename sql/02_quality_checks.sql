-- row counts
SELECT 'orders' AS table, COUNT(*) FROM raw.orders
UNION ALL SELECT 'order_items', COUNT(*) FROM raw.order_items
UNION ALL SELECT 'payments', COUNT(*) FROM raw.payments
UNION ALL SELECT 'customers', COUNT(*) FROM raw.customers
UNION ALL SELECT 'products', COUNT(*) FROM raw.products
UNION ALL SELECT 'sellers', COUNT(*) FROM raw.sellers
UNION ALL SELECT 'category_translation', COUNT(*) FROM raw.category_translation;

-- key null checks
SELECT
  SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS orders_null_order_id,
  SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS orders_null_customer_id
FROM raw.orders;

-- negative/zero sanity
SELECT
  SUM(CASE WHEN price < 0 THEN 1 ELSE 0 END) AS neg_price,
  SUM(CASE WHEN freight_value < 0 THEN 1 ELSE 0 END) AS neg_freight
FROM raw.order_items;

-- duplicates check (should be 0 if PK works)
SELECT order_id, order_item_id, COUNT(*)
FROM raw.order_items
GROUP BY 1,2
HAVING COUNT(*) > 1;
