/*
============================================================
gold.dim_customers quality checks
============================================================
*/

-- Check for nulls or duplicates in surrogate and business keys
-- Expected outcome: 0 rows (no NULL or duplicate keys)
SELECT customer_key, COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1 OR customer_key IS NULL;

SELECT customer_id, COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1 OR customer_id IS NULL;

-- Check for unwanted spaces in key/name columns
-- Expected outcome: 0 rows (all text values are trimmed)
SELECT customer_number, first_name, last_name
FROM gold.dim_customers
WHERE customer_number != TRIM(customer_number)
	OR first_name != TRIM(first_name)
	OR last_name != TRIM(last_name);

-- Check for standardization and consistency of categorical columns
-- Expected outcome: review-only (distinct values follow expected domains)
SELECT DISTINCT marital_status, gender
FROM gold.dim_customers;

-- Check for invalid birthdates
-- Expected outcome: 0 rows (birthdate is NULL or between 1924-01-01 and current date)
SELECT customer_key, birthdate
FROM gold.dim_customers
WHERE birthdate IS NOT NULL
  AND (birthdate < '1924-01-01' OR birthdate > CAST(GETDATE() AS DATE));

-- Check final output
-- Expected outcome: review-only (data present and transformed as intended)
SELECT *
FROM gold.dim_customers;


/*
============================================================
gold.dim_products quality checks
============================================================
*/

-- Check for nulls or duplicates in surrogate and business keys
-- Expected outcome: 0 rows (no NULL or duplicate keys)
SELECT product_key, COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1 OR product_key IS NULL;

SELECT product_id, COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_id
HAVING COUNT(*) > 1 OR product_id IS NULL;

SELECT product_number, COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_number
HAVING COUNT(*) > 1 OR product_number IS NULL;

-- Check for unwanted spaces
-- Expected outcome: 0 rows (all text values are trimmed)
SELECT product_number, product_name, category, subcategory, product_line
FROM gold.dim_products
WHERE product_number != TRIM(product_number)
	OR product_name != TRIM(product_name)
	OR category != TRIM(category)
	OR subcategory != TRIM(subcategory)
	OR product_line != TRIM(product_line);

-- Check for invalid measures and dates
-- Expected outcome: 0 rows (cost is non-negative and start_date is not NULL)
SELECT product_key, cost, start_date
FROM gold.dim_products
WHERE cost < 0 OR cost IS NULL OR start_date IS NULL;

-- Check standardization and consistency
-- Expected outcome: review-only (distinct categories/lines follow expected domains)
SELECT DISTINCT category, subcategory, product_line
FROM gold.dim_products;

-- Check final output
-- Expected outcome: review-only (data present and transformed as intended)
SELECT *
FROM gold.dim_products;


/*
============================================================
gold.fact_sales quality checks
============================================================
*/

-- Check for nulls in critical keys
-- Expected outcome: 0 rows (order_number, product_key, customer_key are populated)
SELECT order_number, product_key, customer_key
FROM gold.fact_sales
WHERE order_number IS NULL
	OR product_key IS NULL
	OR customer_key IS NULL;

-- Check for duplicate transaction grain
-- Expected outcome: 0 rows (order_number + product_key + customer_key is unique)
SELECT order_number, product_key, customer_key, COUNT(*) AS duplicate_count
FROM gold.fact_sales
GROUP BY order_number, product_key, customer_key
HAVING COUNT(*) > 1;

-- Ensure referential integrity against dimensions
-- Expected outcome: 0 rows (all keys in fact exist in dimensions)
SELECT fs.product_key
FROM gold.fact_sales fs
LEFT JOIN gold.dim_products dp
	ON fs.product_key = dp.product_key
WHERE dp.product_key IS NULL;

SELECT fs.customer_key
FROM gold.fact_sales fs
LEFT JOIN gold.dim_customers dc
	ON fs.customer_key = dc.customer_key
WHERE dc.customer_key IS NULL;

-- Check invalid date boundaries and chronology
-- Expected outcome: 0 rows (order_date exists and chronological order is valid)
SELECT order_number, order_date
FROM gold.fact_sales
WHERE order_date IS NULL
	OR order_date > '2050-01-01'
	OR order_date < '1900-01-01';

SELECT order_number, order_date, shipping_date, due_date
FROM gold.fact_sales
WHERE (shipping_date IS NOT NULL AND order_date > shipping_date)
	OR (due_date IS NOT NULL AND order_date > due_date);

-- Check measures consistency
-- Expected outcome: 0 rows (sales_amount = quantity * price and all values positive)
SELECT sales_amount, quantity, sls_price
FROM gold.fact_sales
WHERE sales_amount != quantity * sls_price
	OR sales_amount IS NULL
	OR quantity IS NULL
	OR sls_price IS NULL
	OR sales_amount <= 0
	OR quantity <= 0
	OR sls_price <= 0;

-- Check final output
-- Expected outcome: review-only (data present and transformed as intended)
SELECT *
FROM gold.fact_sales;
