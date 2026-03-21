# Power BI Implementation Runbook

This runbook operationalizes the SQL-first BI strategy for this repository.

## 1) Prerequisites

- SQL objects deployed:
  - scripts/gold/ddl_gold.sql
- Gold validation executed:
  - tests/quality_checks_gold.sql
- SQL Server reachable from Power BI Desktop:
  - Server: Laptop_de_Etor\\SQLEXPRESS (or DW_SERVER value)
  - Database: DataWarehouse (or DW_DATABASE value)

## 2) Recommended Source Objects

Use SQL views as the primary semantic source:

Dimensions:
- gold.dim_customers
- gold.dim_products

Reporting views:
- gold.rpt_sales_monthly_category_country
- gold.rpt_product_performance_monthly
- gold.rpt_customer_country_monthly

Optional detailed fact (only if needed for drill-through):
- gold.fact_sales

## 3) Connection Setup (Power BI Desktop)

1. Home > Get Data > SQL Server.
2. Server: Laptop_de_Etor\\SQLEXPRESS.
3. Database: DataWarehouse.
4. Data connectivity mode: Import.
5. Authentication: Windows (or SQL login if your environment requires it).
6. Select only the objects listed in Section 2.

Why Import first:
- Better visual performance for this workload.
- Simpler model behavior.
- Easier baseline before considering DirectQuery.

## 4) Data Model (Star-Like)

Create one-to-many single-direction relationships:

- dim_products[product_key] -> rpt_product_performance_monthly[product_key]
- dim_customers[country] -> rpt_customer_country_monthly[country]

For rpt_sales_monthly_category_country:
- Join by category to dim_products[category] only if category consistency is guaranteed.
- If ambiguity appears, keep it as a standalone aggregate table.

Date handling:
- Use order_month from each reporting table as the chart axis.
- Optionally create a dedicated calendar table for enterprise-grade time intelligence.

## 5) Baseline Measures (DAX)

Keep business logic in SQL and use DAX mostly for presentation aggregations.

Example measures:

- Total Sales = SUM(rpt_sales_monthly_category_country[gross_sales_amount])
- Orders = SUM(rpt_sales_monthly_category_country[order_count])
- Units Sold = SUM(rpt_sales_monthly_category_country[units_sold])
- Avg Order Value = DIVIDE([Total Sales], [Orders])
- Sales Per Active Day =
  DIVIDE(
    SUM(rpt_sales_monthly_category_country[gross_sales_amount]),
    SUM(rpt_sales_monthly_category_country[active_days])
  )
- Active Customers = SUM(rpt_customer_country_monthly[active_customers])
- Revenue Per Customer =
  DIVIDE(
    SUM(rpt_customer_country_monthly[gross_sales_amount]),
    SUM(rpt_customer_country_monthly[active_customers])
  )

## 6) Suggested Report Pages

1. Executive Summary
- Cards: Total Sales, Orders, Units Sold, Active Customers.
- Line chart: Total Sales vs Sales Per Active Day by order_month.

2. Product Performance
- Top N products by gross sales.
- Monthly trend by category/subcategory.

3. Customer and Geography
- Country trend for sales and active customers.
- New vs returning customer mix.

## 7) Refresh Strategy

Desktop/local:
- Manual refresh during development.

Power BI Service:
1. Publish PBIX.
2. Configure on-premises gateway if SQL Server is local/private.
3. Set scheduled refresh (start daily).
4. Enable incremental refresh when volume or refresh duration requires it.

## 8) Reconciliation Checklist

Before sharing dashboards, validate:

1. SQL quality checks are clean (tests/quality_checks_gold.sql).
2. Power BI totals match SQL outputs for:
   - gross_sales_amount
   - order_count
   - units_sold
3. Notebook visuals in notebooks/01_eda_gold_layer.ipynb align with Power BI trends at monthly grain.

## 9) Governance Rules

- KPI definition ownership remains in SQL views.
- Avoid re-implementing SQL business logic in DAX unless strictly visual.
- Version SQL changes and note corresponding dashboard updates.
- Restrict report authors to approved Gold/Reporting views.

## 10) Exit Criteria

The Power BI implementation is complete when:

1. Dashboard refresh succeeds within target time.
2. KPI totals reconcile with SQL and notebook outputs.
3. Core pages (Executive, Product, Geography/Customer) are published and validated.
