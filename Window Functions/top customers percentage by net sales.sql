with cte as (SELECT c.customer,round(sum(net_sales)/1000000,2) as net_sales_mln 
FROM gdb041.net_sales s
JOIN dim_customer c
ON s.customer_code = c.customer_code
where s.fiscal_year =2021
group by c.customer)

select *, net_sales_mln*100/sum(net_sales_mln) 
over() as pct from cte
order by pct desc