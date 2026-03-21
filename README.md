# SQL Data Warehouse Project (Medallion Architecture)

End-to-end, multi-language data warehouse project built with a **Bronze → Silver → Gold** medallion architecture.
The solution ingests CRM/ERP CSV files, applies cleansing and standardization rules in SQL Server, exports the final gold views as CSV files, and performs exploratory data analysis in Python/Jupyter.

## Prerequisites

Install the following before running anything else:

| Tool | Notes |
|---|---|
| **SQL Server** (Express or Developer) | Both editions are free. [Download here](https://www.microsoft.com/sql-server/sql-server-downloads). |
| **SSMS or Azure Data Studio** | For running `.sql` scripts. [SSMS](https://learn.microsoft.com/sql/ssms/download-sql-server-management-studio-ssms) · [Azure Data Studio](https://learn.microsoft.com/sql/azure-data-studio/download-azure-data-studio) |
| **Microsoft ODBC Driver 17+ for SQL Server** | Required by the Python export script. [Download here](https://learn.microsoft.com/sql/connect/odbc/download-odbc-driver-for-sql-server). Driver 17 and 18 are both supported — the script auto-detects which one is installed. |
| **Miniconda or Anaconda** | For the Python environment. [Miniconda](https://docs.conda.io/en/latest/miniconda.html) is the lightweight option. |
| **VS Code** with the **Jupyter extension** | For running the EDA notebook. The extension is available in the VS Code marketplace (`ms-toolsai.jupyter`). |
| **Git** | For cloning the repository. |

> **Windows PowerShell note:** Before using `conda activate` in PowerShell for the first time, run `conda init powershell` once in an admin terminal and then restart your shell.

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
	- `gold.pricing_kpi_monthly`
	- `gold.rpt_sales_monthly_category_country`
	- `gold.rpt_product_performance_monthly`
	- `gold.rpt_customer_country_monthly`
- Views are created with `CREATE OR ALTER VIEW` for idempotent deployment.

### Export Layer (`scripts/export`)
- Python script (`export_gold_views.py`) reads the gold views via SQLAlchemy/pyodbc and writes them as UTF-8 CSV files to `exports/gold/`.
- Exported CSVs are committed to the repository so the notebook layer can run independently of a live SQL Server connection.

### Notebook Layer (`notebooks/`)
- Jupyter notebook (`01_eda_gold_layer.ipynb`) performs end-to-end EDA on the exported CSVs:
	- data quality inspection (nulls, dtypes, cardinality),
	- monthly revenue and order-volume trends,
	- product and category revenue breakdown,
	- customer demographics (gender, marital status, age, country),
	- key summary KPIs.

## Execution Roadmap: SQL Reporting Layer + Power BI Connection

This roadmap operationalizes two improvements:
- Action 1: create SQL reporting views tailored for EDA and charting.
- Action 2: connect Power BI directly to SQL Gold/Reporting views for production BI.

Implementation status:
1. Action 1 implemented in SQL and export pipeline.
2. Action 2 documented and ready for Power BI workspace execution.

### Action 1 - SQL Reporting Views for EDA Efficiency

Goal: push repeated heavy joins and aggregations to SQL, leaving Python notebooks focused on visualization and interpretation.

Phase 1 (Design)
1. Define canonical reporting grains and KPI definitions.
2. Confirm metric ownership in SQL (single source of truth).
3. Freeze naming conventions for reporting objects under the `gold` schema.

Phase 2 (Build) - implemented
1. Add reporting views in SQL with `CREATE OR ALTER VIEW`:
   - `gold.rpt_sales_monthly_category_country`
   - `gold.rpt_product_performance_monthly`
   - `gold.rpt_customer_country_monthly`
2. Keep filters and business rules aligned with existing silver/gold quality checks.
3. Ensure each view includes analyst-friendly fields and avoids identifier-only outputs unless needed for joins.

Phase 3 (Validation) - implemented in SQL test script
1. Reconcile aggregates against `gold.fact_sales` and `gold.pricing_kpi_monthly`.
2. Add view-level quality checks in `tests/quality_checks_gold.sql`.
3. Validate row counts, duplicate grain, null critical fields, and metric ranges.

Phase 4 (Notebook Adoption) - in progress
1. Update notebook queries to consume reporting views (or their CSV exports).
2. Remove redundant Python checks already guaranteed by SQL tests.
3. Keep lightweight notebook smoke checks (file existence, date range, non-empty outputs).

Acceptance criteria
1. Notebook runtime for aggregate charts decreases versus raw `fact_sales` approach.
2. KPI values in notebook match SQL validation outputs.
3. No duplicated KPI logic between SQL and Python.

### Action 2 - Power BI Directly Connected to SQL

Goal: use SQL as the semantic and performance layer for dashboards, while preserving CSV exports for offline analysis.

Phase 1 (Dataset Contract)
1. Expose only business-ready Gold/Reporting views for BI.
2. Define approved measures and dimensional drill paths.
3. Document refresh expectations and data latency.

Phase 2 (Power BI Model)
1. Connect Power BI to SQL Server using Import mode first.
2. Build star-like relationships from dimensions to reporting/fact views.
3. Implement core measures in DAX only when they are presentation-specific.

Phase 3 (Performance and Refresh)
1. Configure scheduled refresh.
2. Add incremental refresh when dataset size warrants it.
3. Track refresh duration and query performance baselines.

Phase 4 (Governance)
1. Restrict report authors to approved views to avoid KPI drift.
2. Version-control SQL changes and align Power BI updates with release notes.
3. Keep Python notebook and Power BI consuming the same definitions.

Acceptance criteria
1. Power BI dashboards reconcile with SQL and notebook KPI values.
2. Refresh completes within agreed time window.
3. No duplicate business-rule transformations in Power BI.

### Suggested Execution Order
1. Run `scripts/gold/ddl_gold.sql` to create/update all reporting views.
2. Run `tests/quality_checks_gold.sql` to validate reporting grains and KPIs.
3. Run `python scripts/export/export_gold_views.py` to publish reporting CSVs.
4. Connect Power BI to SQL Gold/Reporting views (Import mode first).
5. Keep CSV exports as fallback and portability layer.

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
	pricing_kpi_monthly.csv
	rpt_sales_monthly_category_country.csv
	rpt_product_performance_monthly.csv
	rpt_customer_country_monthly.csv
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
	 - Pass the absolute path to the `datasets/` folder on your machine (use single backslashes or forward slashes):
	   ```sql
	   EXEC bronze.load_bronze @data_root_path = 'C:\Users\you\projects\sql_medallion_data_warehouse\datasets';
	   ```
	   > **Note:** SQL Server reads these files using its own service account, not your Windows user. If you get a permission error, [grant the SQL Server service account read access](https://learn.microsoft.com/sql/relational-databases/import-export/bulk-import-and-export-of-data-sql-server) to that folder, or copy the `datasets/` folder to a location the service account can reach. An easy alternative is to use `scripts/run_pipeline.sql` (see step below).
	 - `EXEC silver.load_silver;`
7. `scripts/gold/ddl_gold.sql`
8. Quality checks:
	 - `tests/quality_checks_pipeline.sql` (quick pipeline smoke checks)
	 - `tests/quality_checks_silver.sql`
	 - `tests/quality_checks_gold.sql`

### Part 2 — Python Export & EDA

```powershell
# 1. Create conda environment (run once from the repo root)
conda env create -f environment.yml

# 2. Activate it
#    If 'conda activate' fails in PowerShell, run 'conda init powershell' first (admin terminal), then restart.
conda activate sql_medallion

# 3. Register the kernel so VS Code can see it (run once)
python -m ipykernel install --user --name sql_medallion --display-name "sql_medallion"

# 4. Export gold views to CSV
#    The script auto-detects whether you have ODBC Driver 18, 17, or 13 installed.
#    Optional config via environment variables:
#      $env:DW_SERVER="localhost\\SQLEXPRESS"
#      $env:DW_DATABASE="DataWarehouse"
#      # Optional SQL auth (if omitted, Windows auth is used):
#      $env:DW_USERNAME="sa"
#      $env:DW_PASSWORD="<your_password>"
python scripts/export/export_gold_views.py

# 5. Open the EDA notebook in VS Code
#    File: notebooks/01_eda_gold_layer.ipynb
#    Select kernel: sql_medallion  (top-right corner of the notebook)
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
- Power BI implementation runbook: `docs/power_bi_runbook.md`
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
- SQL Server reads files using the SQL Server service account, not your interactive Windows user. Ensure it has read access to the `datasets/` folder path you provide.
- Optional shortcut: use `scripts/run_pipeline.sql` to set path once and run bronze/silver in one execution.
- The Python export script defaults to **Windows Authentication**, and also supports SQL login via `DW_USERNAME` + `DW_PASSWORD` environment variables.
- The export script **auto-detects** your installed ODBC Driver (18 → 17 → 13). If none is found, it prints a download link.
- Exported CSVs in `exports/gold/` are tracked in git so the notebook layer can run without a live SQL Server connection. `.xlsx` files are excluded via `.gitignore`.
- For production BI, prefer direct Power BI connection to SQL Gold/Reporting views using Import mode first (see `docs/power_bi_runbook.md`).

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgment

Special thanks to @datawithbaraa for educational guidance and project inspiration.
