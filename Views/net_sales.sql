CREATE VIEW `net_sales` AS
SELECT *,round(net_invoice_sales* (1-post_invoice_discount_pct),2) as net_sales 
FROM sales_postinv_discount