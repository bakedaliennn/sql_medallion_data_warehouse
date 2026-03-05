/*
============================================================
Stored procedure: Load Bronze layer
============================================================
Script Purpose:
  This stored procedure loads data (CRM and ERP) into the bronze schema from csv files.
  It performs the following actions:
	- Truncates the bronze tables before loading data.
	- Uses the BULK INSRT command to load data from csv files to bronze tables.
	- Prints out updates on the process and running times for each load and the whole batch.
	- Prints out errors number and details (if any) to aid debugging.
  Parameters:
	- None.

Usage example:
  EXEC bronze.load_bronze;

WARNING: Running this script will drop the tables in the bronze layer that match the defined name.
This data will be permanently deleted. Proceed with caution and ensure you have proper backups before
running the script.
*/



USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @t_start_time DATETIME, @t_end_time DATETIME;
	DECLARE @start_time DATETIME, @end_time DATETIME;
	DECLARE @rows_loaded INT;
	DECLARE @current_table NVARCHAR(128);
	DECLARE @current_file NVARCHAR(4000);
	
	BEGIN TRY
		SET @t_start_time = GETDATE();
		PRINT '======================================';
		PRINT 'Loading Bronze Layer';
		PRINT '======================================';

		-----------------------------------------------------------------------------------------------------
		-- CRM Full loads
		PRINT '--------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '--------------------------------------';


		SET @start_time = GETDATE();
		SET @current_table = 'bronze.crm_cust_info';
		SET @current_file = 'D:\VSCode\sql-data-warehouse-project\datasets\source_crm\cust_info.csv';
		PRINT '>> Truncating table: ' + @current_table;
		TRUNCATE TABLE bronze.crm_cust_info;
		PRINT '>> Inserting data into: ' + @current_table;
		BULK INSERT bronze.crm_cust_info
		FROM 'D:\VSCode\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			FIELDQUOTE = '"',
			ROWTERMINATOR = '0x0a',
			CODEPAGE = '65001',
			KEEPNULLS,
			TABLOCK 
		);
		SET @rows_loaded = @@ROWCOUNT;
		SET @end_time = GETDATE();
		PRINT '>> Rows loaded: ' + CAST(@rows_loaded AS NVARCHAR);
		PRINT '>> Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------------';


		SET @start_time = GETDATE();
		SET @current_table = 'bronze.crm_prd_info';
		SET @current_file = 'D:\VSCode\sql-data-warehouse-project\datasets\source_crm\prd_info.csv';
		PRINT '>> Truncating table: ' + @current_table;
		TRUNCATE TABLE bronze.crm_prd_info;
		PRINT '>> Inserting data into: ' + @current_table;
		BULK INSERT bronze.crm_prd_info
		FROM 'D:\VSCode\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			FIELDQUOTE = '"',
			ROWTERMINATOR = '0x0a',
			CODEPAGE = '65001',
			KEEPNULLS,
			TABLOCK 
		);
		SET @rows_loaded = @@ROWCOUNT;
		SET @end_time = GETDATE();
		PRINT '>> Rows loaded: ' + CAST(@rows_loaded AS NVARCHAR);
		PRINT '>> Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------------';


		SET @start_time = GETDATE();
		SET @current_table = 'bronze.crm_sales_details';
		SET @current_file = 'D:\VSCode\sql-data-warehouse-project\datasets\source_crm\sales_details.csv';
		PRINT '>> Truncating table: ' + @current_table;
		TRUNCATE TABLE bronze.crm_sales_details;
		PRINT '>> Inserting data into: ' + @current_table;
		BULK INSERT bronze.crm_sales_details
		FROM 'D:\VSCode\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			FIELDQUOTE = '"',
			ROWTERMINATOR = '0x0a',
			CODEPAGE = '65001',
			KEEPNULLS,
			TABLOCK 
		);
		SET @rows_loaded = @@ROWCOUNT;
		SET @end_time = GETDATE();
		PRINT '>> Rows loaded: ' + CAST(@rows_loaded AS NVARCHAR);
		PRINT '>> Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------------';




		-----------------------------------------------------------------------------------------------------
		-- ERP Full loads
		PRINT '--------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '--------------------------------------';


		SET @start_time = GETDATE();
		SET @current_table = 'bronze.erp_cust_az12';
		SET @current_file = 'D:\VSCode\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv';
		PRINT '>> Truncating table: ' + @current_table;
		TRUNCATE TABLE bronze.erp_cust_az12;
		PRINT '>> Inserting data into: ' + @current_table;
		BULK INSERT bronze.erp_cust_az12
		FROM 'D:\VSCode\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			FIELDQUOTE = '"',
			ROWTERMINATOR = '0x0a',
			CODEPAGE = '65001',
			KEEPNULLS,
			TABLOCK 
		);
		SET @rows_loaded = @@ROWCOUNT;
		SET @end_time = GETDATE();
		PRINT '>> Rows loaded: ' + CAST(@rows_loaded AS NVARCHAR);
		PRINT '>> Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------------';


		SET @start_time = GETDATE();
		SET @current_table = 'bronze.erp_loc_a101';
		SET @current_file = 'D:\VSCode\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv';
		PRINT '>> Truncating table: ' + @current_table;
		TRUNCATE TABLE bronze.erp_loc_a101;
		PRINT '>> Inserting data into: ' + @current_table;
		BULK INSERT bronze.erp_loc_a101
		FROM 'D:\VSCode\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			FIELDQUOTE = '"',
			ROWTERMINATOR = '0x0a',
			CODEPAGE = '65001',
			KEEPNULLS,
			TABLOCK 
		);
		SET @rows_loaded = @@ROWCOUNT;
		SET @end_time = GETDATE();
		PRINT '>> Rows loaded: ' + CAST(@rows_loaded AS NVARCHAR);
		PRINT '>> Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------------';


		SET @start_time = GETDATE();
		SET @current_table = 'bronze.erp_px_cat_g1v2';
		SET @current_file = 'D:\VSCode\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv';
		PRINT '>> Truncating table: ' + @current_table;
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		PRINT '>> Inserting data into: ' + @current_table;
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'D:\VSCode\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			FIELDQUOTE = '"',
			ROWTERMINATOR = '0x0a',
			CODEPAGE = '65001',
			KEEPNULLS,
			TABLOCK 
		);
		SET @rows_loaded = @@ROWCOUNT;
		SET @end_time = GETDATE();
		PRINT '>> Rows loaded: ' + CAST(@rows_loaded AS NVARCHAR);
		PRINT '>> Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------------';


		SET @t_end_time = GETDATE();
		PRINT '=======================================';
		PRINT 'Bronze full load complete :)';
		PRINT '>> Total load duration: ' + CAST(DATEDIFF(second, @t_start_time, @t_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=======================================';
	END TRY

	BEGIN CATCH
		PRINT '===============================================';
		PRINT 'ERROR OCCURRED DURING FULL LOAD OF BRONZE LAYER';
		PRINT 'Current table: ' + ISNULL(@current_table, 'N/A');
		PRINT 'Current file: ' + ISNULL(@current_file, 'N/A');
		PRINT 'Error number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error state: ' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT 'Error line: ' + CAST(ERROR_LINE() AS NVARCHAR);
		PRINT 'Error procedure: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
		PRINT 'Error message: ' + ERROR_MESSAGE();
		PRINT '===============================================';
		THROW;
	END CATCH
END


---
EXEC bronze.load_bronze;