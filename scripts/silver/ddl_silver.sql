/*
============================================================
Create DDL for the silver layer tables
============================================================
Why this script exists:
	Provide stable, cleaned structures where business rules are enforced before
	data is exposed to downstream analytics and semantic views.

WARNING: Running this script will drop any tables that match the defined name; this data
will be permanently deleted. Proceed with caution and ensure you have proper backups before
running the script.
*/

USE DataWarehouse;
GO

/* Guarantee schema availability so this script is deployable in fresh environments. */
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
BEGIN
	EXEC('CREATE SCHEMA silver');
END


-- Recreate silver CRM tables so transformation contracts stay deterministic per run.

IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
	DROP TABLE silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info (
	cst_id INT,
	cst_key NVARCHAR(50),
	cst_firstname NVARCHAR(50),
	cst_lastname NVARCHAR(50),
	cst_marital_status NVARCHAR(50),
	cst_gndr NVARCHAR(50),
	cst_create_date DATE,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
	DROP TABLE silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info (
	prd_id INT,
	prd_key NVARCHAR(50),
	cat_id NVARCHAR(50),
	prd_nm NVARCHAR(100),
	prd_cost DECIMAL(18,2),
	prd_line NVARCHAR(50),
	prd_start_dt DATE,
	prd_end_dt DATE,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details (
	sls_ord_num NVARCHAR(50),
	sls_prd_key NVARCHAR(50),
	sls_cust_id INT,
	sls_order_dt DATE,
	sls_ship_dt DATE,
	sls_due_dt DATE,
	sls_sales DECIMAL(18,2),
	sls_quantity INT,
	sls_price DECIMAL(18,2),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);


-- Recreate silver ERP tables to keep standardized entities aligned with CRM outputs.

IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
	DROP TABLE silver.erp_cust_az12;
CREATE TABLE silver.erp_cust_az12 (
	cid NVARCHAR(50),
	bdate DATE,
	gen NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
	DROP TABLE silver.erp_loc_a101;
CREATE TABLE silver.erp_loc_a101 (
	cid NVARCHAR(50),
	cntry NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
	DROP TABLE silver.erp_px_cat_g1v2;
CREATE TABLE silver.erp_px_cat_g1v2 (
	id NVARCHAR(50),
	cat NVARCHAR(100),
	subcat NVARCHAR(100),
	maintenance NVARCHAR(100),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);