/*
============================================================
Create DDL for the gold layer views
============================================================
Script Purpose:
  This script creates the semantic views for the 'gold' schema in the
  'DataWarehouse' database.
  The gold layer contains business-ready dimensions and facts for analytics.

WARNING: Re-running this script will alter existing views in the gold layer.
Validate downstream BI/report dependencies before deployment.
*/

USE DataWarehouse;
GO

/* Ensure the `gold` schema exists (safe to run in DataWarehouse) */
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
BEGIN
	EXEC('CREATE SCHEMA gold');
END
GO


-- Create or alter dimension views in the gold schema

CREATE OR ALTER VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE
		WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is master reference for gender
		ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
	ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
	ON ci.cst_key = la.cid;
GO


CREATE OR ALTER VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
	pn.prd_id AS product_id,
	SUBSTRING(TRIM(pn.prd_key), 7, LEN(TRIM(pn.prd_key))) AS product_number,
	pn.prd_nm AS product_name,
	pn.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS subcategory,
	pc.maintenance,
	pn.prd_cost AS cost,
	pn.prd_line AS product_line,
	pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
	ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL; -- Filter historical data
GO


-- Create or alter fact view in the gold schema

CREATE OR ALTER VIEW gold.fact_sales AS
SELECT
	-- Keys
	sd.sls_ord_num AS order_number,
	pr.product_key,
	cu.customer_key,
	-- Dates
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	-- Measures
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
	ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
	ON sd.sls_cust_id = cu.customer_id;
GO


-- Create or alter pricing KPI view in the gold schema

CREATE OR ALTER VIEW gold.pricing_kpi_monthly AS
SELECT
	DATEFROMPARTS(YEAR(fs.order_date), MONTH(fs.order_date), 1) AS order_month,
	dp.product_key,
	dp.product_number,
	dp.product_name,
	dp.category,
	dp.subcategory,
	dc.country,
	COUNT_BIG(*) AS sales_line_count,
	COUNT(DISTINCT fs.order_number) AS order_count,
	SUM(CAST(fs.quantity AS BIGINT)) AS units_sold,
	CAST(SUM(fs.sales_amount) AS DECIMAL(18,2)) AS gross_sales_amount,
	CAST(SUM(fs.sales_amount) / NULLIF(SUM(CAST(fs.quantity AS DECIMAL(18,4))), 0) AS DECIMAL(18,4)) AS weighted_avg_unit_price,
	MIN(fs.sls_price) AS min_unit_price,
	MAX(fs.sls_price) AS max_unit_price
FROM gold.fact_sales fs
INNER JOIN gold.dim_products dp
	ON fs.product_key = dp.product_key
INNER JOIN gold.dim_customers dc
	ON fs.customer_key = dc.customer_key
WHERE fs.order_date IS NOT NULL
GROUP BY
	DATEFROMPARTS(YEAR(fs.order_date), MONTH(fs.order_date), 1),
	dp.product_key,
	dp.product_number,
	dp.product_name,
	dp.category,
	dp.subcategory,
	dc.country;
GO