with cte as (SELECT 
customer_code,
sum(sold_quantity) as total_quantity, 
sum(forecast_quantity - sold_quantity) as net_error,
sum((forecast_quantity - sold_quantity))*100/sum(forecast_quantity) as net_error_pct,
sum(abs(forecast_quantity - sold_quantity)) as abs_error,
sum(abs(forecast_quantity - sold_quantity))*100/sum(forecast_quantity) as abs_error_pct
 FROM gdb041.fact_act_est
 where fiscal_year = 2021
 group by customer_code
 order by abs_error_pct desc)
 
 select *, 
 if(abs_error_pct > 100,0,100-abs_error_pct) as forecast_accuracy
 from cte ct
 JOIN dim_customer c ON
 c.customer_code = ct.customer_code
 order by forecast_accuracy desc
 
