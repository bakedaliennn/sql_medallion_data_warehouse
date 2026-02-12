/*
============================================================
Stored procedure: Load Silver layer
============================================================
Script Purpose:
  This stored procedure loads data into the silver schema from the bronze schema.
  It performs the following actions:
    - Truncates the silver tables before inserting cleaned data.
    - Transforms and standardizes fields while inserting from bronze.
    - Prints timing information for each step and the full batch.

Usage example:
  EXEC silver.load_silver;

WARNING: Running this script will truncate data in the silver layer. Proceed with caution.
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @t_start_time DATETIME, @t_end_time DATETIME;
    DECLARE @start_time DATETIME, @end_time DATETIME;

    BEGIN TRY
        SET @t_start_time = GETDATE();
        PRINT '======================================';
        PRINT 'Loading Silver Layer';
        PRINT '======================================';

        --------------------------------------------------------------------------------
        -- CRM: CUSTOMER INFORMATION
        --------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating table: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;
        PRINT '>> Inserting data into: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
            cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname),
            TRIM(cst_lastname),
            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END AS cst_marital_status,
            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Married'
                ELSE 'n/a'
            END AS cst_gndr,
            cst_create_date
        FROM (
            SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t
        WHERE flag_last = 1;
        SET @end_time = GETDATE();
        PRINT '>> Load duration (crm_cust_info): ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


        --------------------------------------------------------------------------------
        -- CRM: PRODUCT INFO
        --------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating table: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;
        PRINT '>> Inserting data into: silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
            prd_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
        )
        SELECT
            prd_id,
            TRIM(prd_key) AS prd_key,
            TRIM(prd_nm) AS prd_nm,
            ISNULL(TRY_CAST(prd_cost AS DECIMAL(18,2)), 0) AS prd_cost,
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,
            TRY_CAST(prd_start_dt AS DATE) AS prd_start_dt,
            DATEADD(day, -1, LEAD(TRY_CAST(prd_start_dt AS DATE)) OVER (PARTITION BY prd_key ORDER BY TRY_CAST(prd_start_dt AS DATE) ASC)) AS prd_end_dt
        FROM bronze.crm_prd_info;
        SET @end_time = GETDATE();
        PRINT '>> Load duration (crm_prd_info): ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


        --------------------------------------------------------------------------------
        -- CRM: SALES DETAILS
        --------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating table: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;
        PRINT '>> Inserting data into: silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE WHEN sls_order_dt IS NULL OR sls_order_dt = 0 OR LEN(CAST(sls_order_dt AS VARCHAR(20))) <> 8 THEN NULL
                ELSE TRY_CONVERT(DATE, CAST(sls_order_dt AS CHAR(8))) END AS sls_order_dt,
            CASE WHEN sls_ship_dt IS NULL THEN NULL
                ELSE TRY_CONVERT(DATE, sls_ship_dt) END AS sls_ship_dt,
            CASE WHEN sls_due_dt IS NULL THEN NULL
                ELSE TRY_CONVERT(DATE, sls_due_dt) END AS sls_due_dt,
            CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales <> (sls_quantity * ABS(TRY_CAST(sls_price AS DECIMAL(18,2))))
                THEN sls_quantity * ABS(TRY_CAST(sls_price AS DECIMAL(18,2)))
                ELSE sls_sales END AS sls_sales,
            sls_quantity,
            CASE WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE TRY_CAST(sls_price AS DECIMAL(18,2)) END AS sls_price
        FROM bronze.crm_sales_details;
        SET @end_time = GETDATE();
        PRINT '>> Load duration (crm_sales_details): ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


        --------------------------------------------------------------------------------
        -- ERP: CUSTOMER AZ12
        --------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating table: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;
        PRINT '>> Inserting data into: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
        SELECT
            CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid) - 3) ELSE cid END AS cid,
            CASE WHEN bdate > GETDATE() THEN NULL ELSE bdate END AS bdate,
            CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                 ELSE 'n/a' END AS gen
        FROM bronze.erp_cust_az12;
        SET @end_time = GETDATE();
        PRINT '>> Load duration (erp_cust_az12): ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


        --------------------------------------------------------------------------------
        -- ERP: LOCATION A101
        --------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating table: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;
        PRINT '>> Inserting data into: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101 (cid, cntry)
        SELECT
            REPLACE(cid, '-', '') AS cid,
            CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                 WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                 ELSE TRIM(cntry) END AS cntry
        FROM bronze.erp_loc_a101;
        SET @end_time = GETDATE();
        PRINT '>> Load duration (erp_loc_a101): ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


        --------------------------------------------------------------------------------
        -- ERP: PRODUCT CATEGORY G1V2
        --------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating table: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        PRINT '>> Inserting data into: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
        SELECT id, cat, subcat, maintenance FROM bronze.erp_px_cat_g1v2;
        SET @end_time = GETDATE();
        PRINT '>> Load duration (erp_px_cat_g1v2): ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


        SET @t_end_time = GETDATE();
        PRINT '=======================================';
        PRINT 'Silver load complete :)';
        PRINT '>> Total load duration: ' + CAST(DATEDIFF(second, @t_start_time, @t_end_time) AS NVARCHAR) + ' seconds';
        PRINT '=======================================';

    END TRY
    BEGIN CATCH
        PRINT '===============================================';
        PRINT 'ERROR OCCURRED DURING SILVER LAYER LOAD';
        PRINT 'Error number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error message: ' + ERROR_MESSAGE();
        PRINT 'Error state: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '===============================================';
    END CATCH
END
GO
