"""
==============================================================
Export Gold Layer Views to CSV
==============================================================
Connects to the DataWarehouse SQL Server database, queries the
three gold views, and writes each one to a CSV file inside
exports/gold/.

Usage (from the repo root, with the conda env active):
    python scripts/export/export_gold_views.py

Configuration:
    Edit the SERVER and DATABASE constants below to match your
    SQL Server instance.  Windows Authentication is used by
    default (Trusted_Connection=yes).  For SQL login, swap the
    connection string for the one shown in the comments.
"""

from pathlib import Path
import pandas as pd
import sqlalchemy

# ── Configuration ──────────────────────────────────────────────
SERVER   = "localhost"       # e.g. "localhost\\SQLEXPRESS"
DATABASE = "DataWarehouse"
# ──────────────────────────────────────────────────────────────

# Output folder (repo-root/exports/gold/)
REPO_ROOT  = Path(__file__).resolve().parents[2]
OUTPUT_DIR = REPO_ROOT / "exports" / "gold"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Gold views to export  { view name: output CSV filename }
VIEWS = {
    "gold.dim_customers": "dim_customers.csv",
    "gold.dim_products":  "dim_products.csv",
    "gold.fact_sales":    "fact_sales.csv",
}


def build_engine() -> sqlalchemy.Engine:
    """
    Build a SQLAlchemy engine using pyodbc + Windows Authentication.

    For SQL Server login instead, replace the connection string with:
        mssql+pyodbc://<user>:<password>@<server>/<database>
            ?driver=ODBC+Driver+17+for+SQL+Server
    """
    connection_string = (
        f"mssql+pyodbc://{SERVER}/{DATABASE}"
        "?driver=ODBC+Driver+17+for+SQL+Server"
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
