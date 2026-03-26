"""
==============================================================
Export Gold Layer Views to CSV
==============================================================
Connects to the DataWarehouse SQL Server database, queries the
gold views, and writes each one to a CSV file inside
exports/gold/.

Usage (from the repo root, with the conda env active):
    python scripts/export/export_gold_views.py

Configuration:
    Edit the SERVER and DATABASE constants below to match your
    SQL Server instance.  Windows Authentication is used by
    default (Trusted_Connection=yes).  For SQL login, swap the
    connection string for the one shown in the comments.
"""

import os
from pathlib import Path
import pandas as pd
import pyodbc
import sqlalchemy

# ── Configuration ──────────────────────────────────────────────
# Optional environment variables:
#   DW_SERVER (default: localhost)
#   DW_DATABASE (default: DataWarehouse)
#   DW_USERNAME / DW_PASSWORD (if both are set, SQL auth is used)
SERVER = os.getenv("DW_SERVER", "localhost")       # e.g. "localhost\\SQLEXPRESS"
DATABASE = os.getenv("DW_DATABASE", "DataWarehouse")
USERNAME = os.getenv("DW_USERNAME")
PASSWORD = os.getenv("DW_PASSWORD")
# ──────────────────────────────────────────────────────────────


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

# Output folder (repo-root/exports/gold/)
REPO_ROOT  = Path(__file__).resolve().parents[2]
OUTPUT_DIR = REPO_ROOT / "exports" / "gold"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Gold views to export  { view name: output CSV filename }
VIEWS = {
    "gold.dim_customers": "dim_customers.csv",
    "gold.dim_products":  "dim_products.csv",
    "gold.fact_sales":    "fact_sales.csv",
    "gold.pricing_kpi_monthly": "pricing_kpi_monthly.csv",
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
        )
    else:
        connection_string = (
            f"mssql+pyodbc://{SERVER}/{DATABASE}"
            f"?driver={driver}"
            "&Trusted_Connection=yes"
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
