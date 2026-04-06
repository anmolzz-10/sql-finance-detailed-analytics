##first cte joins tables and calculates sum of sold quantity
with cte1 as (
select p.division,p.product,sum(s.sold_quantity) as total_qty
from fact_sales_monthly s
JOIN dim_product p
ON s.product_code = p.product_code
where fiscal_year =2021
group by p.division,p.product),

##second cte calculates rank
cte2 as (select *,
dense_rank() over(partition by division order by total_qty desc) as Quantity_rank
from cte1)

select * from cte2 where Quantity_rank <=3