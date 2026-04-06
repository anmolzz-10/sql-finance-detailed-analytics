Select s.fiscal_year, round(sum(s.sold_quantity* g.gross_price),2) as total_gross
from fact_sales_monthly s
JOIN fact_gross_price g
ON s.product_code = g.product_code
WHERE customer_code = 90002002 
group by s.fiscal_year