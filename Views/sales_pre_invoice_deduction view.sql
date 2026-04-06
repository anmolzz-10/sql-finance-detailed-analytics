CREATE VIEW `fact_pre_invoice_deductions` AS
SELECT 
    	   s.date, 
           s.fiscal_year,
           s.customer_code,
           s.product_code, 
           p.product, 
	   p.variant, 
       c.market,
           s.sold_quantity, 
           g.gross_price as gross_price_per_item,
           ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total,
           pre.pre_invoice_discount_pct
	FROM fact_sales_monthly s
    Join dim_customer c 
    ON c.customer_code = s.customer_code
	JOIN dim_product p              
            ON s.product_code=p.product_code
	JOIN fact_gross_price g
    	    ON g.fiscal_year=s.fiscal_year
    	    AND g.product_code=s.product_code
	JOIN fact_pre_invoice_deductions as pre
            ON pre.customer_code = s.customer_code AND
            pre.fiscal_year=s.fiscal_year   

    