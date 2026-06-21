with product_segments as(
	select
	product_key,
	cost,
	case 
		when cost<100 then 'below 100'
		when cost between 100 and 500 then '100-500'
		when cost between 500 and 1000 then '500-1000'
		else 'above 1000'
	end as cost_range
	from gold.dim_products
)
select 
cost_range,
count(product_key) as total_products
from product_segments 
group by cost_range 
order by total_products desc;
with customer_spending as(SELECT
    c.customer_key,
    SUM(f.sales_amount) AS total_spending,
    MIN(order_date::date) AS first_order,
    MAX(order_date::date) AS last_order,
    (
        EXTRACT(YEAR FROM AGE(MAX(order_date::date),
                              MIN(order_date::date))) * 12
        +
        EXTRACT(MONTH FROM AGE(MAX(order_date::date),
                               MIN(order_date::date)))
    ) AS lifespan
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
WHERE order_date IS NOT NULL
  AND order_date <> ''
GROUP BY c.customer_key
)
select
customer_segment,
count(customer_key) as total_customers
from
(select customer_key,
case
	when lifespan>=12 and total_spending>5000 then 'VIP'
	when lifespan>=12 and total_spending<=5000 then 'Regular'
	else 'New'
end as customer_segment
from customer_spending 
) as segmented_customers
group by customer_segment 
order by total_customers
