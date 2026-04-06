with cte1 as (
SELECT s.market,c.region,
round(sum(s.gross_price_total)/1000000,2) as total_gross_mln 
FROM gdb041.net_sales s
join dim_customer c on
c.customer_code = s.customer_code 
where fiscal_year = 2021

group by s.market,c.region),

cte2 as (select *, dense_rank() over(partition by region order by total_gross_mln desc )
as drnk from cte1)

select * from cte2 where drnk <=2;

##same query with gross_sales view
with cte1 as (SELECT s.market, c.region, 
round(sum(gross_price_total)/1000000,2) as gross_total_mln
from gross_sales s
JOIN dim_customer c ON
c.customer_code = s.customer_code
where fiscal_year = 2021
group by s.market,c.region ),
cte2 as (SELECT *, 
dense_rank() over(partition by region order by gross_total_mln desc) as drnk from cte1)
select * from cte2 where drnk <=2

