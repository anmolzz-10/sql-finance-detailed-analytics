##Basic exploration on customer table
SELECT distinct market from dim_customer
SELECT distinct channel from dim_customer
SELECT distinct region from dim_customer

##Basic exploration on products table
SELECT distinct division from dim_product
SELECT distinct category from dim_product
##hierarchy of products: division --> segment --> category --> product --> variant


