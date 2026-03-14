# SQL Data Warehouse Project (Medallion Architecture)

End-to-end SQL Server data warehouse project built with a **Bronze → Silver → Gold** medallion architecture.
The solution ingests CRM/ERP CSV files, applies cleansing and standardization rules, and delivers analytics-ready dimensional and fact views.

## Project Overview

### Objectives
- Consolidate CRM and ERP datasets into a unified analytical model.
- Apply robust transformation and data quality validation rules.
- Expose business-friendly dimensions and facts for reporting and BI.

### Scope
- Batch/full-load pipeline (no historization requirement).
- Focus on data engineering + data modeling + quality checks.

## Architecture

### Bronze Layer (`scripts/bronze`)
- Raw ingestion from source CSV files into `bronze` tables.
- Load orchestration in `bronze.load_bronze` with:
	- table truncation + bulk insert,
	- load duration and row-count logging,
	- detailed error output (`table`, `file`, SQL error metadata).

### Silver Layer (`scripts/silver`)
- Cleaned and standardized relational tables in `silver` schema.
- Business rules include trimming, type casting, categorical normalization, date handling, and measure correction.
- Load orchestration in `silver.load_silver` with operational logging and error handling.

### Gold Layer (`scripts/gold`)
- Semantic model for analytics:
	- `gold.dim_customers`
	- `gold.dim_products`
	- `gold.fact_sales`
- Views are created with `CREATE OR ALTER VIEW` for idempotent deployment.

## Source Data

| Source | Files | Description |
|---|---|---|
| CRM | `cust_info.csv`, `prd_info.csv`, `sales_details.csv` | Customers, products, and sales transactions |
| ERP | `CUST_AZ12.csv`, `LOC_A101.csv`, `PX_CAT_G1V2.csv` | Demographics, location, and product categories |

## Repository Structure

```text
datasets/
	source_crm/
	source_erp/
scripts/
	init_database.sql
	bronze/
		ddl_bronze.sql
		proc_load_bronze.sql
	silver/
		ddl_silver.sql
		proc_load_silver.sql
	gold/
		ddl_gold.sql
tests/
	quality_checks_silver.sql
	quality_checks_gold.sql
	quality_checks_pipeline.sql
	troubleshoot_pipeline_load.sql
docs/
	data_catalog.md
```

## How to Run (End-to-End)

Run scripts in this order:

1. `scripts/init_database.sql`
2. `scripts/bronze/ddl_bronze.sql`
3. `scripts/silver/ddl_silver.sql`
4. `scripts/bronze/proc_load_bronze.sql`
	 - creates/updates procedure definition only.
5. `scripts/silver/proc_load_silver.sql`
	 - creates/updates procedure definition only.
6. Execute ETL procedures:
	 - `EXEC bronze.load_bronze;`
	 - or with custom root path:
	   `EXEC bronze.load_bronze @data_root_path = 'C:\\path\\to\\datasets';`
	 - `EXEC silver.load_silver;`
7. `scripts/gold/ddl_gold.sql`
8. Quality checks:
	 - `tests/quality_checks_pipeline.sql` (quick pipeline smoke checks)
	 - `tests/quality_checks_silver.sql`
	 - `tests/quality_checks_gold.sql`
	 - `tests/troubleshoot_pipeline_load.sql` (diagnostic runbook)

## Data Quality Strategy

Quality checks are provided for both transformed layers:

- **Silver checks** validate:
	- duplicates/nulls on key fields,
	- trimming and standardization,
	- date validity and chronology,
	- measure consistency and source alignment.

- **Gold checks** validate:
	- surrogate/business key integrity,
	- dimension/fact referential integrity,
	- date boundaries and metric consistency,
	- analytics-readiness of semantic views.

## Documentation

- Data catalog for gold entities and columns: `docs/data_catalog.md`
- SQL implementation scripts: `scripts/`
- Validation scripts: `tests/`

## Technology Stack

- SQL Server (T-SQL)
- CSV flat-file ingestion (`BULK INSERT`)
- Medallion data modeling pattern (Bronze/Silver/Gold)

## Notes

- Bronze load supports a configurable root path using `@data_root_path`.
- SQL Server reads files using the SQL Server service account, not your interactive Windows user.
- Ensure the SQL Server service account can access the configured dataset directory.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgment

Special thanks to @datawithbaraa for educational guidance and project inspiration.
