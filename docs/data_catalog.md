# Data Catalog

This catalog documents the business-ready views in the gold layer.

## gold.dim_customers

**Description:** Customer dimension with demographic and geographic attributes consolidated from CRM and ERP sources.

| Column Name | Data Type | Description |
|---|---|---|
| customer_key | BIGINT | Surrogate key generated with `ROW_NUMBER()` for analytics joins. |
| customer_id | INT | Natural customer identifier from CRM (`cst_id`). |
| customer_number | NVARCHAR(50) | Business customer code from CRM (`cst_key`). |
| first_name | NVARCHAR(50) | Customer first name. |
| last_name | NVARCHAR(50) | Customer last name. |
| country | NVARCHAR(50) | Standardized country from ERP location source. |
| marital_status | NVARCHAR(50) | Standardized marital status from silver layer. |
| gender | NVARCHAR(50) | Gender attribute (CRM preferred, ERP fallback). |
| birthdate | DATE | Customer birth date from ERP customer source. |
| create_date | DATE | Customer creation date from CRM source. |

## gold.dim_products

**Description:** Product dimension with category hierarchy and current product attributes.

| Column Name | Data Type | Description |
|---|---|---|
| product_key | BIGINT | Surrogate key generated with `ROW_NUMBER()` for analytics joins. |
| product_id | INT | Natural product identifier from CRM (`prd_id`). |
| product_number | NVARCHAR(50) | Normalized product business key used to link with sales (`sls_prd_key`). |
| product_name | NVARCHAR(100) | Product display name. |
| category_id | NVARCHAR(50) | Product category identifier from CRM. |
| category | NVARCHAR(100) | Product category name from ERP mapping. |
| subcategory | NVARCHAR(100) | Product subcategory name from ERP mapping. |
| maintenance | NVARCHAR(100) | Maintenance indicator/flag from ERP mapping. |
| cost | DECIMAL(18,2) | Standardized product cost. |
| product_line | NVARCHAR(50) | Standardized product line (Mountain, Road, etc.). |
| start_date | DATE | Product version start date (current version retained in gold). |

## gold.fact_sales

**Description:** Sales fact table at order-product-customer grain with transactional measures.

| Column Name | Data Type | Description |
|---|---|---|
| order_number | NVARCHAR(50) | Sales order number from source transaction. |
| product_key | BIGINT | Foreign key reference to `gold.dim_products.product_key`. |
| customer_key | BIGINT | Foreign key reference to `gold.dim_customers.customer_key`. |
| order_date | DATE | Order creation date. |
| shipping_date | DATE | Shipment date. |
| due_date | DATE | Due/expected delivery date. |
| sales_amount | DECIMAL(18,2) | Total line sales amount. |
| quantity | INT | Quantity sold. |
| sls_price | DECIMAL(18,2) | Unit price used in the transaction. |

## gold.pricing_kpi_monthly

**Description:** Monthly pricing KPI view at month-product-country grain for pricing trend and mix diagnostics.

| Column Name | Data Type | Description |
|---|---|---|
| order_month | DATE | First day of month derived from order date. |
| product_key | BIGINT | Foreign key reference to `gold.dim_products.product_key`. |
| product_number | NVARCHAR(50) | Product business key for analyst-friendly filtering. |
| product_name | NVARCHAR(100) | Product display name. |
| category | NVARCHAR(100) | Product category from ERP mapping. |
| subcategory | NVARCHAR(100) | Product subcategory from ERP mapping. |
| country | NVARCHAR(50) | Customer country from location mapping. |
| sales_line_count | BIGINT | Number of sales lines included in the aggregate grain. |
| order_count | BIGINT | Distinct orders at the aggregate grain. |
| units_sold | BIGINT | Sum of quantities sold. |
| gross_sales_amount | DECIMAL(18,2) | Sum of sales amount at the aggregate grain. |
| weighted_avg_unit_price | DECIMAL(18,4) | Quantity-weighted average unit price, computed as gross sales / units sold. |
| min_unit_price | DECIMAL(18,2) | Minimum unit price observed in the grain. |
| max_unit_price | DECIMAL(18,2) | Maximum unit price observed in the grain. |

## gold.rpt_sales_monthly_category_country

**Description:** Monthly sales summary at month-category-country grain for trend visualizations and KPI dashboards.

| Column Name | Data Type | Description |
|---|---|---|
| order_month | DATE | First day of month derived from order date. |
| category | NVARCHAR(100) | Product category. |
| country | NVARCHAR(50) | Customer country. |
| sales_line_count | BIGINT | Number of sales lines in the aggregate grain. |
| order_count | BIGINT | Distinct order count in the aggregate grain. |
| units_sold | BIGINT | Sum of quantity sold. |
| active_days | INT | Distinct order dates in the month/grain. |
| gross_sales_amount | DECIMAL(18,2) | Sum of sales amount in the grain. |
| avg_order_value | DECIMAL(18,2) | Gross sales divided by order count. |
| sales_per_active_day | DECIMAL(18,2) | Gross sales divided by active day count. |

## gold.rpt_product_performance_monthly

**Description:** Product-level monthly performance summary for ranking, contribution, and price-mix analysis.

| Column Name | Data Type | Description |
|---|---|---|
| order_month | DATE | First day of month derived from order date. |
| product_key | BIGINT | Product surrogate key. |
| product_number | NVARCHAR(50) | Product business key. |
| product_name | NVARCHAR(100) | Product display name. |
| category | NVARCHAR(100) | Product category. |
| subcategory | NVARCHAR(100) | Product subcategory. |
| sales_line_count | BIGINT | Number of sales lines in the aggregate grain. |
| order_count | BIGINT | Distinct order count in the aggregate grain. |
| units_sold | BIGINT | Sum of quantity sold. |
| gross_sales_amount | DECIMAL(18,2) | Sum of sales amount in the grain. |
| weighted_avg_unit_price | DECIMAL(18,4) | Gross sales divided by units sold. |
| min_unit_price | DECIMAL(18,2) | Minimum observed unit price. |
| max_unit_price | DECIMAL(18,2) | Maximum observed unit price. |

## gold.rpt_customer_country_monthly

**Description:** Customer activity summary by country and month for retention and mix diagnostics.

| Column Name | Data Type | Description |
|---|---|---|
| order_month | DATE | First day of month derived from order date. |
| country | NVARCHAR(50) | Customer country. |
| active_customers | INT | Distinct customers with activity in the month/country. |
| new_customers | INT | Active customers created in the same month. |
| returning_customers | INT | Active customers not created in the same month. |
| order_count | BIGINT | Distinct order count in the month/country. |
| gross_sales_amount | DECIMAL(18,2) | Sum of sales amount in the month/country. |
| avg_revenue_per_customer | DECIMAL(18,2) | Gross sales divided by active customers. |

## BI Consumption Contract

Power BI production dashboards should connect to SQL Gold/Reporting views instead of ad hoc notebook outputs.

Scope:
1. Preferred source for BI: Gold and Reporting views in SQL Server.
2. CSV exports remain supported for offline analysis and portability.
3. KPI definitions are owned by SQL; Power BI and notebooks should reuse those definitions.

