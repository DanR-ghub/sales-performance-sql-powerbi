-- Check if every order_id in order_items exists in orders table
SELECT COUNT(*) AS orphan_order_items
FROM raw.order_items oi
LEFT JOIN raw.orders o ON o.order_id = oi.order_id
WHERE o.order_id IS NULL;

-- Check if every customer_id in orders exists in customers table
SELECT COUNT(*) AS orphan_orders_customers
FROM raw.orders o
LEFT JOIN raw.customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

-- Check if every product_id in order_items exists in products table
SELECT COUNT(*) AS orphan_items_products
FROM raw.order_items oi
LEFT JOIN raw.products p ON p.product_id = oi.product_id
WHERE p.product_id IS NULL;

-- Check if every seller_id in order_items exists in sellers table
SELECT COUNT(*) AS orphan_items_sellers
FROM raw.order_items oi
LEFT JOIN raw.sellers s ON s.seller_id = oi.seller_id
WHERE s.seller_id IS NULL;
