/*
============================================================
crm_cust_info quality checks
============================================================
*/

-- Check for nulls or duplicates in the primary keys
-- Expected outcome: 0 rows (no NULL or duplicate cst_id values)
SELECT cst_id FROM silver.crm_cust_info
GROUP BY cst_id
	HAVING COUNT (*) > 1 OR cst_id IS NULL;

--Check for unwanted spaces
-- Expected outcome: 0 rows (all text values are trimmed)
SELECT cst_key, cst_firstname, cst_lastname
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key)
OR cst_firstname != TRIM(cst_firstname)
OR cst_lastname != TRIM(cst_lastname);

--Check for standardization & consistency of categorical columns
-- Expected outcome: review-only (distinct values should match approved domain values)
SELECT DISTINCT cst_marital_status, cst_gndr
FROM silver.crm_cust_info;

--Check final output
-- Expected outcome: review-only (data present and transformed as intended)
SELECT * FROM silver.crm_cust_info;

/*
============================================================
crm_prd_info quality checks
============================================================
*/

-- Check for nulls or duplicates in the primary keys
-- Expected outcome: 0 rows (no NULL or duplicate prd_id values)
SELECT prd_id, COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
	HAVING COUNT (*) > 1
	OR prd_id IS NULL;

--Check for unwanted spaces
-- Expected outcome: 0 rows (all product names are trimmed)
SELECT prd_nm
FROM silver.crm_prd_info
Where prd_nm != TRIM(prd_nm);

-- Check for unwanted spaces in product names (bronze source)
-- Expected outcome: 0 rows (all source product names are trimmed)
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check for unwanted negative values
-- Expected outcome: 0 rows (prd_cost is non-negative and not NULL)
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Check standardization and consistency
-- Expected outcome: review-only (distinct product lines follow expected categories)
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

--Check for invalid date orders
-- Expected outcome: 0 rows (prd_end_dt is not earlier than prd_start_dt)
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- Check final output
-- Expected outcome: review-only (data present and transformed as intended)
SELECT * FROM silver.crm_prd_info;

/*
============================================================
crm_sales_details quality checks
============================================================
*/

-- Check for unwanted spaces
-- Expected outcome: 0 rows (order numbers are trimmed)
SELECT *
FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

-- Ensure connections
-- Expected outcome: 0 rows (all product keys in sales exist in product dimension)
SELECT sls_prd_key   -- w/Product 
FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN (
	SELECT prd_key FROM silver.crm_prd_info);

-- Expected outcome: 0 rows (all customer ids in sales exist in customer dimension)
SELECT sls_cust_id   -- w/Customer
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (
	SELECT cst_id FROM silver.crm_cust_info);

-- Check invalid dates
-- Expected outcome: 0 rows (order date is not NULL)
SELECT sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt IS NULL;

-- Expected outcome: 0 rows (order dates are within valid boundaries)
SELECT sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt IS NULL
	--boundary definition
	OR sls_order_dt > '2050-01-01'
	OR sls_order_dt < '1900-01-01';

-- Expected outcome: 0 rows (order date is not after ship/due dates)
SELECT sls_order_dt, sls_ship_dt, sls_due_dt
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
	OR sls_order_dt > sls_due_dt;

-- Expected outcome: 0 rows (sales = quantity * price, all values positive and non-NULL)
SELECT sls_sales, sls_quantity, sls_price
FROM silver.crm_sales_details
--sales formula
WHERE sls_sales != sls_quantity * sls_price
--neg, zeros, nulls
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0;

-- Check final output
-- Expected outcome: review-only (data present and transformed as intended)
SELECT * FROM silver.crm_sales_details;

/*
============================================================
erp_cust_az12 quality checks
============================================================
*/

--Identify out of range dates
-- Expected outcome: 0 rows (bdate is between 1924-01-01 and current date)
SELECT DISTINCT bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > CAST(GETDATE() AS DATE);

-- Check silver date datatype standardization
-- Expected outcome: 0 rows (all date columns in silver are typed as DATE)
SELECT table_name, column_name, data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'silver'
	AND (column_name LIKE '%_dt' OR column_name = 'bdate')
	AND data_type <> 'date';

--Standardization and normalization
-- Expected outcome: review-only (distinct gender values are standardized)
SELECT DISTINCT
gen
FROM silver.erp_cust_az12;

--Final check
-- Expected outcome: review-only (data present and transformed as intended)
SELECT *
FROM silver.erp_cust_az12;

/*
============================================================
erp_loc_a101 quality checks
============================================================
*/

-- Check data standardization and consistency
-- Expected outcome: review-only (country values are standardized)
SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry;

-- Final check
-- Expected outcome: review-only (data present and transformed as intended)
SELECT *
FROM silver.erp_loc_a101;

/*
============================================================
erp_px_cat_g1v2 quality checks
============================================================
*/

-- Check for unwanted spaces
-- Expected outcome: 0 rows (category fields are trimmed)
SELECT * FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
    OR subcat != TRIM(subcat)
	OR maintenance != TRIM(maintenance);

-- Check for data standardization and consistency
-- Expected outcome: review-only (distinct category combinations are valid)
SELECT DISTINCT cat, subcat, maintenance
FROM silver.erp_px_cat_g1v2;
