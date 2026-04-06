CREATE DEFINER=`root`@`localhost` PROCEDURE `market_badge`(
IN in_fiscal_years int,
IN in_markets varchar(45) ,
OUT out_badge varchar(45) 
)
BEGIN
declare qty int default 0;

##set default market to india

if in_markets  = "" then
set in_markets = "India";
end if ;

##retrieve total qty for a given market+year 
select  sum(s.sold_quantity) INTO qty ##INTO is used to capture a value from a query select statement
from fact_sales_monthly s JOIN
dim_customer c ON 
s.customer_code =c.customer_code
WHERE 
fiscal_year =in_fiscal_years and c.market = in_markets
group by c.market ;

##determine market badge
if qty >5000000 then 
set out_badge = "gold";
else 
set out_badge = "silver";
end if;

END