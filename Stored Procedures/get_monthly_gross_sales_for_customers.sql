CREATE DEFINER=`root`@`localhost` PROCEDURE `get_monthly_gross_sales_for_customer`(
     in_customer_codes TEXT
)
BEGIN
    SELECT 
        s.date, 
        SUM(ROUND(s.sold_quantity * g.gross_price, 2)) AS monthly_sales
    FROM fact_sales_monthly s
    LEFT JOIN fact_gross_price g  -- Change to LEFT JOIN to ensure missing matches don't remove data
        ON g.fiscal_year = get_fiscal_year(s.date) 
        AND s.product_code = g.product_code
    WHERE find_in_set(s.customer_code,in_customer_codes)>0  ##find_in_set ensures if customer code from sales belongs to a set of customer_codes as input. One customer can have multiple customer codes in real life business scenarios 
    GROUP BY s.date 
    order by s.date asc;
END