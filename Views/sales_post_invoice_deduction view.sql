CREATE VIEW `fact_post_invoice_deductions` AS
SELECT     	
			s.date, s.fiscal_year,
            s.customer_code, s.market,
            s.product_code, s.product, s.variant,
            s.sold_quantity, s.gross_price_total,
            s.pre_invoice_discount_pct, round(gross_price_total * (1-pre_invoice_discount_pct),2) as net_invoice_sales,
			(po.discounts_pct+po.other_deductions_pct) as post_invoice_discount_pct 
			from sales_preinv_discount s
			JOIN fact_post_invoice_deductions po
			ON po.customer_code = s.customer_code and
			po.product_code = s.product_code  and 
			po.date = s.date