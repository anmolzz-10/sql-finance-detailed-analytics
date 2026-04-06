# SQL Finance & Market Analytics — AtliQ Hardware

> A structured, end-to-end SQL analytics project built on a real-world hardware company database.  
> Progresses from raw data exploration through to production-grade database objects — covering User-Defined Functions, Stored Procedures, Views, CTEs, and Window Functions.

🔗 **[Repository →](https://github.com/anmolzz-10/sql-finance-detailed-analytics)**  
🗄️ **Database:** AtliQ Hardware (provided by Codebasics)  
🛠️ **Stack:** MySQL · Advanced SQL

---

## Table of Contents

- [Project Overview](#project-overview)
- [What Is AtliQ Hardware? (Non-Technical Context)](#what-is-atliq-hardware-non-technical-context)
- [Database Schema — Understanding the Tables](#database-schema--understanding-the-tables)
- [Repository Structure](#repository-structure)
- [Analytical Progression — Stage by Stage](#analytical-progression--stage-by-stage)
  - [Stage 1 · Data Exploration](#stage-1--data-exploration)
  - [Stage 2 · Customer-Level Sales Reporting](#stage-2--customer-level-sales-reporting)
  - [Stage 3 · Pre-Invoice Deduction Pipeline](#stage-3--pre-invoice-deduction-pipeline)
  - [Stage 4 · Forecast Accuracy Analysis](#stage-4--forecast-accuracy-analysis)
- [Database Objects Deep Dive](#database-objects-deep-dive)
  - [User-Defined Functions (UDF)](#user-defined-functions-udf)
  - [Stored Procedures](#stored-procedures)
  - [Views](#views)
  - [Window Functions](#window-functions)
- [Key SQL Concepts Demonstrated](#key-sql-concepts-demonstrated)
- [Business Questions Answered](#business-questions-answered)
- [Why This Architecture Matters](#why-this-architecture-matters)
- [Getting Started](#getting-started)

---

## Project Overview

This project applies advanced SQL to a real-world transactional database from AtliQ Hardware — a fictional but realistic global hardware manufacturer that sells products like PCs, mice, keyboards, and printers through retailers and distributors across multiple markets.

The analysis is structured as a progressive build. It starts with basic schema exploration to understand the data landscape, then develops increasingly sophisticated queries to answer business-critical finance and supply chain questions. Rather than stopping at ad-hoc queries, the project abstracts repeated logic into **reusable database objects** — UDFs, stored procedures, and views — which is how analytics is actually deployed in production environments.

By the end, the codebase can answer questions like:
- How much gross revenue did Croma India generate in FY2021, broken down by product and month?
- What is every customer's net invoice sales after applying their negotiated pre-invoice discount?
- Which customers have the best and worst forecast accuracy — and by how much do they deviate from plan?
- How do AtliQ's products rank within their category on net sales using window-based ranking?

---

## What Is AtliQ Hardware? (Non-Technical Context)

AtliQ Hardware is a simulated global electronics hardware company. Like a real manufacturer, it:

- **Makes products** across multiple divisions (Networking, Storage, Peripherals, PC) and segments (Notebook, Desktop, Accessories)
- **Sells through channels** — Retailers (like Croma, Amazon), Direct sales, and Distributors
- **Operates in multiple markets** across APAC, EU, NA, and LATAM regions
- **Issues invoices with discounts** — pre-invoice discounts are negotiated upfront per customer, while post-invoice deductions (rebates, promotional allowances) are applied after

The company runs on a fiscal year that starts in **September** rather than January — a detail that has real implications for how every date-based query must be written, which is why the project builds a custom `get_fiscal_year()` function as one of its first steps.

The database itself follows a **star schema** design — a central fact table surrounded by dimension tables that provide context. This is the standard pattern in data warehousing and business intelligence.

---

## Database Schema — Understanding the Tables

The project works across two primary databases: `gdb041` (sales and finance) and a supply chain schema containing forecast data.

### Fact Tables (transactional data)

| Table | What It Contains |
|---|---|
| `fact_sales_monthly` | One row per product per customer per month — sold quantity and fiscal year |
| `fact_gross_price` | Gross (list) price per product per fiscal year |
| `fact_pre_invoice_deductions` | Negotiated pre-invoice discount percentage per customer per fiscal year |
| `fact_post_invoice_deductions` | Post-invoice deductions (rebates, promotions) per product per customer per month |
| `fact_act_est` | Actual vs forecast sold quantities — used for supply chain accuracy analysis |

### Dimension Tables (reference/context data)

| Table | What It Contains |
|---|---|
| `dim_customer` | Customer name, code, market, region, channel (Retailer/Distributor/Direct) |
| `dim_product` | Product code, name, variant, segment, category, division |
| `dim_date` | Date mapping — calendar date to fiscal year (September start) |

### Product Hierarchy

AtliQ's product taxonomy flows top-down:

```
Division  →  Segment  →  Category  →  Product  →  Variant
(e.g., PC)   (Notebook)  (Personal Laptop)  (AQ Aspiron)  (Standard, Premium)
```

This hierarchy is key to understanding aggregation — a monthly revenue figure can be sliced at any level from individual variant down to total division.

---

## Repository Structure

```
├── Basic data exploration.sql              # Schema mapping — customers, markets, products
├── croma sales report for 2021.sql         # Product-level gross sales report, FY2021
├── monthly sales report for croma.sql      # Aggregated monthly gross revenue for Croma
├── yearly sales croma customer.sql         # Annual gross revenue by fiscal year
├── pre_invoiced_sales.sql                  # Full pipeline: gross price → net invoice sales
├── forecast accuracy as per customer.sql   # Supply chain forecast accuracy by customer
│
├── UDF/                                    # User-Defined Functions
│   └── get_fiscal_year.sql                 # Converts calendar date → AtliQ fiscal year
│
├── Stored Procedures/                      # Reusable parameterised query routines
│   ├── get_monthly_gross_sales.sql         # Monthly gross sales for any given customer
│   ├── get_market_badge.sql                # Classifies markets as Gold/Silver by volume
│   └── top_n_products_per_division.sql     # Top N products per division by sold quantity
│
├── Views/                                  # Saved virtual tables for pipeline reuse
│   ├── gross_sales.sql                     # Base view joining sales, products, prices
│   └── net_invoice_sales.sql              # Applies pre-invoice discount to gross sales
│
└── Window Functions/                       # Ranking and analytical calculations
    ├── top_products_by_net_sales.sql        # RANK() / DENSE_RANK() across categories
    └── net_sales_pct_by_region.sql          # % contribution per customer within region
```

---

## Analytical Progression — Stage by Stage

### Stage 1 · Data Exploration

**File:** `Basic data exploration.sql`

Before writing any business queries, the project maps the shape and domain of the data using `SELECT DISTINCT` across key dimension columns:

```sql
-- Understand the customer landscape
SELECT DISTINCT market FROM dim_customer;
SELECT DISTINCT channel FROM dim_customer;
SELECT DISTINCT region FROM dim_customer;

-- Understand the product taxonomy
SELECT DISTINCT division FROM dim_product;
SELECT DISTINCT category FROM dim_product;
```

**Why this matters:** Knowing that AtliQ operates across markets like India, USA, South Korea, Australia — and through three distinct channels — determines how every subsequent GROUP BY and WHERE clause must be written. Skipping this step leads to queries that silently miss data or double-count across channel types.

The exploration also establishes the product hierarchy: Division → Segment → Category → Product → Variant. This informs every aggregation decision — a report "by category" is a different grain than "by product."

---

### Stage 2 · Customer-Level Sales Reporting

**Files:** `croma sales report for 2021.sql`, `monthly sales report for croma.sql`, `yearly sales croma customer.sql`

The analytical work begins with AtliQ's largest Indian retail customer — **Croma (customer_code: 90002002)** — as a focused case study before scaling to the full customer base.

**Granular product-level report (FY2021):**

```sql
SELECT
    MONTH(date) AS month,
    p.product,
    p.variant,
    ROUND(g.gross_price, 2) AS gross_price,
    ROUND(g.gross_price * s.sold_quantity, 2) AS gross_price_total
FROM fact_sales_monthly s
JOIN dim_product p ON p.product_code = s.product_code
JOIN fact_gross_price g ON s.product_code = g.product_code
    AND g.fiscal_year = get_fiscal_year(s.date)
WHERE customer_code = 90002002
    AND get_fiscal_year(date) = 2021
ORDER BY date DESC;
```

**Key design decision — the fiscal year join condition:**  
The `JOIN` between `fact_sales_monthly` and `fact_gross_price` uses `get_fiscal_year(s.date)` to match prices to the correct pricing year. Without this, a sale in November 2020 (which falls in AtliQ's FY2021) would incorrectly pull FY2020 prices. This is a subtle but consequential correctness issue that demonstrates real data warehouse awareness.

**Monthly aggregation:**

The monthly report collapses to total gross price per month — useful for identifying seasonal patterns, peak order months, and year-over-year comparisons at the customer level.

**Annual roll-up:**

The yearly report further aggregates to fiscal year total, answering the executive-level question: *"How has Croma's total spend with AtliQ grown year over year?"*

---

### Stage 3 · Pre-Invoice Deduction Pipeline

**File:** `pre_invoiced_sales.sql`

Moving beyond gross price, this stage builds the first layer of the true revenue pipeline: applying pre-invoice discounts to arrive at **net invoice sales** — what AtliQ actually invoices the customer after agreed discounts.

**The formula:**
```
Net Invoice Sales = Gross Price Total × (1 − Pre-Invoice Discount %)
```

**Approach 1 — Direct JOIN:**

A single query joins five tables: `fact_sales_monthly`, `dim_product`, `dim_customer`, `fact_gross_price`, and `fact_pre_invoice_deductions`. This produces the correct result but becomes difficult to maintain as the pipeline grows more complex.

**Approach 2 — CTE (Common Table Expression):**

The same logic is refactored using a CTE to separate concerns: the inner query assembles the gross price and discount data, and the outer query applies the net calculation cleanly:

```sql
WITH cte AS (
    SELECT
        s.date, s.fiscal_year, s.product_code,
        p.product, p.variant, c.market,
        s.sold_quantity,
        ROUND(s.sold_quantity * g.gross_price, 2) AS gross_price_total,
        pre.pre_invoice_discount_pct
    FROM fact_sales_monthly s
    JOIN dim_customer c ON c.customer_code = s.customer_code
    JOIN dim_product p ON s.product_code = p.product_code
    JOIN fact_gross_price g ON g.fiscal_year = s.fiscal_year
        AND g.product_code = s.product_code
    JOIN fact_pre_invoice_deductions pre ON pre.customer_code = s.customer_code
        AND pre.fiscal_year = s.fiscal_year
)
SELECT *,
    ROUND(gross_price_total * (1 - pre_invoice_discount_pct), 2) AS net_invoice_sales
FROM cte;
```

**Why CTEs over subqueries:**  
CTEs improve readability, allow the intermediate result to be referenced multiple times, and reflect how professional SQL pipelines are structured for maintainability. They also make the query plan easier to reason about during performance tuning.

---

### Stage 4 · Forecast Accuracy Analysis

**File:** `forecast accuracy as per customer.sql`

Shifting from finance to supply chain, this stage measures how accurately AtliQ's customers' demand forecasts matched actual sold quantities — a critical metric for inventory planning and procurement.

```sql
WITH cte AS (
    SELECT
        customer_code,
        SUM(sold_quantity) AS total_quantity,
        SUM(forecast_quantity - sold_quantity) AS net_error,
        SUM(forecast_quantity - sold_quantity) * 100 / SUM(forecast_quantity) AS net_error_pct,
        SUM(ABS(forecast_quantity - sold_quantity)) AS abs_error,
        SUM(ABS(forecast_quantity - sold_quantity)) * 100 / SUM(forecast_quantity) AS abs_error_pct
    FROM gdb041.fact_act_est
    WHERE fiscal_year = 2021
    GROUP BY customer_code
)
SELECT *,
    IF(abs_error_pct > 100, 0, 100 - abs_error_pct) AS forecast_accuracy
FROM cte ct
JOIN dim_customer c ON c.customer_code = ct.customer_code
ORDER BY forecast_accuracy DESC;
```

**Metrics explained:**

| Metric | Formula | What It Reveals |
|---|---|---|
| `net_error` | `Σ(forecast − actual)` | Systematic bias — are forecasts consistently over or under? |
| `net_error_pct` | `net_error / Σforecast × 100` | Relative directional bias |
| `abs_error` | `Σ\|forecast − actual\|` | Total deviation regardless of direction |
| `abs_error_pct` | `abs_error / Σforecast × 100` | Normalised total deviation |
| `forecast_accuracy` | `MAX(0, 100 − abs_error_pct)` | Final 0–100% score. Capped at 0 for extreme deviations |

**Why absolute error over net error:**  
Net error allows overestimates and underestimates to cancel each other out — a customer who over-forecasts by 500 units in January and under-forecasts by 500 units in February shows zero net error but a real operational problem. Absolute error captures both directions, giving a true picture of forecasting volatility.

The `IF(abs_error_pct > 100, 0, ...)` guard handles pathological cases where the absolute error exceeds the total forecast (implying the forecast was almost entirely wrong), clamping the accuracy score to zero rather than producing a negative percentage that would be meaningless.

---

## Database Objects Deep Dive

The top-level SQL files establish the analytical foundation. The four subfolders contain reusable, production-grade database objects that abstract that logic for scalability.

### User-Defined Functions (UDF)

**Folder:** `UDF/`

#### `get_fiscal_year(calendar_date)`

The single most critical function in the project. AtliQ's fiscal year runs September–August: September 2020 to August 2021 is FY2021, not FY2020.

Without this function, every single date-based query in the project would need to manually embed the September-offset logic. With it, fiscal year conversion becomes a single, tested, reliable call:

```sql
-- Instead of this brittle inline logic everywhere:
CASE WHEN MONTH(date) >= 9 THEN YEAR(date) + 1 ELSE YEAR(date) END

-- The project uses this everywhere:
get_fiscal_year(date)  -- returns 2021, 2022, etc.
```

**Impact:** Every join between `fact_sales_monthly` and `fact_gross_price` depends on this function for correctness. A bug here would silently corrupt every revenue figure in the system — encapsulating it in a UDF means it's tested once and trusted everywhere.

---

### Stored Procedures

**Folder:** `Stored Procedures/`

Stored procedures convert ad-hoc queries into parameterised, callable routines — the equivalent of Python functions in SQL. They eliminate copy-paste query duplication and allow any stakeholder or downstream system to retrieve consistent results with a single `CALL`.

#### `get_monthly_gross_sales(in_customer_code)`

Accepts a customer code and returns that customer's complete monthly gross sales history. Instead of hard-coding `customer_code = 90002002` for Croma, the procedure accepts any customer code, making it reusable across the entire customer base.

```sql
CALL get_monthly_gross_sales(90002002);   -- Croma India
CALL get_monthly_gross_sales(90002016);   -- Any other customer
```

#### `get_market_badge(in_market, in_fiscal_year, OUT out_badge)`

Classifies any given market as **"Gold"** or **"Silver"** based on total sold quantity exceeding a threshold (typically 5 million units) in a given fiscal year. This type of market segmentation is used in tiered pricing strategies and account management.

The use of an `OUT` parameter is intentional — it makes the badge value composable, allowing it to be used inside larger procedures or application code rather than requiring a results set to be parsed.

#### `top_n_products_per_division(in_fiscal_year, in_top_n)`

Returns the top N products within each division ranked by total sold quantity. The parameterised `in_top_n` value makes it trivial to pull a Top 5 for an executive summary or a Top 20 for a detailed product review — the same procedure serves both.

---

### Views

**Folder:** `Views/`

Views are saved virtual tables — named queries that behave like tables in subsequent queries. Rather than duplicating complex multi-table JOIN logic across every downstream query, views encapsulate it once so higher-level queries can read cleanly.

#### `gross_sales` (view)

Joins `fact_sales_monthly`, `dim_product`, `dim_customer`, and `fact_gross_price` with the fiscal year match into a single reusable view. Any query that needs gross sales data can now read from this view with a simple `SELECT` rather than rewriting four-table JOIN logic.

#### `net_invoice_sales` (view)

Extends `gross_sales` by joining `fact_pre_invoice_deductions` and applying the discount calculation. This view represents the first materialisable layer of AtliQ's P&L — the revenue figure after customer discounts but before post-invoice adjustments.

**The view pipeline:**

```
fact_sales_monthly
       ↓
  gross_sales (view)                ← adds product, customer, price context
       ↓
  net_invoice_sales (view)          ← applies pre-invoice discount
       ↓
  (future) net_sales (view)         ← would apply post-invoice deductions
```

This layered view architecture mirrors how real data warehouses are structured: each layer adds one transformation, each is independently testable, and downstream reports always read from the most appropriate layer.

---

### Window Functions

**Folder:** `Window Functions/`

Window functions perform calculations *across a set of rows related to the current row* without collapsing the result set the way `GROUP BY` does. They enable a class of business questions that are impossible to answer with simple aggregation.

#### Top products by net sales — `RANK()` and `DENSE_RANK()`

Ranks products within their category by net sales, enabling questions like: *"For each product category, which products are in the top tier by revenue?"*

```sql
RANK() OVER (PARTITION BY category ORDER BY net_sales DESC) AS rank_in_category
```

The distinction between `RANK()` and `DENSE_RANK()` matters here: `RANK()` leaves gaps after ties (1, 2, 2, 4) while `DENSE_RANK()` does not (1, 2, 2, 3). For a "Top 3 products" report, `DENSE_RANK() <= 3` correctly captures all products that tied for third, whereas `RANK() <= 3` would miss them.

#### Net sales percentage by region

Calculates each customer's percentage contribution to their region's total net sales — a classic share-of-wallet analysis:

```sql
net_sales * 100 / SUM(net_sales) OVER (PARTITION BY region) AS pct_share
```

This is not possible with a single `GROUP BY` query because that would collapse customer-level detail. The window function retains individual rows while simultaneously computing the regional total in the denominator.

---

## Key SQL Concepts Demonstrated

| Concept | Where Used | Purpose |
|---|---|---|
| Multi-table `JOIN` | All sales reports | Linking fact and dimension tables |
| `GROUP BY` with `SUM()` | Monthly/yearly reports | Aggregating sales by time period |
| Fiscal year UDF | All date-filtered queries | Correct September-offset year mapping |
| CTE (`WITH` clause) | `pre_invoiced_sales.sql`, forecast accuracy | Readable, maintainable multi-step logic |
| Stored Procedures | `Stored Procedures/` folder | Parameterised, reusable query routines |
| `OUT` parameters | `get_market_badge` | Composable results for downstream use |
| Views | `Views/` folder | Layered, reusable transformation pipeline |
| `RANK()` / `DENSE_RANK()` | Window Functions folder | Rankings within partitions |
| `SUM() OVER (PARTITION BY)` | Net sales percentage | Running totals and share-of-total |
| `IF()` conditional | Forecast accuracy | Clamping edge case values |
| `ABS()` for error metrics | Forecast accuracy | Directional-neutral deviation |

---

## Business Questions Answered

| Business Question | SQL Technique | File |
|---|---|---|
| What markets, channels, and product categories does AtliQ operate in? | `DISTINCT` exploration | `Basic data exploration.sql` |
| What did Croma India buy from AtliQ by product in FY2021? | Multi-table JOIN + UDF | `croma sales report for 2021.sql` |
| What were Croma's total monthly gross revenue figures? | JOIN + GROUP BY date | `monthly sales report for croma.sql` |
| How has Croma's annual spend grown year over year? | GROUP BY fiscal year | `yearly sales croma customer.sql` |
| What is each customer's net invoice sales after their discount? | 5-table JOIN + CTE | `pre_invoiced_sales.sql` |
| Which customers forecast demand most and least accurately? | CTE + ABS() + IF() | `forecast accuracy as per customer.sql` |
| What are the top N products per division by volume? | Stored Procedure | `Stored Procedures/` |
| Is a given market Gold or Silver tier? | Stored Procedure + OUT | `Stored Procedures/` |
| How do products rank within their category by net sales? | RANK() / DENSE_RANK() | `Window Functions/` |
| What % of regional net sales does each customer represent? | SUM() OVER PARTITION | `Window Functions/` |

---

## Why This Architecture Matters

A data analyst who only writes ad-hoc SELECT queries is limited to answering questions one at a time. This project demonstrates the next level — building a **queryable analytics infrastructure**:

**Encapsulation via UDFs** means business logic (like fiscal year calculation) is defined once and trusted everywhere. Change it in one place and every query in the system benefits.

**Stored procedures** enable non-SQL stakeholders — sales operations, finance teams, BI tools — to retrieve consistent, parameterised reports without knowing query internals. They are also the foundation of scheduled reporting automation.

**Layered views** create a transformation pipeline where each layer adds exactly one business rule. This mirrors the Bronze/Silver/Gold architecture used in modern data lakehouses — raw data in, clean aggregated data out, with every intermediate state inspectable.

**Window functions** unlock analytics that cannot be expressed with aggregation alone — rankings, running totals, percentage contributions, period-over-period comparisons. These are the queries that convert raw transactional data into the ranked, compared, and benchmarked figures that actually drive decisions.

Together, these techniques represent how SQL is used in production analytics environments, not just in learning exercises.

---

## Getting Started

**Requirements:**
- MySQL 8.0+ (window functions and CTEs require 8.0)
- Access to the AtliQ Hardware database (`gdb041` schema)
- The database is provided as part of the [Codebasics SQL course](https://codebasics.io/) — enroll to get the full dataset

**Recommended execution order:**

1. `Basic data exploration.sql` — orient yourself in the schema
2. `UDF/get_fiscal_year.sql` — install the fiscal year function first (required by almost everything else)
3. `croma sales report for 2021.sql` → `monthly sales report for croma.sql` → `yearly sales croma customer.sql` — build up the sales reporting progression
4. `Views/gross_sales.sql` → `Views/net_invoice_sales.sql` — create the view pipeline
5. `pre_invoiced_sales.sql` — see the full query before it was abstracted into views
6. `Stored Procedures/` — install the procedures
7. `forecast accuracy as per customer.sql` — supply chain analysis
8. `Window Functions/` — advanced analytics layer

**To use a stored procedure after installation:**

```sql
-- Monthly gross sales for any customer
CALL get_monthly_gross_sales(90002002);

-- Market badge classification
SET @badge = '';
CALL get_market_badge('India', 2021, @badge);
SELECT @badge;

-- Top 5 products per division
CALL top_n_products_per_division(2021, 5);
```

---

*Database: AtliQ Hardware (Codebasics) · Engine: MySQL 8.0 · Techniques: UDFs, Stored Procedures, Views, CTEs, Window Functions*
