"""
==============================================================
Export Gold Layer Views to CSV
==============================================================
Why this script exists:
  Publish a portable analytics extract from the gold semantic layer so notebooks
  and downstream consumers can run without a live SQL connection.

Usage (from the repo root, with the conda env active):
    python scripts/export/export_gold_views.py

Operational notes:
    Configure connection settings through DW_* environment variables.
    Defaults target local Windows Authentication for fast local onboarding.

Warning:
    ODBC Driver 18 may require certificate trust settings in local environments.
    Use DW_ENCRYPT and DW_TRUST_SERVER_CERTIFICATE as needed.
"""

import os
from pathlib import Path
import pandas as pd
import pyodbc
import sqlalchemy

# Connection defaults prioritize local development ergonomics.
# Optional environment variables:
#   DW_SERVER (default: localhost)
#   DW_DATABASE (default: DataWarehouse)
#   DW_USERNAME / DW_PASSWORD (if both are set, SQL auth is used)
#   DW_ENCRYPT (default: yes)
#   DW_TRUST_SERVER_CERTIFICATE (default: yes)
SERVER = os.getenv("DW_SERVER", "localhost")       # e.g. "localhost\\SQLEXPRESS"
DATABASE = os.getenv("DW_DATABASE", "DataWarehouse")
USERNAME = os.getenv("DW_USERNAME")
PASSWORD = os.getenv("DW_PASSWORD")
ENCRYPT = os.getenv("DW_ENCRYPT", "yes")
TRUST_SERVER_CERTIFICATE = os.getenv("DW_TRUST_SERVER_CERTIFICATE", "yes")


def _find_odbc_driver() -> str:
    """
    Return the best available Microsoft ODBC Driver for SQL Server.

    Tries newer drivers first so the script works whether the user has
    Driver 13, 17, or 18 installed — no manual version editing required.
    """
    preferred = [
        "ODBC Driver 18 for SQL Server",
        "ODBC Driver 17 for SQL Server",
        "ODBC Driver 13 for SQL Server",
    ]
    available = set(pyodbc.drivers())
    for driver in preferred:
        if driver in available:
            return driver
    raise RuntimeError(
        "No Microsoft ODBC Driver for SQL Server was found on this machine.\n"
        "Download and install it from:\n"
        "  https://learn.microsoft.com/sql/connect/odbc/download-odbc-driver-for-sql-server\n"
        f"Drivers currently installed: {sorted(available) or ['(none)']}"
    )

# Keep exports under versioned project artifacts for reproducible analysis inputs.
REPO_ROOT  = Path(__file__).resolve().parents[2]
OUTPUT_DIR = REPO_ROOT / "exports" / "gold"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Pin exported datasets to canonical gold entities to keep notebook assumptions stable.
VIEWS = {
    "gold.dim_customers": "dim_customers.csv",
    "gold.dim_products":  "dim_products.csv",
    "gold.fact_sales":    "fact_sales.csv",
    "gold.pricing_kpi_monthly": "pricing_kpi_monthly.csv",
    "gold.rpt_sales_monthly_category_country": "rpt_sales_monthly_category_country.csv",
    "gold.rpt_product_performance_monthly": "rpt_product_performance_monthly.csv",
    "gold.rpt_customer_country_monthly": "rpt_customer_country_monthly.csv",
}


def build_engine() -> sqlalchemy.Engine:
    """
    Build a SQLAlchemy engine using pyodbc.

    Auth behavior:
    - If DW_USERNAME and DW_PASSWORD are set: SQL authentication.
    - Otherwise: Windows authentication (Trusted_Connection=yes).

    The ODBC driver version is detected automatically.
    """
    driver = _find_odbc_driver().replace(" ", "+")
    if USERNAME and PASSWORD:
        connection_string = (
            f"mssql+pyodbc://{USERNAME}:{PASSWORD}@{SERVER}/{DATABASE}"
            f"?driver={driver}"
            f"&Encrypt={ENCRYPT}"
            f"&TrustServerCertificate={TRUST_SERVER_CERTIFICATE}"
        )
    else:
        connection_string = (
            f"mssql+pyodbc://{SERVER}/{DATABASE}"
            f"?driver={driver}"
            "&Trusted_Connection=yes"
            f"&Encrypt={ENCRYPT}"
            f"&TrustServerCertificate={TRUST_SERVER_CERTIFICATE}"
        )
    return sqlalchemy.create_engine(connection_string, fast_executemany=True)


def export_views(engine: sqlalchemy.Engine) -> None:
    """Query each gold view and save it to CSV."""
    for view, csv_name in VIEWS.items():
        print(f"Exporting {view} ...", end=" ", flush=True)
        df = pd.read_sql(f"SELECT * FROM {view}", engine)
        out_path = OUTPUT_DIR / csv_name
        df.to_csv(out_path, index=False, encoding="utf-8")
        print(f"saved → {out_path.relative_to(REPO_ROOT)}  ({len(df):,} rows)")


if __name__ == "__main__":
    engine = build_engine()
    export_views(engine)
    print(f"\nAll exports written to: {OUTPUT_DIR.relative_to(REPO_ROOT)}")
