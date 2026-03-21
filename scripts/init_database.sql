/*
============================================================
Create the database and its schemas
============================================================
Why this script exists:
  Provide a clean, repeatable baseline so every layer starts from a known state.
  Recreating the database avoids drift from prior local runs.

WARNING: Running this script will drop the entire 'DataWarehouse' database if it exists,
all data in the database will be permanently deleted. Proceed with caution and ensure you
have proper backups before running the script.
*/

USE master;
GO

  
-- Recreate the database to avoid carrying over stale objects from prior runs.
IF EXISTS (SELECT 1 FROM sys.databases WHERE name='DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse
END;
GO


-- Create the baseline analytical database.
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO


-- Separate schemas to preserve clear layer boundaries and ownership.
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
