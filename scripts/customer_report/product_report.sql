create view gold.report_products as
with base_query as(
select
f.order_number,
f.order_date,
f.customer_key,
f.sales_amount,
f.quantity,
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost
from gold.fact_sales f
left join gold.dim_products p
on f.product_key = p.product_key
where order_date is not null 
and order_date <> ''
)
,

product_aggregations as(
  select
  product_key,
  product_name,
  category,
  subcategory,
  cost,
  MAX(order_date :: date) AS last_sale_date,
(
        EXTRACT(YEAR FROM AGE(MAX(order_date::date),
                              MIN(order_date::date))) * 12
        +
        EXTRACT(MONTH FROM AGE(MAX(order_date::date),
                               MIN(order_date::date)))
    ) AS lifespan,
count(distinct order_number) as total_orders,
count(distinct customer_key) as total_customers,
SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
	ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0))::numeric,1) AS avg_selling_price
FROM base_query

GROUP BY
    product_key,
    product_name,
    category,
    subcategory,
    cost
)
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,

    (
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, last_sale_date)) * 12
        +
        EXTRACT(MONTH FROM AGE(CURRENT_DATE, last_sale_date))
    ) AS recency_in_months,

    CASE
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,

    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,

    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_revenue,

    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_revenue

FROM product_aggregations;
