/*
============================================================
Pipeline smoke checks (Bronze -> Silver -> Gold)
============================================================
Script Purpose:
  Run this script after executing bronze/silver/gold loads to verify that
  data is present and key integrity checks pass across all layers.

Expected use:
  1) Run ETL scripts for bronze, silver, and gold.
  2) Run this file.
  3) Review PASS/FAIL results and summary.
*/

USE DataWarehouse;
GO

SET NOCOUNT ON;

DECLARE @checks TABLE (
	check_id INT IDENTITY(1,1) PRIMARY KEY,
	layer VARCHAR(10),
	check_name NVARCHAR(200),
	status VARCHAR(10),
	details NVARCHAR(4000)
);

DECLARE @row_count BIGINT;
DECLARE @expected_count BIGINT;

/*
============================================================
1) Object existence checks
============================================================
*/

INSERT INTO @checks(layer, check_name, status, details)
SELECT
	'BRONZE',
	'All expected bronze tables exist',
	CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END,
	'Found ' + CAST(COUNT(*) AS NVARCHAR(20)) + ' of 6 expected tables.'
FROM sys.tables t
JOIN sys.schemas s
	ON t.schema_id = s.schema_id
WHERE s.name = 'bronze'
  AND t.name IN (
	'crm_cust_info',
	'crm_prd_info',
	'crm_sales_details',
	'erp_cust_az12',
	'erp_loc_a101',
	'erp_px_cat_g1v2'
  );

INSERT INTO @checks(layer, check_name, status, details)
SELECT
	'SILVER',
	'All expected silver tables exist',
	CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END,
	'Found ' + CAST(COUNT(*) AS NVARCHAR(20)) + ' of 6 expected tables.'
FROM sys.tables t
JOIN sys.schemas s
	ON t.schema_id = s.schema_id
WHERE s.name = 'silver'
  AND t.name IN (
	'crm_cust_info',
	'crm_prd_info',
	'crm_sales_details',
	'erp_cust_az12',
	'erp_loc_a101',
	'erp_px_cat_g1v2'
  );

INSERT INTO @checks(layer, check_name, status, details)
SELECT
	'GOLD',
	'All expected gold views exist',
	CASE WHEN COUNT(*) = 3 THEN 'PASS' ELSE 'FAIL' END,
	'Found ' + CAST(COUNT(*) AS NVARCHAR(20)) + ' of 3 expected views.'
FROM sys.views v
JOIN sys.schemas s
	ON v.schema_id = s.schema_id
WHERE s.name = 'gold'
  AND v.name IN ('dim_customers', 'dim_products', 'fact_sales');

/*
============================================================
2) Data presence checks (row counts > 0)
============================================================
*/

SELECT @row_count = COUNT(*) FROM bronze.crm_cust_info;
INSERT INTO @checks VALUES
('BRONZE', 'bronze.crm_cust_info has rows', CASE WHEN @row_count > 0 THEN 'PASS' ELSE 'FAIL' END, 'Rows: ' + CAST(@row_count AS NVARCHAR(20)));

SELECT @row_count = COUNT(*) FROM bronze.crm_prd_info;
INSERT INTO @checks VALUES
('BRONZE', 'bronze.crm_prd_info has rows', CASE WHEN @row_count > 0 THEN 'PASS' ELSE 'FAIL' END, 'Rows: ' + CAST(@row_count AS NVARCHAR(20)));

SELECT @row_count = COUNT(*) FROM bronze.crm_sales_details;
INSERT INTO @checks VALUES
('BRONZE', 'bronze.crm_sales_details has rows', CASE WHEN @row_count > 0 THEN 'PASS' ELSE 'FAIL' END, 'Rows: ' + CAST(@row_count AS NVARCHAR(20)));

SELECT @row_count = COUNT(*) FROM bronze.erp_cust_az12;
INSERT INTO @checks VALUES
('BRONZE', 'bronze.erp_cust_az12 has rows', CASE WHEN @row_count > 0 THEN 'PASS' ELSE 'FAIL' END, 'Rows: ' + CAST(@row_count AS NVARCHAR(20)));

SELECT @row_count = COUNT(*) FROM bronze.erp_loc_a101;
INSERT INTO @checks VALUES
('BRONZE', 'bronze.erp_loc_a101 has rows', CASE WHEN @row_count > 0 THEN 'PASS' ELSE 'FAIL' END, 'Rows: ' + CAST(@row_count AS NVARCHAR(20)));

SELECT @row_count = COUNT(*) FROM bronze.erp_px_cat_g1v2;
INSERT INTO @checks VALUES
('BRONZE', 'bronze.erp_px_cat_g1v2 has rows', CASE WHEN @row_count > 0 THEN 'PASS' ELSE 'FAIL' END, 'Rows: ' + CAST(@row_count AS NVARCHAR(20)));

SELECT @row_count = COUNT(*) FROM silver.crm_cust_info;
INSERT INTO @checks VALUES
('SILVER', 'silver.crm_cust_info has rows', CASE WHEN @row_count > 0 THEN 'PASS' ELSE 'FAIL' END, 'Rows: ' + CAST(@row_count AS NVARCHAR(20)));

