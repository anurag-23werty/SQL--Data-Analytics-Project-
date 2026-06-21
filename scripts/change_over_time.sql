select
    EXTRACT(year FROM order_date::date) AS order_year,
    EXTRACT(month FROM order_date::date) AS order_month,
    SUM(sales_amount) AS total_sales,
    count(distinct customer_key) as total_customers,
    sum(quantity) as total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
  AND order_date <> ''
GROUP BY EXTRACT(year FROM order_date::date),order_month
ORDER BY order_year,order_month; 
