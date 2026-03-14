/*
============================================================
Troubleshooting script: pipeline load diagnostics
============================================================
Script Purpose:
  Diagnose why bronze/silver/gold objects show zero rows after a load run.

How to use:
  1) Adjust @data_root_path if needed.
  2) Run this script in SSMS.
  3) Review result sets and messages in order.
*/

USE DataWarehouse;
GO

SET NOCOUNT ON;

DECLARE @data_root_path NVARCHAR(4000) = 'C:\Users\hecto\OneDrive\Documentos\VSCode\sql_medallion_data_warehouse\datasets';
DECLARE @bronze_proc_exists BIT = CASE WHEN OBJECT_ID('bronze.load_bronze', 'P') IS NOT NULL THEN 1 ELSE 0 END;
DECLARE @silver_proc_exists BIT = CASE WHEN OBJECT_ID('silver.load_silver', 'P') IS NOT NULL THEN 1 ELSE 0 END;
DECLARE @msg NVARCHAR(4000);

PRINT '=== ENVIRONMENT ===';
SELECT
	@@SERVERNAME AS server_name,
	CAST(SERVERPROPERTY('MachineName') AS NVARCHAR(128)) AS machine_name,
	CAST(SERVERPROPERTY('InstanceName') AS NVARCHAR(128)) AS instance_name,
	CAST(SERVERPROPERTY('Edition') AS NVARCHAR(128)) AS edition,
	CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)) AS product_version,
	DB_NAME() AS current_database;

PRINT '=== SQL SERVER SERVICE ACCOUNT (if permitted) ===';
BEGIN TRY
	SELECT servicename, startup_type_desc, status_desc, service_account
	FROM sys.dm_server_services
	ORDER BY servicename;
END TRY
BEGIN CATCH
	PRINT 'Could not read sys.dm_server_services (requires server-level permission).';
END CATCH;

PRINT '=== EXPECTED PROCEDURES ===';
SELECT
	'bronze.load_bronze' AS object_name,
	CASE WHEN @bronze_proc_exists = 1 THEN 'FOUND' ELSE 'MISSING' END AS status
UNION ALL
SELECT
	'silver.load_silver',
	CASE WHEN @silver_proc_exists = 1 THEN 'FOUND' ELSE 'MISSING' END;

PRINT '=== FILE ACCESS CHECK FROM SQL SERVER PROCESS ===';
IF OBJECT_ID('master.dbo.xp_fileexist') IS NOT NULL
BEGIN
	DECLARE @files TABLE (
		file_path NVARCHAR(4000),
		file_exists INT,
		parent_exists INT,
		is_directory INT
	);

	DECLARE @probe TABLE (
		FileExists INT,
		ParentDirectoryExists INT,
		FileIsDirectory INT
	);

	DECLARE @f NVARCHAR(4000);

	DECLARE file_cursor CURSOR LOCAL FAST_FORWARD FOR
	SELECT @data_root_path + v.rel_path
	FROM (VALUES
		(N'\source_crm\cust_info.csv'),
		(N'\source_crm\prd_info.csv'),
		(N'\source_crm\sales_details.csv'),
		(N'\source_erp\CUST_AZ12.csv'),
		(N'\source_erp\LOC_A101.csv'),
		(N'\source_erp\PX_CAT_G1V2.csv')
	) v(rel_path);

	OPEN file_cursor;
	FETCH NEXT FROM file_cursor INTO @f;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		DELETE FROM @probe;
		INSERT INTO @probe EXEC master.dbo.xp_fileexist @f;

		INSERT INTO @files(file_path, file_exists, parent_exists, is_directory)
		SELECT @f, FileExists, ParentDirectoryExists, FileIsDirectory
		FROM @probe;

		FETCH NEXT FROM file_cursor INTO @f;
	END

	CLOSE file_cursor;
	DEALLOCATE file_cursor;

	SELECT
		file_path,
		file_exists,
		parent_exists,
		is_directory,
		CASE
			WHEN file_exists = 1 THEN 'OK'
			WHEN parent_exists = 0 THEN 'PARENT_NOT_FOUND'
			ELSE 'NOT_ACCESSIBLE_OR_NOT_FOUND'
		END AS status
	FROM @files;
END
ELSE
BEGIN
	PRINT 'xp_fileexist is not available. Run manual check with SQL Server service account permissions.';
END

