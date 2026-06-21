WITH yearly_product_sales AS (
    SELECT
        EXTRACT(YEAR FROM f.order_date::date) AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
      AND f.order_date <> ''
    GROUP BY
        EXTRACT(YEAR FROM f.order_date::date),
        p.product_name
),

sales_analysis AS (
    SELECT
        order_year,
        product_name,
        current_sales,

        AVG(current_sales) OVER
            (PARTITION BY product_name) AS avg_sales,

        current_sales -
        AVG(current_sales) OVER
            (PARTITION BY product_name) AS diff_avg,

        LAG(current_sales) OVER
            (PARTITION BY product_name ORDER BY order_year) AS py_sales

    FROM yearly_product_sales
)

SELECT
    *,
    CASE
        WHEN diff_avg > 0 THEN 'ABOVE AVG'
        WHEN diff_avg < 0 THEN 'BELOW AVG'
        ELSE 'AVG'
    END AS avg_change,

    current_sales - py_sales AS diff_py,

    CASE
        WHEN current_sales - py_sales > 0 THEN 'Increase'
        WHEN current_sales - py_sales < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS py_change

FROM sales_analysis
ORDER BY product_name, order_year;
