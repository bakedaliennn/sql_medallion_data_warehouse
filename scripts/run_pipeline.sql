/*
============================================================
Run pipeline (portable execution entry point)
============================================================
Why this script exists:
  Keep pipeline execution consistent across machines by setting the dataset
  root path once and reusing the same operational entry point.
*/

USE DataWarehouse;
GO

DECLARE @data_root_path NVARCHAR(4000) = 'YOUR PATH TO DATASETS FOLDER HERE';

EXEC bronze.load_bronze @data_root_path = @data_root_path;
EXEC silver.load_silver;
GO

-- Gold views are deployed separately to keep semantic changes explicit and reviewable.
