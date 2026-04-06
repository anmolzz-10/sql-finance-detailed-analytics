## Monthy aggregated sales report for croma customer 
-- Fields
-- Month
-- total gross for that month for croma in india
select s.date,
sum(round(s.sold_quantity * g.gross_price,2)) as total_gross_price
from fact_sales_monthly s
JOIN fact_gross_price g ON
s.product_code = g.product_code and 
g.fiscal_year = get_fiscal_year(s.date)
where customer_code = 90002002
group by s.date
order by s.date asc
