CREATE PROCEDURE `get_top_n_customers`(
in_market varchar(55),
in_fiscal_year int,
in_top_n int )
BEGIN
SELECT c.customer,round(sum(net_sales)/1000000,2) as net_sales_mln 
FROM gdb041.net_sales s
JOIN dim_customer c
ON s.customer_code = c.customer_code
where s.fiscal_year =in_fiscal_year and s.market = in_market
group by c.customer
order by net_sales_mln desc limit in_top_n;
END