/*
============================================================
Run pipeline (portable execution entry point)
============================================================
Script Purpose:
  Execute bronze and silver procedures plus gold view refresh using a
  machine-specific datasets path provided once at the top.

How to use:
  1) Set @data_root_path to your local datasets folder.
  2) Execute this script.
*/

USE DataWarehouse;
GO

DECLARE @data_root_path NVARCHAR(4000) = 'C:\path\to\sql_medallion_data_warehouse\datasets';

EXEC bronze.load_bronze @data_root_path = @data_root_path;
EXEC silver.load_silver;
GO

-- After running this file, run scripts/gold/ddl_gold.sql in a separate query window.