SELECT @row_count = COUNT(*) FROM silver.crm_prd_info;
INSERT INTO @checks VALUES
('SILVER', 'silver.crm_prd_info has rows', CASE WHEN @row_count > 0 THEN 'PASS' ELSE 'FAIL' END, 'Rows: ' + CAST(@row_count AS NVARCHAR(20)));

SELECT @row_count = COUNT(*) FROM silver.crm_sales_details;
INSERT INTO @checks VALUES
('SILVER', 'silver.crm_sales_details has rows', CASE WHEN @row_count > 0 THEN 'PASS' ELSE 'FAIL' END, 'Rows: ' + CAST(@row_count AS NVARCHAR(20)));

SELECT @row_count = COUNT(*) FROM silver.erp_cust_az12;
INSERT INTO @checks VALUES
('SILVER', 'silver.erp_cust_az12 has rows', CASE WHEN @row_count > 0 THEN 'PASS' ELSE 'FAIL' END, 'Rows: ' + CAST(@row_count AS NVARCHAR(20)));

SELECT @row_count = COUNT(*) FROM silver.erp_loc_a101;
INSERT INTO @checks VALUES
('SILVER', 'silver.erp_loc_a101 has rows', CASE WHEN @row_count > 0 THEN 'PASS' ELSE 'FAIL' END, 'Rows: ' + CAST(@row_count AS NVARCHAR(20)));

SELECT @row_count = COUNT(*) FROM silver.erp_px_cat_g1v2;
INSERT INTO @checks VALUES
('SILVER', 'silver.erp_px_cat_g1v2 has rows', CASE WHEN @row_count > 0 THEN 'PASS' ELSE 'FAIL' END, 'Rows: ' + CAST(@row_count AS NVARCHAR(20)));

SELECT @row_count = COUNT(*) FROM gold.dim_customers;
INSERT INTO @checks VALUES
('GOLD', 'gold.dim_customers has rows', CASE WHEN @row_count > 0 THEN 'PASS' ELSE 'FAIL' END, 'Rows: ' + CAST(@row_count AS NVARCHAR(20)));

SELECT @row_count = COUNT(*) FROM gold.dim_products;
INSERT INTO @checks VALUES
('GOLD', 'gold.dim_products has rows', CASE WHEN @row_count > 0 THEN 'PASS' ELSE 'FAIL' END, 'Rows: ' + CAST(@row_count AS NVARCHAR(20)));

SELECT @row_count = COUNT(*) FROM gold.fact_sales;
INSERT INTO @checks VALUES
('GOLD', 'gold.fact_sales has rows', CASE WHEN @row_count > 0 THEN 'PASS' ELSE 'FAIL' END, 'Rows: ' + CAST(@row_count AS NVARCHAR(20)));

/*
============================================================
3) Cross-layer sanity checks
============================================================
*/

SELECT @row_count = COUNT(*) FROM silver.crm_sales_details;
SELECT @expected_count = COUNT(*) FROM bronze.crm_sales_details;
INSERT INTO @checks VALUES
(
	'SILVER',
	'Sales row count preserved from bronze to silver',
	CASE WHEN @row_count = @expected_count THEN 'PASS' ELSE 'FAIL' END,
	'Silver rows: ' + CAST(@row_count AS NVARCHAR(20)) + ', Bronze rows: ' + CAST(@expected_count AS NVARCHAR(20))
);

SELECT @row_count = COUNT(*) FROM gold.dim_products;
SELECT @expected_count = COUNT(*) FROM silver.crm_prd_info WHERE prd_end_dt IS NULL;
INSERT INTO @checks VALUES
(
	'GOLD',
	'gold.dim_products matches active products in silver',
	CASE WHEN @row_count = @expected_count THEN 'PASS' ELSE 'FAIL' END,
	'Gold rows: ' + CAST(@row_count AS NVARCHAR(20)) + ', Expected active silver rows: ' + CAST(@expected_count AS NVARCHAR(20))
);

SELECT @row_count = COUNT(*) FROM gold.fact_sales WHERE product_key IS NULL OR customer_key IS NULL;
INSERT INTO @checks VALUES
(
	'GOLD',
	'gold.fact_sales has no NULL foreign keys',
	CASE WHEN @row_count = 0 THEN 'PASS' ELSE 'FAIL' END,
	'Rows with NULL product/customer key: ' + CAST(@row_count AS NVARCHAR(20))
);

/*
============================================================
4) Output
============================================================
*/

SELECT
	check_id,
	layer,
	check_name,
	status,
	details
FROM @checks
ORDER BY
	CASE status WHEN 'FAIL' THEN 0 ELSE 1 END,
	layer,
	check_id;

SELECT
	COUNT(*) AS total_checks,
	SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) AS passed_checks,
	SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) AS failed_checks
FROM @checks;

IF EXISTS (SELECT 1 FROM @checks WHERE status = 'FAIL')
BEGIN
	PRINT 'Pipeline smoke check result: FAIL (review failed checks above).';
END
ELSE
BEGIN
	PRINT 'Pipeline smoke check result: PASS.';
END
GO
