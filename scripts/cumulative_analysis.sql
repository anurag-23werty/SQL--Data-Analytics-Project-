SELECT
    order_month,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_month) AS running_total_sales
FROM
(
    SELECT
        DATE_TRUNC('month', order_date::date) AS order_month,
        SUM(sales_amount) AS total_sales
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
      AND order_date <> ''
    GROUP BY DATE_TRUNC('month', order_date::date)
) t
ORDER BY order_month;
