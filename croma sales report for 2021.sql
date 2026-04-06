## Generate a report of individual product sales(aggregated on motnhly basis at the product code level.
# for chroma india customer for FY = 2021
-- Month
-- Product Name
-- Variant
-- Sold Quantity
-- Gross Price per Item
-- Gross Price Total
  
select month(date) as month, p.product,p.variant,
round(g.gross_price,2) as gross_price,round(g.gross_price* s.sold_quantity,2) as gross_price_total
from fact_sales_monthly s
JOIN dim_product p
 ON p.product_code= s.product_code 
 JOIN fact_gross_price g
 ON s.product_code = g.product_code and
 g.fiscal_year = get_fiscal_year(s.date)
 where customer_code = 90002002 and
get_fiscal_year(date) = 2021
 order by date desc
 