PRINT '=== LAYER ROW COUNTS (BEFORE LOAD) ===';
SELECT 'bronze.crm_cust_info' AS object_name, COUNT(*) AS row_count FROM bronze.crm_cust_info
UNION ALL SELECT 'bronze.crm_prd_info', COUNT(*) FROM bronze.crm_prd_info
UNION ALL SELECT 'bronze.crm_sales_details', COUNT(*) FROM bronze.crm_sales_details
UNION ALL SELECT 'bronze.erp_cust_az12', COUNT(*) FROM bronze.erp_cust_az12
UNION ALL SELECT 'bronze.erp_loc_a101', COUNT(*) FROM bronze.erp_loc_a101
UNION ALL SELECT 'bronze.erp_px_cat_g1v2', COUNT(*) FROM bronze.erp_px_cat_g1v2
UNION ALL SELECT 'silver.crm_cust_info', COUNT(*) FROM silver.crm_cust_info
UNION ALL SELECT 'silver.crm_prd_info', COUNT(*) FROM silver.crm_prd_info
UNION ALL SELECT 'silver.crm_sales_details', COUNT(*) FROM silver.crm_sales_details
UNION ALL SELECT 'silver.erp_cust_az12', COUNT(*) FROM silver.erp_cust_az12
UNION ALL SELECT 'silver.erp_loc_a101', COUNT(*) FROM silver.erp_loc_a101
UNION ALL SELECT 'silver.erp_px_cat_g1v2', COUNT(*) FROM silver.erp_px_cat_g1v2
UNION ALL SELECT 'gold.dim_customers', COUNT(*) FROM gold.dim_customers
UNION ALL SELECT 'gold.dim_products', COUNT(*) FROM gold.dim_products
UNION ALL SELECT 'gold.fact_sales', COUNT(*) FROM gold.fact_sales;

PRINT '=== EXECUTE BRONZE ONLY (ISOLATION STEP) ===';
IF @bronze_proc_exists = 1
BEGIN
	BEGIN TRY
		EXEC bronze.load_bronze @data_root_path = @data_root_path;
		PRINT 'bronze.load_bronze executed successfully.';
	END TRY
	BEGIN CATCH
		SET @msg = 'bronze.load_bronze failed. Error ' + CAST(ERROR_NUMBER() AS NVARCHAR(20)) + ': ' + ERROR_MESSAGE();
		PRINT @msg;
	END CATCH
END
ELSE
BEGIN
	PRINT 'bronze.load_bronze not found. Create it first from scripts/bronze/proc_load_bronze.sql';
END

PRINT '=== BRONZE ROW COUNTS (AFTER BRONZE LOAD) ===';
SELECT 'bronze.crm_cust_info' AS object_name, COUNT(*) AS row_count FROM bronze.crm_cust_info
UNION ALL SELECT 'bronze.crm_prd_info', COUNT(*) FROM bronze.crm_prd_info
UNION ALL SELECT 'bronze.crm_sales_details', COUNT(*) FROM bronze.crm_sales_details
UNION ALL SELECT 'bronze.erp_cust_az12', COUNT(*) FROM bronze.erp_cust_az12
UNION ALL SELECT 'bronze.erp_loc_a101', COUNT(*) FROM bronze.erp_loc_a101
UNION ALL SELECT 'bronze.erp_px_cat_g1v2', COUNT(*) FROM bronze.erp_px_cat_g1v2;

PRINT '=== EXECUTE SILVER ONLY (IF BRONZE HAS DATA) ===';
IF @silver_proc_exists = 1
BEGIN
	BEGIN TRY
		EXEC silver.load_silver;
		PRINT 'silver.load_silver executed successfully.';
	END TRY
	BEGIN CATCH
		SET @msg = 'silver.load_silver failed. Error ' + CAST(ERROR_NUMBER() AS NVARCHAR(20)) + ': ' + ERROR_MESSAGE();
		PRINT @msg;
	END CATCH
END
ELSE
BEGIN
	PRINT 'silver.load_silver not found. Create it first from scripts/silver/proc_load_silver.sql';
END

PRINT '=== SILVER/GOLD ROW COUNTS (AFTER SILVER LOAD) ===';
SELECT 'silver.crm_cust_info' AS object_name, COUNT(*) AS row_count FROM silver.crm_cust_info
UNION ALL SELECT 'silver.crm_prd_info', COUNT(*) FROM silver.crm_prd_info
UNION ALL SELECT 'silver.crm_sales_details', COUNT(*) FROM silver.crm_sales_details
UNION ALL SELECT 'silver.erp_cust_az12', COUNT(*) FROM silver.erp_cust_az12
UNION ALL SELECT 'silver.erp_loc_a101', COUNT(*) FROM silver.erp_loc_a101
UNION ALL SELECT 'silver.erp_px_cat_g1v2', COUNT(*) FROM silver.erp_px_cat_g1v2
UNION ALL SELECT 'gold.dim_customers', COUNT(*) FROM gold.dim_customers
UNION ALL SELECT 'gold.dim_products', COUNT(*) FROM gold.dim_products
UNION ALL SELECT 'gold.fact_sales', COUNT(*) FROM gold.fact_sales;

PRINT '=== NEXT INTERPRETATION ===';
PRINT '1) Bronze = 0 rows after bronze load: check file path and SQL Server service account access to files.';
PRINT '2) Bronze > 0 but Silver = 0: inspect silver.load_silver logic/errors.';
PRINT '3) Silver > 0 but Gold = 0: ensure scripts/gold/ddl_gold.sql was executed in DataWarehouse.';
GO
