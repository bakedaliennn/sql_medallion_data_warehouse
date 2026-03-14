# SQL Data Warehouse Project (Medallion Architecture)

End-to-end, multi-language data warehouse project built with a **Bronze → Silver → Gold** medallion architecture.
The solution ingests CRM/ERP CSV files, applies cleansing and standardization rules in SQL Server, exports the final gold views as CSV files, and performs exploratory data analysis in Python/Jupyter.

## Project Overview

### Objectives
- Consolidate CRM and ERP datasets into a unified analytical model.
- Apply robust transformation and data quality validation rules.
- Expose business-friendly dimensions and facts for reporting and BI.
- Enable Python-based EDA directly on top of the gold layer.

### Scope
- Batch/full-load pipeline (no historization requirement).
- Focus on data engineering + data modeling + quality checks + exploratory analysis.

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

### Export Layer (`scripts/export`)
- Python script (`export_gold_views.py`) reads the three gold views via SQLAlchemy/pyodbc and writes them as UTF-8 CSV files to `exports/gold/`.
- Exported CSVs are committed to the repository so the notebook layer can run independently of a live SQL Server connection.

### Notebook Layer (`notebooks/`)
- Jupyter notebook (`01_eda_gold_layer.ipynb`) performs end-to-end EDA on the exported CSVs:
	- data quality inspection (nulls, dtypes, cardinality),
	- monthly revenue and order-volume trends,
	- product and category revenue breakdown,
	- customer demographics (gender, marital status, age, country),
	- key summary KPIs.

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
    run_pipeline.sql
    bronze/
        ddl_bronze.sql
        proc_load_bronze.sql
    silver/
        ddl_silver.sql
        proc_load_silver.sql
    gold/
        ddl_gold.sql
    export/
        export_gold_views.py   ← exports gold views → exports/gold/*.csv
exports/
    gold/
        dim_customers.csv
        dim_products.csv
        fact_sales.csv
notebooks/
    01_eda_gold_layer.ipynb    ← exploratory data analysis
tests/
    quality_checks_silver.sql
    quality_checks_gold.sql
    quality_checks_pipeline.sql
docs/
    data_catalog.md
environment.yml                ← conda environment (Python + data science libs)
```

## How to Run (End-to-End)

### Part 1 — SQL Pipeline (SQL Server)

Run scripts in this order:

1. `scripts/init_database.sql`
2. `scripts/bronze/ddl_bronze.sql`
3. `scripts/silver/ddl_silver.sql`
4. `scripts/bronze/proc_load_bronze.sql`
	 - creates/updates procedure definition only.
5. `scripts/silver/proc_load_silver.sql`
	 - creates/updates procedure definition only.
6. Execute ETL procedures:
	 - set a machine-specific datasets path and run:
	   `EXEC bronze.load_bronze @data_root_path = 'C:\\path\\to\\datasets';`
	 - `EXEC silver.load_silver;`
7. `scripts/gold/ddl_gold.sql`
8. Quality checks:
	 - `tests/quality_checks_pipeline.sql` (quick pipeline smoke checks)
	 - `tests/quality_checks_silver.sql`
	 - `tests/quality_checks_gold.sql`

### Part 2 — Python Export & EDA

```bash
# 1. Create and activate the conda environment (once)
conda env create -f environment.yml
conda activate sql_medallion

# 2. Register the Jupyter kernel (once)
python -m ipykernel install --user --name sql_medallion --display-name "sql_medallion"

# 3. Export gold views to CSV
#    Edit SERVER in the script if your instance is not localhost.
python scripts/export/export_gold_views.py

# 4. Open the EDA notebook in VS Code (select kernel: sql_medallion)
#    notebooks/01_eda_gold_layer.ipynb
```

## Data Quality
These scripts are optional in terms of the functionality of the layers' ddl and load procedures, **BUT** important for data traceability.

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

| Layer | Technology |
|---|---|
| Ingestion & transformation | SQL Server (T-SQL), `BULK INSERT` |
| Data modeling | Medallion pattern (Bronze / Silver / Gold) |
| Export | Python 3.11, pandas, SQLAlchemy, pyodbc |
| EDA | Jupyter, pandas, matplotlib, seaborn |
| Environment | Miniconda (`environment.yml`) |

## Notes

- Bronze load requires a configurable root path using `@data_root_path` (no hardcoded local default).
- SQL Server reads files using the SQL Server service account, not your interactive Windows user.
- Ensure the SQL Server service account can access the configured dataset directory.
- Optional shortcut: use `scripts/run_pipeline.sql` to set path once and run bronze/silver in one execution.
- The export script uses Windows Authentication by default. See the script header for SQL login instructions.
- Exported CSVs in `exports/gold/` are tracked in git; `.xlsx` files are excluded via `.gitignore`.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgment

Special thanks to @datawithbaraa for educational guidance and project inspiration.
