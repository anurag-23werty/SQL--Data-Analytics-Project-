create view gold.report_customers as
with base_query as(SELECT
    f.order_number,
    f.product_key,
    f.order_date,
    f.sales_amount,
    f.quantity,
    c.customer_key,
    c.customer_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    EXTRACT(
        YEAR FROM AGE(
            CURRENT_DATE,
            NULLIF(c.birthdate, '')::date
        )
    ) AS age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL
  AND order_date <> '')

,customer_aggregation as 
(select 
customer_key,
customer_number,
customer_name,
age,
count(distinct order_number) as total_orders,
sum(sales_amount) as total_sales,
sum(quantity) as total_quantity,
COUNT(DISTINCT product_key) AS total_products,
MAX(order_date :: date) AS last_order_date,
(
        EXTRACT(YEAR FROM AGE(MAX(order_date::date),
                              MIN(order_date::date))) * 12
        +
        EXTRACT(MONTH FROM AGE(MAX(order_date::date),
                               MIN(order_date::date)))
    ) AS lifespan
from base_query
group by 
customer_key,
customer_number,
customer_name,
age 
)

select 
customer_key,
customer_number,
customer_name,
age,
case
	when age<20 then 'UNDER 20'
	when age between 20 and 29 then '20-29'
	when age between 30 and 39 then '30-39'
	when age between 40 and 49 then '40-49'
	else '50 and above'
end as age_group,
case
	when lifespan>=12 and total_sales>5000 then 'VIP'
	when lifespan>=12 and total_sales<=5000 then'Regular'
	else 'new'
end as customer_segment,
last_order_date,

 extract(month from AGE(last_order_date,CURRENT_DATE)) as recency,
 total_orders,
total_sales,
total_quantity,
total_products
lifespan,
CASE WHEN total_sales = 0 THEN 0
	 ELSE total_sales / total_orders
END AS avg_order_value,
-- Compuate average monthly spend
CASE WHEN lifespan = 0 THEN total_sales
     ELSE total_sales / lifespan
END AS avg_monthly_spend
FROM customer_aggregation
